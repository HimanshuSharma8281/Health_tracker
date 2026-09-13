import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart' show Content;
import '../models/user_profile.dart';
import 'health_data_controller.dart';
import '../services/aurora_api_service.dart';

class AuroraChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;
  final String status; // 'sent', 'sending', 'error'

  AuroraChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.status = 'sent',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
      };

  factory AuroraChatMessage.fromJson(Map<String, dynamic> json) =>
      AuroraChatMessage(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        role: json['role'] as String? ?? 'assistant',
        text: json['text'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        status: json['status'] as String? ?? 'sent',
      );
}

class AuroraChatController extends ChangeNotifier {
  static const String _defaultGreeting =
      'Hello! I am Aurora, your clinical AI health coach. I can access your real health readings and score history to answer questions, analyze trends, or provide guidance. What would you like to know today?';

  final List<AuroraChatMessage> _messages = [];
  final List<Content> _conversationHistory = [];
  bool _isTyping = false;
  String? _currentUid;
  bool _isLoaded = false;

  List<AuroraChatMessage> get messages => List.unmodifiable(_messages);
  List<Content> get conversationHistory => List.unmodifiable(_conversationHistory);
  bool get isTyping => _isTyping;
  bool get isLoaded => _isLoaded;
  String? get currentUid => _currentUid;

  /// Loads chat history from local SharedPreferences for the given user.
  Future<void> loadHistory(String? uid) async {
    final targetUid = (uid != null && uid.isNotEmpty) ? uid : 'guest';
    if (_isLoaded && _currentUid == targetUid) return;

    _currentUid = targetUid;
    _messages.clear();
    _conversationHistory.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'aurora_chat_history_$targetUid';
      final jsonStr = prefs.getString(key);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _messages.add(AuroraChatMessage.fromJson(item));
          }
        }
      }
    } catch (e) {
      debugPrint('[AuroraChatController] Error loading chat history: $e');
    }

    if (_messages.isEmpty) {
      _messages.add(
        AuroraChatMessage(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          role: 'assistant',
          text: _defaultGreeting,
          timestamp: DateTime.now(),
        ),
      );
    }

    // Rebuild in-memory Content history for API continuity
    _rebuildConversationHistory();

    _isLoaded = true;
    notifyListeners();
  }

  void _rebuildConversationHistory() {
    _conversationHistory.clear();
    for (final m in _messages) {
      if (m.text.isNotEmpty && m.id != 'welcome') {
        _conversationHistory.add(Content.text(m.text));
      }
    }
  }

  /// Persists current messages to SharedPreferences.
  Future<void> _saveHistory() async {
    if (_currentUid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'aurora_chat_history_$_currentUid';
      final jsonList = _messages.map((m) => m.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[AuroraChatController] Error saving chat history: $e');
    }
  }

  /// Sends a message, triggers tool execution, syncs health actions, and stores response.
  Future<AuroraChatResult> sendMessage({
    required String text,
    required String uid,
    required HealthDataController healthData,
    UserProfile? userProfile,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isTyping) {
      return AuroraChatResult(
        text: '',
        updatedHistory: _conversationHistory,
        isBackend: false,
      );
    }

    if (_currentUid != uid) {
      await loadHistory(uid);
    }

    final userMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final userMessage = AuroraChatMessage(
      id: userMsgId,
      role: 'user',
      text: cleanText,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isTyping = true;
    notifyListeners();
    await _saveHistory();

    AuroraChatResult result;
    try {
      result = await AuroraApiService.chat(
        uid: uid,
        userMessage: cleanText,
        conversationHistory: _conversationHistory,
        healthData: healthData,
        userProfile: userProfile,
      );

      // Persist and synchronize any executed actions (e.g. water logging)
      if (result.executedAction != null) {
        final action = result.executedAction!;
        final actionType = action['action']?.toString();
        if (actionType == 'water_logged' || actionType == 'log_water') {
          final logged = (action['amount_ml'] as num?)?.toInt() ??
              (action['logged_ml'] as num?)?.toInt() ??
              0;
          final newTotal = (action['new_total_ml'] as num?)?.toInt() ??
              (healthData.waterMl + logged);
          final recordId = action['record_id']?.toString();

          debugPrint('[AuroraChatController] Syncing water action: logged=$logged ml, newTotal=$newTotal ml, recordId=$recordId');
          healthData.syncWaterFromAction(
            loggedMl: logged,
            newTotalMl: newTotal,
            recordId: recordId,
          );
        }
      }

      final assistantMsgId = 'resp_${DateTime.now().millisecondsSinceEpoch}';
      final assistantMessage = AuroraChatMessage(
        id: assistantMsgId,
        role: 'assistant',
        text: result.text,
        timestamp: DateTime.now(),
      );

      _messages.add(assistantMessage);
      _conversationHistory.clear();
      _conversationHistory.addAll(result.updatedHistory);
    } catch (e) {
      debugPrint('[AuroraChatController] Error in chat: $e');
      final errorMsgId = 'err_${DateTime.now().millisecondsSinceEpoch}';
      _messages.add(
        AuroraChatMessage(
          id: errorMsgId,
          role: 'assistant',
          text: 'I ran into an issue processing your health request. Please try again in a moment.',
          timestamp: DateTime.now(),
          status: 'error',
        ),
      );
      result = AuroraChatResult(
        text: 'Error processing request',
        updatedHistory: _conversationHistory,
        isBackend: false,
        error: e.toString(),
      );
    } finally {
      _isTyping = false;
      await _saveHistory();
      notifyListeners();
    }

    return result;
  }

  /// Clears the chat history and resets to default greeting.
  Future<void> clearHistory() async {
    _messages.clear();
    _conversationHistory.clear();
    _messages.add(
      AuroraChatMessage(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        text: _defaultGreeting,
        timestamp: DateTime.now(),
      ),
    );
    await _saveHistory();
    notifyListeners();
  }
}

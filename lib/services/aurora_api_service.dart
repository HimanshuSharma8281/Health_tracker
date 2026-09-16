import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart' show Content;
import '../controllers/health_data_controller.dart';
import '../models/user_profile.dart';
import 'health_agent_service.dart';

class AuroraChatResult {
  final String text;
  final List<Content> updatedHistory;
  final List<String> toolsCalled;
  final Map<String, dynamic>? pendingAction;
  final Map<String, dynamic>? executedAction;
  final List<String> sources;
  final bool isBackend;
  final String? error;

  AuroraChatResult({
    required this.text,
    required this.updatedHistory,
    this.toolsCalled = const [],
    this.pendingAction,
    this.executedAction,
    this.sources = const [],
    this.isBackend = true,
    this.error,
  });
}

class AuroraApiService {
  static const String _envHost = String.fromEnvironment('AURORA_BACKEND_URL');

  static const String productionBackendUrl =
      'https://aurora-ai-backend-vcmb.onrender.com';

  static String get baseUrl {
    if (_envHost.isNotEmpty) return _envHost;
    return productionBackendUrl;
  }

  /// Sends a message to the Agentic Python Backend, with automatic local fallback.
  static Future<AuroraChatResult> chat({
    required String uid,
    required String userMessage,
    List<Content>? conversationHistory,
    HealthDataController? healthData,
    UserProfile? userProfile,
  }) async {
    try {
      debugPrint('[AuroraAPI] Sending request to: $baseUrl/api/v1/chat');
      debugPrint('[AuroraAPI] Request started');

      // Fetch Firebase Auth ID token if signed in
      String? idToken;
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          idToken = await currentUser.getIdToken();
        }
      } catch (e) {
        debugPrint('[AuroraAPI] Token fetch note: $e');
      }

      // Prepare client-side metrics snapshot to assist backend context
      final clientSnapshot = <String, dynamic>{
        'user_name': userProfile?.name ?? healthData?.username ?? 'User',
        'water_ml': healthData?.waterMl ?? 0,
        'water_goal': healthData?.waterGoal ?? 2500,
        'steps': healthData?.stepsToday ?? 0,
        'step_goal': healthData?.stepGoal ?? 10000,
        'sleep_hours': healthData?.sleepHours ?? 0.0,
        'sleep_goal': healthData?.sleepGoal ?? 8.0,
        'calories': healthData?.caloriesConsumed.round() ?? 0,
        'calorie_goal': healthData?.calorieGoal.round() ?? 2000,
        'heart_rate': healthData?.heartRate ?? 0.0,
        'today_score': healthData?.todayScore?.overall,
        'score_label': healthData?.todayScore?.label,
      };

      // Format messages history for the backend
      final historyPayload = <Map<String, String>>[];
      if (conversationHistory != null) {
        for (final item in conversationHistory) {
          final role = item.role == 'user' ? 'user' : 'assistant';
          final content = item.parts.map((p) => p.toString()).join(' ');
          historyPayload.add({'role': role, 'content': content});
        }
      }

      final requestBody = jsonEncode({
        'message': userMessage,
        'history': historyPayload,
        'client_snapshot': clientSnapshot,
      });

      final uri = Uri.parse('$baseUrl/api/v1/chat');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${idToken ?? "dev_$uid"}',
      };

      final response = await http
          .post(uri, headers: headers, body: requestBody)
          .timeout(const Duration(seconds: 90));

      debugPrint('[AuroraAPI] HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('[AuroraAPI] Backend response received');
        debugPrint('[AuroraAPI] Using backend Aurora response');
        debugPrint('[AuroraAPI] BACKEND REQUEST SUCCESS');

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final responseText =
            (data['response'] ?? data['message'] ?? '').toString();
        final tools = (data['tools_called'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final sources = (data['sources'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final pendingAction = data['pending_action'] as Map<String, dynamic>?;
        final executedAction = data['executed_action'] as Map<String, dynamic>?;

        final newHistory = List<Content>.from(conversationHistory ?? []);
        newHistory.add(Content.text(userMessage));
        newHistory.add(Content.text(responseText));

        return AuroraChatResult(
          text: responseText,
          updatedHistory: newHistory,
          toolsCalled: tools,
          pendingAction: pendingAction,
          executedAction: executedAction,
          sources: sources,
          isBackend: true,
        );
      } else {
        // Backend was reached but returned an error status code (e.g., 400, 500)
        debugPrint(
            '[AuroraAPI] Backend returned error status: ${response.statusCode}');
        String errorMsg = 'Unable to process health request at this moment.';
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data.containsKey('detail')) {
            errorMsg = data['detail'].toString();
          } else if (data.containsKey('message')) {
            errorMsg = data['message'].toString();
          }
        } catch (_) {}

        final newHistory = List<Content>.from(conversationHistory ?? []);
        newHistory.add(Content.text(userMessage));
        newHistory.add(Content.text(errorMsg));

        return AuroraChatResult(
          text: errorMsg,
          updatedHistory: newHistory,
          toolsCalled: const ['backend_error'],
          isBackend: true,
          error: errorMsg,
        );
      }
    } catch (e) {
      debugPrint('[AuroraAPI] Backend unreachable — emergency local fallback');
      debugPrint('[AuroraAPI] Exact failure reason: $e');
    }

    // Emergency local fallback only when backend is genuinely unreachable (network failure / offline)
    final localResult = await HealthAgentService.chat(
      uid: uid,
      userMessage: userMessage,
      conversationHistory: conversationHistory,
      healthData: healthData,
      userProfile: userProfile,
    );

    return AuroraChatResult(
      text: localResult.text,
      updatedHistory: localResult.updatedHistory,
      toolsCalled: const ['local_health_agent'],
      isBackend: false,
      error: localResult.error,
    );
  }

  /// Confirm a pending action (e.g., drastic goal change)
  static Future<bool> confirmAction({
    required String actionId,
    required bool confirmed,
  }) async {
    try {
      String? idToken;
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          idToken = await currentUser.getIdToken();
        }
      } catch (_) {}

      final uri = Uri.parse('$baseUrl/api/v1/actions/confirm');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${idToken ?? "dev_user"}',
      };
      final body = jsonEncode({
        'action_id': actionId,
        'confirmed': confirmed,
      });

      final res = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('[AuroraAPI] confirmAction error: $e');
    }
    return false;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';
import 'aurora_api_service.dart';

class GeminiAIService {
  static String get _apiKey => ApiKeys.geminiApiKey;

  static Future<List<String>> generateHealthInsights(
      Map<String, dynamic> healthData) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: _apiKey,
      );

      final prompt =
          '''Based on this health data, provide 3 short, actionable wellness insights (max 15 words each):
Steps: ${healthData['steps']} (Goal: ${healthData['stepGoal'] ?? 10000})
Calories: ${healthData['calories']} / ${healthData['calorieGoal']}
Water: ${healthData['water']} ml / ${healthData['waterGoal']} ml
Sleep: ${healthData['sleep']} hrs / ${healthData['sleepGoal']} hrs
Stress: ${(healthData['stress'] * 100).toInt()}%

Format: Return only 3 bullet points, one per line, starting with •''';

      print('📤 Generating health insights...');

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        final insights = response.text!
            .split('\n')
            .where((line) =>
                line.trim().isNotEmpty &&
                (line.contains('•') ||
                    line.contains('-') ||
                    line.contains('*')))
            .map((line) => line.replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim())
            .where((line) => line.isNotEmpty)
            .take(3)
            .toList();

        print('✅ Generated ${insights.length} insights');
        return insights;
      }

      return [];
    } catch (e) {
      print('💥 Error generating insights: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> analyzeFoodImage(
      Uint8List imageBytes) async {
    try {
      print('📤 Sending food image to Aurora backend...');
      print('📦 Image bytes length: ${imageBytes.length}');

      if (imageBytes.isEmpty) {
        throw Exception('Image is empty');
      }

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User is not authenticated');
      }

      final idToken = await currentUser.getIdToken();

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Unable to obtain Firebase authentication token');
      }

      print('🔐 Firebase authentication token acquired');

      final backendUrl = AuroraApiService.baseUrl;

      final uri = Uri.parse(
        '$backendUrl/api/v1/food/analyze',
      );

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      request.headers['Authorization'] = 'Bearer $idToken';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'food_image.jpg',
        ),
      );

      print('🔄 Sending request to Aurora Food Vision backend...');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
      );

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      print(
        '📡 Food Vision HTTP status: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        String errorMessage = 'Food analysis failed';

        try {
          final errorData =
              jsonDecode(response.body) as Map<String, dynamic>;

          errorMessage =
              errorData['detail']?.toString() ??
              errorMessage;
        } catch (_) {}

        throw Exception(errorMessage);
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(
          data['message']?.toString() ??
              'Food analysis failed',
        );
      }

      final result =
          Map<String, dynamic>.from(
        data['data'] as Map,
      );

      print(
        '✅ Food detected: ${result['name']}',
      );

      print(
        '📊 Nutrition: '
        '${result['calories']} kcal, '
        '${result['protein']}g protein, '
        '${result['carbs']}g carbs, '
        '${result['fat']}g fat',
      );

      return result;
    } on TimeoutException {
      print('⏱️ Food Vision backend request timed out');

      throw Exception(
        'Food analysis is taking longer than expected. '
        'Please try again.',
      );
    } catch (e, stackTrace) {
      print('💥 Food image analysis failed: $e');
      print('📚 Stack trace: $stackTrace');

      rethrow;
    }
  }
}

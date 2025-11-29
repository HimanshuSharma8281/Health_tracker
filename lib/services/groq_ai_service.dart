import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class GroqAIService {
  static const String _apiKey = ApiKeys.groqApiKey;
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // Add your methods here to interact with the Groq AI API
  // For example:
  static Future<String> generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to load response');
      }
    } catch (e) {
      rethrow;
    }
  }
}

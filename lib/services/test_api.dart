import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiTester {
  static Future<void> testGeminiApi() async {
    const apiKey = 'AIzaSyCuCie5CbM4O-PHfHEOPIi8WR4rgffijUw';

    print('🧪 Testing Gemini API...');

    try {
      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': 'Say "API works"'}
              ]
            }
          ],
        }),
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ API is working!');
      } else {
        print('❌ API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqAIService {
  static const String _apiKey =
      String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String _baseUrl = 'https://api.groq.com/openai/v1';

  // Analyze food and get nutrition information
  static Future<Map<String, dynamic>> analyzeFoodFromDescription(
      String foodDescription) async {
    print('🤖 Analyzing: $foodDescription with Groq AI');

    try {
      final url = Uri.parse('$_baseUrl/chat/completions');

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a nutrition database. Respond ONLY with valid JSON (no markdown, no code blocks). Format: {"name":"Food Name","calories":150,"protein":"10.0","carbs":"20.0","fat":"5.0","serving":"1 serving"}'
                },
                {
                  'role': 'user',
                  'content': 'Provide nutrition data for: $foodDescription'
                }
              ],
              'temperature': 0.1,
              'max_tokens': 200,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('📡 Groq response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content =
            data['choices'][0]['message']['content'].toString().trim();

        print('📄 AI Response: $content');

        // Clean response (remove markdown if present)
        String cleanContent =
            content.replaceAll('```json', '').replaceAll('```', '').trim();

        try {
          final nutritionData = json.decode(cleanContent);

          return {
            'name': nutritionData['name']?.toString() ?? foodDescription,
            'calories': nutritionData['calories'] is int
                ? nutritionData['calories']
                : int.tryParse(nutritionData['calories'].toString()) ?? 0,
            'protein': nutritionData['protein']
                    ?.toString()
                    .replaceAll('g', '')
                    .trim() ??
                '0',
            'carbs':
                nutritionData['carbs']?.toString().replaceAll('g', '').trim() ??
                    '0',
            'fat':
                nutritionData['fat']?.toString().replaceAll('g', '').trim() ??
                    '0',
            'serving': nutritionData['serving']?.toString() ?? '1 serving',
            'foodId': 'groq_${DateTime.now().millisecondsSinceEpoch}',
          };
        } catch (parseError) {
          print('❌ JSON parse error: $parseError');
          return _getFallbackNutrition(foodDescription);
        }
      } else {
        print('❌ Groq API Error: ${response.statusCode}');
        return _getFallbackNutrition(foodDescription);
      }
    } catch (e) {
      print('❌ Error: $e');
      return _getFallbackNutrition(foodDescription);
    }
  }

  // Fallback nutrition data
  static Map<String, dynamic> _getFallbackNutrition(String foodName) {
    final fallbackData = {
      'chicken': {
        'calories': 165,
        'protein': '31.0',
        'carbs': '0.0',
        'fat': '3.6'
      },
      'rice': {
        'calories': 130,
        'protein': '2.7',
        'carbs': '28.0',
        'fat': '0.3'
      },
      'salmon': {
        'calories': 208,
        'protein': '20.0',
        'carbs': '0.0',
        'fat': '13.0'
      },
      'salad': {
        'calories': 150,
        'protein': '5.0',
        'carbs': '15.0',
        'fat': '8.0'
      },
      'burger': {
        'calories': 354,
        'protein': '16.0',
        'carbs': '30.0',
        'fat': '17.0'
      },
      'pizza': {
        'calories': 285,
        'protein': '12.0',
        'carbs': '36.0',
        'fat': '10.0'
      },
      'pasta': {
        'calories': 220,
        'protein': '8.0',
        'carbs': '43.0',
        'fat': '1.3'
      },
      'default': {
        'calories': 200,
        'protein': '10.0',
        'carbs': '25.0',
        'fat': '5.0'
      },
    };

    final key = foodName.toLowerCase().split(' ').firstWhere(
          (word) => fallbackData.containsKey(word),
          orElse: () => 'default',
        );

    final nutrition = fallbackData[key]!;

    return {
      'name': foodName,
      'calories': nutrition['calories'],
      'protein': nutrition['protein'],
      'carbs': nutrition['carbs'],
      'fat': nutrition['fat'],
      'serving': '1 serving',
      'foodId': 'fallback_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // Search for multiple food items
  static Future<List<Map<String, dynamic>>> searchFoods(String query) async {
    try {
      final url = Uri.parse('$_baseUrl/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a nutrition database. Return top 5 matching foods for the search query. Respond ONLY with a JSON array of objects, each with: name, calories, protein, carbs, fat, serving. No additional text.'
            },
            {'role': 'user', 'content': 'Search foods matching: $query'}
          ],
          'temperature': 0.2,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];

        final foodList = json.decode(content) as List;

        return foodList
            .map((food) => {
                  'name': food['name'] ?? 'Unknown',
                  'calories': food['calories'] ?? 0,
                  'protein': food['protein']?.toString() ?? '0',
                  'carbs': food['carbs']?.toString() ?? '0',
                  'fat': food['fat']?.toString() ?? '0',
                  'serving': food['serving'] ?? '1 serving',
                  'foodId': 'groq_${DateTime.now().millisecondsSinceEpoch}',
                })
            .toList();
      }
      return [];
    } catch (e) {
      print('Error searching foods: $e');
      return [];
    }
  }

  // Generate AI wellness insights
  static Future<List<String>> generateHealthInsights(
      Map<String, dynamic> healthData) async {
    try {
      final url = Uri.parse('$_baseUrl/chat/completions');

      final prompt = '''
Based on this health data, provide 3 personalized wellness insights:
- Steps: ${healthData['steps']}
- Calories: ${healthData['calories']} / ${healthData['calorieGoal']}
- Water: ${healthData['water']}ml / ${healthData['waterGoal']}ml
- Sleep: ${healthData['sleep']}h / ${healthData['sleepGoal']}h
- Stress Level: ${healthData['stress']}

Return as JSON array of strings. Be concise and actionable.
''';

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a wellness coach. Provide actionable health insights based on user data. Return only a JSON array of strings.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 400,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];

        final insights = json.decode(content) as List;
        return insights.map((i) => i.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error generating insights: $e');
      return [];
    }
  }
}

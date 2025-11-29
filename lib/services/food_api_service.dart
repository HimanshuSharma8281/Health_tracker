import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class FoodApiService {
  static const String _groqApiKey =
      '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';
  static const String _groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // Search for food by name using Groq AI
  static Future<List<Map<String, dynamic>>> searchFood(String query) async {
    print('🔍 Searching for: $query using Groq AI');

    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final prompt =
          '''What is the nutritional information for "$query" per typical serving (100g or standard portion)?

Provide exact numbers in this format only:
CALORIES|PROTEIN|CARBS|FAT

Example for chicken breast:
165|31.0|0.0|3.6

Give realistic values based on USDA nutritional database.''';

      final requestBody = {
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a nutrition database. Provide accurate nutritional values based on USDA data. Respond ONLY with numbers in the format: CALORIES|PROTEIN|CARBS|FAT'
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.1, // Lower temperature for more accurate numbers
        'max_tokens': 100,
      };

      print('📤 Sending request to Groq API...');

      final response = await http
          .post(
            Uri.parse(_groqApiUrl),
            headers: {
              'Authorization': 'Bearer $_groqApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Groq API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['choices'] != null && (data['choices'] as List).isNotEmpty) {
          final content = data['choices'][0]['message']['content'] as String;

          print('✅ Groq Response: $content');

          // Parse pipe-delimited format
          final cleanContent =
              content.trim().replaceAll(RegExp(r'[^\d|.]'), '');

          if (cleanContent.contains('|')) {
            final parts = cleanContent.split('|').map((e) => e.trim()).toList();

            if (parts.length >= 4) {
              final calories = int.tryParse(parts[0]) ?? 250;
              final protein = double.tryParse(parts[1]) ?? 10.0;
              final carbs = double.tryParse(parts[2]) ?? 30.0;
              final fat = double.tryParse(parts[3]) ?? 8.0;

              // Validate numbers are reasonable
              if (calories > 0 &&
                  calories < 1000 &&
                  protein >= 0 &&
                  protein < 100 &&
                  carbs >= 0 &&
                  carbs < 100 &&
                  fat >= 0 &&
                  fat < 100) {
                final result = {
                  'name': _formatFoodName(query),
                  'calories': calories,
                  'protein': protein,
                  'carbs': carbs,
                  'fat': fat,
                };

                print(
                    '✅ Parsed: ${result['name']} - ${result['calories']} kcal, ${result['protein']}g protein');
                return [result];
              } else {
                print('⚠️ Numbers out of range, using fallback');
              }
            }
          }

          // Fallback: Try to extract from natural language
          final caloriesMatch =
              RegExp(r'(\d+)\s*(kcal|calories?|cal)', caseSensitive: false)
                  .firstMatch(content);
          final proteinMatch =
              RegExp(r'protein[:\s]*(\d+\.?\d*)', caseSensitive: false)
                  .firstMatch(content);
          final carbsMatch =
              RegExp(r'carb[a-z]*[:\s]*(\d+\.?\d*)', caseSensitive: false)
                  .firstMatch(content);
          final fatMatch = RegExp(r'fat[:\s]*(\d+\.?\d*)', caseSensitive: false)
              .firstMatch(content);

          if (caloriesMatch != null) {
            final result = {
              'name': _formatFoodName(query),
              'calories': int.tryParse(caloriesMatch.group(1)!) ?? 250,
              'protein':
                  double.tryParse(proteinMatch?.group(1) ?? '10.0') ?? 10.0,
              'carbs': double.tryParse(carbsMatch?.group(1) ?? '30.0') ?? 30.0,
              'fat': double.tryParse(fatMatch?.group(1) ?? '8.0') ?? 8.0,
            };

            print('✅ Extracted from text: ${result['name']}');
            return [result];
          }
        }
      } else {
        print('❌ Groq API Error: ${response.statusCode}');
        print('📋 Error details: ${response.body}');
      }

      print('⚠️ Using fallback nutrition data');
      return [_getFallbackNutrition(query)];
    } catch (e) {
      print('❌ Search error: $e');
      return [_getFallbackNutrition(query)];
    }
  }

  static String _formatFoodName(String rawName) {
    return rawName
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim()
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static Map<String, dynamic> _getFallbackNutrition(String foodName) {
    final nutritionDatabase = {
      'chicken': {'calories': 248, 'protein': 46.5, 'carbs': 0.0, 'fat': 5.4},
      'beef': {'calories': 375, 'protein': 39.0, 'carbs': 0.0, 'fat': 22.5},
      'fish': {'calories': 206, 'protein': 22.0, 'carbs': 0.0, 'fat': 12.0},
      'rice': {'calories': 130, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3},
      'pasta': {'calories': 158, 'protein': 5.8, 'carbs': 31.0, 'fat': 0.9},
      'bread': {'calories': 265, 'protein': 9.0, 'carbs': 49.0, 'fat': 3.2},
      'pizza': {'calories': 266, 'protein': 11.0, 'carbs': 33.0, 'fat': 10.0},
      'burger': {'calories': 295, 'protein': 17.0, 'carbs': 24.0, 'fat': 14.0},
      'egg': {'calories': 155, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0},
      'apple': {'calories': 52, 'protein': 0.3, 'carbs': 14.0, 'fat': 0.2},
      'banana': {'calories': 89, 'protein': 1.1, 'carbs': 23.0, 'fat': 0.3},
    };

    final lowerFoodName = foodName.toLowerCase();
    for (var entry in nutritionDatabase.entries) {
      if (lowerFoodName.contains(entry.key)) {
        return {
          'name': _formatFoodName(entry.key),
          ...entry.value,
        };
      }
    }

    return {
      'name': _formatFoodName(foodName),
      'calories': 250,
      'protein': 10.0,
      'carbs': 30.0,
      'fat': 8.0,
    };
  }

  // Detect food from image using Groq AI only (simplified)
  static Future<Map<String, dynamic>> detectFoodFromImage(
      File imageFile) async {
    print('🖼️ Processing food image...');

    try {
      // Since Groq can't process images directly, we'll show a manual entry dialog
      // In a production app, you would integrate a real image recognition service

      // Simulate processing
      await Future.delayed(const Duration(seconds: 2));

      // Return a prompt for manual entry
      return {
        'detected': false,
        'error': 'IMAGE_MANUAL_ENTRY',
        'message': 'Please describe what food you see in the image',
      };
    } catch (e) {
      print('❌ Error: $e');
      return {
        'detected': false,
        'error': 'Error processing image: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>?> getNutritionDetails(
      String foodId, double quantity, String measure) async {
    return null;
  }
}

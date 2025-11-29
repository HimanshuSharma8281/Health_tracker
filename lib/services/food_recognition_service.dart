import 'dart:io';
import 'gemini_ai_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class FoodRecognitionService {
  static const String _geminiApiKey = 'AIzaSyArgSyIEmRgUfwv3Pw1HbjqzRombgz5WSc';

  static Future<Map<String, dynamic>> recognizeFoodFromImage(
      File imageFile) async {
    try {
      print('🔍 Starting food recognition with Gemini AI...');

      final bytes = await imageFile.readAsBytes();
      print('📦 Image size: ${bytes.length} bytes');

      if (bytes.isEmpty) {
        print('❌ Image file is empty');
        throw Exception('Image file is empty');
      }

      // Use Gemini Vision to analyze the food image
      final result = await GeminiAIService.analyzeFoodImage(bytes);

      print('✅ Food detected: ${result['name']}');
      print(
          '📊 Nutrition: ${result['calories']} kcal, ${result['protein']}g protein');

      // Check if we got real data, not fallback
      if (result['name'] == 'Food Item' ||
          result['name'].toLowerCase() == 'food') {
        print('⚠️ WARNING: Received generic/fallback data from Gemini');
        throw Exception('Unable to identify food from image');
      }

      return result;
    } catch (error, stackTrace) {
      print('⚠️ Recognition failed with error: $error');
      print('📚 Stack trace: $stackTrace');

      // Don't return fallback data - rethrow the error
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> searchFoodWithGemini(
      String foodName) async {
    try {
      print('🔍 Searching nutrition for: $foodName');

      // Use google_generative_ai package instead of http
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _geminiApiKey,
      );

      final prompt =
          '''Provide nutritional information for "$foodName" in JSON format.
Return ONLY a valid JSON object:
{
  "name": "$foodName",
  "calories": number (per serving),
  "protein": number (grams),
  "carbs": number (grams),
  "fat": number (grams)
}''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        final text = response.text!;

        final jsonMatch =
            RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(text);

        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;

          // Parse JSON manually
          final name =
              RegExp(r'"name"\s*:\s*"([^"]+)"').firstMatch(jsonStr)?.group(1);
          final calories =
              RegExp(r'"calories"\s*:\s*(\d+)').firstMatch(jsonStr)?.group(1);
          final protein =
              RegExp(r'"protein"\s*:\s*([\d.]+)').firstMatch(jsonStr)?.group(1);
          final carbs =
              RegExp(r'"carbs"\s*:\s*([\d.]+)').firstMatch(jsonStr)?.group(1);
          final fat =
              RegExp(r'"fat"\s*:\s*([\d.]+)').firstMatch(jsonStr)?.group(1);

          return {
            'name': _formatFoodName(name ?? foodName),
            'calories': int.tryParse(calories ?? '250') ?? 250,
            'protein': double.tryParse(protein ?? '10.0') ?? 10.0,
            'carbs': double.tryParse(carbs ?? '30.0') ?? 30.0,
            'fat': double.tryParse(fat ?? '8.0') ?? 8.0,
          };
        }
      }

      // Fallback to local database
      return _estimateNutrition(foodName);
    } catch (error) {
      print('❌ Search failed: $error');
      return _estimateNutrition(foodName);
    }
  }

  static int _parseNumber(dynamic value, int defaultValue) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static double _parseDouble(dynamic value, double defaultValue) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static Map<String, dynamic> _getFallbackResult() {
    return {
      'name': 'Food Item',
      'calories': 300,
      'protein': 12.0,
      'carbs': 35.0,
      'fat': 10.0,
      'confidence': '70.0',
    };
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

  static Map<String, dynamic> _estimateNutrition(String foodName) {
    final nutritionDatabase = {
      'chicken': {'calories': 248, 'protein': 46.5, 'carbs': 0.0, 'fat': 5.4},
      'beef': {'calories': 375, 'protein': 39.0, 'carbs': 0.0, 'fat': 22.5},
      'fish': {'calories': 206, 'protein': 22.0, 'carbs': 0.0, 'fat': 12.0},
      'rice': {'calories': 130, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3},
      'pasta': {'calories': 158, 'protein': 5.8, 'carbs': 31.0, 'fat': 0.9},
      'bread': {'calories': 265, 'protein': 9.0, 'carbs': 49.0, 'fat': 3.2},
      'pizza': {'calories': 266, 'protein': 11.0, 'carbs': 33.0, 'fat': 10.0},
      'burger': {'calories': 295, 'protein': 17.0, 'carbs': 24.0, 'fat': 14.0},
      'salad': {'calories': 15, 'protein': 1.2, 'carbs': 3.0, 'fat': 0.2},
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
}

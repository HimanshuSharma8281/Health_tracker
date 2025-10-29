import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'groq_ai_service.dart';

class FoodApiService {
  // Search for food by name using Groq AI
  static Future<List<Map<String, dynamic>>> searchFood(String query) async {
    print('🔍 Searching for: $query using Groq AI');

    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final results = await GroqAIService.searchFoods(query);
      print('✅ Found ${results.length} results');
      return results;
    } catch (e) {
      print('❌ Error: $e');
      return _getFallbackFoods(query);
    }
  }

  // Fallback local database
  static List<Map<String, dynamic>> _getFallbackFoods(String query) {
    print('📦 Using fallback database for: $query');

    final localFoods = [
      {
        'name': 'Chicken Breast (100g)',
        'calories': 165,
        'protein': '31.0',
        'carbs': '0.0',
        'fat': '3.6',
        'serving': '100g',
        'foodId': 'local_1'
      },
      {
        'name': 'Brown Rice (1 cup)',
        'calories': 216,
        'protein': '5.0',
        'carbs': '45.0',
        'fat': '1.8',
        'serving': '1 cup',
        'foodId': 'local_2'
      },
      {
        'name': 'Salmon (100g)',
        'calories': 208,
        'protein': '20.0',
        'carbs': '0.0',
        'fat': '13.0',
        'serving': '100g',
        'foodId': 'local_3'
      },
      {
        'name': 'Banana (1 medium)',
        'calories': 105,
        'protein': '1.3',
        'carbs': '27.0',
        'fat': '0.4',
        'serving': '1 medium',
        'foodId': 'local_4'
      },
      {
        'name': 'Eggs (2 large)',
        'calories': 140,
        'protein': '12.0',
        'carbs': '1.0',
        'fat': '10.0',
        'serving': '2 eggs',
        'foodId': 'local_5'
      },
      {
        'name': 'Pizza (1 slice)',
        'calories': 285,
        'protein': '12.0',
        'carbs': '36.0',
        'fat': '10.0',
        'serving': '1 slice',
        'foodId': 'local_6'
      },
      {
        'name': 'Burger (1 whole)',
        'calories': 354,
        'protein': '16.0',
        'carbs': '30.0',
        'fat': '17.0',
        'serving': '1 burger',
        'foodId': 'local_7'
      },
    ];

    return localFoods
        .where((food) =>
            food['name'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
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

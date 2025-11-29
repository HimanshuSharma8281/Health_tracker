import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiAIService {
  static const String _apiKey = 'AIzaSyArgSyIEmRgUfwv3Pw1HbjqzRombgz5WSc';

  static Future<List<String>> generateHealthInsights(
      Map<String, dynamic> healthData) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash', // Use stable version
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
      print('📤 Analyzing food image with Gemini Vision...');
      print('📦 Image bytes length: ${imageBytes.length}');
      print('🔑 Using API key: ${_apiKey.substring(0, 10)}...');

      // Use the correct stable model name
      final model = GenerativeModel(
        model: 'gemini-2.5-flash', // Changed from gemini-2.5-flash
        apiKey: _apiKey,
      );

      final prompt = '''Look at this food image carefully. Tell me:
1. What specific food item is this?
2. Estimated calories per serving
3. Protein in grams
4. Carbohydrates in grams  
5. Fat in grams

Reply ONLY in this format: FoodName|Calories|Protein|Carbs|Fat
Example: Chicken Biryani|450|28.5|52.0|15.0

Be specific with the food name. Do not say "Food Item".''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      print('🔄 Sending request to Gemini API...');
      print('📝 Using model: gemini-2.5-flash');

      final response = await model.generateContent(content).timeout(
            const Duration(seconds: 30),
          );

      print('✅ Response received successfully');
      print('📄 Full response text: "${response.text}"');

      if (response.text == null || response.text!.isEmpty) {
        print('❌ ERROR: Response is null or empty');
        throw Exception('Empty response from Gemini API');
      }

      final text = response.text!.trim();
      print('📋 Cleaned text: "$text"');

      // Parse pipe-delimited format
      if (text.contains('|')) {
        final parts = text.split('|').map((e) => e.trim()).toList();
        print('✂️ Split into ${parts.length} parts: $parts');

        if (parts.length >= 5) {
          final foodName = parts[0];

          // Validate it's not a generic response
          if (foodName.toLowerCase() != 'food item' &&
              foodName.toLowerCase() != 'food' &&
              foodName.isNotEmpty) {
            final result = {
              'name': foodName,
              'calories':
                  int.tryParse(parts[1].replaceAll(RegExp(r'[^\d]'), '')) ??
                      300,
              'protein':
                  double.tryParse(parts[2].replaceAll(RegExp(r'[^\d.]'), '')) ??
                      12.0,
              'carbs':
                  double.tryParse(parts[3].replaceAll(RegExp(r'[^\d.]'), '')) ??
                      35.0,
              'fat':
                  double.tryParse(parts[4].replaceAll(RegExp(r'[^\d.]'), '')) ??
                      10.0,
              'confidence': '85.0',
            };

            print('✅ SUCCESS! Parsed food: ${result['name']}');
            print(
                '📊 Nutrition: ${result['calories']} kcal, ${result['protein']}g protein');
            return result;
          } else {
            print('⚠️ WARNING: Got generic response: "$foodName"');
          }
        } else {
          print(
              '⚠️ WARNING: Not enough parts (expected 5, got ${parts.length})');
        }
      } else {
        print('⚠️ WARNING: Response does not contain pipe delimiter');
        print('💡 Trying to parse as natural language...');

        // Try to extract from natural language response
        return _parseNaturalLanguage(text);
      }

      print('❌ ERROR: All parsing methods failed');
      throw Exception('Could not extract valid food information');
    } catch (e, stackTrace) {
      print('💥 EXCEPTION in analyzeFoodImage');
      print('❌ Error: $e');
      print('📚 Stack trace: $stackTrace');

      // Don't return default result - rethrow error
      rethrow;
    }
  }

  static Map<String, dynamic> _parseNaturalLanguage(String text) {
    print('🔍 Attempting natural language parsing...');

    final lines = text.split('\n');
    String? foodName;
    int? calories;
    double? protein;
    double? carbs;
    double? fat;

    for (var line in lines) {
      final lower = line.toLowerCase();

      // Extract food name (usually in first line or contains "food:")
      if (foodName == null) {
        if (lower.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1 && parts[0].toLowerCase().contains('food')) {
            foodName = parts[1].trim();
          }
        } else if (lines.indexOf(line) == 0 && !lower.contains('sorry')) {
          foodName = line.trim();
        }
      }

      // Extract calories
      if (lower.contains('calor')) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) calories = int.parse(match.group(1)!);
      }

      // Extract protein
      if (lower.contains('protein')) {
        final match = RegExp(r'(\d+\.?\d*)').firstMatch(line);
        if (match != null) protein = double.parse(match.group(1)!);
      }

      // Extract carbs
      if (lower.contains('carb')) {
        final match = RegExp(r'(\d+\.?\d*)').firstMatch(line);
        if (match != null) carbs = double.parse(match.group(1)!);
      }

      // Extract fat
      if (lower.contains('fat')) {
        final match = RegExp(r'(\d+\.?\d*)').firstMatch(line);
        if (match != null) fat = double.parse(match.group(1)!);
      }
    }

    if (foodName != null &&
        foodName.toLowerCase() != 'food item' &&
        foodName.toLowerCase() != 'food') {
      return {
        'name': foodName,
        'calories': calories ?? 300,
        'protein': protein ?? 12.0,
        'carbs': carbs ?? 35.0,
        'fat': fat ?? 10.0,
        'confidence': '75.0',
      };
    }

    throw Exception('Could not extract food name');
  }

  static Future<Map<String, dynamic>> _tryFlashModel(
      Uint8List imageBytes) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );

    final prompt =
        '''What food is this? Reply with: FoodName|Calories|Protein|Carbs|Fat
Example: Chicken Curry|350|28.5|18.0|12.0''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    final response = await model.generateContent(content);

    if (response.text != null && response.text!.contains('|')) {
      final parts = response.text!.split('|').map((e) => e.trim()).toList();

      if (parts.length >= 5) {
        return {
          'name': parts[0],
          'calories': int.tryParse(parts[1]) ?? 300,
          'protein': double.tryParse(parts[2]) ?? 12.0,
          'carbs': double.tryParse(parts[3]) ?? 35.0,
          'fat': double.tryParse(parts[4]) ?? 10.0,
          'confidence': '80.0',
        };
      }
    }

    throw Exception('Could not parse response');
  }

  static Future<Map<String, dynamic>> _extractFromText(
      String text, GenerativeModel model) async {
    try {
      // Ask AI to structure the response
      final structurePrompt = '''Convert this text to JSON format:
$text

Return: {"name":"Food Name","calories":250,"protein":12.0,"carbs":30.0,"fat":8.0,"confidence":80}''';

      final response =
          await model.generateContent([Content.text(structurePrompt)]);

      if (response.text != null) {
        final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(response.text!);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;

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

          if (name != null && name.isNotEmpty) {
            return {
              'name': name,
              'calories': int.tryParse(calories ?? '300') ?? 300,
              'protein': double.tryParse(protein ?? '12.0') ?? 12.0,
              'carbs': double.tryParse(carbs ?? '35.0') ?? 35.0,
              'fat': double.tryParse(fat ?? '10.0') ?? 10.0,
              'confidence': '75.0',
            };
          }
        }
      }
    } catch (e) {
      print('Text extraction failed: $e');
    }

    throw Exception('All extraction methods failed');
  }

  static Map<String, dynamic> _parseTextResponse(String text) {
    // Try to extract information from text
    final lines = text.toLowerCase().split('\n');

    String name = 'Food Item';
    int calories = 300;
    double protein = 12.0;
    double carbs = 35.0;
    double fat = 10.0;

    for (var line in lines) {
      if (line.contains('food') ||
          line.contains('dish') ||
          line.contains('item')) {
        final words = line.split(':');
        if (words.length > 1) {
          name = words[1].trim();
        }
      }
      if (line.contains('calor')) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) calories = int.parse(match.group(1)!);
      }
      if (line.contains('protein')) {
        final match = RegExp(r'(\d+\.?\d*)').firstMatch(line);
        if (match != null) protein = double.parse(match.group(1)!);
      }
      if (line.contains('carb')) {
        final match = RegExp(r'(\d+\.?\d*)').firstMatch(line);
        if (match != null) carbs = double.parse(match.group(1)!);
      }
      if (line.contains('fat')) {
        final match = RegExp(r'(\d+\.?\d*)').firstMatch(line);
        if (match != null) fat = double.parse(match.group(1)!);
      }
    }

    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'confidence': '70.0',
    };
  }

  static Future<Map<String, dynamic>> _tryAlternativeModel(
      Uint8List imageBytes) async {
    try {
      print('🔄 Trying gemini-pro-vision model...');

      final model = GenerativeModel(
        model: 'gemini-pro-vision',
        apiKey: _apiKey,
      );

      final prompt = '''What food is in this image? Provide:
1. Food name
2. Estimated calories
3. Protein (grams)
4. Carbs (grams)
5. Fat (grams)

Format: Food Name, Calories, Protein, Carbs, Fat''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);

      if (response.text != null) {
        print('✅ Alternative model response: ${response.text}');

        final parts = response.text!.split(',').map((e) => e.trim()).toList();

        return {
          'name': parts.isNotEmpty
              ? parts[0].replaceAll(RegExp(r'\d+\.'), '')
              : 'Food Item',
          'calories': parts.length > 1
              ? int.tryParse(parts[1].replaceAll(RegExp(r'[^\d]'), '')) ?? 300
              : 300,
          'protein': parts.length > 2
              ? double.tryParse(parts[2].replaceAll(RegExp(r'[^\d.]'), '')) ??
                  12.0
              : 12.0,
          'carbs': parts.length > 3
              ? double.tryParse(parts[3].replaceAll(RegExp(r'[^\d.]'), '')) ??
                  35.0
              : 35.0,
          'fat': parts.length > 4
              ? double.tryParse(parts[4].replaceAll(RegExp(r'[^\d.]'), '')) ??
                  10.0
              : 10.0,
          'confidence': '75.0',
        };
      }

      throw Exception('Alternative model failed');
    } catch (e) {
      print('💥 Alternative model error: $e');
      rethrow;
    }
  }
}

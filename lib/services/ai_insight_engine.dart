import '../controllers/health_data_controller.dart';
import 'gemini_ai_service.dart';

class AIInsightEngine {
  static Future<List<String>> generate(HealthDataController data) async {
    try {
      final healthData = {
        'steps': data.stepsToday,
        'stepGoal': data.stepGoal,
        'calories': data.caloriesConsumed,
        'calorieGoal': data.calorieGoal,
        'water': data.waterMl,
        'waterGoal': data.waterGoal,
        'sleep': data.sleepHours,
        'sleepGoal': data.sleepGoal,
        'stress': data.stressLevel,
      };

      print('🔍 Generating AI insights with Gemini...');

      final insights =
          await GeminiAIService.generateHealthInsights(healthData).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Gemini timeout, using fallback');
          return <String>[];
        },
      );

      if (insights.isNotEmpty) {
        print('✅ Generated ${insights.length} Gemini insights');
        return insights;
      }
    } catch (e) {
      print('⚠️ Error generating Gemini insights: $e');
    }

    print('📝 Using fallback insights');
    return _generateFallbackInsights(data);
  }

  static List<String> _generateFallbackInsights(HealthDataController data) {
    final insights = <String>[];

    // Water intake insight
    if (data.waterMl < data.waterGoal * 0.85) {
      insights.add(
          'Increase hydration by ${data.waterGoal - data.waterMl} ml to hit today\'s target.');
    } else if (data.waterMl >= data.waterGoal) {
      insights.add('Great hydration today! You\'ve met your water goal.');
    }

    // Stress level insight
    if (data.stressLevel > 0.55) {
      insights.add(
          'Stress signals are elevated. Try a 10 minute breathing routine.');
    } else if (data.stressLevel < 0.3) {
      insights.add('Your stress levels are well managed today.');
    }

    // Steps insight
    if (data.stepsToday < data.stepGoal * 0.7) {
      insights.add('Add a 15 minute walk to reach your step goal.');
    } else if (data.stepsToday >= data.stepGoal) {
      insights.add('Excellent! You\'ve achieved your daily step goal.');
    }

    // Calorie insight
    final calorieDeficit = data.calorieGoal - data.caloriesConsumed;
    if (calorieDeficit > 500) {
      insights.add('You have $calorieDeficit calories remaining for today.');
    } else if (calorieDeficit < 0) {
      insights.add(
          'You\'ve exceeded your calorie goal by ${-calorieDeficit} calories.');
    }

    // Sleep insight
    if (data.sleepHours < data.sleepGoal) {
      insights.add(
          'Aim for ${(data.sleepGoal - data.sleepHours).toStringAsFixed(1)} more hours of sleep tonight.');
    } else if (data.sleepHours >= data.sleepGoal) {
      insights.add('Well rested! You\'re meeting your sleep goals.');
    }

    // General encouragement if doing well
    if (insights.isEmpty || insights.length < 2) {
      insights.add('Outstanding balance today. Keep up the great work!');
    }

    return insights.take(3).toList(); // Return max 3 insights
  }
}

import '../controllers/health_data_controller.dart';
import 'groq_ai_service.dart';

class AIInsightEngine {
  static Future<List<String>> generate(HealthDataController data) async {
    try {
      final healthData = {
        'steps': data.stepsToday,
        'calories': data.caloriesConsumed,
        'calorieGoal': data.calorieGoal,
        'water': data.waterMl,
        'waterGoal': data.waterGoal,
        'sleep': data.sleepHours,
        'sleepGoal': data.sleepGoal,
        'stress': data.stressLevel,
      };

      final insights = await GroqAIService.generateHealthInsights(healthData);

      if (insights.isNotEmpty) {
        return insights;
      }
    } catch (e) {
      print('Error generating AI insights: $e');
    }

    // Fallback insights
    return _generateFallbackInsights(data);
  }

  static List<String> _generateFallbackInsights(HealthDataController data) {
    final insights = <String>[];
    if (data.waterMl < data.waterGoal * 0.85) {
      insights.add(
          'Increase hydration by ${data.waterGoal - data.waterMl} ml to hit today\'s target.');
    }
    if (data.stressLevel > 0.55) {
      insights.add(
          'Stress signals are elevated. Try a 10 minute breathing routine.');
    }
    if (data.stepsToday < data.stepGoal) {
      insights.add('Add a 15 minute walk to reach your step goal.');
    }
    if (insights.isEmpty) {
      insights.add('Outstanding balance today. Keep up the great work!');
    }
    return insights;
  }
}

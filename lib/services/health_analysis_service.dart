import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../controllers/health_data_controller.dart';

class HealthAnalysisService {
  static const String apiKey =
      'AIzaSyArgSyIEmRgUfwv3Pw1HbjqzRombgz5WSc'; // Replace with your actual API key

  static Future<HealthAnalysis> analyzeHealthData(
      HealthDataController data) async {
    try {
      final model = GenerativeModel(
        model:
            'gemini-2.5-flash', // Changed from 'gemini-2.5-flash' to 'gemini-pro'
        apiKey: apiKey,
      );

      final prompt = _buildAnalysisPrompt(data);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return _parseAnalysisResponse(response.text ?? '', data);
    } catch (e) {
      print('Error analyzing health data: $e');
      return HealthAnalysis(
        overallScore: 70,
        healthStatus: 'Good',
        recommendations: [
          'Unable to fetch AI insights. Please check your connection.',
        ],
        strengths: ['Maintaining basic health metrics'],
        areasToImprove: ['Monitor your health regularly'],
        dailySummary: 'Keep tracking your health metrics.',
        insights: ['Track your metrics daily for better insights'],
      );
    }
  }

  static String _buildAnalysisPrompt(HealthDataController data) {
    final lastWeekAvg = _calculateWeeklyAverages(data);

    return '''
You are a professional health and wellness coach. Analyze the following health metrics and provide personalized recommendations.

**Today's Health Data:**
- Steps: ${data.stepsToday} / ${data.stepGoal} (Goal: ${data.stepGoal})
- Calories: ${data.caloriesConsumed.round()} kcal / ${data.calorieGoal.round()} kcal
- Water: ${data.waterMl} ml / ${data.waterGoal} ml
- Sleep: ${data.sleepHours.toStringAsFixed(1)} hrs / ${data.sleepGoal.toStringAsFixed(1)} hrs
- Blood Pressure: ${data.systolic}/${data.diastolic} mmHg
- Blood Sugar: ${data.bloodSugar.toStringAsFixed(1)} mg/dL
- Heart Rate: ${data.heartRate.toStringAsFixed(0)} bpm
- Stress Level: ${(data.stressLevel * 100).toStringAsFixed(0)}%

**Last 7 Days Average:**
- Steps: ${lastWeekAvg['steps']?.round() ?? 0}
- Sleep: ${lastWeekAvg['sleep']?.toStringAsFixed(1) ?? '0.0'} hrs
- Water: ${lastWeekAvg['water']?.round() ?? 0} ml
- Calories: ${lastWeekAvg['calories']?.round() ?? 0} kcal

**Recent Sleep Entries:** ${data.sleepReadingHistory.length} records
**Recent Water Intake:** ${data.waterIntakeHistory.length} records
**Blood Pressure Readings:** ${data.bloodPressureHistory.length} records

Please provide a comprehensive health analysis in this EXACT format:

HEALTH_SCORE: [number 0-100]
STATUS: [Excellent/Good/Fair/Needs Attention]
SUMMARY: [2-3 sentence overall health summary]

STRENGTHS:
- [strength 1]
- [strength 2]
- [strength 3]

IMPROVEMENTS:
- [area 1]
- [area 2]
- [area 3]

RECOMMENDATIONS:
- [actionable recommendation 1]
- [actionable recommendation 2]
- [actionable recommendation 3]
- [actionable recommendation 4]
- [actionable recommendation 5]

INSIGHTS:
- [specific insight about trends]
- [specific insight about patterns]
- [specific insight about correlations]

Be specific, actionable, and encouraging. Focus on positive reinforcement while highlighting areas for improvement.
''';
  }

  static Map<String, double> _calculateWeeklyAverages(
      HealthDataController data) {
    if (data.history.isEmpty) {
      return {
        'steps': 0.0,
        'sleep': 0.0,
        'water': 0.0,
        'calories': 0.0,
      };
    }

    final last7Days = data.history.length > 7
        ? data.history.sublist(data.history.length - 7)
        : data.history;

    return {
      'steps':
          last7Days.fold(0, (sum, day) => sum + day.steps) / last7Days.length,
      'sleep': last7Days.fold(0.0, (sum, day) => sum + day.sleepHours) /
          last7Days.length,
      'water':
          last7Days.fold(0, (sum, day) => sum + day.waterMl) / last7Days.length,
      'calories': last7Days.fold(0, (sum, day) => sum + day.calories) /
          last7Days.length,
    };
  }

  static HealthAnalysis _parseAnalysisResponse(
      String response, HealthDataController data) {
    try {
      final lines =
          response.split('\n').where((line) => line.trim().isNotEmpty);

      int score = 75;
      String status = 'Good';
      String summary = 'Your health metrics are being tracked.';
      List<String> strengths = [];
      List<String> improvements = [];
      List<String> recommendations = [];
      List<String> insights = [];

      String currentSection = '';

      for (var line in lines) {
        final trimmed = line.trim();

        if (trimmed.startsWith('HEALTH_SCORE:')) {
          final scoreText = trimmed.split(':')[1].trim();
          score =
              int.tryParse(scoreText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 75;
        } else if (trimmed.startsWith('STATUS:')) {
          status = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        } else if (trimmed.startsWith('SUMMARY:')) {
          summary = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        } else if (trimmed == 'STRENGTHS:') {
          currentSection = 'strengths';
        } else if (trimmed == 'IMPROVEMENTS:') {
          currentSection = 'improvements';
        } else if (trimmed == 'RECOMMENDATIONS:') {
          currentSection = 'recommendations';
        } else if (trimmed == 'INSIGHTS:') {
          currentSection = 'insights';
        } else if (trimmed.startsWith('-')) {
          final content = trimmed.substring(1).trim();
          if (content.isNotEmpty) {
            switch (currentSection) {
              case 'strengths':
                strengths.add(content);
                break;
              case 'improvements':
                improvements.add(content);
                break;
              case 'recommendations':
                recommendations.add(content);
                break;
              case 'insights':
                insights.add(content);
                break;
            }
          }
        }
      }

      // Ensure we have at least some data
      if (strengths.isEmpty) {
        strengths = ['Tracking health metrics regularly'];
      }
      if (improvements.isEmpty) {
        improvements = ['Continue monitoring your health'];
      }
      if (recommendations.isEmpty) {
        recommendations = ['Keep logging your daily activities'];
      }
      if (insights.isEmpty) {
        insights = ['Your health tracking is improving'];
      }

      return HealthAnalysis(
        overallScore: score,
        healthStatus: status,
        dailySummary: summary,
        strengths: strengths.take(3).toList(),
        areasToImprove: improvements.take(3).toList(),
        recommendations: recommendations.take(5).toList(),
        insights: insights.take(3).toList(),
      );
    } catch (e) {
      print('Error parsing analysis: $e');
      return HealthAnalysis(
        overallScore: 70,
        healthStatus: 'Good',
        dailySummary: 'Keep tracking your health metrics consistently.',
        strengths: [
          'Consistent tracking',
          'Health awareness',
          'Daily monitoring'
        ],
        areasToImprove: [
          'Maintain regular monitoring',
          'Set realistic goals',
          'Track progress'
        ],
        recommendations: [
          'Continue logging your daily activities',
          'Stay hydrated throughout the day',
          'Maintain regular sleep schedule',
          'Exercise regularly',
          'Monitor vital signs daily',
        ],
        insights: [
          'Your tracking consistency is improving',
          'Keep monitoring trends',
          'Small improvements add up over time',
        ],
      );
    }
  }
}

class HealthAnalysis {
  final int overallScore;
  final String healthStatus;
  final String dailySummary;
  final List<String> strengths;
  final List<String> areasToImprove;
  final List<String> recommendations;
  final List<String> insights;

  HealthAnalysis({
    required this.overallScore,
    required this.healthStatus,
    required this.dailySummary,
    this.strengths = const [],
    this.areasToImprove = const [],
    this.recommendations = const [],
    this.insights = const [],
  });

  Color get statusColor {
    if (overallScore >= 80) return const Color(0xFF2E7D32);
    if (overallScore >= 60) return const Color(0xFF3A86FF);
    if (overallScore >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFFF006E);
  }

  IconData get statusIcon {
    if (overallScore >= 80) return Icons.emoji_events;
    if (overallScore >= 60) return Icons.thumb_up;
    if (overallScore >= 40) return Icons.trending_up;
    return Icons.warning_amber_rounded;
  }
}

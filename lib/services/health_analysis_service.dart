import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../controllers/health_data_controller.dart';
import '../services/health_score_engine.dart';
import '../models/health_reading.dart';
import '../models/user_profile.dart';
import '../models/daily_score.dart';
import '../config/api_keys.dart';

/// Gemini narrative service for health insights.
///
/// Phase 8 implementation:
/// - Overall score and status are DETERMINISTIC (calculated by [HealthScoreEngine]).
/// - Gemini is given the real calculated scores and demographic profile.
/// - Gemini produces narrative only: summary, strengths, areas to improve, recommendations, insights.
/// - Gemini is strictly prohibited from inventing or modifying numerical scores.
class HealthAnalysisService {
  static const String apiKey = ApiKeys.geminiApiKey;

  static const String _systemInstruction = '''
You are Aurora, a certified wellness and clinical health coach inside Aurora Wellness.

CRITICAL RULES:
1. You MUST NOT invent, calculate, or alter numerical health scores. Scores have already been deterministically calculated from clinical reference ranges and provided to you.
2. You MUST NOT diagnose or prescribe medical treatments.
3. Provide encouraging, scientifically grounded, and actionable wellness guidance.
4. Keep advice concise, practical, and empathetic.
''';

  /// Synchronously builds an immediate clinical analysis from the controller's current data.
  /// Guarantees instant rendering with 0ms delay and populates data.todayScore.
  static HealthAnalysis buildImmediateDeterministicAnalysis(
      HealthDataController data) {
    final profile = (data.profile ??
        UserProfile(
          uid: data.userId ?? 'anonymous',
          email: '',
          name: data.username ?? 'User',
          avatarUrl: '',
        )).copyWith(
          stepGoal: data.stepGoal,
          waterGoalMl: data.waterGoal,
          calorieGoal: data.calorieGoal,
          sleepGoalHours: data.sleepGoal,
        );

    final expectedActivityTarget = '${data.stepGoal} steps';
    final cached = data.todayScore;
    final score = (cached != null && cached.metrics['activity']?.target == expectedActivityTarget)
        ? cached
        : HealthScoreEngine.calculate(
            profile: profile,
            date: HealthReading.todayDate(),
            heartRateBpm: data.heartRate > 0 ? data.heartRate : null,
            systolic: data.systolic > 0 ? data.systolic : null,
            diastolic: data.diastolic > 0 ? data.diastolic : null,
            sleepHours: data.sleepHours > 0 ? data.sleepHours : null,
            waterMl: data.waterMl > 0 ? data.waterMl : null,
            caloriesKcal: data.caloriesConsumed > 0 ? data.caloriesConsumed : null,
            steps: data.stepsToday > 0 ? data.stepsToday : null,
            bloodSugarMgDl: data.bloodSugar > 0 ? data.bloodSugar : null,
          );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      data.todayScore = score;
    });
    return _buildDeterministicFallback(score, score.overall, score.label);
  }

  static Future<HealthAnalysis> analyzeHealthData(
      HealthDataController data) async {
    // 1. Obtain or calculate deterministic DailyScore
    final profile = (data.profile ??
        UserProfile(
          uid: data.userId ?? 'anonymous',
          email: '',
          name: data.username ?? 'User',
          avatarUrl: '',
        )).copyWith(
          stepGoal: data.stepGoal,
          waterGoalMl: data.waterGoal,
          calorieGoal: data.calorieGoal,
          sleepGoalHours: data.sleepGoal,
        );

    final expectedActivityTarget = '${data.stepGoal} steps';
    final cached = data.todayScore;
    final score = (cached != null && cached.metrics['activity']?.target == expectedActivityTarget)
        ? cached
        : HealthScoreEngine.calculate(
            profile: profile,
            date: HealthReading.todayDate(),
            heartRateBpm: data.heartRate > 0 ? data.heartRate : null,
            systolic: data.systolic > 0 ? data.systolic : null,
            diastolic: data.diastolic > 0 ? data.diastolic : null,
            sleepHours: data.sleepHours > 0 ? data.sleepHours : null,
            waterMl: data.waterMl > 0 ? data.waterMl : null,
            caloriesKcal: data.caloriesConsumed > 0 ? data.caloriesConsumed : null,
            steps: data.stepsToday > 0 ? data.stepsToday : null,
            bloodSugarMgDl: data.bloodSugar > 0 ? data.bloodSugar : null,
          );

    data.todayScore = score;
    final overall = score.overall;
    final status = score.label;

    try {
      final prompt = _buildAnalysisPrompt(data, profile, score);
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$apiKey');

      final client = http.Client();
      try {
        final res = await client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': _systemInstruction}
              ]
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.2,
              'responseMimeType': 'application/json',
            }
          }),
        ).timeout(const Duration(seconds: 6));

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body) as Map<String, dynamic>;
          final candidates = decoded['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.isNotEmpty) {
                return _parseAnalysisResponse(text, overall, status, score);
              }
            }
          }
        } else if (res.statusCode == 429) {
          debugPrint('⚠️ [HealthAnalysisService] Gemini rate limit/quota reached (429) - using clinical fallback instantly');
          return _buildDeterministicFallback(score, overall, status);
        } else {
          debugPrint('⚠️ [HealthAnalysisService] Gemini returned status ${res.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('🔴 [HealthAnalysisService] Gemini error: $e');
    }
    return _buildDeterministicFallback(score, overall, status);
  }

  static String _buildAnalysisPrompt(
    HealthDataController data,
    UserProfile profile,
    DailyScore score,
  ) {
    final metricSummary = score.metrics.entries.map((e) {
      final m = e.value;
      if (!m.available) {
        return '- ${e.key}: Not recorded today';
      }
      return '- ${e.key}: Score ${m.score}/10 | Reading: ${m.reading ?? '${m.readingSystolic}/${m.readingDiastolic}'} | Target: ${m.target ?? '—'} (${m.reason})';
    }).join('\n');

    return '''
The deterministic health score engine has evaluated the user's data for today:
Overall Score: ${score.overall}/100
Status: ${score.label}
Active Metrics Count: ${score.availableMetricCount}

User Profile Demographics:
- Age: ${profile.age ?? 'Not specified'}
- Sex: ${profile.sex ?? 'Not specified'}
- BMI: ${profile.bmi != null ? '${profile.bmi!.toStringAsFixed(1)} (${profile.bmiCategory})' : 'Not calculated'}
- Activity Level: ${profile.activityLevel ?? 'moderately_active'}
- Fitness Goal: ${profile.fitnessGoal ?? 'maintain'}

Metric Scores:
$metricSummary

Provide your narrative response in JSON format with exactly these keys:
{
  "summary": "2-3 encouraging sentences explaining what drove this score and the main takeaway for today",
  "strengths": ["list of 2-3 specific habits or metrics the user did well on today"],
  "areasToImprove": ["list of 1-3 specific metrics that scored lower or need attention"],
  "recommendations": ["list of 3-4 actionable steps for the rest of today or tomorrow"],
  "insights": ["list of 2-3 analytical observations linking their metrics (e.g. sleep and steps, or hydration and recovery)"]
}

Respond ONLY with valid JSON. Do not include markdown code block formatting.
''';
  }

  static HealthAnalysis _parseAnalysisResponse(
    String raw,
    int overallScore,
    String healthStatus,
    DailyScore score,
  ) {
    try {
      var cleaned = raw.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      return HealthAnalysis(
        overallScore: overallScore,
        healthStatus: healthStatus,
        dailySummary: json['summary'] as String? ??
            'Your deterministic wellness score is $overallScore/100 ($healthStatus).',
        strengths: (json['strengths'] as List?)?.map((e) => e.toString()).toList() ??
            _extractStrengths(score),
        areasToImprove:
            (json['areasToImprove'] as List?)?.map((e) => e.toString()).toList() ??
                _extractImprovements(score),
        recommendations:
            (json['recommendations'] as List?)?.map((e) => e.toString()).toList() ??
                const ['Continue tracking your metrics daily to maintain wellness momentum.'],
        insights: (json['insights'] as List?)?.map((e) => e.toString()).toList() ??
            const ['Consistent tracking is the strongest predictor of meeting wellness goals.'],
      );
    } catch (_) {
      return _buildDeterministicFallback(score, overallScore, healthStatus);
    }
  }

  static HealthAnalysis _buildDeterministicFallback(
    DailyScore score,
    int overall,
    String status,
  ) {
    return HealthAnalysis(
      overallScore: overall,
      healthStatus: status,
      dailySummary:
          'Your clinical wellness score today is $overall/100, evaluated as "$status" across ${score.availableMetricCount} logged metrics.',
      strengths: _extractStrengths(score),
      areasToImprove: _extractImprovements(score),
      recommendations: const [
        'Stay consistent with hydration throughout the afternoon.',
        'Target 7–9 hours of sleep tonight for optimal recovery.',
        'Log all meals to maintain accurate caloric awareness.',
      ],
      insights: const [
        'Clinical scoring updates dynamically as each metric is logged.',
        'Track all metrics consistently for the most accurate health profile.',
      ],
    );
  }

  static List<String> _extractStrengths(DailyScore score) {
    final list = score.metrics.entries
        .where((e) => e.value.available && e.value.score >= 7)
        .map((e) => '${_name(e.key)} scored ${e.value.score}/10 — ${e.value.reason}')
        .toList();
    if (list.isEmpty) {
      list.add('Actively recording health data is the foundational first step.');
    }
    return list;
  }

  static List<String> _extractImprovements(DailyScore score) {
    final list = score.metrics.entries
        .where((e) => e.value.available && e.value.score < 7)
        .map((e) => '${_name(e.key)} (${e.value.score}/10) — ${e.value.reason}')
        .toList();
    if (list.isEmpty) {
      list.add('Keep all metrics balanced at current high performance levels.');
    }
    return list;
  }

  static String _name(String key) {
    switch (key) {
      case 'water':
        return 'Hydration';
      case 'sleep':
        return 'Sleep';
      case 'activity':
      case 'steps':
        return 'Activity';
      case 'calories':
        return 'Calories';
      case 'heart_rate':
        return 'Heart Rate';
      case 'blood_pressure':
        return 'Blood Pressure';
      default:
        return key;
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

  int get score => overallScore;

  Color get statusColor {
    if (overallScore >= 90) return const Color(0xFF10B981);
    if (overallScore >= 75) return const Color(0xFF3A86FF);
    if (overallScore >= 60) return const Color(0xFFF59E0B);
    if (overallScore >= 40) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  IconData get statusIcon {
    if (overallScore >= 90) return Icons.verified;
    if (overallScore >= 75) return Icons.emoji_events;
    if (overallScore >= 60) return Icons.thumb_up;
    if (overallScore >= 40) return Icons.trending_up;
    return Icons.warning_amber_rounded;
  }
}

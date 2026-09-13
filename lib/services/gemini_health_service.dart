import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_profile.dart';
import '../models/daily_score.dart';
import '../config/api_keys.dart';

/// Gemini-powered health narrative service.
///
/// Receives ALREADY-COMPUTED deterministic scores from [HealthScoreEngine]
/// and asks Gemini to provide human-readable analysis and recommendations.
///
/// Gemini's responsibilities:
///   ✅ Explain which metrics are strong and which need attention
///   ✅ Identify trends from weekly history
///   ✅ Provide actionable wellness suggestions
///   ✅ Motivate and coach in a positive tone
///
/// Gemini must NOT:
///   ❌ Invent, override, or recalculate the numerical scores
///   ❌ Diagnose medical conditions
///   ❌ Fabricate readings or trends
class GeminiHealthService {
  static String get _apiKey => ApiKeys.geminiApiKey;

  static const String _systemInstruction = '''
You are Aurora, a certified wellness coach assistant inside the Aurora Wellness app.

STRICT RULES:
1. You MUST NOT invent, override, or alter any numerical scores — they are calculated by the app's score engine and provided to you.
2. You MUST NOT diagnose, treat, or suggest treatment for medical conditions.
3. You MUST NOT fabricate health readings or trends not provided to you.
4. You MUST be encouraging, specific, and actionable.
5. Always refer to provided scores rather than reassessing them yourself.
6. Keep responses concise and mobile-friendly (no walls of text).
''';

  // ── Shared model instance ─────────────────────────────────────────────────
  static GenerativeModel get _model => GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system(_systemInstruction),
      );

  // ════════════════════════════════════════════════════════════════════════
  // DAILY HEALTH ANALYSIS
  // ════════════════════════════════════════════════════════════════════════

  /// Analyse today's health data and return a structured [HealthNarrative].
  ///
  /// [weeklyScores] is optional — if provided, Gemini will include trend insights.
  static Future<HealthNarrative> analyzeDailyHealth({
    required UserProfile profile,
    required DailyScore todayScore,
    List<DailyScore>? weeklyScores,
  }) async {
    try {
      final prompt = _buildDailyPrompt(
        profile: profile,
        todayScore: todayScore,
        weeklyScores: weeklyScores,
      );

      final response = await _model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 20));

      return _parseDailyResponse(response.text ?? '', todayScore);
    } catch (e) {
      return HealthNarrative.fallback(todayScore);
    }
  }

  /// Generate 3 short AI insights for the dashboard card.
  static Future<List<String>> generateInsights({
    required DailyScore score,
    required UserProfile profile,
  }) async {
    try {
      final prompt = '''
Based on today's deterministic health scores for ${profile.name}:

Overall Score: ${score.overall}/100 (${score.label})
${_metricsBlock(score)}

Provide EXACTLY 3 short, actionable wellness insights (max 20 words each).
Each insight should target one of the lower-scoring available metrics.
Format: Return only 3 bullet points starting with •
''';

      final response = await _model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 15));

      if (response.text != null) {
        final insights = response.text!
            .split('\n')
            .where((l) => l.trim().startsWith('•') || l.trim().startsWith('-'))
            .map((l) => l.replaceAll(RegExp(r'^[•\-]\s*'), '').trim())
            .where((l) => l.isNotEmpty)
            .take(3)
            .toList();
        if (insights.isNotEmpty) return insights;
      }
    } catch (e) {
      // Fall through to fallback
    }
    return _fallbackInsights(score);
  }

  // ════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ════════════════════════════════════════════════════════════════════════

  static String _buildDailyPrompt({
    required UserProfile profile,
    required DailyScore todayScore,
    List<DailyScore>? weeklyScores,
  }) {
    final sb = StringBuffer();

    sb.writeln('Analyze today\'s wellness data for ${profile.name} '
        '(${profile.age ?? "unknown age"}, ${profile.sex ?? "unspecified"}).');
    sb.writeln();
    sb.writeln('PROFILE:');
    sb.writeln('  Height: ${profile.heightCm?.toStringAsFixed(0) ?? "—"} cm');
    sb.writeln('  Weight: ${profile.weightKg?.toStringAsFixed(1) ?? "—"} kg');
    sb.writeln('  Activity: ${profile.activityLevel?.activityDisplayName ?? "—"}');
    sb.writeln('  Goal: ${profile.fitnessGoal?.goalDisplayName ?? "—"}');
    sb.writeln();
    sb.writeln('TODAY\'S SCORE: ${todayScore.overall}/100 (${todayScore.label})');
    sb.writeln();
    sb.writeln('METRIC SCORES (do NOT change these numbers):');
    sb.writeln(_metricsBlock(todayScore));

    if (weeklyScores != null && weeklyScores.length >= 3) {
      sb.writeln();
      sb.writeln('LAST ${weeklyScores.length} DAYS SCORES:');
      for (final s in weeklyScores) {
        sb.writeln('  ${s.date}: ${s.overall}/100 (${s.label})');
      }
    }

    sb.writeln();
    sb.writeln('''
Provide a health analysis in EXACTLY this format:

SUMMARY: [2–3 encouraging sentences about today's overall wellness]

STRENGTHS:
- [strength 1 based on high-scoring available metrics]
- [strength 2]

IMPROVEMENTS:
- [area 1 based on low-scoring available metrics]
- [area 2]

RECOMMENDATIONS:
- [specific actionable tip 1]
- [specific actionable tip 2]
- [specific actionable tip 3]

TREND: [1–2 sentences about trend if weekly data provided, otherwise omit]
''');
    return sb.toString();
  }

  static String _metricsBlock(DailyScore score) {
    final lines = <String>[];
    for (final entry in score.metrics.entries) {
      final m = entry.value;
      if (m.available) {
        lines.add('  ${_metricDisplayName(entry.key)}: ${m.score}/10 — ${m.reason}');
      } else {
        lines.add('  ${_metricDisplayName(entry.key)}: not recorded today');
      }
    }
    return lines.join('\n');
  }

  static String _metricDisplayName(String key) {
    switch (key) {
      case 'heart_rate':
        return 'Heart Rate';
      case 'blood_pressure':
        return 'Blood Pressure';
      case 'sleep':
        return 'Sleep';
      case 'water':
        return 'Hydration';
      case 'calories':
        return 'Calories';
      case 'activity':
        return 'Activity';
      default:
        return key;
    }
  }

  static HealthNarrative _parseDailyResponse(
      String text, DailyScore todayScore) {
    String summary = 'Keep tracking your health metrics consistently.';
    final strengths = <String>[];
    final improvements = <String>[];
    final recommendations = <String>[];
    String trend = '';
    String currentSection = '';

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('SUMMARY:')) {
        summary = line.substring('SUMMARY:'.length).trim();
      } else if (line == 'STRENGTHS:') {
        currentSection = 'strengths';
      } else if (line == 'IMPROVEMENTS:') {
        currentSection = 'improvements';
      } else if (line == 'RECOMMENDATIONS:') {
        currentSection = 'recommendations';
      } else if (line.startsWith('TREND:')) {
        trend = line.substring('TREND:'.length).trim();
      } else if (line.startsWith('- ')) {
        final content = line.substring(2).trim();
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
        }
      }
    }

    return HealthNarrative(
      overallScore: todayScore.overall,
      scoreLabel: todayScore.label,
      summary: summary.isNotEmpty ? summary : 'Great job tracking your health today!',
      strengths: strengths.take(3).toList(),
      areasToImprove: improvements.take(3).toList(),
      recommendations: recommendations.take(5).toList(),
      trendInsight: trend,
      metricScores: todayScore.metrics,
    );
  }

  static List<String> _fallbackInsights(DailyScore score) {
    final insights = <String>[];
    final sorted = score.metrics.entries
        .where((e) => e.value.available)
        .toList()
      ..sort((a, b) => a.value.score.compareTo(b.value.score));

    for (final entry in sorted.take(3)) {
      switch (entry.key) {
        case 'water':
          insights.add('Drink more water throughout the day to hit your hydration goal.');
          break;
        case 'sleep':
          insights.add('Aim for 7–9 hours of sleep tonight for better recovery.');
          break;
        case 'activity':
          insights.add('A 15-minute walk will help you get closer to your step goal.');
          break;
        case 'calories':
          insights.add('Log all your meals to stay on track with your calorie goal.');
          break;
        case 'heart_rate':
          insights.add('Regular cardio exercise can help lower your resting heart rate.');
          break;
        case 'blood_pressure':
          insights.add('Reducing sodium and stress can support healthy blood pressure.');
          break;
      }
    }

    if (insights.isEmpty) {
      insights.add('Great balance today — keep up the momentum!');
      insights.add('Consistency is key. Track your metrics every day.');
    }

    return insights.take(3).toList();
  }
}

// ════════════════════════════════════════════════════════════════════════
// RESPONSE MODEL
// ════════════════════════════════════════════════════════════════════════

/// Structured Gemini narrative response.
///
/// The [overallScore] here is the DETERMINISTIC score from [HealthScoreEngine].
/// Gemini did NOT set this value.
class HealthNarrative {
  const HealthNarrative({
    required this.overallScore,
    required this.scoreLabel,
    required this.summary,
    required this.metricScores,
    this.strengths = const [],
    this.areasToImprove = const [],
    this.recommendations = const [],
    this.trendInsight = '',
  });

  final int overallScore;
  final String scoreLabel;
  final String summary;
  final List<String> strengths;
  final List<String> areasToImprove;
  final List<String> recommendations;
  final String trendInsight;
  final Map<String, MetricScore> metricScores;

  factory HealthNarrative.fallback(DailyScore score) => HealthNarrative(
        overallScore: score.overall,
        scoreLabel: score.label,
        summary: 'Your health metrics are being tracked. '
            'Keep logging to get personalized insights.',
        strengths: score.metrics.entries
            .where((e) => e.value.available && e.value.score >= 7)
            .map((e) => '${_displayName(e.key)}: ${e.value.score}/10')
            .take(3)
            .toList(),
        areasToImprove: score.metrics.entries
            .where((e) => e.value.available && e.value.score < 7)
            .map((e) => '${_displayName(e.key)}: ${e.value.score}/10')
            .take(3)
            .toList(),
        recommendations: const [
          'Log all meals to track calorie intake accurately.',
          'Drink water regularly throughout the day.',
          'Aim for 7–9 hours of sleep every night.',
        ],
        metricScores: score.metrics,
      );

  static String _displayName(String key) {
    const names = {
      'heart_rate': 'Heart Rate',
      'blood_pressure': 'Blood Pressure',
      'sleep': 'Sleep',
      'water': 'Hydration',
      'calories': 'Calories',
      'activity': 'Activity',
    };
    return names[key] ?? key;
  }
}

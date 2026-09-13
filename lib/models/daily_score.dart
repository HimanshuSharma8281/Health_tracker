import 'package:cloud_firestore/cloud_firestore.dart';

/// Individual metric score — output of [HealthScoreEngine] for a single metric.
///
/// [score] is 0–10 (integer).
/// [available] is false when no valid reading exists for the period.
/// When [available] is false, the metric is excluded from the overall score
/// (it is NOT treated as 0).
class MetricScore {
  const MetricScore({
    required this.metric,
    required this.score,
    required this.available,
    this.reading,
    this.readingSystolic,
    this.readingDiastolic,
    this.target,
    this.reason = '',
  });

  final String metric;

  /// 0–10 integer score. Meaningless if [available] is false.
  final int score;

  /// Whether a valid reading exists to score against.
  final bool available;

  /// The raw reading value (e.g., 1800 ml, 7.2 hours, 72 bpm).
  final double? reading;

  /// Blood pressure specific.
  final int? readingSystolic;
  final int? readingDiastolic;

  /// Human-readable target description (e.g., "7–9 hours").
  final String? target;

  /// One-line explanation of the score (e.g., "6.8h vs 7–9h recommended").
  final String reason;

  Map<String, dynamic> toMap() => {
        'metric': metric,
        'score': score,
        'available': available,
        if (reading != null) 'reading': reading,
        if (readingSystolic != null) 'readingSystolic': readingSystolic,
        if (readingDiastolic != null) 'readingDiastolic': readingDiastolic,
        if (target != null) 'target': target,
        'reason': reason,
      };

  factory MetricScore.fromMap(String metric, Map<String, dynamic> data) =>
      MetricScore(
        metric: metric,
        score: data['score'] as int? ?? 0,
        available: data['available'] as bool? ?? false,
        reading: (data['reading'] as num?)?.toDouble(),
        readingSystolic: data['readingSystolic'] as int?,
        readingDiastolic: data['readingDiastolic'] as int?,
        target: data['target'] as String?,
        reason: data['reason'] as String? ?? '',
      );

  static MetricScore unavailable(String metric) => MetricScore(
        metric: metric,
        score: 0,
        available: false,
        reason: 'No reading available for this period.',
      );
}

/// Daily health score — stored in Firestore at users/{uid}/dailyScores/{date}.
///
/// Calculated deterministically from real readings by [HealthScoreEngine].
/// Gemini does NOT produce or alter this score.
class DailyScore {
  const DailyScore({
    required this.date,
    required this.overall,
    required this.label,
    required this.metrics,
    required this.scoredAt,
    required this.availableMetricCount,
  });

  /// Date string (YYYY-MM-DD).
  final String date;

  /// Overall health score 0–100.
  final int overall;

  /// Human-readable label.
  final String label; // 'Excellent' | 'Good' | 'Fair' | 'Needs Improvement' | 'Needs Attention'

  /// Map of metric name → [MetricScore].
  final Map<String, MetricScore> metrics;

  final DateTime scoredAt;

  /// How many metrics contributed to the overall score.
  final int availableMetricCount;

  static String labelFor(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    if (score >= 40) return 'Needs Improvement';
    return 'Needs Attention';
  }

  Map<String, dynamic> toFirestore() => {
        'date': date,
        'overall': overall,
        'label': label,
        'metrics': metrics.map((k, v) => MapEntry(k, v.toMap())),
        'scoredAt': Timestamp.fromDate(scoredAt),
        'availableMetricCount': availableMetricCount,
      };

  factory DailyScore.fromFirestore(Map<String, dynamic> data) {
    final metricsData = Map<String, dynamic>.from(data['metrics'] ?? {});
    return DailyScore(
      date: data['date'] as String? ?? '',
      overall: data['overall'] as int? ?? 0,
      label: data['label'] as String? ?? 'Needs Attention',
      metrics: metricsData.map(
        (k, v) => MapEntry(k, MetricScore.fromMap(k, Map<String, dynamic>.from(v))),
      ),
      scoredAt: (data['scoredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      availableMetricCount: data['availableMetricCount'] as int? ?? 0,
    );
  }
}

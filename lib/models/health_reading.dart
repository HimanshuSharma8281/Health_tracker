import 'package:cloud_firestore/cloud_firestore.dart';

/// A single health metric reading — stored in Firestore at
/// users/{uid}/healthReadings/{readingId}.
///
/// All health data goes here rather than in one huge user document
/// or in SharedPreferences, enabling querying by date range and metric type.
class HealthReading {
  const HealthReading({
    required this.id,
    required this.userId,
    required this.metric,
    required this.value,
    required this.date,
    required this.timestamp,
    this.valueSystolic,
    this.valueDiastolic,
    this.metadata = const {},
  });

  final String id;
  final String userId;

  /// Metric type constant — use the static constants below.
  final String metric;

  /// Primary numeric value (ml for water, hours for sleep, bpm for HR, etc.).
  final double value;

  /// Date string (YYYY-MM-DD) for efficient grouping queries.
  final String date;

  final DateTime timestamp;

  /// Only populated for blood_pressure readings.
  final int? valueSystolic;
  final int? valueDiastolic;

  /// Optional metadata (e.g., meal type, meal name for calorie readings).
  final Map<String, dynamic> metadata;

  // ── Metric type constants ──────────────────────────────────────────────────
  static const String water         = 'water';        // value = ml
  static const String sleep         = 'sleep';        // value = hours
  static const String steps         = 'steps';        // value = count
  static const String heartRate     = 'heart_rate';   // value = bpm
  static const String bloodPressure = 'blood_pressure'; // systolic/diastolic
  static const String bloodSugar    = 'blood_sugar';  // value = mg/dL
  static const String calories      = 'calories';     // value = kcal
  static const String weight        = 'weight';       // value = kg

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'metric': metric,
        'value': value,
        'date': date,
        'timestamp': Timestamp.fromDate(timestamp),
        if (valueSystolic != null) 'valueSystolic': valueSystolic,
        if (valueDiastolic != null) 'valueDiastolic': valueDiastolic,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory HealthReading.fromFirestore(String docId, Map<String, dynamic> data) =>
      HealthReading(
        id: docId,
        userId: data['userId'] as String? ?? '',
        metric: data['metric'] as String? ?? '',
        value: (data['value'] as num?)?.toDouble() ?? 0,
        date: data['date'] as String? ?? '',
        timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        valueSystolic: data['valueSystolic'] as int?,
        valueDiastolic: data['valueDiastolic'] as int?,
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );

  HealthReading copyWith({
    String? id,
    String? userId,
    String? metric,
    double? value,
    String? date,
    DateTime? timestamp,
    int? valueSystolic,
    int? valueDiastolic,
    Map<String, dynamic>? metadata,
  }) =>
      HealthReading(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        metric: metric ?? this.metric,
        value: value ?? this.value,
        date: date ?? this.date,
        timestamp: timestamp ?? this.timestamp,
        valueSystolic: valueSystolic ?? this.valueSystolic,
        valueDiastolic: valueDiastolic ?? this.valueDiastolic,
        metadata: metadata ?? this.metadata,
      );

  static String todayDate() {
    return formatDate(DateTime.now());
  }

  static String formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

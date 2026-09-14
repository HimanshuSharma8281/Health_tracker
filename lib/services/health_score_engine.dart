import 'dart:math';
import '../models/user_profile.dart';
import '../models/daily_score.dart';

/// Deterministic Health Score Engine.
///
/// Calculates a score for each available health metric (0–10) and an overall
/// score (0–100) from the average of available metrics.
///
/// Rules:
///   - ZERO randomness. Same profile + same readings → same scores every time.
///   - Missing readings → metric is [MetricScore.unavailable] → excluded from overall.
///   - Gemini does NOT set or adjust these scores.
///   - Business logic lives here, NOT in widgets or controllers.
class HealthScoreEngine {
  HealthScoreEngine._();

  // ── Weight configuration (equal by default, adjustable in future) ─────────
  static const Map<String, double> _defaultWeights = {
    MetricKeys.heartRate:     1.0,
    MetricKeys.bloodPressure: 1.0,
    MetricKeys.sleep:         1.0,
    MetricKeys.water:         1.0,
    MetricKeys.calories:      1.0,
    MetricKeys.activity:      1.0,
    MetricKeys.bloodSugar:    1.0,
  };

  // ════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ════════════════════════════════════════════════════════════════════════

  /// Calculate a full [DailyScore] from today's readings and the user profile.
  ///
  /// Pass null for any reading that has not been recorded today.
  static DailyScore calculate({
    required UserProfile profile,
    required String date,
    double? heartRateBpm,
    int? systolic,
    int? diastolic,
    double? sleepHours,
    int? waterMl,
    double? caloriesKcal,
    int? steps,
    double? bloodSugarMgDl,
    Map<String, double>? weights,
  }) {
    final w = weights ?? _defaultWeights;

    final metrics = <String, MetricScore>{
      MetricKeys.heartRate:
          calculateHeartRateScore(bpm: heartRateBpm, age: profile.age),

      MetricKeys.bloodPressure:
          calculateBloodPressureScore(systolic: systolic, diastolic: diastolic),

      MetricKeys.sleep:
          calculateSleepScore(hours: sleepHours, age: profile.age),

      MetricKeys.water:
          calculateHydrationScore(
            waterMl: waterMl,
            weightKg: profile.weightKg,
            activityLevel: profile.activityLevel,
          ),

      MetricKeys.calories:
          calculateCalorieScore(
            consumed: caloriesKcal,
            profile: profile,
          ),

      MetricKeys.activity:
          calculateActivityScore(steps: steps, stepGoal: profile.stepGoal),

      MetricKeys.bloodSugar:
          calculateBloodSugarScore(mgDl: bloodSugarMgDl),
    };

    // Compute overall from available metrics only, applying weights.
    double weightedSum = 0;
    double weightTotal = 0;

    for (final entry in metrics.entries) {
      final ms = entry.value;
      if (!ms.available) continue;
      final weight = w[entry.key] ?? 1.0;
      weightedSum += ms.score * weight;
      weightTotal += weight;
    }

    final int overall = weightTotal == 0
        ? 0
        : (weightedSum / weightTotal * 10).round().clamp(0, 100);

    return DailyScore(
      date: date,
      overall: overall,
      label: DailyScore.labelFor(overall),
      metrics: metrics,
      scoredAt: DateTime.now(),
      availableMetricCount:
          metrics.values.where((m) => m.available).length,
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // INDIVIDUAL METRIC SCORERS
  // ════════════════════════════════════════════════════════════════════════

  /// Heart rate score (resting HR in bpm).
  ///
  /// Reference: AHA resting HR guidelines for adults.
  /// Age adjustment: for age ≥ 60, thresholds relaxed by 5 bpm.
  static MetricScore calculateHeartRateScore({double? bpm, int? age}) {
    if (bpm == null || bpm <= 0) {
      return MetricScore.unavailable(MetricKeys.heartRate);
    }

    // Optional mild relaxation for seniors
    final ageAdj = (age != null && age >= 60) ? 5.0 : 0.0;

    int score;
    String reason;

    if (bpm < (50 + ageAdj)) {
      score = 10;
      reason = '${bpm.toStringAsFixed(0)} bpm — athlete/very fit range';
    } else if (bpm < (60 + ageAdj)) {
      score = 9;
      reason = '${bpm.toStringAsFixed(0)} bpm — excellent';
    } else if (bpm < (70 + ageAdj)) {
      score = 8;
      reason = '${bpm.toStringAsFixed(0)} bpm — good';
    } else if (bpm < (80 + ageAdj)) {
      score = 7;
      reason = '${bpm.toStringAsFixed(0)} bpm — normal';
    } else if (bpm < (90 + ageAdj)) {
      score = 5;
      reason = '${bpm.toStringAsFixed(0)} bpm — above normal';
    } else if (bpm < (100 + ageAdj)) {
      score = 3;
      reason = '${bpm.toStringAsFixed(0)} bpm — high normal';
    } else {
      score = 1;
      reason = '${bpm.toStringAsFixed(0)} bpm — elevated (≥100 bpm)';
    }

    return MetricScore(
      metric: MetricKeys.heartRate,
      score: score,
      available: true,
      reading: bpm,
      target: '60–80 bpm (resting)',
      reason: reason,
    );
  }

  /// Blood pressure score.
  ///
  /// Reference: ACC/AHA 2017 BP guidelines.
  static MetricScore calculateBloodPressureScore({int? systolic, int? diastolic}) {
    if (systolic == null || diastolic == null || systolic <= 0 || diastolic <= 0) {
      return MetricScore.unavailable(MetricKeys.bloodPressure);
    }

    int score;
    String reason;
    final bpStr = '$systolic/$diastolic mmHg';

    if (systolic < 90 || diastolic < 60) {
      score = 3;
      reason = '$bpStr — hypotension (low BP)';
    } else if (systolic < 120 && diastolic < 80) {
      score = 10;
      reason = '$bpStr — optimal';
    } else if (systolic < 130 && diastolic < 80) {
      score = 8;
      reason = '$bpStr — elevated';
    } else if (systolic < 140 || diastolic < 90) {
      score = 5;
      reason = '$bpStr — Stage 1 hypertension';
    } else {
      score = 2;
      reason = '$bpStr — Stage 2 hypertension';
    }

    return MetricScore(
      metric: MetricKeys.bloodPressure,
      score: score,
      available: true,
      readingSystolic: systolic,
      readingDiastolic: diastolic,
      target: '<120/80 mmHg (optimal)',
      reason: reason,
    );
  }

  /// Sleep score.
  ///
  /// Reference: National Sleep Foundation recommendations.
  static MetricScore calculateSleepScore({double? hours, int? age}) {
    if (hours == null || hours <= 0) {
      return MetricScore.unavailable(MetricKeys.sleep);
    }

    // Target range by age
    double minTarget;
    double maxTarget;
    if (age != null && age >= 65) {
      minTarget = 7.0;
      maxTarget = 8.0;
    } else if (age != null && age < 18) {
      minTarget = 8.0;
      maxTarget = 10.0;
    } else {
      minTarget = 7.0;
      maxTarget = 9.0;
    }

    final midTarget = (minTarget + maxTarget) / 2;
    final diff = (hours - midTarget).abs();
    final targetStr =
        '${minTarget.toStringAsFixed(0)}–${maxTarget.toStringAsFixed(0)} hours';

    int score;
    String reason;

    if (hours >= minTarget && hours <= maxTarget) {
      score = 10;
      reason = '${hours.toStringAsFixed(1)}h — within recommended $targetStr';
    } else if (diff <= 0.5) {
      score = 8;
      reason = '${hours.toStringAsFixed(1)}h — slightly outside $targetStr';
    } else if (diff <= 1.0) {
      score = 6;
      reason = '${hours.toStringAsFixed(1)}h — moderately outside $targetStr';
    } else if (diff <= 1.5) {
      score = 4;
      reason = '${hours.toStringAsFixed(1)}h — significantly outside $targetStr';
    } else if (hours < 5 || hours > 12) {
      score = 2;
      reason = '${hours.toStringAsFixed(1)}h — very far from $targetStr';
    } else {
      score = 3;
      reason = '${hours.toStringAsFixed(1)}h — outside $targetStr';
    }

    return MetricScore(
      metric: MetricKeys.sleep,
      score: score,
      available: true,
      reading: hours,
      target: targetStr,
      reason: reason,
    );
  }

  /// Hydration score.
  ///
  /// Personalised target: 35 ml/kg × activity multiplier.
  static MetricScore calculateHydrationScore({
    int? waterMl,
    double? weightKg,
    String? activityLevel,
  }) {
    if (waterMl == null || waterMl <= 0) {
      return MetricScore.unavailable(MetricKeys.water);
    }

    // Calculate personalised target
    final weight = weightKg ?? 70.0; // sensible default
    const baseMlPerKg = 35.0;
    final multiplier = _activityMultiplier(activityLevel);
    final targetMl = (weight * baseMlPerKg * multiplier).round();

    final pct = waterMl / targetMl;

    int score;
    String reason;
    final targetStr = '${targetMl}ml (${weight.toStringAsFixed(0)}kg × $baseMlPerKg × ${multiplier.toStringAsFixed(1)})';

    if (pct >= 1.0) {
      score = 10;
      reason = '${waterMl}ml — met/exceeded target of ${targetMl}ml';
    } else if (pct >= 0.9) {
      score = 9;
      reason = '${waterMl}ml — 90%+ of ${targetMl}ml target';
    } else if (pct >= 0.75) {
      score = 7;
      reason = '${waterMl}ml — 75–90% of ${targetMl}ml target';
    } else if (pct >= 0.6) {
      score = 5;
      reason = '${waterMl}ml — 60–75% of ${targetMl}ml target';
    } else if (pct >= 0.4) {
      score = 3;
      reason = '${waterMl}ml — 40–60% of ${targetMl}ml target';
    } else {
      score = 1;
      reason = '${waterMl}ml — below 40% of ${targetMl}ml target';
    }

    return MetricScore(
      metric: MetricKeys.water,
      score: score,
      available: true,
      reading: waterMl.toDouble(),
      target: targetStr,
      reason: reason,
    );
  }

  /// Calorie score.
  ///
  /// Target = BMR (Mifflin-St Jeor) × activity multiplier × goal adjustment.
  /// Falls back gracefully if profile is incomplete.
  static MetricScore calculateCalorieScore({
    double? consumed,
    required UserProfile profile,
  }) {
    if (consumed == null || consumed <= 0) {
      return MetricScore.unavailable(MetricKeys.calories);
    }

    double targetKcal;
    String targetStr;

    if (profile.heightCm != null &&
        profile.weightKg != null &&
        profile.age != null &&
        profile.sex != null) {
      // Mifflin-St Jeor BMR
      double bmr;
      if (profile.sex == 'male') {
        bmr = (10 * profile.weightKg!) +
            (6.25 * profile.heightCm!) -
            (5 * profile.age!) +
            5;
      } else {
        bmr = (10 * profile.weightKg!) +
            (6.25 * profile.heightCm!) -
            (5 * profile.age!) -
            161;
      }

      final activityMult = _tdeeMultiplier(profile.activityLevel);
      double tdee = bmr * activityMult;

      // Goal adjustment
      switch (profile.fitnessGoal) {
        case 'lose_weight':
          tdee *= 0.8;
          break;
        case 'gain_weight':
          tdee *= 1.1;
          break;
        default:
          break; // maintain / improve: no change
      }

      targetKcal = tdee;
      targetStr = '${tdee.round()} kcal (personalised)';
    } else {
      // No demographic data — use goal stored in profile
      targetKcal = profile.calorieGoal;
      targetStr = '${profile.calorieGoal.round()} kcal (user goal)';
    }

    final double ratio = consumed / max(targetKcal, 1.0);
    final int pct = (ratio * 100).round();

    int score;
    String reason;

    if (ratio >= 0.90 && ratio <= 1.10) {
      score = 10;
      reason = '${consumed.round()} kcal — $pct% of ${targetKcal.round()} kcal goal (Optimal ✓)';
    } else if ((ratio >= 0.80 && ratio < 0.90) || (ratio > 1.10 && ratio <= 1.20)) {
      score = 9;
      reason = '${consumed.round()} kcal — $pct% of ${targetKcal.round()} kcal goal';
    } else if ((ratio >= 0.70 && ratio < 0.80) || (ratio > 1.20 && ratio <= 1.30)) {
      score = 8;
      reason = '${consumed.round()} kcal — $pct% of ${targetKcal.round()} kcal goal';
    } else if (ratio >= 0.60 && ratio < 0.70) {
      score = 7;
      reason = '${consumed.round()} kcal — $pct% of ${targetKcal.round()} kcal goal';
    } else if (ratio >= 0.50 && ratio < 0.60) {
      score = 6;
      reason = '${consumed.round()} kcal — $pct% of ${targetKcal.round()} kcal goal';
    } else if (ratio >= 0.40 && ratio < 0.50) {
      score = 5;
      reason = '${consumed.round()} kcal — $pct% of ${targetKcal.round()} kcal goal';
    } else if (ratio >= 0.30 && ratio < 0.40) {
      score = 4;
      reason = '${consumed.round()} kcal — $pct% of ${targetKcal.round()} kcal goal';
    } else if (ratio >= 0.20 && ratio < 0.30) {
      score = 3;
      reason = '${consumed.round()} kcal — $pct% of ${targetKcal.round()} kcal goal';
    } else if (ratio >= 0.10 && ratio < 0.20) {
      score = 2;
      reason = '${consumed.round()} kcal — $pct% of ${targetKcal.round()} kcal goal';
    } else if (ratio > 1.30 && ratio <= 1.50) {
      score = 5;
      reason = '${consumed.round()} kcal — $pct% of ${targetKcal.round()} kcal goal (Surplus)';
    } else if (ratio > 1.50) {
      score = 3;
      reason = '${consumed.round()} kcal — $pct% of ${targetKcal.round()} kcal goal (High surplus)';
    } else {
      score = 1;
      reason = '${consumed.round()} kcal — $pct% of ${targetKcal.round()} kcal goal';
    }

    return MetricScore(
      metric: MetricKeys.calories,
      score: score,
      available: true,
      reading: consumed,
      target: targetStr,
      reason: reason,
    );
  }

  /// Activity score (steps).
  static MetricScore calculateActivityScore({int? steps, int stepGoal = 10000}) {
    if (steps == null || steps <= 0) {
      return MetricScore.unavailable(MetricKeys.activity);
    }

    final pct = steps / max(stepGoal, 1);
    int score;
    String reason;

    if (pct >= 1.0) {
      score = 10;
      reason = '$steps steps — goal of $stepGoal met ✓';
    } else if (pct >= 0.85) {
      score = 8;
      reason = '$steps steps — 85–100% of $stepGoal goal';
    } else if (pct >= 0.70) {
      score = 6;
      reason = '$steps steps — 70–85% of $stepGoal goal';
    } else if (pct >= 0.50) {
      score = 4;
      reason = '$steps steps — 50–70% of $stepGoal goal';
    } else if (pct >= 0.30) {
      score = 2;
      reason = '$steps steps — 30–50% of $stepGoal goal';
    } else {
      score = 1;
      reason = '$steps steps — below 30% of $stepGoal goal';
    }

    return MetricScore(
      metric: MetricKeys.activity,
      score: score,
      available: true,
      reading: steps.toDouble(),
      target: '$stepGoal steps',
      reason: reason,
    );
  }

  /// Blood sugar score (fasting blood glucose in mg/dL).
  ///
  /// Reference: ADA clinical guidelines for glycemic targets:
  ///   - 70–99 mg/dL: Normal / Optimal (Score 10)
  ///   - 100 mg/dL: Normal fasting baseline (Score 10)
  ///   - 101–115 mg/dL: Mildly elevated (Score 8)
  ///   - 116–125 mg/dL: Elevated / Pre-diabetic range (Score 6)
  ///   - 126–150 mg/dL: High (Score 4)
  ///   - 151–180 mg/dL: Significantly elevated (Score 3)
  ///   - >180 mg/dL: Very high (Score 1)
  ///   - 60–69 mg/dL: Mildly low (Score 6)
  ///   - 50–59 mg/dL: Low / Hypoglycemia risk (Score 3)
  ///   - <50 mg/dL: Very low (Score 1)
  static MetricScore calculateBloodSugarScore({double? mgDl}) {
    if (mgDl == null || mgDl <= 0) {
      return MetricScore.unavailable(MetricKeys.bloodSugar);
    }

    int score;
    String reason;
    final valStr = '${mgDl.toStringAsFixed(0)} mg/dL';

    if (mgDl >= 70 && mgDl <= 99) {
      score = 10;
      reason = '$valStr — optimal fasting range (70–99 mg/dL)';
    } else if (mgDl == 100) {
      score = 10;
      reason = '$valStr — normal fasting baseline';
    } else if (mgDl > 100 && mgDl <= 115) {
      score = 8;
      reason = '$valStr — slightly elevated (101–115 mg/dL)';
    } else if (mgDl > 115 && mgDl <= 125) {
      score = 6;
      reason = '$valStr — elevated (116–125 mg/dL)';
    } else if (mgDl > 125 && mgDl <= 150) {
      score = 4;
      reason = '$valStr — high (>125 mg/dL)';
    } else if (mgDl > 150 && mgDl <= 180) {
      score = 3;
      reason = '$valStr — significantly elevated (>150 mg/dL)';
    } else if (mgDl > 180) {
      score = 1;
      reason = '$valStr — very high (≥180 mg/dL)';
    } else if (mgDl >= 60) {
      score = 6;
      reason = '$valStr — mildly low (60–69 mg/dL)';
    } else if (mgDl >= 50) {
      score = 3;
      reason = '$valStr — low (50–59 mg/dL)';
    } else {
      score = 1;
      reason = '$valStr — very low (<50 mg/dL)';
    }

    return MetricScore(
      metric: MetricKeys.bloodSugar,
      score: score,
      available: true,
      reading: mgDl,
      target: '70–100 mg/dL (fasting)',
      reason: reason,
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ════════════════════════════════════════════════════════════════════════

  static double _activityMultiplier(String? level) {
    switch (level) {
      case 'lightly_active':
        return 1.1;
      case 'moderately_active':
        return 1.2;
      case 'very_active':
        return 1.4;
      default:
        return 1.0; // sedentary
    }
  }

  static double _tdeeMultiplier(String? level) {
    switch (level) {
      case 'lightly_active':
        return 1.375;
      case 'moderately_active':
        return 1.55;
      case 'very_active':
        return 1.725;
      default:
        return 1.2; // sedentary
    }
  }
}

/// Metric key constants (matches [HealthReading] metric constants).
class MetricKeys {
  static const String heartRate     = 'heart_rate';
  static const String bloodPressure = 'blood_pressure';
  static const String sleep         = 'sleep';
  static const String water         = 'water';
  static const String calories      = 'calories';
  static const String activity      = 'activity';
  static const String bloodSugar    = 'blood_sugar';
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/models/user_profile.dart';
import 'package:tracker/models/daily_score.dart';
import 'package:tracker/services/health_score_engine.dart';

void main() {
  group('Blood Sugar 7th Metric Health Score Engine Tests', () {
    const profile = UserProfile(
      uid: 'test-user-123',
      name: 'Test User',
      email: 'test@example.com',
      avatarUrl: '',
      age: 25,
      heightCm: 175.0,
      weightKg: 70.0,
      activityLevel: 'moderately_active',
      fitnessGoal: 'maintain',
      calorieGoal: 2000,
      stepGoal: 10000,
      waterGoalMl: 2500,
      sleepGoalHours: 8.0,
    );

    test('TEST 1 & TEST 8: All seven metrics available produce 7 available metrics and include Blood Sugar', () {
      final score = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-14',
        heartRateBpm: 72,      // 7/10
        systolic: 118,          // 10/10
        diastolic: 76,
        sleepHours: 8.0,        // 10/10
        waterMl: 2500,          // 10/10
        caloriesKcal: 2000,     // 10/10
        steps: 10000,           // 10/10
        bloodSugarMgDl: 90,     // 10/10
      );

      expect(score.availableMetricCount, equals(7));
      expect(score.metrics.length, equals(7));
      expect(score.metrics.containsKey(MetricKeys.bloodSugar), isTrue);
      expect(score.metrics[MetricKeys.bloodSugar]!.available, isTrue);
      expect(score.metrics[MetricKeys.bloodSugar]!.score, equals(10));
      expect(score.metrics[MetricKeys.bloodSugar]!.reading, equals(90.0));
      expect(score.metrics[MetricKeys.bloodSugar]!.target, contains('70–100'));
    });

    test('TEST 2 & TEST 9: Blood Sugar unavailable is excluded from denominator without penalty', () {
      final scoreWith6 = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-14',
        heartRateBpm: 72,
        systolic: 118,
        diastolic: 76,
        sleepHours: 8.0,
        waterMl: 2500,
        caloriesKcal: 2000,
        steps: 10000,
        bloodSugarMgDl: null, // unavailable
      );

      expect(scoreWith6.availableMetricCount, equals(6));
      expect(scoreWith6.metrics[MetricKeys.bloodSugar]!.available, isFalse);
      expect(scoreWith6.metrics[MetricKeys.bloodSugar]!.reason, contains('No reading'));
      // The 6 available metrics are all high, so overall score is not penalized by missing blood sugar
      expect(scoreWith6.overall, greaterThanOrEqualTo(90));
    });

    test('TEST 3: Only Blood Sugar available produces valid score based only on Blood Sugar', () {
      final scoreOnlySugar = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-14',
        bloodSugarMgDl: 90.0, // 10/10
      );

      expect(scoreOnlySugar.availableMetricCount, equals(1));
      expect(scoreOnlySugar.metrics[MetricKeys.bloodSugar]!.available, isTrue);
      expect(scoreOnlySugar.metrics[MetricKeys.bloodSugar]!.score, equals(10));
      expect(scoreOnlySugar.overall, equals(100)); // 10 / 1 * 10 = 100
    });

    test('TEST 4: Optimal Blood Sugar (70-100 mg/dL) receives high score (10/10)', () {
      final normalFasting = HealthScoreEngine.calculateBloodSugarScore(mgDl: 85);
      final normal100 = HealthScoreEngine.calculateBloodSugarScore(mgDl: 100);

      expect(normalFasting.score, equals(10));
      expect(normalFasting.available, isTrue);
      expect(normalFasting.reason, contains('optimal'));

      expect(normal100.score, equals(10));
      expect(normal100.available, isTrue);
    });

    test('TEST 5: Elevated and High Blood Sugar receive lower deterministic scores', () {
      final prediabetic = HealthScoreEngine.calculateBloodSugarScore(mgDl: 120); // 6/10
      final high = HealthScoreEngine.calculateBloodSugarScore(mgDl: 140);        // 4/10
      final veryHigh = HealthScoreEngine.calculateBloodSugarScore(mgDl: 220);    // 1/10
      final hypoglycemic = HealthScoreEngine.calculateBloodSugarScore(mgDl: 45); // 1/10

      expect(prediabetic.score, equals(6));
      expect(high.score, equals(4));
      expect(veryHigh.score, equals(1));
      expect(hypoglycemic.score, equals(1));
    });

    test('TEST 6: Changing only Blood Sugar changes the overall score', () {
      final scoreGoodSugar = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-14',
        heartRateBpm: 72,
        systolic: 118,
        diastolic: 76,
        sleepHours: 8.0,
        waterMl: 2500,
        caloriesKcal: 2000,
        steps: 10000,
        bloodSugarMgDl: 90, // 10/10
      );

      final scorePoorSugar = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-14',
        heartRateBpm: 72,
        systolic: 118,
        diastolic: 76,
        sleepHours: 8.0,
        waterMl: 2500,
        caloriesKcal: 2000,
        steps: 10000,
        bloodSugarMgDl: 240, // 1/10
      );

      expect(scoreGoodSugar.overall, greaterThan(scorePoorSugar.overall));
    });

    test('TEST 7: Changing Blood Sugar does NOT alter individual scores of other 6 metrics', () {
      final score1 = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-14',
        heartRateBpm: 75,
        systolic: 125,
        diastolic: 79,
        sleepHours: 7.0,
        waterMl: 2000,
        caloriesKcal: 1900,
        steps: 8000,
        bloodSugarMgDl: 90,
      );

      final score2 = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-14',
        heartRateBpm: 75,
        systolic: 125,
        diastolic: 79,
        sleepHours: 7.0,
        waterMl: 2000,
        caloriesKcal: 1900,
        steps: 8000,
        bloodSugarMgDl: 220,
      );

      expect(score1.metrics[MetricKeys.heartRate]!.score, equals(score2.metrics[MetricKeys.heartRate]!.score));
      expect(score1.metrics[MetricKeys.bloodPressure]!.score, equals(score2.metrics[MetricKeys.bloodPressure]!.score));
      expect(score1.metrics[MetricKeys.sleep]!.score, equals(score2.metrics[MetricKeys.sleep]!.score));
      expect(score1.metrics[MetricKeys.water]!.score, equals(score2.metrics[MetricKeys.water]!.score));
      expect(score1.metrics[MetricKeys.calories]!.score, equals(score2.metrics[MetricKeys.calories]!.score));
      expect(score1.metrics[MetricKeys.activity]!.score, equals(score2.metrics[MetricKeys.activity]!.score));
    });

    test('TEST 10: Zero randomness across 50 iterations', () {
      final first = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-14',
        heartRateBpm: 68,
        systolic: 120,
        diastolic: 80,
        sleepHours: 7.5,
        waterMl: 2200,
        caloriesKcal: 2100,
        steps: 9500,
        bloodSugarMgDl: 95,
      );

      for (int i = 0; i < 50; i++) {
        final repeat = HealthScoreEngine.calculate(
          profile: profile,
          date: '2026-09-14',
          heartRateBpm: 68,
          systolic: 120,
          diastolic: 80,
          sleepHours: 7.5,
          waterMl: 2200,
          caloriesKcal: 2100,
          steps: 9500,
          bloodSugarMgDl: 95,
        );

        expect(repeat.overall, equals(first.overall));
        expect(repeat.availableMetricCount, equals(7));
        expect(repeat.metrics[MetricKeys.bloodSugar]!.score, equals(first.metrics[MetricKeys.bloodSugar]!.score));
      }
    });

    test('TEST 11: Controlled dataset manual calculation exactly matches engine output', () {
      final score = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-14',
        heartRateBpm: 72,       // 7/10
        systolic: 118,          // 10/10
        diastolic: 76,
        sleepHours: 8.0,        // 10/10
        waterMl: 2940,          // 10/10 (matches 70kg * 35 * 1.2 target)
        caloriesKcal: 2000,     // 8/10
        steps: 10000,           // 10/10
        bloodSugarMgDl: 90,     // 10/10
      );

      final sum = score.metrics.values.map((m) => m.score).reduce((a, b) => a + b);
      final expectedOverall = (sum / 7.0 * 10).round().clamp(0, 100);

      expect(score.availableMetricCount, equals(7));
      expect(score.overall, equals(expectedOverall));
    });

    test('TEST 13: DailyScore Firestore serialization and deserialization preserves Blood Sugar', () {
      final original = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-14',
        bloodSugarMgDl: 98,
      );

      final map = original.toFirestore();
      final reconstructed = DailyScore.fromFirestore(map);

      expect(reconstructed.date, equals('2026-09-14'));
      expect(reconstructed.metrics.containsKey(MetricKeys.bloodSugar), isTrue);
      expect(reconstructed.metrics[MetricKeys.bloodSugar]!.score, equals(10));
      expect(reconstructed.metrics[MetricKeys.bloodSugar]!.reading, equals(98.0));
      expect(reconstructed.metrics[MetricKeys.bloodSugar]!.available, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/models/user_profile.dart';
import 'package:tracker/services/health_score_engine.dart';

void main() {
  group('HealthScoreEngine Deterministic Tests', () {
    const profile = UserProfile(
      uid: 'test-user-123',
      name: 'Test User',
      email: 'test@example.com',
      avatarUrl: '',
      age: 22,
      heightCm: 175.0,
      weightKg: 72.0,
      activityLevel: 'moderately_active',
      fitnessGoal: 'maintain',
    );

    test('Identical inputs produce identical outputs across 100 iterations (Zero Randomness)', () {
      final initialScore = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-11',
        heartRateBpm: 68,
        systolic: 118,
        diastolic: 76,
        sleepHours: 7.5,
        waterMl: 2500,
        caloriesKcal: 2200,
        steps: 10000,
      );

      for (int i = 0; i < 100; i++) {
        final nextScore = HealthScoreEngine.calculate(
          profile: profile,
          date: '2026-09-11',
          heartRateBpm: 68,
          systolic: 118,
          diastolic: 76,
          sleepHours: 7.5,
          waterMl: 2500,
          caloriesKcal: 2200,
          steps: 10000,
        );

        expect(nextScore.overall, equals(initialScore.overall));
        expect(nextScore.label, equals(initialScore.label));
        expect(nextScore.availableMetricCount, equals(6));

        for (final key in initialScore.metrics.keys) {
          expect(nextScore.metrics[key]!.score, equals(initialScore.metrics[key]!.score));
          expect(nextScore.metrics[key]!.available, equals(initialScore.metrics[key]!.available));
        }
      }
    });

    test('Missing metric is marked unavailable and excluded from denominator', () {
      // Score with NO sleep logged
      final scoreWithoutSleep = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-11',
        heartRateBpm: 68,
        systolic: 118,
        diastolic: 76,
        sleepHours: null, // missing
        waterMl: 2500,
        caloriesKcal: 2200,
        steps: 10000,
      );

      expect(scoreWithoutSleep.metrics['sleep']!.available, isFalse);
      expect(scoreWithoutSleep.metrics['sleep']!.reason, contains('No reading'));
      expect(scoreWithoutSleep.availableMetricCount, equals(5));

      // Missing sleep is NOT treated as 0; the remaining 5 metrics still yield a high score
      expect(scoreWithoutSleep.overall, greaterThanOrEqualTo(80));
    });

    test('Modifying a metric dynamically changes the overall score', () {
      final healthySleepScore = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-11',
        sleepHours: 8.0, // 10/10
        steps: 10000,
      );

      final poorSleepScore = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-11',
        sleepHours: 3.5, // 2/10
        steps: 10000,
      );

      expect(healthySleepScore.metrics['sleep']!.score, equals(10));
      expect(poorSleepScore.metrics['sleep']!.score, equals(2));
      expect(healthySleepScore.overall, greaterThan(poorSleepScore.overall));
    });

    test('Steps with 0 count is marked unavailable and not tracked prematurely', () {
      final zeroStepsScore = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-12',
        steps: 0,
      );

      expect(zeroStepsScore.metrics['activity']!.available, isFalse);
      expect(zeroStepsScore.availableMetricCount, equals(0));

      final activeStepsScore = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-12',
        steps: 1200,
      );

      expect(activeStepsScore.metrics['activity']!.available, isTrue);
      expect(activeStepsScore.availableMetricCount, equals(1));
    });

    test('Calorie scoring dynamically scales as user logs meals throughout the day', () {
      // Base profile calorie goal is 2000 kcal (or TDEE based)
      final snackScore = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-12',
        caloriesKcal: 400,
      );
      final lunchScore = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-12',
        caloriesKcal: 1332,
      );
      final targetScore = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-12',
        caloriesKcal: 2500, // Close to TDEE ~2650
      );

      final snackCal = snackScore.metrics['calories']!;
      final lunchCal = lunchScore.metrics['calories']!;
      final targetCal = targetScore.metrics['calories']!;

      expect(snackCal.available, isTrue);
      expect(lunchCal.available, isTrue);
      expect(targetCal.available, isTrue);

      // Score should increase as user adds calories towards target
      expect(lunchCal.score, greaterThan(snackCal.score));
      expect(targetCal.score, greaterThanOrEqualTo(lunchCal.score));

      // Reason strings should accurately report percent of goal
      expect(lunchCal.reason, contains('% of'));
      expect(lunchCal.reason, contains('1332 kcal'));
    });

    test('Updating step goal from 10000 to 100 immediately updates target and scoring', () {
      final initialProfile = profile.copyWith(stepGoal: 10000);
      final scoreWithOldGoal = HealthScoreEngine.calculate(
        profile: initialProfile,
        date: '2026-09-12',
        steps: 29,
      );

      final activityOld = scoreWithOldGoal.metrics['activity']!;
      expect(activityOld.target, equals('10000 steps'));
      expect(activityOld.reason, contains('10000 goal'));

      // Update goal to 100
      final updatedProfile = initialProfile.copyWith(stepGoal: 100);
      final scoreWithNewGoal = HealthScoreEngine.calculate(
        profile: updatedProfile,
        date: '2026-09-12',
        steps: 29,
      );

      final activityNew = scoreWithNewGoal.metrics['activity']!;
      expect(activityNew.target, equals('100 steps'));
      expect(activityNew.reason, contains('100 goal'));

      // If user reaches 95 steps with 100 goal (95%), score increases to 8
      final nearGoalScore = HealthScoreEngine.calculate(
        profile: updatedProfile,
        date: '2026-09-12',
        steps: 95,
      );
      expect(nearGoalScore.metrics['activity']!.score, equals(8));
      expect(nearGoalScore.metrics['activity']!.target, equals('100 steps'));
    });

    test('User Screenshots Case: Steps=29, Water=3250, Sleep=12.5, HR=72, Cal=1898, BP=130/60 produces exactly Overall 58 with identical breakdown', () {
      const caseProfile = UserProfile(
        uid: 'user-screenshots',
        name: 'Himanshu',
        email: 'himanshu@example.com',
        stepGoal: 100,
        waterGoalMl: 2450,
        calorieGoal: 2000,
        sleepGoalHours: 8.0,
      );

      final score = HealthScoreEngine.calculate(
        profile: caseProfile,
        date: '2026-09-12',
        steps: 29,
        waterMl: 3250,
        sleepHours: 12.5,
        heartRateBpm: 72,
        caloriesKcal: 1898,
        systolic: 130,
        diastolic: 60,
      );

      // Verify all 6 metrics exist and match Insights Screenshot 2
      expect(score.availableMetricCount, equals(6));

      // Steps: 29 / 100 -> score = 1 -> 10%
      expect(score.metrics['activity']!.score, equals(1));
      expect(score.metrics['activity']!.score * 10, equals(10));

      // Water: 3250 -> score = 10 -> 100%
      expect(score.metrics['water']!.score, equals(10));
      expect(score.metrics['water']!.score * 10, equals(100));

      // Sleep: 12.5 hrs -> score = 2 -> 20%
      expect(score.metrics['sleep']!.score, equals(2));
      expect(score.metrics['sleep']!.score * 10, equals(20));

      // Heart: 72 bpm -> score = 7 -> 70%
      expect(score.metrics['heart_rate']!.score, equals(7));
      expect(score.metrics['heart_rate']!.score * 10, equals(70));

      // Calories: 1898 kcal -> score = 10 -> 100%
      expect(score.metrics['calories']!.score, equals(10));
      expect(score.metrics['calories']!.score * 10, equals(100));

      // BP: 130/60 mmHg -> score = 5 -> 50%
      expect(score.metrics['blood_pressure']!.score, equals(5));
      expect(score.metrics['blood_pressure']!.score * 10, equals(50));

      // Overall: (1 + 10 + 2 + 7 + 10 + 5) / 6 = 35 / 6 = 5.833 * 10 = 58!
      expect(score.overall, equals(58));
      expect(score.label, equals('Needs Improvement'));
    });

    test('Subset combinations: 1, 2, 3 metrics calculate exact averages and never treat missing as 0', () {
      const p = UserProfile(
        uid: 'user-subsets',
        name: 'Test',
        email: 'test@example.com',
        stepGoal: 100,
        waterGoalMl: 2500,
        sleepGoalHours: 8.0,
      );

      // 1 metric: only Water 2500 ml -> score 10 -> overall 100
      final score1 = HealthScoreEngine.calculate(
        profile: p,
        date: '2026-09-12',
        waterMl: 2500,
      );
      expect(score1.availableMetricCount, equals(1));
      expect(score1.overall, equals(100));
      expect(score1.metrics['water']!.score, equals(10));
      expect(score1.metrics['activity']!.available, isFalse);

      // 2 metrics: Steps 29 (score 1) + Sleep 12.5 (score 2) -> (1 + 2) / 2 = 1.5 * 10 = 15
      final score2 = HealthScoreEngine.calculate(
        profile: p,
        date: '2026-09-12',
        steps: 29,
        sleepHours: 12.5,
      );
      expect(score2.availableMetricCount, equals(2));
      expect(score2.overall, equals(15));

      // 3 metrics: Steps 29 (1) + Water 2500 (10) + Sleep 12.5 (2) -> (1 + 10 + 2) / 3 = 4.33 * 10 = 43
      final score3 = HealthScoreEngine.calculate(
        profile: p,
        date: '2026-09-12',
        steps: 29,
        waterMl: 2500,
        sleepHours: 12.5,
      );
      expect(score3.availableMetricCount, equals(3));
      expect(score3.overall, equals(43));
    });
  });
}

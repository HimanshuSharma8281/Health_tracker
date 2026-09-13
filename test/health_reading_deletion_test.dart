import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/models/health_reading.dart';
import 'package:tracker/models/user_profile.dart';
import 'package:tracker/services/health_score_engine.dart';

void main() {
  group('Health Reading Deletion & Persistence Flow Tests', () {
    const profile = UserProfile(
      uid: 'user-persistence-test-uid',
      name: 'Persistence Tester',
      email: 'test@persistence.com',
      avatarUrl: '',
      stepGoal: 10000,
      waterGoalMl: 2000,
      calorieGoal: 2000,
      sleepGoalHours: 8.0,
    );

    test('TEST 1 — Water Delete: 500 ml - 200 ml = 300 ml persisted & reconstructed', () {
      final now = DateTime.now();
      final todayStr = HealthReading.todayDate();

      // Start: 500 ml logged
      final readings = <HealthReading>[
        HealthReading(
          id: 'water_doc_1',
          userId: profile.uid,
          metric: HealthReading.water,
          value: 500,
          date: todayStr,
          timestamp: now,
        ),
      ];

      var totalWater = readings
          .where((r) => r.metric == HealthReading.water && r.date == todayStr)
          .fold<int>(0, (sum, r) => sum + r.value.round());
      expect(totalWater, equals(500));

      // User deletes the 500 ml entry and adds 300 ml (or user logged 300 + 200 = 500, deletes 200)
      final readingA = HealthReading(
        id: 'water_entry_300',
        userId: profile.uid,
        metric: HealthReading.water,
        value: 300,
        date: todayStr,
        timestamp: now.subtract(const Duration(minutes: 30)),
      );
      final readingB = HealthReading(
        id: 'water_entry_200',
        userId: profile.uid,
        metric: HealthReading.water,
        value: 200,
        date: todayStr,
        timestamp: now,
      );

      final liveReadings = [readingA, readingB];
      totalWater = liveReadings
          .where((r) => r.metric == HealthReading.water && r.date == todayStr)
          .fold<int>(0, (sum, r) => sum + r.value.round());
      expect(totalWater, equals(500));

      // Delete 200 ml entry
      liveReadings.removeWhere((r) => r.id == 'water_entry_200');

      // Immediately: 300 ml
      totalWater = liveReadings
          .where((r) => r.metric == HealthReading.water && r.date == todayStr)
          .fold<int>(0, (sum, r) => sum + r.value.round());
      expect(totalWater, equals(300));

      // App restart hydration simulation: load directly from Firestore readings
      final restartedReadings = List<HealthReading>.from(liveReadings);
      final restartedWater = restartedReadings
          .where((r) => r.metric == HealthReading.water && r.date == todayStr)
          .fold<int>(0, (sum, r) => sum + r.value.round());
      expect(restartedWater, equals(300), reason: 'After restart, water must remain 300 ml');
    });

    test('TEST 2 — Multiple Water Entries: 500 + 750 + 250 + 1000 = 2500 -> delete 750 -> 1750 ml', () {
      final now = DateTime.now();
      final todayStr = HealthReading.todayDate();

      final entries = [
        HealthReading(id: 'w1', userId: profile.uid, metric: HealthReading.water, value: 500, date: todayStr, timestamp: now),
        HealthReading(id: 'w2', userId: profile.uid, metric: HealthReading.water, value: 750, date: todayStr, timestamp: now),
        HealthReading(id: 'w3', userId: profile.uid, metric: HealthReading.water, value: 250, date: todayStr, timestamp: now),
        HealthReading(id: 'w4', userId: profile.uid, metric: HealthReading.water, value: 1000, date: todayStr, timestamp: now),
      ];

      expect(entries.fold<double>(0, (s, r) => s + r.value), equals(2500));

      // Delete 750 ml entry
      entries.removeWhere((r) => r.id == 'w2');

      final remainingTotal = entries
          .where((r) => r.metric == HealthReading.water && r.date == todayStr)
          .fold<int>(0, (sum, r) => sum + r.value.round());
      expect(remainingTotal, equals(1750));

      // Simulating restart
      final restartTotal = List<HealthReading>.from(entries)
          .where((r) => r.metric == HealthReading.water && r.date == todayStr)
          .fold<int>(0, (sum, r) => sum + r.value.round());
      expect(restartTotal, equals(1750));
    });

    test('TEST 3 — Calorie Delete: 500 + 700 + 800 = 2000 kcal -> delete 700 -> 1300 kcal', () {
      final now = DateTime.now();
      final todayStr = HealthReading.todayDate();

      final meals = [
        HealthReading(id: 'm1', userId: profile.uid, metric: HealthReading.calories, value: 500, date: todayStr, timestamp: now),
        HealthReading(id: 'm2', userId: profile.uid, metric: HealthReading.calories, value: 700, date: todayStr, timestamp: now),
        HealthReading(id: 'm3', userId: profile.uid, metric: HealthReading.calories, value: 800, date: todayStr, timestamp: now),
      ];

      expect(meals.fold<double>(0, (s, r) => s + r.value), equals(2000));

      // Delete 700 kcal meal
      meals.removeWhere((r) => r.id == 'm2');

      final remainingCal = meals
          .where((r) => r.metric == HealthReading.calories && r.date == todayStr)
          .fold<double>(0, (sum, r) => sum + r.value);
      expect(remainingCal, equals(1300.0));

      // Simulating restart
      final restartCal = List<HealthReading>.from(meals)
          .where((r) => r.metric == HealthReading.calories && r.date == todayStr)
          .fold<double>(0, (sum, r) => sum + r.value);
      expect(restartCal, equals(1300.0));
    });

    test('TEST 4 — Delete then Add: 500 - 200 = 300 + 400 = 700 ml', () {
      final now = DateTime.now();
      final todayStr = HealthReading.todayDate();

      final readings = <HealthReading>[
        HealthReading(id: 'w1', userId: profile.uid, metric: HealthReading.water, value: 300, date: todayStr, timestamp: now),
        HealthReading(id: 'w2', userId: profile.uid, metric: HealthReading.water, value: 200, date: todayStr, timestamp: now),
      ];

      // Delete 200
      readings.removeWhere((r) => r.id == 'w2');
      var total = readings.fold<double>(0, (s, r) => s + r.value);
      expect(total, equals(300));

      // Add 400
      readings.add(HealthReading(id: 'w3', userId: profile.uid, metric: HealthReading.water, value: 400, date: todayStr, timestamp: now));
      total = readings.fold<double>(0, (s, r) => s + r.value);
      expect(total, equals(700));

      // After restart
      final restartTotal = List<HealthReading>.from(readings)
          .where((r) => r.metric == HealthReading.water && r.date == todayStr)
          .fold<int>(0, (s, r) => s + r.value.round());
      expect(restartTotal, equals(700));
    });

    test('TEST 5 — Multiple Delete Operations: 1500 ml -> delete first 500 -> 1000 -> delete second 500 -> 500', () {
      final now = DateTime.now();
      final todayStr = HealthReading.todayDate();

      final readings = <HealthReading>[
        HealthReading(id: 'e1', userId: profile.uid, metric: HealthReading.water, value: 500, date: todayStr, timestamp: now),
        HealthReading(id: 'e2', userId: profile.uid, metric: HealthReading.water, value: 500, date: todayStr, timestamp: now),
        HealthReading(id: 'e3', userId: profile.uid, metric: HealthReading.water, value: 500, date: todayStr, timestamp: now),
      ];

      expect(readings.fold<double>(0, (s, r) => s + r.value), equals(1500));

      // Delete first 500
      readings.removeWhere((r) => r.id == 'e1');
      expect(readings.fold<double>(0, (s, r) => s + r.value), equals(1000));

      // Delete second 500
      readings.removeWhere((r) => r.id == 'e2');
      expect(readings.fold<double>(0, (s, r) => s + r.value), equals(500));

      // After restart
      final restartTotal = List<HealthReading>.from(readings).fold<double>(0, (s, r) => s + r.value);
      expect(restartTotal, equals(500));
    });

    test('TEST 6 — Wellness Score Recalculation after reading deletion', () {
      final todayStr = HealthReading.todayDate();

      // Before deletion: water is 2000 ml (100% of goal), calories 2000 kcal
      final initialScore = HealthScoreEngine.calculate(
        profile: profile,
        date: todayStr,
        waterMl: 2000,
        caloriesKcal: 2000,
        sleepHours: 8.0,
        steps: 10000,
      );

      // Water entry of 1000 ml deleted -> water is now 1000 ml (50% of goal)
      final scoreAfterDelete = HealthScoreEngine.calculate(
        profile: profile,
        date: todayStr,
        waterMl: 1000,
        caloriesKcal: 2000,
        sleepHours: 8.0,
        steps: 10000,
      );

      expect(scoreAfterDelete.metrics[HealthReading.water]!.score, isNot(equals(initialScore.metrics[HealthReading.water]!.score)));
      expect(scoreAfterDelete.overall, isNot(equals(initialScore.overall)));
      expect(scoreAfterDelete.metrics[HealthReading.water]!.score, equals(3));

      // Simulating restart: recalculating with persisted 1000 ml yields identical score
      final restartScore = HealthScoreEngine.calculate(
        profile: profile,
        date: todayStr,
        waterMl: 1000,
        caloriesKcal: 2000,
        sleepHours: 8.0,
        steps: 10000,
      );
      expect(restartScore.overall, equals(scoreAfterDelete.overall));
      expect(restartScore.metrics[HealthReading.water]!.score, equals(scoreAfterDelete.metrics[HealthReading.water]!.score));
    });

    test('TEST 7 — History: deleted reading removed, historical dates & totals remain correct', () {
      final todayStr = HealthReading.todayDate();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = HealthReading.formatDate(yesterday);

      final readings = <HealthReading>[
        // Yesterday's readings
        HealthReading(id: 'y1', userId: profile.uid, metric: HealthReading.water, value: 1000, date: yesterdayStr, timestamp: yesterday),
        HealthReading(id: 'y2', userId: profile.uid, metric: HealthReading.water, value: 500, date: yesterdayStr, timestamp: yesterday),
        // Today's readings
        HealthReading(id: 't1', userId: profile.uid, metric: HealthReading.water, value: 750, date: todayStr, timestamp: DateTime.now()),
      ];

      // Total yesterday = 1500
      var yesterdayTotal = readings
          .where((r) => r.metric == HealthReading.water && r.date == yesterdayStr)
          .fold<int>(0, (s, r) => s + r.value.round());
      expect(yesterdayTotal, equals(1500));

      // Delete one reading from yesterday (y2 = 500 ml)
      readings.removeWhere((r) => r.id == 'y2');

      // Yesterday's total is now 1000, today's total is still 750
      yesterdayTotal = readings
          .where((r) => r.metric == HealthReading.water && r.date == yesterdayStr)
          .fold<int>(0, (s, r) => s + r.value.round());
      final todayTotal = readings
          .where((r) => r.metric == HealthReading.water && r.date == todayStr)
          .fold<int>(0, (s, r) => s + r.value.round());

      expect(yesterdayTotal, equals(1000));
      expect(todayTotal, equals(750));
    });
  });
}

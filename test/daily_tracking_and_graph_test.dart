import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/controllers/health_data_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Daily Tracking & Weekly/Monthly Graph Tests (Tests 1-7)', () {
    late HealthDataController controller;

    setUp(() {
      controller = HealthDataController();
      controller.userId = 'test_user_daily_tracking';
      controller.heartRateHistory.clear();
      controller.bloodPressureHistory.clear();
      controller.bloodSugarHistory.clear();
    });

    test('TEST 1: Readings on Sep 13 do not make Sep 14 appear tracked', () {
      final sep13 = DateTime(2026, 9, 13, 10, 0);
      final sep14 = DateTime(2026, 9, 14, 10, 0);

      // Add readings on Sep 13
      controller.updateHeartRate(75.0, timestamp: sep13);
      controller.addBloodPressureReading(120, 80, timestamp: sep13);
      controller.updateBloodSugar(95.0, timestamp: sep13);

      // Check Sep 13 state
      expect(controller.isHeartRateTrackedForDay(sep13), isTrue);
      expect(controller.getHeartRateForDay(sep13), equals(75.0));
      expect(controller.isBloodPressureTrackedForDay(sep13), isTrue);
      expect(controller.getBloodPressureForDay(sep13)?.systolic, equals(120));
      expect(controller.getBloodPressureForDay(sep13)?.diastolic, equals(80));
      expect(controller.isBloodSugarTrackedForDay(sep13), isTrue);
      expect(controller.getBloodSugarForDay(sep13), equals(95.0));

      // Check Sep 14 state: must be untracked
      expect(controller.isHeartRateTrackedForDay(sep14), isFalse);
      expect(controller.getHeartRateForDay(sep14), equals(0.0));
      expect(controller.isBloodPressureTrackedForDay(sep14), isFalse);
      expect(controller.getBloodPressureForDay(sep14), isNull);
      expect(controller.isBloodSugarTrackedForDay(sep14), isFalse);
      expect(controller.getBloodSugarForDay(sep14), equals(0.0));
    });

    test('TEST 2: Recording HR on Sep 14 marks only HR as tracked on Sep 14', () {
      final sep13 = DateTime(2026, 9, 13, 10, 0);
      final sep14 = DateTime(2026, 9, 14, 10, 0);

      controller.updateHeartRate(75.0, timestamp: sep13);
      controller.addBloodPressureReading(120, 80, timestamp: sep13);
      controller.updateBloodSugar(95.0, timestamp: sep13);

      // On Sep 14, record ONLY heart rate = 72
      controller.updateHeartRate(72.0, timestamp: sep14);

      expect(controller.isHeartRateTrackedForDay(sep14), isTrue);
      expect(controller.getHeartRateForDay(sep14), equals(72.0));
      expect(controller.isBloodPressureTrackedForDay(sep14), isFalse);
      expect(controller.isBloodSugarTrackedForDay(sep14), isFalse);
    });

    test('TEST 3: Navigating back to Sep 13 restores all Sep 13 tracked states', () {
      final sep13 = DateTime(2026, 9, 13, 10, 0);
      final sep14 = DateTime(2026, 9, 14, 10, 0);

      controller.updateHeartRate(75.0, timestamp: sep13);
      controller.addBloodPressureReading(120, 80, timestamp: sep13);
      controller.updateBloodSugar(95.0, timestamp: sep13);

      controller.updateHeartRate(72.0, timestamp: sep14);

      // Check Sep 13 again
      expect(controller.isHeartRateTrackedForDay(sep13), isTrue);
      expect(controller.getHeartRateForDay(sep13), equals(75.0));
      expect(controller.isBloodPressureTrackedForDay(sep13), isTrue);
      expect(controller.getBloodPressureForDay(sep13)?.systolic, equals(120));
      expect(controller.isBloodSugarTrackedForDay(sep13), isTrue);
      expect(controller.getBloodSugarForDay(sep13), equals(95.0));
    });

    test('TEST 4: Today vs Historical measurement separation is strictly maintained', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      controller.updateHeartRate(80.0, timestamp: yesterday);
      controller.addBloodPressureReading(130, 85, timestamp: yesterday);
      controller.updateBloodSugar(105.0, timestamp: yesterday);

      // Today should NOT be tracked automatically
      expect(controller.heartRate, equals(0.0));
      expect(controller.systolic, equals(0));
      expect(controller.diastolic, equals(0));
      expect(controller.bloodSugar, equals(0.0));

      // But historical getters still retain the readings
      expect(controller.latestHeartRate, equals(80.0));
      expect(controller.latestBloodPressure?.systolic, equals(130));
      expect(controller.latestBloodSugar, equals(105.0));
      expect(controller.heartRateHistory.length, equals(1));
      expect(controller.bloodPressureHistory.length, equals(1));
      expect(controller.bloodSugarHistory.length, equals(1));
    });

    test('TEST 5: Switching Weekly -> Monthly changes dataset and switching back restores weekly dataset', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12, 0);
      final twelveDaysAgo = today.subtract(const Duration(days: 12));

      // Reading within 7 days
      controller.updateHeartRate(70.0, timestamp: today);
      controller.addBloodPressureReading(120, 80, timestamp: today);
      controller.updateBloodSugar(90.0, timestamp: today);

      // Reading 12 days ago (in 30-day monthly range, but NOT in 7-day weekly range)
      controller.updateHeartRate(85.0, timestamp: twelveDaysAgo);
      controller.addBloodPressureReading(135, 88, timestamp: twelveDaysAgo);
      controller.updateBloodSugar(115.0, timestamp: twelveDaysAgo);

      // Weekly queries
      final weeklyHR = controller.getLastWeekHeartRateReadings(today);
      final weeklyBP = controller.getLastWeekBPReadings(today);
      final weeklyBS = controller.getLastWeekReadings(today);

      expect(weeklyHR.length, equals(1));
      expect(weeklyHR.first.bpm, equals(70.0));
      expect(weeklyBP.length, equals(1));
      expect(weeklyBP.first.systolic, equals(120));
      expect(weeklyBS.length, equals(1));
      expect(weeklyBS.first.value, equals(90.0));

      // Monthly queries
      final monthlyHR = controller.getLastMonthHeartRateReadings(today);
      final monthlyBP = controller.getLastMonthBPReadings(today);
      final monthlyBS = controller.getLastMonthReadings(today);

      expect(monthlyHR.length, equals(2));
      expect(monthlyBP.length, equals(2));
      expect(monthlyBS.length, equals(2));

      // Datasets are distinctly different
      expect(monthlyHR.length > weeklyHR.length, isTrue);
      expect(monthlyBP.length > weeklyBP.length, isTrue);
      expect(monthlyBS.length > weeklyBS.length, isTrue);

      // Switching back to weekly returns exactly 1 item
      expect(controller.getLastWeekHeartRateReadings(today).length, equals(1));
    });

    test('TEST 6: Multi-date series (Sep 10-15) accurately filters Weekly vs Monthly ranges', () {
      final refDate = DateTime(2026, 9, 15, 12, 0);

      // Add readings for 6 dates in Sep
      final dates = [
        DateTime(2026, 9, 10, 8, 0),
        DateTime(2026, 9, 11, 8, 0),
        DateTime(2026, 9, 12, 8, 0),
        DateTime(2026, 9, 13, 8, 0),
        DateTime(2026, 9, 14, 8, 0),
        DateTime(2026, 9, 15, 8, 0),
      ];

      for (int i = 0; i < dates.length; i++) {
        final d = dates[i];
        controller.updateHeartRate(70.0 + i, timestamp: d);
        controller.addBloodPressureReading(120 + i, 80 + i, timestamp: d);
        controller.updateBloodSugar(90.0 + i, timestamp: d);
      }

      // Also add an older reading from 20 days prior (Aug 26)
      final oldDate = DateTime(2026, 8, 26, 8, 0);
      controller.updateHeartRate(65.0, timestamp: oldDate);
      controller.addBloodPressureReading(115, 75, timestamp: oldDate);
      controller.updateBloodSugar(85.0, timestamp: oldDate);

      // Weekly for Sep 15 (7 days: Sep 9 to Sep 15)
      final weeklyHR = controller.getLastWeekHeartRateReadings(refDate);
      expect(weeklyHR.length, equals(6)); // All 6 Sep readings are within Sep 9-15
      expect(weeklyHR.any((r) => r.bpm == 65.0), isFalse); // Old reading excluded

      // Monthly for Sep 15 (30 days: Aug 17 to Sep 15)
      final monthlyHR = controller.getLastMonthHeartRateReadings(refDate);
      expect(monthlyHR.length, equals(7)); // All 6 Sep readings + Aug 26 reading included
      expect(monthlyHR.any((r) => r.bpm == 65.0), isTrue);
    });

    test('TEST 7: Changing selected date checks tracking status without modifying historical entries', () {
      final day1 = DateTime(2026, 9, 1, 9, 0);
      final day2 = DateTime(2026, 9, 2, 9, 0);
      final day3 = DateTime(2026, 9, 3, 9, 0);

      controller.updateHeartRate(68.0, timestamp: day1);
      controller.updateHeartRate(74.0, timestamp: day3);

      expect(controller.isHeartRateTrackedForDay(day1), isTrue);
      expect(controller.getHeartRateForDay(day1), equals(68.0));

      expect(controller.isHeartRateTrackedForDay(day2), isFalse);
      expect(controller.getHeartRateForDay(day2), equals(0.0));

      expect(controller.isHeartRateTrackedForDay(day3), isTrue);
      expect(controller.getHeartRateForDay(day3), equals(74.0));

      // Total history is intact and unchanged
      expect(controller.heartRateHistory.length, equals(2));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/controllers/health_data_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Weekly / Monthly Graph Date Filtering Tests', () {
    late HealthDataController controller;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10, 30);

    setUp(() {
      controller = HealthDataController();
      controller.userId = 'test_user_123';
      controller.bloodSugarHistory.clear();
      controller.bloodPressureHistory.clear();
      controller.heartRateHistory.clear();
    });

    test('TEST 1 & TEST 8: Blood Sugar Weekly filter returns only readings in weekly range', () {
      final weeklyStart = HealthDataController.getWeeklyStartDate();
      final readingInside = BloodSugarReading(id: '1', date: today, value: 95.0);
      final readingOld = BloodSugarReading(
        id: '2',
        date: weeklyStart.subtract(const Duration(days: 2)),
        value: 110.0,
      );

      controller.bloodSugarHistory.addAll([readingInside, readingOld]);

      final weekly = controller.getLastWeekReadings();
      expect(weekly.length, 1);
      expect(weekly.first.id, '1');
      expect(weekly.first.value, 95.0);
    });

    test('TEST 2 & TEST 8: Blood Sugar Monthly filter returns readings in monthly range', () {
      final weeklyStart = HealthDataController.getWeeklyStartDate();
      // Reading that is in the current month (e.g., 10 days ago or start of month) but older than 7 days
      final monthlyStart = HealthDataController.getMonthlyStartDate();
      final readingWithinWeek = BloodSugarReading(id: '1', date: today, value: 95.0);
      final readingMonthOnly = BloodSugarReading(
        id: '2',
        date: monthlyStart.isBefore(weeklyStart)
            ? monthlyStart.add(const Duration(hours: 1))
            : weeklyStart.subtract(const Duration(days: 1)),
        value: 105.0,
      );

      controller.bloodSugarHistory.addAll([readingWithinWeek, readingMonthOnly]);

      final monthly = controller.getLastMonthReadings();
      // If readingMonthOnly is in current month range, it should be in monthly
      if (!readingMonthOnly.date.isBefore(HealthDataController.getMonthlyStartDate())) {
        expect(monthly.length, 2);
      } else {
        expect(monthly.length, 1);
      }
    });

    test('TEST 3: Weekly and Monthly produce different datasets when readings exist outside weekly range', () {
      // 1 reading today, 1 reading 10 days ago (if in same month) or start of current month
      final monthStart = HealthDataController.getMonthlyStartDate();
      final reading1 = BloodPressureReading(
        id: 'bp1',
        systolic: 120,
        diastolic: 80,
        timestamp: today,
      );
      final reading2 = BloodPressureReading(
        id: 'bp2',
        systolic: 130,
        diastolic: 85,
        timestamp: monthStart.add(const Duration(hours: 2)),
      );

      controller.bloodPressureHistory.addAll([reading1, reading2]);

      final weeklyBP = controller.getLastWeekBPReadings();
      final monthlyBP = controller.getLastMonthBPReadings();

      if (reading2.timestamp.isBefore(HealthDataController.getWeeklyStartDate())) {
        expect(weeklyBP.length, 1);
        expect(monthlyBP.length, 2);
        expect(weeklyBP.length != monthlyBP.length, isTrue);
      }
    });

    test('TEST 4: Readings outside selected periods are excluded', () {
      final veryOld = DateTime(2020, 1, 1);
      final readingOld = HeartRateReading(id: 'hr_old', bpm: 72, timestamp: veryOld);
      controller.heartRateHistory.add(readingOld);

      expect(controller.getLastWeekHeartRateReadings(), isEmpty);
      expect(controller.getLastMonthHeartRateReadings(), isEmpty);
    });

    test('TEST 5: Reading exactly at the start boundary is included', () {
      final weeklyStart = HealthDataController.getWeeklyStartDate();
      final bpAtStart = BloodPressureReading(
        id: 'bp_start',
        systolic: 118,
        diastolic: 78,
        timestamp: weeklyStart,
      );
      controller.bloodPressureHistory.add(bpAtStart);

      final weekly = controller.getLastWeekBPReadings();
      expect(weekly.length, 1);
      expect(weekly.first.id, 'bp_start');
    });

    test('TEST 6: Reading at or after exclusive end boundary is excluded', () {
      final weeklyEnd = HealthDataController.getWeeklyEndDate();
      final bpAtEnd = BloodPressureReading(
        id: 'bp_end',
        systolic: 125,
        diastolic: 82,
        timestamp: weeklyEnd,
      );
      controller.bloodPressureHistory.add(bpAtEnd);

      final weekly = controller.getLastWeekBPReadings();
      expect(weekly, isEmpty);
    });

    test('TEST 7: Switching Weekly -> Monthly -> Weekly produces consistent datasets', () {
      final now = DateTime.now();
      final todayHr = HeartRateReading(id: 'hr_today', bpm: 70, timestamp: now);
      final monthHr = HeartRateReading(
        id: 'hr_month',
        bpm: 80,
        timestamp: DateTime(now.year, now.month, 1, 12, 0),
      );

      controller.heartRateHistory.addAll([todayHr, monthHr]);

      final weekly1 = controller.getLastWeekHeartRateReadings();
      final monthly = controller.getLastMonthHeartRateReadings();
      final weekly2 = controller.getLastWeekHeartRateReadings();

      expect(weekly1.length, weekly2.length);
      expect(weekly1.first.id, weekly2.first.id);
      expect(monthly.length, greaterThanOrEqualTo(weekly1.length));
    });

    test('TEST 9: Blood Pressure Weekly and Monthly filtering work accurately', () {
      final now = DateTime.now();
      final bpToday = BloodPressureReading(id: '1', systolic: 120, diastolic: 80, timestamp: now);
      final bpMonth = BloodPressureReading(
        id: '2',
        systolic: 135,
        diastolic: 88,
        timestamp: DateTime(now.year, now.month, 1, 9, 0),
      );

      controller.bloodPressureHistory.addAll([bpToday, bpMonth]);

      final weekly = controller.getLastWeekBPReadings();
      final monthly = controller.getLastMonthBPReadings();

      expect(weekly.any((r) => r.id == '1'), isTrue);
      expect(monthly.any((r) => r.id == '1'), isTrue);
      expect(monthly.any((r) => r.id == '2'), isTrue);
    });

    test('TEST 10: Heart Rate Weekly and Monthly filtering work accurately', () {
      final now = DateTime.now();
      final hrToday = HeartRateReading(id: '1', bpm: 68, timestamp: now);
      final hrMonth = HeartRateReading(
        id: '2',
        bpm: 78,
        timestamp: DateTime(now.year, now.month, 1, 8, 0),
      );

      controller.heartRateHistory.addAll([hrToday, hrMonth]);

      final weekly = controller.getLastWeekHeartRateReadings();
      final monthly = controller.getLastMonthHeartRateReadings();

      expect(weekly.any((r) => r.id == '1'), isTrue);
      expect(monthly.any((r) => r.id == '1'), isTrue);
      expect(monthly.any((r) => r.id == '2'), isTrue);
    });

    test('TEST 11: Empty data produces empty lists without errors', () {
      expect(controller.getLastWeekReadings(), isEmpty);
      expect(controller.getLastMonthReadings(), isEmpty);
      expect(controller.getLastWeekBPReadings(), isEmpty);
      expect(controller.getLastMonthBPReadings(), isEmpty);
      expect(controller.getLastWeekHeartRateReadings(), isEmpty);
      expect(controller.getLastMonthHeartRateReadings(), isEmpty);
    });

    test('TEST 12: Changing one metric history does not affect another', () {
      controller.bloodSugarHistory.add(BloodSugarReading(id: 'bs1', date: today, value: 100));
      expect(controller.getLastWeekReadings().length, 1);
      expect(controller.getLastWeekBPReadings(), isEmpty);
      expect(controller.getLastWeekHeartRateReadings(), isEmpty);
    });

    test('TEST 14: Dynamic date calculations without hardcoding', () {
      final mockDate = DateTime(2027, 4, 15, 14, 20);
      final weekStart = HealthDataController.getWeeklyStartDate(mockDate);
      final weekEnd = HealthDataController.getWeeklyEndDate(mockDate);
      final monthStart = HealthDataController.getMonthlyStartDate(mockDate);
      final monthEnd = HealthDataController.getMonthlyEndDate(mockDate);

      expect(weekStart, DateTime(2027, 4, 9, 0, 0));
      expect(weekEnd, DateTime(2027, 4, 16, 0, 0));
      expect(monthStart, DateTime(2027, 3, 17, 0, 0));
      expect(monthEnd, DateTime(2027, 4, 16, 0, 0));
    });

    test('MANDATORY TEST MATRIX: Blood Sugar (Sep 1, 5, 10, 13, 16, 18 with ref date Sep 18)', () {
      final refDate = DateTime(2026, 9, 18, 15, 0);

      final rSep1 = BloodSugarReading(id: 'bs_sep1', date: DateTime(2026, 9, 1, 10, 0), value: 90.0);
      final rSep5 = BloodSugarReading(id: 'bs_sep5', date: DateTime(2026, 9, 5, 10, 0), value: 95.0);
      final rSep10 = BloodSugarReading(id: 'bs_sep10', date: DateTime(2026, 9, 10, 10, 0), value: 110.0);
      final rSep13 = BloodSugarReading(id: 'bs_sep13', date: DateTime(2026, 9, 13, 10, 0), value: 150.0);
      final rSep16 = BloodSugarReading(id: 'bs_sep16', date: DateTime(2026, 9, 16, 10, 0), value: 60.0);
      final rSep18 = BloodSugarReading(id: 'bs_sep18', date: DateTime(2026, 9, 18, 10, 0), value: 79.0);

      controller.bloodSugarHistory.addAll([rSep1, rSep5, rSep10, rSep13, rSep16, rSep18]);

      final weekly = controller.getLastWeekReadings(refDate);
      final monthly = controller.getLastMonthReadings(refDate);

      // Weekly: Sep 12 00:00 to Sep 19 00:00 -> includes Sep 13, 16, 18 (3 records)
      expect(weekly.length, 3);
      expect(weekly.map((r) => r.id).toList(), ['bs_sep13', 'bs_sep16', 'bs_sep18']);
      expect(weekly.map((r) => r.value).toList(), [150.0, 60.0, 79.0]);

      // Monthly: Aug 20 00:00 to Sep 19 00:00 -> includes all 6 records
      expect(monthly.length, 6);
      expect(monthly.map((r) => r.id).toList(), ['bs_sep1', 'bs_sep5', 'bs_sep10', 'bs_sep13', 'bs_sep16', 'bs_sep18']);
      expect(monthly.map((r) => r.value).toList(), [90.0, 95.0, 110.0, 150.0, 60.0, 79.0]);
    });

    test('MANDATORY TEST MATRIX: Blood Pressure (Sep 1, 5, 10, 13, 16, 18 with ref date Sep 18)', () {
      final refDate = DateTime(2026, 9, 18, 15, 0);

      final rSep1 = BloodPressureReading(id: 'bp_sep1', timestamp: DateTime(2026, 9, 1, 10, 0), systolic: 118, diastolic: 78);
      final rSep5 = BloodPressureReading(id: 'bp_sep5', timestamp: DateTime(2026, 9, 5, 10, 0), systolic: 122, diastolic: 80);
      final rSep10 = BloodPressureReading(id: 'bp_sep10', timestamp: DateTime(2026, 9, 10, 10, 0), systolic: 125, diastolic: 82);
      final rSep13 = BloodPressureReading(id: 'bp_sep13', timestamp: DateTime(2026, 9, 13, 10, 0), systolic: 140, diastolic: 80);
      final rSep16 = BloodPressureReading(id: 'bp_sep16', timestamp: DateTime(2026, 9, 16, 10, 0), systolic: 150, diastolic: 80);
      final rSep18 = BloodPressureReading(id: 'bp_sep18', timestamp: DateTime(2026, 9, 18, 10, 0), systolic: 130, diastolic: 85);

      controller.bloodPressureHistory.addAll([rSep1, rSep5, rSep10, rSep13, rSep16, rSep18]);

      final weekly = controller.getLastWeekBPReadings(refDate);
      final monthly = controller.getLastMonthBPReadings(refDate);

      // Weekly: Sep 13, 16, 18 (3 records)
      expect(weekly.length, 3);
      expect(weekly.map((r) => r.id).toList(), ['bp_sep13', 'bp_sep16', 'bp_sep18']);

      // Monthly: all 6 records
      expect(monthly.length, 6);
      expect(monthly.map((r) => r.id).toList(), ['bp_sep1', 'bp_sep5', 'bp_sep10', 'bp_sep13', 'bp_sep16', 'bp_sep18']);
    });

    test('MANDATORY TEST MATRIX: Heart Rate (Sep 1, 5, 10, 13, 16, 18 with ref date Sep 18)', () {
      final refDate = DateTime(2026, 9, 18, 15, 0);

      final rSep1 = HeartRateReading(id: 'hr_sep1', timestamp: DateTime(2026, 9, 1, 10, 0), bpm: 65.0);
      final rSep5 = HeartRateReading(id: 'hr_sep5', timestamp: DateTime(2026, 9, 5, 10, 0), bpm: 70.0);
      final rSep10 = HeartRateReading(id: 'hr_sep10', timestamp: DateTime(2026, 9, 10, 10, 0), bpm: 72.0);
      final rSep13 = HeartRateReading(id: 'hr_sep13', timestamp: DateTime(2026, 9, 13, 10, 0), bpm: 85.0);
      final rSep16 = HeartRateReading(id: 'hr_sep16', timestamp: DateTime(2026, 9, 16, 10, 0), bpm: 90.0);
      final rSep18 = HeartRateReading(id: 'hr_sep18', timestamp: DateTime(2026, 9, 18, 10, 0), bpm: 69.0);

      controller.heartRateHistory.addAll([rSep1, rSep5, rSep10, rSep13, rSep16, rSep18]);

      final weekly = controller.getLastWeekHeartRateReadings(refDate);
      final monthly = controller.getLastMonthHeartRateReadings(refDate);

      // Weekly: Sep 13, 16, 18 (3 records)
      expect(weekly.length, 3);
      expect(weekly.map((r) => r.id).toList(), ['hr_sep13', 'hr_sep16', 'hr_sep18']);

      // Monthly: all 6 records
      expect(monthly.length, 6);
      expect(monthly.map((r) => r.id).toList(), ['hr_sep1', 'hr_sep5', 'hr_sep10', 'hr_sep13', 'hr_sep16', 'hr_sep18']);
    });
  });
}

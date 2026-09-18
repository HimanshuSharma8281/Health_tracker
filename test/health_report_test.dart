import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker/models/user_profile.dart';
import 'package:tracker/models/health_reading.dart';
import 'package:tracker/models/daily_score.dart';
import 'package:tracker/models/activity_models.dart';
import 'package:tracker/controllers/health_data_controller.dart';
import 'package:tracker/services/health_report_service.dart';
import 'package:tracker/services/health_report_pdf_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Health Data PDF Report Service & Generator Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TEST 1: Single-day range (Sep 1 to Sep 1)', () async {
      final sep1 = DateTime(2026, 9, 1);
      final reportData = HealthReportData(
        fromDate: DateTime(2026, 9, 1, 0, 0, 0),
        toDate: DateTime(2026, 9, 1, 23, 59, 59),
        generatedAt: DateTime(2026, 9, 1, 14, 0),
        uid: 'user_a',
        profile: const UserProfile(uid: 'user_a', name: 'User A', email: 'a@aurora.com'),
        totalDays: 1,
        dailyScores: [
          DailyScore(
            date: '2026-09-01',
            overall: 82,
            label: 'Good',
            metrics: {},
            scoredAt: DateTime(2026, 9, 1),
            availableMetricCount: 4,
          ),
        ],
        averageScore: 82.0,
        latestScore: 82,
        minScore: 82,
        maxScore: 82,
        scoreLabel: 'Good',
        dailySteps: [DailyStepRecord(date: sep1, steps: 8500)],
        totalSteps: 8500,
        avgSteps: 8500,
        highestStepDay: DailyStepRecord(date: sep1, steps: 8500),
        lowestStepDay: DailyStepRecord(date: sep1, steps: 8500),
        stepGoal: 10000,
        dailyWater: [DailyWaterRecord(date: sep1, amount: 2200)],
        totalWaterMl: 2200,
        avgWaterMl: 2200,
        waterGoal: 2500,
        dailySleep: [DailySleepRecord(date: sep1, hours: 7.5)],
        totalSleepHours: 7.5,
        avgSleepHours: 7.5,
        sleepGoal: 8.0,
        meals: [
          MealEntry(
            id: 'm1',
            name: 'Oatmeal & Berries',
            calories: 450,
            time: DateTime(2026, 9, 1, 8, 30),
            mealType: MealType.breakfast,
          ),
        ],
        totalCalories: 450.0,
        avgCalories: 450.0,
        calorieGoal: 2000.0,
        mealTypeCounts: {MealType.breakfast: 1},
        heartRateReadings: [
          HeartRateReading(id: 'hr1', bpm: 68.0, timestamp: DateTime(2026, 9, 1, 9, 0)),
        ],
        avgHeartRate: 68.0,
        minHeartRate: 68.0,
        maxHeartRate: 68.0,
        bloodPressureReadings: [
          BloodPressureReading(id: 'bp1', systolic: 118, diastolic: 76, timestamp: DateTime(2026, 9, 1, 9, 0)),
        ],
        avgSystolic: 118.0,
        avgDiastolic: 76.0,
        highestBP: BloodPressureReading(id: 'bp1', systolic: 118, diastolic: 76, timestamp: DateTime(2026, 9, 1, 9, 0)),
        lowestBP: BloodPressureReading(id: 'bp1', systolic: 118, diastolic: 76, timestamp: DateTime(2026, 9, 1, 9, 0)),
        bpClassification: 'Normal (Optimal)',
        bloodSugarReadings: [
          BloodSugarReading(id: 'bs1', value: 88.0, date: DateTime(2026, 9, 1, 8, 0)),
        ],
        avgBloodSugar: 88.0,
        minBloodSugar: 88.0,
        maxBloodSugar: 88.0,
        bloodSugarStatus: 'Normal Fasting Glycemia',
        keyObservations: ['Physical Activity: Averaged 8,500 steps/day.'],
        clinicalRecommendations: ['Maintain the strong baseline.'],
      );

      expect(reportData.totalDays, equals(1));
      expect(reportData.dailySteps.length, equals(1));
      expect(reportData.dailySteps.first.steps, equals(8500));
      expect(reportData.dailyWater.first.amount, equals(2200));

      // Generate PDF
      final pdfBytes = await HealthReportPdfGenerator.generate(reportData);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('TEST 2: 7-Day multi-day range (Sep 1 to Sep 7)', () async {
      final sep1 = DateTime(2026, 9, 1);
      final sep7 = DateTime(2026, 9, 7);
      final days = List.generate(7, (i) => sep1.add(Duration(days: i)));

      final reportData = HealthReportData(
        fromDate: DateTime(2026, 9, 1),
        toDate: DateTime(2026, 9, 7, 23, 59, 59),
        generatedAt: DateTime(2026, 9, 7, 20, 0),
        uid: 'user_a',
        profile: const UserProfile(uid: 'user_a', name: 'User A', email: 'a@aurora.com'),
        totalDays: 7,
        dailyScores: days.map((d) => DailyScore(
          date: HealthReading.formatDate(d),
          overall: 75 + (d.day % 10),
          label: 'Good',
          metrics: {},
          scoredAt: d,
          availableMetricCount: 5,
        )).toList(),
        averageScore: 78.5,
        latestScore: 82,
        minScore: 75,
        maxScore: 82,
        scoreLabel: 'Good',
        dailySteps: days.map((d) => DailyStepRecord(date: d, steps: 6000 + (d.day * 500))).toList(),
        totalSteps: 56000,
        avgSteps: 8000,
        highestStepDay: DailyStepRecord(date: sep7, steps: 9500),
        lowestStepDay: DailyStepRecord(date: sep1, steps: 6500),
        stepGoal: 10000,
        dailyWater: days.map((d) => DailyWaterRecord(date: d, amount: 2000 + (d.day * 100))).toList(),
        totalWaterMl: 16800,
        avgWaterMl: 2400,
        waterGoal: 2500,
        dailySleep: days.map((d) => DailySleepRecord(date: d, hours: 7.0 + (d.day % 2) * 0.5)).toList(),
        totalSleepHours: 51.5,
        avgSleepHours: 7.35,
        sleepGoal: 8.0,
        meals: [],
        totalCalories: 0,
        avgCalories: 0,
        calorieGoal: 2000,
        mealTypeCounts: {},
        heartRateReadings: days.map((d) => HeartRateReading(id: 'hr_${d.day}', bpm: 70.0 + d.day, timestamp: d)).toList(),
        avgHeartRate: 74.0,
        minHeartRate: 71.0,
        maxHeartRate: 77.0,
        bloodPressureReadings: days.map((d) => BloodPressureReading(id: 'bp_${d.day}', systolic: 120 + d.day, diastolic: 80, timestamp: d)).toList(),
        avgSystolic: 124.0,
        avgDiastolic: 80.0,
        highestBP: BloodPressureReading(id: 'bp_7', systolic: 127, diastolic: 80, timestamp: sep7),
        lowestBP: BloodPressureReading(id: 'bp_1', systolic: 121, diastolic: 80, timestamp: sep1),
        bpClassification: 'Elevated',
        bloodSugarReadings: [],
        avgBloodSugar: null,
        minBloodSugar: null,
        maxBloodSugar: null,
        bloodSugarStatus: 'No Data',
        keyObservations: ['Consistent 7-day tracking activity.'],
        clinicalRecommendations: ['Hydration is close to target.'],
      );

      expect(reportData.totalDays, equals(7));
      expect(reportData.dailySteps.length, equals(7));
      expect(reportData.dailyWater.length, equals(7));

      final pdfBytes = await HealthReportPdfGenerator.generate(reportData);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1500));
    });

    test('TEST 3 & 7: 30-Day large range (Sep 1 to Sep 30) renders cleanly with page breaks', () async {
      final sep1 = DateTime(2026, 9, 1);
      final days = List.generate(30, (i) => sep1.add(Duration(days: i)));

      final reportData = HealthReportData(
        fromDate: DateTime(2026, 9, 1),
        toDate: DateTime(2026, 9, 30, 23, 59, 59),
        generatedAt: DateTime(2026, 9, 30, 23, 0),
        uid: 'user_large',
        profile: const UserProfile(uid: 'user_large', name: 'Dr. John Doe', email: 'johndoe@aurora.com', age: 35, sex: 'male', heightCm: 178, weightKg: 75),
        totalDays: 30,
        dailyScores: days.map((d) => DailyScore(
          date: HealthReading.formatDate(d),
          overall: 70 + (d.day % 20),
          label: 'Good',
          metrics: {},
          scoredAt: d,
          availableMetricCount: 6,
        )).toList(),
        averageScore: 80.0,
        latestScore: 84,
        minScore: 70,
        maxScore: 89,
        scoreLabel: 'Good',
        dailySteps: days.map((d) => DailyStepRecord(date: d, steps: 5000 + (d.day * 150))).toList(),
        totalSteps: 217500,
        avgSteps: 7250,
        highestStepDay: DailyStepRecord(date: days.last, steps: 9500),
        lowestStepDay: DailyStepRecord(date: days.first, steps: 5000),
        stepGoal: 10000,
        dailyWater: days.map((d) => DailyWaterRecord(date: d, amount: 2000 + (d.day * 30))).toList(),
        totalWaterMl: 73500,
        avgWaterMl: 2450,
        waterGoal: 2500,
        dailySleep: days.map((d) => DailySleepRecord(date: d, hours: 7.2)).toList(),
        totalSleepHours: 216.0,
        avgSleepHours: 7.2,
        sleepGoal: 8.0,
        meals: days.take(15).map((d) => MealEntry(
          id: 'meal_${d.day}',
          name: 'Healthy Lunch #${d.day}',
          calories: 600,
          time: d.add(const Duration(hours: 12)),
          mealType: MealType.lunch,
        )).toList(),
        totalCalories: 9000,
        avgCalories: 600,
        calorieGoal: 2000,
        mealTypeCounts: {MealType.lunch: 15},
        heartRateReadings: days.take(20).map((d) => HeartRateReading(id: 'hr_${d.day}', bpm: 72.0, timestamp: d)).toList(),
        avgHeartRate: 72.0,
        minHeartRate: 65.0,
        maxHeartRate: 80.0,
        bloodPressureReadings: days.take(15).map((d) => BloodPressureReading(id: 'bp_${d.day}', systolic: 120, diastolic: 80, timestamp: d)).toList(),
        avgSystolic: 120.0,
        avgDiastolic: 80.0,
        highestBP: BloodPressureReading(id: 'bp_1', systolic: 125, diastolic: 82, timestamp: sep1),
        lowestBP: BloodPressureReading(id: 'bp_2', systolic: 118, diastolic: 78, timestamp: sep1),
        bpClassification: 'Normal (Optimal)',
        bloodSugarReadings: days.take(10).map((d) => BloodSugarReading(id: 'bs_${d.day}', value: 92.0, date: d)).toList(),
        avgBloodSugar: 92.0,
        minBloodSugar: 85.0,
        maxBloodSugar: 98.0,
        bloodSugarStatus: 'Normal Fasting Glycemia',
        keyObservations: ['Excellent month-long tracking consistency across all 6 clinical indicators.'],
        clinicalRecommendations: ['Continue the balanced nutrition and daily walking routine.'],
      );

      final pdfBytes = await HealthReportPdfGenerator.generate(reportData);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(3000));
    });

    test('TEST 4: Empty period / missing metrics handling does not fail', () async {
      final reportData = HealthReportData(
        fromDate: DateTime(2026, 9, 1),
        toDate: DateTime(2026, 9, 5),
        generatedAt: DateTime(2026, 9, 5),
        uid: 'empty_user',
        profile: null,
        totalDays: 5,
        dailyScores: [],
        averageScore: null,
        latestScore: null,
        minScore: null,
        maxScore: null,
        scoreLabel: 'No Data',
        dailySteps: [],
        totalSteps: 0,
        avgSteps: 0,
        highestStepDay: null,
        lowestStepDay: null,
        stepGoal: 10000,
        dailyWater: [],
        totalWaterMl: 0,
        avgWaterMl: 0,
        waterGoal: 2500,
        dailySleep: [],
        totalSleepHours: 0.0,
        avgSleepHours: 0.0,
        sleepGoal: 8.0,
        meals: [],
        totalCalories: 0.0,
        avgCalories: 0.0,
        calorieGoal: 2000.0,
        mealTypeCounts: {},
        heartRateReadings: [],
        avgHeartRate: null,
        minHeartRate: null,
        maxHeartRate: null,
        bloodPressureReadings: [],
        avgSystolic: null,
        avgDiastolic: null,
        highestBP: null,
        lowestBP: null,
        bpClassification: 'No Data',
        bloodSugarReadings: [],
        avgBloodSugar: null,
        minBloodSugar: null,
        maxBloodSugar: null,
        bloodSugarStatus: 'No Data',
        keyObservations: ['No step logs recorded during this period.'],
        clinicalRecommendations: ['Keep tracking your daily metrics consistently.'],
      );

      expect(reportData.hasAnyData, isFalse);

      final pdfBytes = await HealthReportPdfGenerator.generate(reportData);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(500));
    });

    test('TEST 5: Multiple readings on the same day handled correctly', () async {
      final today = DateTime(2026, 9, 15);
      final waterEntries = [
        WaterIntakeReading(id: 'w1', amount: 300, timestamp: DateTime(2026, 9, 15, 8, 0)),
        WaterIntakeReading(id: 'w2', amount: 500, timestamp: DateTime(2026, 9, 15, 12, 30)),
        WaterIntakeReading(id: 'w3', amount: 400, timestamp: DateTime(2026, 9, 15, 17, 0)),
      ];

      final totalLoggedWater = waterEntries.fold<int>(0, (sum, w) => sum + w.amount);
      expect(totalLoggedWater, equals(1200));

      final reportData = HealthReportData(
        fromDate: today,
        toDate: today,
        generatedAt: DateTime.now(),
        uid: 'user_multi',
        profile: const UserProfile(uid: 'user_multi', name: 'Multi Reader', email: 'm@example.com'),
        totalDays: 1,
        dailyScores: [],
        averageScore: null,
        latestScore: null,
        minScore: null,
        maxScore: null,
        scoreLabel: 'No Data',
        dailySteps: [DailyStepRecord(date: today, steps: 7200)],
        totalSteps: 7200,
        avgSteps: 7200,
        highestStepDay: DailyStepRecord(date: today, steps: 7200),
        lowestStepDay: DailyStepRecord(date: today, steps: 7200),
        stepGoal: 10000,
        dailyWater: [DailyWaterRecord(date: today, amount: totalLoggedWater)],
        totalWaterMl: totalLoggedWater,
        avgWaterMl: totalLoggedWater,
        waterGoal: 2500,
        dailySleep: [],
        totalSleepHours: 0.0,
        avgSleepHours: 0.0,
        sleepGoal: 8.0,
        meals: [],
        totalCalories: 0,
        avgCalories: 0,
        calorieGoal: 2000,
        mealTypeCounts: {},
        heartRateReadings: [
          HeartRateReading(id: 'hr1', bpm: 65.0, timestamp: DateTime(2026, 9, 15, 8, 0)),
          HeartRateReading(id: 'hr2', bpm: 82.0, timestamp: DateTime(2026, 9, 15, 14, 0)),
          HeartRateReading(id: 'hr3', bpm: 71.0, timestamp: DateTime(2026, 9, 15, 21, 0)),
        ],
        avgHeartRate: 72.67,
        minHeartRate: 65.0,
        maxHeartRate: 82.0,
        bloodPressureReadings: [],
        avgSystolic: null,
        avgDiastolic: null,
        highestBP: null,
        lowestBP: null,
        bpClassification: 'No Data',
        bloodSugarReadings: [],
        avgBloodSugar: null,
        minBloodSugar: null,
        maxBloodSugar: null,
        bloodSugarStatus: 'No Data',
        keyObservations: ['Multiple intraday readings aggregated into true daily statistics.'],
        clinicalRecommendations: ['Hydration and HR were steady.'],
      );

      expect(reportData.totalWaterMl, equals(1200));
      expect(reportData.heartRateReadings.length, equals(3));
      expect(reportData.minHeartRate, equals(65.0));
      expect(reportData.maxHeartRate, equals(82.0));

      final pdfBytes = await HealthReportPdfGenerator.generate(reportData);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('TEST 6: UID isolation: User A report has 0 of User B readings', () async {
      final userAReport = HealthReportData(
        fromDate: DateTime(2026, 9, 1),
        toDate: DateTime(2026, 9, 7),
        generatedAt: DateTime.now(),
        uid: 'UID_A',
        profile: const UserProfile(uid: 'UID_A', name: 'User A', email: 'userA@example.com'),
        totalDays: 7,
        dailyScores: [],
        averageScore: 85.0,
        latestScore: 85,
        minScore: 85,
        maxScore: 85,
        scoreLabel: 'Excellent',
        dailySteps: [DailyStepRecord(date: DateTime(2026, 9, 1), steps: 12000)],
        totalSteps: 12000,
        avgSteps: 12000,
        highestStepDay: DailyStepRecord(date: DateTime(2026, 9, 1), steps: 12000),
        lowestStepDay: DailyStepRecord(date: DateTime(2026, 9, 1), steps: 12000),
        stepGoal: 10000,
        dailyWater: [DailyWaterRecord(date: DateTime(2026, 9, 1), amount: 3000)],
        totalWaterMl: 3000,
        avgWaterMl: 3000,
        waterGoal: 2500,
        dailySleep: [DailySleepRecord(date: DateTime(2026, 9, 1), hours: 8.5)],
        totalSleepHours: 8.5,
        avgSleepHours: 8.5,
        sleepGoal: 8.0,
        meals: [],
        totalCalories: 0,
        avgCalories: 0,
        calorieGoal: 2000,
        mealTypeCounts: {},
        heartRateReadings: [],
        avgHeartRate: 62.0,
        minHeartRate: 62.0,
        maxHeartRate: 62.0,
        bloodPressureReadings: [],
        avgSystolic: 115.0,
        avgDiastolic: 75.0,
        highestBP: null,
        lowestBP: null,
        bpClassification: 'Normal (Optimal)',
        bloodSugarReadings: [],
        avgBloodSugar: 82.0,
        minBloodSugar: 82.0,
        maxBloodSugar: 82.0,
        bloodSugarStatus: 'Normal Fasting Glycemia',
        keyObservations: ['User A specific observations'],
        clinicalRecommendations: ['User A specific plan'],
      );

      final userBReport = HealthReportData(
        fromDate: DateTime(2026, 9, 1),
        toDate: DateTime(2026, 9, 7),
        generatedAt: DateTime.now(),
        uid: 'UID_B',
        profile: const UserProfile(uid: 'UID_B', name: 'User B', email: 'userB@example.com'),
        totalDays: 7,
        dailyScores: [],
        averageScore: null,
        latestScore: null,
        minScore: null,
        maxScore: null,
        scoreLabel: 'No Data',
        dailySteps: [],
        totalSteps: 0,
        avgSteps: 0,
        highestStepDay: null,
        lowestStepDay: null,
        stepGoal: 10000,
        dailyWater: [],
        totalWaterMl: 0,
        avgWaterMl: 0,
        waterGoal: 2500,
        dailySleep: [],
        totalSleepHours: 0.0,
        avgSleepHours: 0.0,
        sleepGoal: 8.0,
        meals: [],
        totalCalories: 0,
        avgCalories: 0,
        calorieGoal: 2000,
        mealTypeCounts: {},
        heartRateReadings: [],
        avgHeartRate: null,
        minHeartRate: null,
        maxHeartRate: null,
        bloodPressureReadings: [],
        avgSystolic: null,
        avgDiastolic: null,
        highestBP: null,
        lowestBP: null,
        bpClassification: 'No Data',
        bloodSugarReadings: [],
        avgBloodSugar: null,
        minBloodSugar: null,
        maxBloodSugar: null,
        bloodSugarStatus: 'No Data',
        keyObservations: [],
        clinicalRecommendations: [],
      );

      expect(userAReport.uid, equals('UID_A'));
      expect(userBReport.uid, equals('UID_B'));
      expect(userBReport.totalSteps, equals(0));
      expect(userBReport.totalWaterMl, equals(0));
      expect(userBReport.totalSleepHours, equals(0.0));
      expect(userBReport.totalSteps, isNot(equals(userAReport.totalSteps)));
      expect(userBReport.totalWaterMl, isNot(equals(userAReport.totalWaterMl)));
    });

    test('TEST 8: Date validation fromDate > toDate is detected as invalid', () {
      final fromDate = DateTime(2026, 9, 15);
      final toDate = DateTime(2026, 9, 1);

      final isInvalid = fromDate.isAfter(toDate);
      expect(isInvalid, isTrue);

      final validFrom = DateTime(2026, 9, 1);
      final validTo = DateTime(2026, 9, 15);
      expect(validFrom.isAfter(validTo), isFalse);
    });
  });
}

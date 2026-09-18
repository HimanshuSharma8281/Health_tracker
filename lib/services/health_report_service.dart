import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/health_reading.dart';
import '../models/daily_score.dart';
import '../models/activity_models.dart';
import '../controllers/health_data_controller.dart';
import 'firestore_service.dart';

/// Aggregated health report data model for a specified date range.
class HealthReportData {
  final DateTime fromDate;
  final DateTime toDate;
  final DateTime generatedAt;
  final String uid;
  final UserProfile? profile;
  final int totalDays;

  // Wellness Score
  final List<DailyScore> dailyScores;
  final double? averageScore;
  final int? latestScore;
  final int? minScore;
  final int? maxScore;
  final String scoreLabel;

  // Steps
  final List<DailyStepRecord> dailySteps;
  final int totalSteps;
  final int avgSteps;
  final DailyStepRecord? highestStepDay;
  final DailyStepRecord? lowestStepDay;
  final int stepGoal;

  // Water
  final List<DailyWaterRecord> dailyWater;
  final int totalWaterMl;
  final int avgWaterMl;
  final int waterGoal;

  // Sleep
  final List<DailySleepRecord> dailySleep;
  final double totalSleepHours;
  final double avgSleepHours;
  final double sleepGoal;

  // Calories & Meals
  final List<MealEntry> meals;
  final double totalCalories;
  final double avgCalories;
  final double calorieGoal;
  final Map<MealType, int> mealTypeCounts;

  // Heart Rate
  final List<HeartRateReading> heartRateReadings;
  final double? avgHeartRate;
  final double? minHeartRate;
  final double? maxHeartRate;

  // Blood Pressure
  final List<BloodPressureReading> bloodPressureReadings;
  final double? avgSystolic;
  final double? avgDiastolic;
  final BloodPressureReading? highestBP;
  final BloodPressureReading? lowestBP;
  final String bpClassification;

  // Blood Sugar
  final List<BloodSugarReading> bloodSugarReadings;
  final double? avgBloodSugar;
  final double? minBloodSugar;
  final double? maxBloodSugar;
  final String bloodSugarStatus;

  // Clinical Observations & Insights
  final List<String> keyObservations;
  final List<String> clinicalRecommendations;

  const HealthReportData({
    required this.fromDate,
    required this.toDate,
    required this.generatedAt,
    required this.uid,
    required this.profile,
    required this.totalDays,
    required this.dailyScores,
    required this.averageScore,
    required this.latestScore,
    required this.minScore,
    required this.maxScore,
    required this.scoreLabel,
    required this.dailySteps,
    required this.totalSteps,
    required this.avgSteps,
    required this.highestStepDay,
    required this.lowestStepDay,
    required this.stepGoal,
    required this.dailyWater,
    required this.totalWaterMl,
    required this.avgWaterMl,
    required this.waterGoal,
    required this.dailySleep,
    required this.totalSleepHours,
    required this.avgSleepHours,
    required this.sleepGoal,
    required this.meals,
    required this.totalCalories,
    required this.avgCalories,
    required this.calorieGoal,
    required this.mealTypeCounts,
    required this.heartRateReadings,
    required this.avgHeartRate,
    required this.minHeartRate,
    required this.maxHeartRate,
    required this.bloodPressureReadings,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.highestBP,
    required this.lowestBP,
    required this.bpClassification,
    required this.bloodSugarReadings,
    required this.avgBloodSugar,
    required this.minBloodSugar,
    required this.maxBloodSugar,
    required this.bloodSugarStatus,
    required this.keyObservations,
    required this.clinicalRecommendations,
  });

  bool get hasAnyData =>
      dailyScores.isNotEmpty ||
      dailySteps.isNotEmpty ||
      dailyWater.isNotEmpty ||
      dailySleep.isNotEmpty ||
      meals.isNotEmpty ||
      heartRateReadings.isNotEmpty ||
      bloodPressureReadings.isNotEmpty ||
      bloodSugarReadings.isNotEmpty;
}

class HealthReportService {
  HealthReportService._();
  static final HealthReportService instance = HealthReportService._();

  /// Compiles all health data for [uid] strictly within [fromDate] and [toDate] (inclusive).
  Future<HealthReportData> compileReportData({
    required String uid,
    required DateTime fromDate,
    required DateTime toDate,
    UserProfile? profile,
  }) async {
    final startOfDay = DateTime(fromDate.year, fromDate.month, fromDate.day, 0, 0, 0);
    final endOfDay = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
    final totalDays = max(1, endOfDay.difference(startOfDay).inDays + 1);
    final now = DateTime.now();

    // 1. Fetch user profile if not supplied
    final effectiveProfile = profile ?? await FirestoreService.instance.loadProfile(uid);

    // 2. Fetch raw readings in range
    final readings = await FirestoreService.instance.getReadingsForDateRange(
      uid: uid,
      startDate: startOfDay,
      endDate: endOfDay,
    );

    // 3. Fetch daily scores in range
    final dailyScores = await FirestoreService.instance.getScoresForDateRange(
      uid: uid,
      startDate: startOfDay,
      endDate: endOfDay,
    );

    // ── Process Wellness Scores ──────────────────────────────────────────────
    double? avgScore;
    int? latestScore;
    int? minScore;
    int? maxScore;
    String scoreLabel = 'No Data';

    if (dailyScores.isNotEmpty) {
      final validScores = dailyScores.where((s) => s.availableMetricCount > 0).toList();
      if (validScores.isNotEmpty) {
        final totalScore = validScores.fold<int>(0, (sum, s) => sum + s.overall);
        avgScore = totalScore / validScores.length;
        latestScore = validScores.last.overall;
        minScore = validScores.map((s) => s.overall).reduce(min);
        maxScore = validScores.map((s) => s.overall).reduce(max);

        if (avgScore >= 85) {
          scoreLabel = 'Excellent';
        } else if (avgScore >= 70) {
          scoreLabel = 'Good';
        } else if (avgScore >= 55) {
          scoreLabel = 'Fair';
        } else if (avgScore >= 40) {
          scoreLabel = 'Needs Improvement';
        } else {
          scoreLabel = 'Needs Attention';
        }
      }
    }

    // ── Process Steps ────────────────────────────────────────────────────────
    final stepReadings = readings.where((r) => r.metric == HealthReading.steps).toList();
    final stepByDate = <String, int>{};
    for (final r in stepReadings) {
      stepByDate[r.date] = max(stepByDate[r.date] ?? 0, r.value.round());
    }
    final dailySteps = stepByDate.entries.map((e) {
      return DailyStepRecord(
        date: DateTime.tryParse(e.key) ?? startOfDay,
        steps: e.value,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final totalSteps = dailySteps.fold<int>(0, (sum, r) => sum + r.steps);
    final avgSteps = dailySteps.isNotEmpty ? (totalSteps / dailySteps.length).round() : 0;
    DailyStepRecord? highestStepDay;
    DailyStepRecord? lowestStepDay;
    if (dailySteps.isNotEmpty) {
      highestStepDay = dailySteps.reduce((a, b) => a.steps > b.steps ? a : b);
      lowestStepDay = dailySteps.reduce((a, b) => a.steps < b.steps ? a : b);
    }
    final stepGoal = effectiveProfile?.stepGoal ?? 10000;

    // ── Process Water ────────────────────────────────────────────────────────
    final waterReadings = readings.where((r) => r.metric == HealthReading.water).toList();
    final waterByDate = <String, int>{};
    for (final r in waterReadings) {
      waterByDate[r.date] = (waterByDate[r.date] ?? 0) + r.value.round();
    }
    final dailyWater = waterByDate.entries.map((e) {
      return DailyWaterRecord(
        date: DateTime.tryParse(e.key) ?? startOfDay,
        amount: e.value,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final totalWaterMl = dailyWater.fold<int>(0, (sum, r) => sum + r.amount);
    final avgWaterMl = dailyWater.isNotEmpty ? (totalWaterMl / dailyWater.length).round() : 0;
    final waterGoal = effectiveProfile?.waterGoalMl ?? 2500;

    // ── Process Sleep ────────────────────────────────────────────────────────
    final sleepReadings = readings.where((r) => r.metric == HealthReading.sleep).toList();
    final sleepByDate = <String, double>{};
    for (final r in sleepReadings) {
      sleepByDate[r.date] = (sleepByDate[r.date] ?? 0.0) + r.value;
    }
    final dailySleep = sleepByDate.entries.map((e) {
      return DailySleepRecord(
        date: DateTime.tryParse(e.key) ?? startOfDay,
        hours: e.value,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final totalSleepHours = dailySleep.fold<double>(0.0, (sum, r) => sum + r.hours);
    final avgSleepHours = dailySleep.isNotEmpty ? (totalSleepHours / dailySleep.length) : 0.0;
    final sleepGoal = effectiveProfile?.sleepGoalHours ?? 8.0;

    // ── Process Calories & Meals ─────────────────────────────────────────────
    final calReadings = readings.where((r) => r.metric == HealthReading.calories).toList();
    final meals = <MealEntry>[];
    final mealTypeCounts = <MealType, int>{
      MealType.breakfast: 0,
      MealType.lunch: 0,
      MealType.dinner: 0,
      MealType.snack: 0,
    };

    for (final r in calReadings) {
      final mealTypeStr = r.metadata['mealType'] as String?;
      final mealName = r.metadata['mealName'] as String? ?? 'Meal';
      final mealType = MealType.values.firstWhere(
        (m) => m.name == mealTypeStr,
        orElse: () => MealType.snack,
      );
      mealTypeCounts[mealType] = (mealTypeCounts[mealType] ?? 0) + 1;
      meals.add(MealEntry(
        id: r.id,
        name: mealName,
        calories: r.value.round(),
        time: r.timestamp,
        mealType: mealType,
      ));
    }
    meals.sort((a, b) => a.time.compareTo(b.time));

    final totalCalories = meals.fold<double>(0.0, (sum, m) => sum + m.calories);
    // Distinct days where meals were logged
    final mealDays = meals.map((m) => HealthReading.formatDate(m.time)).toSet().length;
    final avgCalories = mealDays > 0 ? (totalCalories / mealDays) : 0.0;
    final calorieGoal = effectiveProfile?.calorieGoal ?? 2000.0;

    // ── Process Heart Rate ───────────────────────────────────────────────────
    final hrReadings = readings.where((r) => r.metric == HealthReading.heartRate).toList();
    final heartRateReadings = hrReadings.map((r) {
      return HeartRateReading(
        id: r.id,
        bpm: r.value,
        timestamp: r.timestamp,
      );
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double? avgHeartRate;
    double? minHeartRate;
    double? maxHeartRate;
    if (heartRateReadings.isNotEmpty) {
      final totalBpm = heartRateReadings.fold<double>(0.0, (sum, r) => sum + r.bpm);
      avgHeartRate = totalBpm / heartRateReadings.length;
      minHeartRate = heartRateReadings.map((r) => r.bpm).reduce(min);
      maxHeartRate = heartRateReadings.map((r) => r.bpm).reduce(max);
    }

    // ── Process Blood Pressure ───────────────────────────────────────────────
    final bpReadings = readings.where((r) => r.metric == HealthReading.bloodPressure).toList();
    final bloodPressureReadings = bpReadings.map((r) {
      return BloodPressureReading(
        id: r.id,
        systolic: r.valueSystolic ?? r.value.round(),
        diastolic: r.valueDiastolic ?? 80,
        timestamp: r.timestamp,
      );
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double? avgSystolic;
    double? avgDiastolic;
    BloodPressureReading? highestBP;
    BloodPressureReading? lowestBP;
    String bpClassification = 'No Data';

    if (bloodPressureReadings.isNotEmpty) {
      final totalSys = bloodPressureReadings.fold<int>(0, (sum, r) => sum + r.systolic);
      final totalDia = bloodPressureReadings.fold<int>(0, (sum, r) => sum + r.diastolic);
      avgSystolic = totalSys / bloodPressureReadings.length;
      avgDiastolic = totalDia / bloodPressureReadings.length;

      highestBP = bloodPressureReadings.reduce((a, b) => a.systolic > b.systolic ? a : b);
      lowestBP = bloodPressureReadings.reduce((a, b) => a.systolic < b.systolic ? a : b);

      if (avgSystolic < 120 && avgDiastolic < 80) {
        bpClassification = 'Normal (Optimal)';
      } else if (avgSystolic <= 129 && avgDiastolic < 80) {
        bpClassification = 'Elevated';
      } else if (avgSystolic <= 139 || avgDiastolic <= 89) {
        bpClassification = 'Hypertension Stage 1';
      } else {
        bpClassification = 'Hypertension Stage 2';
      }
    }

    // ── Process Blood Sugar ──────────────────────────────────────────────────
    final bsReadings = readings.where((r) => r.metric == HealthReading.bloodSugar).toList();
    final bloodSugarReadings = bsReadings.map((r) {
      return BloodSugarReading(
        id: r.id,
        value: r.value,
        date: r.timestamp,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    double? avgBloodSugar;
    double? minBloodSugar;
    double? maxBloodSugar;
    String bloodSugarStatus = 'No Data';

    if (bloodSugarReadings.isNotEmpty) {
      final totalBs = bloodSugarReadings.fold<double>(0.0, (sum, r) => sum + r.value);
      avgBloodSugar = totalBs / bloodSugarReadings.length;
      minBloodSugar = bloodSugarReadings.map((r) => r.value).reduce(min);
      maxBloodSugar = bloodSugarReadings.map((r) => r.value).reduce(max);

      if (avgBloodSugar < 70) {
        bloodSugarStatus = 'Low (Hypoglycemic Tendency)';
      } else if (avgBloodSugar <= 99) {
        bloodSugarStatus = 'Normal Fasting Glycemia';
      } else if (avgBloodSugar <= 125) {
        bloodSugarStatus = 'Elevated / Impaired Fasting';
      } else {
        bloodSugarStatus = 'High / Hyperglycemic Range';
      }
    }

    // ── Generate Deterministic Clinical Observations & Insights ───────────────
    final keyObservations = <String>[];
    final clinicalRecommendations = <String>[];

    // Activity insights
    if (dailySteps.isNotEmpty) {
      final goalMetDays = dailySteps.where((s) => s.steps >= stepGoal).length;
      keyObservations.add(
        'Physical Activity: Averaged ${avgSteps.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} steps/day over ${dailySteps.length} recorded day(s) ($goalMetDays day(s) reached the $stepGoal step target).',
      );
      if (avgSteps < stepGoal * 0.7) {
        clinicalRecommendations.add('Gradually increase daily walking intervals by 10-15 minutes to improve cardiovascular conditioning.');
      } else {
        clinicalRecommendations.add('Maintain the strong daily activity baseline to support long-term metabolic health.');
      }
    } else {
      keyObservations.add('Physical Activity: No step logs recorded during this period.');
    }

    // Hydration insights
    if (dailyWater.isNotEmpty) {
      final hydrationRate = ((avgWaterMl / waterGoal) * 100).round();
      keyObservations.add(
        'Hydration: Average intake was $avgWaterMl ml/day ($hydrationRate% of the $waterGoal ml goal) across ${dailyWater.length} active day(s).',
      );
      if (avgWaterMl < waterGoal) {
        clinicalRecommendations.add('Aim to distribute water intake evenly throughout morning and afternoon to meet the $waterGoal ml daily hydration target.');
      }
    } else {
      keyObservations.add('Hydration: No water intake entries logged for this period.');
    }

    // Sleep insights
    if (dailySleep.isNotEmpty) {
      keyObservations.add(
        'Sleep Duration: Averaged ${avgSleepHours.toStringAsFixed(1)} hours/night across ${dailySleep.length} recorded night(s) (Goal: ${sleepGoal.toStringAsFixed(1)}h).',
      );
      if (avgSleepHours < 7.0) {
        clinicalRecommendations.add('Prioritize consistent bedtime routines and sleep hygiene to increase restorative rest toward 7-8 hours.');
      }
    } else {
      keyObservations.add('Sleep: No sleep duration logs available for this period.');
    }

    // Blood Pressure & Cardiovascular insights
    if (bloodPressureReadings.isNotEmpty) {
      keyObservations.add(
        'Cardiovascular (BP): Average reading was ${avgSystolic!.round()}/${avgDiastolic!.round()} mmHg ($bpClassification).',
      );
      if (avgSystolic >= 130 || avgDiastolic >= 85) {
        clinicalRecommendations.add('Continue monitoring blood pressure regularly and consult your healthcare provider regarding ongoing elevated trends.');
      }
    }

    // Blood Sugar insights
    if (bloodSugarReadings.isNotEmpty) {
      keyObservations.add(
        'Metabolic (Blood Sugar): Average level was ${avgBloodSugar!.toStringAsFixed(1)} mg/dL ($bloodSugarStatus) with range ${minBloodSugar!.toStringAsFixed(1)}-${maxBloodSugar!.toStringAsFixed(1)} mg/dL.',
      );
      if (avgBloodSugar > 100) {
        clinicalRecommendations.add('Monitor carbohydrate and glycemic intake to support steady glucose stabilization.');
      }
    }

    // Heart Rate insights
    if (heartRateReadings.isNotEmpty) {
      keyObservations.add(
        'Resting Heart Rate: Average was ${avgHeartRate!.round()} BPM (Range: ${minHeartRate!.round()}-${maxHeartRate!.round()} BPM).',
      );
    }

    if (clinicalRecommendations.isEmpty) {
      clinicalRecommendations.add('Keep tracking your daily metrics consistently to unlock deeper clinical trend analysis.');
    }

    return HealthReportData(
      fromDate: startOfDay,
      toDate: endOfDay,
      generatedAt: now,
      uid: uid,
      profile: effectiveProfile,
      totalDays: totalDays,
      dailyScores: dailyScores,
      averageScore: avgScore,
      latestScore: latestScore,
      minScore: minScore,
      maxScore: maxScore,
      scoreLabel: scoreLabel,
      dailySteps: dailySteps,
      totalSteps: totalSteps,
      avgSteps: avgSteps,
      highestStepDay: highestStepDay,
      lowestStepDay: lowestStepDay,
      stepGoal: stepGoal,
      dailyWater: dailyWater,
      totalWaterMl: totalWaterMl,
      avgWaterMl: avgWaterMl,
      waterGoal: waterGoal,
      dailySleep: dailySleep,
      totalSleepHours: totalSleepHours,
      avgSleepHours: avgSleepHours,
      sleepGoal: sleepGoal,
      meals: meals,
      totalCalories: totalCalories,
      avgCalories: avgCalories,
      calorieGoal: calorieGoal,
      mealTypeCounts: mealTypeCounts,
      heartRateReadings: heartRateReadings,
      avgHeartRate: avgHeartRate,
      minHeartRate: minHeartRate,
      maxHeartRate: maxHeartRate,
      bloodPressureReadings: bloodPressureReadings,
      avgSystolic: avgSystolic,
      avgDiastolic: avgDiastolic,
      highestBP: highestBP,
      lowestBP: lowestBP,
      bpClassification: bpClassification,
      bloodSugarReadings: bloodSugarReadings,
      avgBloodSugar: avgBloodSugar,
      minBloodSugar: minBloodSugar,
      maxBloodSugar: maxBloodSugar,
      bloodSugarStatus: bloodSugarStatus,
      keyObservations: keyObservations,
      clinicalRecommendations: clinicalRecommendations,
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/activity_models.dart';
import '../models/social_models.dart';
import '../models/analytics_models.dart';
import '../models/health_reading.dart';
import '../models/daily_score.dart';
import '../services/ai_insight_engine.dart';
import '../services/goal_planner.dart';
import '../services/predictive_analytics.dart';
import '../services/social_service.dart';
import '../services/step_tracking_service.dart';
import '../services/firestore_service.dart';
import '../services/health_score_engine.dart';

class HealthDataController extends ChangeNotifier {
  // profile is now managed by AuthController; a reference is provided
  // here so HealthScoreEngine can access demographics for scoring.
  UserProfile? profile;

  // Initialize with zero values - these reset daily
  int stepsToday = 0;
  int stepGoal = 10000;
  int waterMl = 0;
  int waterGoal = 2500;
  double caloriesConsumed = 0;
  double calorieGoal = 2000;
  double sleepHours = 0;
  double sleepGoal = 8.0;
  double heartRate = 0;
  double stressLevel = 0;
  int mindfulnessMinutes = 0;
  int rewardPoints = 0;
  int streakDays = 0;
  String? lastFoodLabel;
  int? lastFoodCalories;

  final List<ActivityEntry> history = [];
  final List<MealEntry> meals = [];
  final List<ReminderItem> reminders = [];
  final List<Challenge> challenges = [];
  final List<LeaderboardEntry> leaderboard = [];

  List<String> _cachedInsights = [];
  bool _isLoadingInsights = false;

  int _systolic = 0;
  int _diastolic = 0;

  List<BloodPressureReading> bloodPressureHistory = [];
  double bloodSugar = 0;
  List<BloodSugarReading> bloodSugarHistory = [];
  List<SleepReading> sleepReadingHistory = [];
  List<WaterIntakeReading> waterIntakeHistory = [];
  List<HeartRateReading> heartRateHistory = [];

  DateTime _lastResetDate = DateTime.now();

  List<DailyStepRecord> stepHistory = [];
  List<DailySleepRecord> sleepHistory = [];
  List<DailyWaterRecord> waterHistory = [];

  String pedestrianStatus = 'unknown';
  String? userId;
  String? username;
  int userScore = 0;
  int userRank = 0;

  /// Latest deterministic daily score.
  DailyScore? _todayScore;
  DailyScore? get todayScore {
    if (_todayScore == null) {
      _refreshDailyScore();
    }
    return _todayScore;
  }
  set todayScore(DailyScore? s) {
    _todayScore = s;
    notifyListeners();
  }

  bool _isDataLoaded = false;
  bool _isLoadingData = false; // Guard against re-entrant setUserInfo calls

  HealthDataController() {
    _lastResetDate = DateTime.now();
    _initializeStepTracking();
  }

  // Initialize step tracking
  Future<void> _initializeStepTracking() async {
    try {
      final stepService = StepTrackingService.instance;
      await stepService.initialize();

      stepService.onStepsUpdated = (steps) {
        if (steps != stepsToday && userId != null) {
          stepsToday = steps;
          _updateTodayInHistory();
          _saveCurrentData();

          if (username != null) {
            _updateSocialScore();
          }

          notifyListeners();
        }
      };

      stepService.onStatusChanged = (status) {
        pedestrianStatus = status;
        notifyListeners();
      };
    } catch (e) {
      print('Error initializing step tracking: $e');
    }
  }

  // USER INFO METHODS - This is the key method that loads user-specific data
  void setUserInfo(String id, String name) {
    // Guard: same user already fully loaded → no-op
    if (userId == id && _isDataLoaded) {
      debugPrint('🔥 [HealthData] setUserInfo skipped – already loaded for uid=$id');
      return;
    }

    // Guard: same user currently loading → no-op (prevents the race condition
    // where Google Sign-In triggers 2-3 setUserInfo calls in rapid succession;
    // the second/third call arrives while _isDataLoaded is still false because
    // _loadUserData is async, causing _clearAllLocalData to wipe in-progress data)
    if (userId == id && _isLoadingData) {
      debugPrint('🔥 [HealthData] setUserInfo skipped – load already in progress for uid=$id');
      return;
    }

    debugPrint('🔥 [HealthData] setUserInfo: uid=$id, name=$name (previous uid=$userId)');

    // Clear all data before loading new user
    _clearAllLocalData();

    userId = id;
    username = name;
    _isDataLoaded = false;
    _isLoadingData = false; // will be set to true inside _loadUserData

    // Load user-specific data from SharedPreferences
    _loadUserData();

    notifyListeners();
  }

  void clearUserInfo() {
    // Save current user's data before clearing
    if (userId != null) {
      debugPrint('🔥 [HealthData] clearUserInfo: saving data for uid=$userId');
      _saveCurrentData();
      _saveHistoryData();
    }

    // Clear everything
    _clearAllLocalData();

    userId = null;
    username = null;
    userScore = 0;
    userRank = 0;
    _todayScore = null;
    _isDataLoaded = false;
    _isLoadingData = false;

    debugPrint('🔥 [HealthData] clearUserInfo: complete');
    notifyListeners();
  }

  // Clear ALL local data
  void _clearAllLocalData() {
    stepsToday = 0;
    waterMl = 0;
    sleepHours = 0;
    caloriesConsumed = 0;
    heartRate = 0;
    stressLevel = 0;
    mindfulnessMinutes = 0;
    bloodSugar = 0;
    _systolic = 0;
    _diastolic = 0;
    rewardPoints = 0;
    streakDays = 0;

    // Clear all lists
    stepHistory.clear();
    sleepHistory.clear();
    waterHistory.clear();
    sleepReadingHistory.clear();
    waterIntakeHistory.clear();
    meals.clear();
    bloodPressureHistory.clear();
    bloodSugarHistory.clear();
    heartRateHistory.clear();
    history.clear();
    reminders.clear();
    challenges.clear();

    // Reset goals to defaults
    stepGoal = 10000;
    waterGoal = 2500;
    calorieGoal = 2000;
    sleepGoal = 8.0;
  }

  // Load user-specific data from SharedPreferences and Firestore
  Future<void> _loadUserData() async {
    if (userId == null) return;

    _isLoadingData = true;
    final loadingForUid = userId; // capture to detect if user changed mid-load
    debugPrint('🔥 [HealthData] _loadUserData started for uid=$loadingForUid');

    try {
      final prefs = await SharedPreferences.getInstance();

      // If the user changed while we were waiting for SharedPreferences,
      // abort this load so we don't overwrite the new user's in-progress load.
      if (userId != loadingForUid) {
        debugPrint('🔥 [HealthData] _loadUserData aborted – uid changed during load (was $loadingForUid, now $userId)');
        return;
      }
      final prefix = 'user_${userId}_';

      // 1. Initial quick load from SharedPreferences (for instant local rendering)
      final stepHistoryJson =
          prefs.getStringList('${prefix}step_history') ?? [];
      stepHistory = stepHistoryJson.map((json) {
        final parts = json.split('|');
        if (parts.length >= 2) {
          return DailyStepRecord(
            date: DateTime.tryParse(parts[0]) ?? DateTime.now(),
            steps: int.tryParse(parts[1]) ?? 0,
          );
        }
        return DailyStepRecord(date: DateTime.now(), steps: 0);
      }).toList();

      final sleepHistoryJson =
          prefs.getStringList('${prefix}sleep_history') ?? [];
      sleepHistory = sleepHistoryJson.map((json) {
        final parts = json.split('|');
        if (parts.length >= 2) {
          return DailySleepRecord(
            date: DateTime.tryParse(parts[0]) ?? DateTime.now(),
            hours: double.tryParse(parts[1]) ?? 0,
          );
        }
        return DailySleepRecord(date: DateTime.now(), hours: 0);
      }).toList();

      final waterHistoryJson =
          prefs.getStringList('${prefix}water_history') ?? [];
      waterHistory = waterHistoryJson.map((json) {
        final parts = json.split('|');
        if (parts.length >= 2) {
          return DailyWaterRecord(
            date: DateTime.tryParse(parts[0]) ?? DateTime.now(),
            amount: int.tryParse(parts[1]) ?? 0,
          );
        }
        return DailyWaterRecord(date: DateTime.now(), amount: 0);
      }).toList();

      // Load goals
      stepGoal = prefs.getInt('${prefix}step_goal') ?? stepGoal;
      waterGoal = prefs.getInt('${prefix}water_goal') ?? waterGoal;
      calorieGoal = prefs.getDouble('${prefix}calorie_goal') ?? calorieGoal;
      sleepGoal = prefs.getDouble('${prefix}sleep_goal') ?? sleepGoal;

      // Check if today's data exists
      final savedDate = prefs.getString('${prefix}current_date');
      final today = DateTime.now().toIso8601String().substring(0, 10);

      if (savedDate == today) {
        stepsToday = prefs.getInt('${prefix}current_steps') ?? 0;
        waterMl = prefs.getInt('${prefix}current_water') ?? 0;
        sleepHours = prefs.getDouble('${prefix}current_sleep') ?? 0.0;
        caloriesConsumed = prefs.getDouble('${prefix}current_calories') ?? 0.0;
      }

      // 2. Load canonical User Profile from Firestore
      if (profile == null) {
        final loadedProfile = await FirestoreService.instance.loadProfile(userId!);
        if (loadedProfile != null && userId == loadingForUid) {
          profile = loadedProfile;
          stepGoal = loadedProfile.stepGoal;
          waterGoal = loadedProfile.waterGoalMl;
          calorieGoal = loadedProfile.calorieGoal;
          sleepGoal = loadedProfile.sleepGoalHours;
        }
      } else {
        stepGoal = profile!.stepGoal;
        waterGoal = profile!.waterGoalMl;
        calorieGoal = profile!.calorieGoal;
        sleepGoal = profile!.sleepGoalHours;
      }

      // 3. Load all persistent HealthReadings from Firestore (the canonical source of truth)
      final readings = await FirestoreService.instance.getAllReadings(userId!);
      if (userId != loadingForUid) return;

      if (readings.isNotEmpty) {
        final todayStr = HealthReading.todayDate();

        // 3a. Water: individual entries, daily history, and today's total
        final waterReadings = readings.where((r) => r.metric == HealthReading.water).toList();
        waterIntakeHistory.clear();
        if (waterReadings.isNotEmpty) {
          for (final r in waterReadings) {
            waterIntakeHistory.add(WaterIntakeReading(
              id: r.id,
              amount: r.value.round(),
              timestamp: r.timestamp,
            ));
          }
          final waterByDate = <String, int>{};
          for (final r in waterReadings) {
            waterByDate[r.date] = (waterByDate[r.date] ?? 0) + r.value.round();
          }
          waterHistory = waterByDate.entries.map((e) => DailyWaterRecord(
            date: DateTime.tryParse(e.key) ?? DateTime.now(),
            amount: e.value,
          )).toList()..sort((a, b) => a.date.compareTo(b.date));

          waterMl = waterByDate[todayStr] ?? 0;
        } else {
          waterHistory.clear();
          waterMl = 0;
        }

        // 3b. Calories & Meals: individual meal entries and today's total
        final calReadings = readings.where((r) => r.metric == HealthReading.calories).toList();
        meals.clear();
        if (calReadings.isNotEmpty) {
          for (final r in calReadings.reversed) {
            final mealTypeStr = r.metadata['mealType'] as String?;
            final mealName = r.metadata['mealName'] as String? ?? 'Meal';
            final mealType = MealType.values.firstWhere(
              (m) => m.name == mealTypeStr,
              orElse: () => MealType.snack,
            );
            meals.add(MealEntry(
              id: r.id,
              name: mealName,
              calories: r.value.round(),
              time: r.timestamp,
              mealType: mealType,
            ));
          }
          final todayCal = calReadings
              .where((r) => r.date == todayStr)
              .fold<double>(0.0, (sum, r) => sum + r.value);
          caloriesConsumed = todayCal;
        } else {
          caloriesConsumed = 0.0;
        }

        // 3c. Sleep: individual entries, daily history, and today's total
        final sleepReadings = readings.where((r) => r.metric == HealthReading.sleep).toList();
        sleepReadingHistory.clear();
        if (sleepReadings.isNotEmpty) {
          for (final r in sleepReadings) {
            sleepReadingHistory.add(SleepReading(
              id: r.id,
              date: r.timestamp,
              hours: r.value,
            ));
          }
          final sleepByDate = <String, double>{};
          for (final r in sleepReadings) {
            sleepByDate[r.date] = (sleepByDate[r.date] ?? 0.0) + r.value;
          }
          sleepHistory = sleepByDate.entries.map((e) => DailySleepRecord(
            date: DateTime.tryParse(e.key) ?? DateTime.now(),
            hours: e.value,
          )).toList()..sort((a, b) => a.date.compareTo(b.date));

          sleepHours = sleepByDate[todayStr] ?? 0.0;
        } else {
          sleepHistory.clear();
          sleepHours = 0.0;
        }

        // 3d. Heart Rate: history and latest bpm
        final hrReadings = readings.where((r) => r.metric == HealthReading.heartRate).toList();
        heartRateHistory.clear();
        if (hrReadings.isNotEmpty) {
          for (final r in hrReadings.reversed) {
            heartRateHistory.add(HeartRateReading(
              id: r.id,
              bpm: r.value,
              timestamp: r.timestamp,
            ));
          }
          heartRate = heartRateHistory.first.bpm;
        } else {
          heartRate = 0.0;
        }

        // 3e. Blood Pressure: history and latest systolic/diastolic
        final bpReadings = readings.where((r) => r.metric == HealthReading.bloodPressure).toList();
        bloodPressureHistory.clear();
        if (bpReadings.isNotEmpty) {
          for (final r in bpReadings.reversed) {
            bloodPressureHistory.add(BloodPressureReading(
              id: r.id,
              systolic: r.valueSystolic ?? r.value.round(),
              diastolic: r.valueDiastolic ?? 80,
              timestamp: r.timestamp,
            ));
          }
          _systolic = bloodPressureHistory.first.systolic;
          _diastolic = bloodPressureHistory.first.diastolic;
        } else {
          _systolic = 0;
          _diastolic = 0;
        }

        // 3f. Blood Sugar: history and latest value
        final bsReadings = readings.where((r) => r.metric == HealthReading.bloodSugar).toList();
        bloodSugarHistory.clear();
        if (bsReadings.isNotEmpty) {
          for (final r in bsReadings) {
            bloodSugarHistory.add(BloodSugarReading(
              id: r.id,
              date: r.timestamp,
              value: r.value,
            ));
          }
          bloodSugar = bloodSugarHistory.last.value;
        } else {
          bloodSugar = 0.0;
        }

        // 3g. Steps: daily history records
        final stepReadings = readings.where((r) => r.metric == HealthReading.steps).toList();
        if (stepReadings.isNotEmpty) {
          stepHistory.clear();
          final stepByDate = <String, int>{};
          for (final r in stepReadings) {
            stepByDate[r.date] = max(stepByDate[r.date] ?? 0, r.value.round());
          }
          for (final entry in stepByDate.entries) {
            final d = DateTime.tryParse(entry.key) ?? DateTime.now();
            stepHistory.add(DailyStepRecord(date: d, steps: entry.value));
          }
          stepHistory.sort((a, b) => a.date.compareTo(b.date));
          if (stepByDate.containsKey(todayStr)) {
            stepsToday = stepByDate[todayStr]!;
          }
        }

        // 3h. Activity History across all recorded dates
        final allDates = readings.map((r) => r.date).toSet().toList()..sort();
        history.clear();
        for (final dStr in allDates) {
          final d = DateTime.tryParse(dStr) ?? DateTime.now();
          final dWater = readings
              .where((r) => r.metric == HealthReading.water && r.date == dStr)
              .fold<int>(0, (s, r) => s + r.value.round());
          final dSleep = readings
              .where((r) => r.metric == HealthReading.sleep && r.date == dStr)
              .fold<double>(0.0, (s, r) => s + r.value);
          final dCal = readings
              .where((r) => r.metric == HealthReading.calories && r.date == dStr)
              .fold<double>(0.0, (s, r) => s + r.value)
              .round();
          final dSteps = readings
              .where((r) => r.metric == HealthReading.steps && r.date == dStr)
              .fold<int>(0, (s, r) => max(s, r.value.round()));
          history.add(ActivityEntry(
            date: d,
            steps: dSteps,
            calories: dCal,
            sleepHours: dSleep,
            waterMl: dWater,
            stressLevel: 0,
            mindfulnessMinutes: 0,
          ));
        }
      } else {
        // No persistent readings in Firestore: ensure all lists and totals are clean
        waterIntakeHistory.clear();
        waterHistory.clear();
        waterMl = 0;
        meals.clear();
        caloriesConsumed = 0.0;
        sleepReadingHistory.clear();
        sleepHistory.clear();
        sleepHours = 0.0;
        heartRateHistory.clear();
        heartRate = 0.0;
        bloodPressureHistory.clear();
        _systolic = 0;
        _diastolic = 0;
        bloodSugarHistory.clear();
        bloodSugar = 0.0;
        history.clear();
      }

      // Update current date and persist cache
      await prefs.setString('${prefix}current_date', today);
      await _saveCurrentData();
      await _saveHistoryData();

      _isDataLoaded = true;
      _isLoadingData = false;
      debugPrint('🔥 [HealthData] _loadUserData complete for uid=$userId | water=$waterMl ml | sleep=$sleepHours h | steps=$stepsToday | meals=${meals.length} | HR entries=${heartRateHistory.length} | BP entries=${bloodPressureHistory.length}');
      _refreshDailyScore();
      _loadInsights();
      if (username != null) _updateSocialScore();
      notifyListeners();
    } catch (e) {
      _isLoadingData = false;
      debugPrint('🔥 [HealthData] _loadUserData ERROR for uid=$userId: $e');
    }
  }

  /// Reloads all user data and health readings directly from Firestore.
  Future<void> reloadUserData() => _loadUserData();

  /// Synchronizes an action executed by Aurora AI (such as water logging)
  /// into controller state and persists to local cache and Firestore.
  void syncWaterFromAction({required int loggedMl, required int newTotalMl, String? recordId}) {
    if (newTotalMl > 0) {
      final now = DateTime.now();
      final today = HealthReading.todayDate();
      final docId = recordId ?? (userId != null ? FirestoreService.instance.newReadingId(userId!) : 'aurora_${now.millisecondsSinceEpoch}');

      final alreadyExists = waterIntakeHistory.any((r) => r.id == docId);
      if (!alreadyExists && loggedMl > 0) {
        waterIntakeHistory.add(WaterIntakeReading(id: docId, amount: loggedMl, timestamp: now));
        if (waterIntakeHistory.length > 50) waterIntakeHistory.removeAt(0);

        if (userId != null) {
          _writeReading(HealthReading(
            id: docId,
            userId: userId!,
            metric: HealthReading.water,
            value: loggedMl.toDouble(),
            date: today,
            timestamp: now,
          ));
        }
      }
      waterMl = newTotalMl;
      _updateTodayInWaterHistory();
      _updateTodayInHistory();
      _saveCurrentData();
      _saveHistoryData();
      _refreshDailyScore();
      if (username != null) _updateSocialScore();
      notifyListeners();
    }
  }

  // Save current day's data
  Future<void> _saveCurrentData() async {
    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'user_${userId}_';
      final today = DateTime.now().toIso8601String().substring(0, 10);

      await prefs.setString('${prefix}current_date', today);
      await prefs.setInt('${prefix}current_steps', stepsToday);
      await prefs.setInt('${prefix}current_water', waterMl);
      await prefs.setDouble('${prefix}current_sleep', sleepHours);
      await prefs.setDouble('${prefix}current_calories', caloriesConsumed);
    } catch (e) {
      print('Error saving current data: $e');
    }
  }

  // Save history data
  Future<void> _saveHistoryData() async {
    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'user_${userId}_';

      final stepHistoryJson = stepHistory
          .map((r) => '${r.date.toIso8601String()}|${r.steps}')
          .toList();
      final sleepHistoryJson = sleepHistory
          .map((r) => '${r.date.toIso8601String()}|${r.hours}')
          .toList();
      final waterHistoryJson = waterHistory
          .map((r) => '${r.date.toIso8601String()}|${r.amount}')
          .toList();

      await prefs.setStringList('${prefix}step_history', stepHistoryJson);
      await prefs.setStringList('${prefix}sleep_history', sleepHistoryJson);
      await prefs.setStringList('${prefix}water_history', waterHistoryJson);
    } catch (e) {
      print('Error saving history data: $e');
    }
  }

  // Save goals
  Future<void> _saveGoals() async {
    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'user_${userId}_';

      await prefs.setInt('${prefix}step_goal', stepGoal);
      await prefs.setInt('${prefix}water_goal', waterGoal);
      await prefs.setDouble('${prefix}calorie_goal', calorieGoal);
      await prefs.setDouble('${prefix}sleep_goal', sleepGoal);

      // Persist to Firestore profile so it survives restart
      await FirestoreService.instance.updateProfileFields(userId!, {
        'stepGoal': stepGoal,
        'waterGoalMl': waterGoal,
        'calorieGoal': calorieGoal,
        'sleepGoalHours': sleepGoal,
      });
    } catch (e) {
      debugPrint('Error saving goals: $e');
    }
  }

  // GOAL UPDATE METHODS
  void updateStepGoal(int goal) {
    stepGoal = goal;
    if (profile != null) {
      profile = profile!.copyWith(stepGoal: goal);
    }
    _saveGoals();
    _refreshDailyScore();
    notifyListeners();
  }

  void updateWaterGoal(int goal) {
    waterGoal = goal;
    if (profile != null) {
      profile = profile!.copyWith(waterGoalMl: goal);
    }
    _saveGoals();
    _refreshDailyScore();
    notifyListeners();
  }

  void updateCalorieGoal(double goal) {
    calorieGoal = goal;
    if (profile != null) {
      profile = profile!.copyWith(calorieGoal: goal);
    }
    _saveGoals();
    _refreshDailyScore();
    notifyListeners();
  }

  void updateSleepGoal(double goal) {
    sleepGoal = goal;
    if (profile != null) {
      profile = profile!.copyWith(sleepGoalHours: goal);
    }
    _saveGoals();
    _refreshDailyScore();
    notifyListeners();
  }

  // HELPER METHODS FOR CHARTS
  int getStepsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    if (dayStart.isAtSameMomentAs(today)) return stepsToday;

    for (var record in stepHistory) {
      final recordDate =
          DateTime(record.date.year, record.date.month, record.date.day);
      if (recordDate.isAtSameMomentAs(dayStart)) {
        return record.steps;
      }
    }
    return 0;
  }

  double getSleepForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    if (dayStart.isAtSameMomentAs(today)) return sleepHours;

    for (var record in sleepHistory) {
      final recordDate =
          DateTime(record.date.year, record.date.month, record.date.day);
      if (recordDate.isAtSameMomentAs(dayStart)) {
        return record.hours;
      }
    }
    return 0;
  }

  int getWaterForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    if (dayStart.isAtSameMomentAs(today)) return waterMl;

    for (var record in waterHistory) {
      final recordDate =
          DateTime(record.date.year, record.date.month, record.date.day);
      if (recordDate.isAtSameMomentAs(dayStart)) {
        return record.amount;
      }
    }
    return 0;
  }

  int getWaterIntakeForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return waterIntakeHistory
        .where((r) =>
            r.timestamp.isAfter(dayStart) && r.timestamp.isBefore(dayEnd))
        .fold(0, (sum, r) => sum + r.amount);
  }

  // GETTERS
  List<FlSpot> get stepTrend => List.generate(history.length,
      (index) => FlSpot(index.toDouble(), history[index].steps.toDouble()));

  List<String> get topInsights {
    final insights = <String>[];
    if (stepsToday >= stepGoal) {
      insights.add('Great job! You hit your step goal today 🎉');
    }
    if (caloriesConsumed < calorieGoal * 0.8 && caloriesConsumed > 0) {
      insights.add('You might need more calories to meet your daily goal');
    }
    if (waterMl >= waterGoal) {
      insights.add('Excellent hydration! Keep it up 💧');
    }
    if (sleepHours >= sleepGoal) {
      insights.add('Perfect sleep! You\'re well rested 😴');
    }
    return insights.take(3).toList();
  }

  bool get isLoadingInsights => _isLoadingInsights;
  List<String> get cachedInsights => List.unmodifiable(_cachedInsights);
  GoalPlan get recommendedGoals => GoalPlanner.generate(this);
  List<LeaderboardEntry> get leaderboardSorted {
    final copy = [...leaderboard];
    copy.sort((a, b) => b.score.compareTo(a.score));
    return copy;
  }

  String get bedtimeSuggestion => PredictiveAnalytics.optimalBedtime(this);
  ForecastBundle get forecastBundle =>
      PredictiveAnalytics.stepAndCalorieForecast(history);
  int get systolic => _systolic;
  int get diastolic => _diastolic;

  /// Called by AuthController after the Firestore profile is loaded.
  /// Triggers a score refresh so the dashboard shows an up-to-date score
  /// immediately after login.
  void loadProfile(UserProfile p) {
    profile = p;
    // Also sync goals from Firestore profile
    stepGoal = p.stepGoal;
    waterGoal = p.waterGoalMl;
    calorieGoal = p.calorieGoal;
    sleepGoal = p.sleepGoalHours;
    _saveGoals();
    _refreshDailyScore();
    notifyListeners();
  }

  void clearProfile() {
    profile = null;
    notifyListeners();
  }

  /// Completely wipes all health metrics, history, and user identity from memory.
  void resetAllUserData() {
    profile = null;
    userId = null;
    username = null;
    stepsToday = 0;
    waterMl = 0;
    sleepHours = 0;
    caloriesConsumed = 0;
    heartRate = 0;
    _systolic = 0;
    _diastolic = 0;
    bloodSugar = 0;
    userScore = 0;
    userRank = 0;
    _todayScore = null;
    bloodPressureHistory.clear();
    bloodSugarHistory.clear();
    sleepReadingHistory.clear();
    waterIntakeHistory.clear();
    heartRateHistory.clear();
    stepHistory.clear();
    sleepHistory.clear();
    waterHistory.clear();
    meals.clear();
    history.clear();
    _isDataLoaded = false;
    _isLoadingData = false;
    notifyListeners();
  }

  Future<void> refreshDailyMetrics() async {
    await Future.delayed(const Duration(milliseconds: 600));
    notifyListeners();
    await _loadInsights();
  }

  void _updateTodayInWaterHistory() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final idx = waterHistory.indexWhere((r) {
      final rd = DateTime(r.date.year, r.date.month, r.date.day);
      return rd.isAtSameMomentAs(today);
    });
    if (idx != -1) {
      if (waterMl > 0) {
        waterHistory[idx] = DailyWaterRecord(date: waterHistory[idx].date, amount: waterMl);
      } else {
        waterHistory.removeAt(idx);
      }
    } else if (waterMl > 0) {
      waterHistory.add(DailyWaterRecord(date: today, amount: waterMl));
    }
  }

  void _updateTodayInSleepHistory() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final idx = sleepHistory.indexWhere((r) {
      final rd = DateTime(r.date.year, r.date.month, r.date.day);
      return rd.isAtSameMomentAs(today);
    });
    if (idx != -1) {
      if (sleepHours > 0) {
        sleepHistory[idx] = DailySleepRecord(date: sleepHistory[idx].date, hours: sleepHours);
      } else {
        sleepHistory.removeAt(idx);
      }
    } else if (sleepHours > 0) {
      sleepHistory.add(DailySleepRecord(date: today, hours: sleepHours));
    }
  }

  void addWater(int milliliters) {
    if (userId == null) {
      debugPrint('🔥 [HealthData] addWater($milliliters ml) BLOCKED – userId is null');
      return;
    }

    if (milliliters <= 0) return;

    final docId = FirestoreService.instance.newReadingId(userId!);
    final now = DateTime.now();
    final today = HealthReading.todayDate();

    final entry = WaterIntakeReading(id: docId, amount: milliliters, timestamp: now);
    waterIntakeHistory.add(entry);
    if (waterIntakeHistory.length > 50) waterIntakeHistory.removeAt(0);

    waterMl = waterIntakeHistory
        .where((r) => HealthReading.formatDate(r.timestamp) == today)
        .fold(0, (sum, r) => sum + r.amount);
    rewardPoints += 5;

    // Write to Firestore with canonical docId
    _writeReading(HealthReading(
      id: docId,
      userId: userId!,
      metric: HealthReading.water,
      value: milliliters.toDouble(),
      date: today,
      timestamp: now,
    ));

    _updateTodayInWaterHistory();
    _updateTodayInHistory();
    _saveCurrentData();
    _saveHistoryData();
    _refreshDailyScore();

    if (username != null) _updateSocialScore();
    notifyListeners();
  }

  void addSleepReading(double hours) {
    if (userId == null) {
      debugPrint('🔥 [HealthData] addSleepReading($hours h) BLOCKED – userId is null');
      return;
    }

    final docId = FirestoreService.instance.newReadingId(userId!);
    final now = DateTime.now();
    final today = HealthReading.todayDate();

    final entry = SleepReading(id: docId, date: now, hours: hours);
    sleepReadingHistory.add(entry);
    if (sleepReadingHistory.length > 30) sleepReadingHistory.removeAt(0);

    sleepHours = hours; // sleep is a total, not accumulative

    // Write to Firestore
    _writeReading(HealthReading(
      id: docId,
      userId: userId!,
      metric: HealthReading.sleep,
      value: hours,
      date: today,
      timestamp: now,
    ));

    _updateTodayInSleepHistory();
    _updateTodayInHistory();
    _saveCurrentData();
    _saveHistoryData();
    _refreshDailyScore();

    if (username != null) _updateSocialScore();
    notifyListeners();
  }

  void logMeal(MealEntry meal) {
    if (userId == null) return;

    final docId = meal.id.isNotEmpty
        ? meal.id
        : FirestoreService.instance.newReadingId(userId!);

    final effectiveMeal = meal.id.isEmpty
        ? MealEntry(
            id: docId,
            name: meal.name,
            calories: meal.calories,
            time: meal.time,
            mealType: meal.mealType,
          )
        : meal;

    meals.insert(0, effectiveMeal);

    final today = HealthReading.todayDate();
    caloriesConsumed = meals
        .where((m) => HealthReading.formatDate(m.time) == today)
        .fold(0.0, (sum, m) => sum + m.calories);

    rewardPoints += 8;

    // Write calorie reading to Firestore
    _writeReading(HealthReading(
      id: docId,
      userId: userId!,
      metric: HealthReading.calories,
      value: meal.calories.toDouble(),
      date: today,
      timestamp: meal.time,
      metadata: {'mealType': meal.mealType.name, 'mealName': meal.name},
    ));

    _updateTodayInHistory();
    _saveCurrentData();
    _saveHistoryData();
    _refreshDailyScore();
    if (username != null) _updateSocialScore();
    notifyListeners();
  }

  void removeMeal(MealEntry meal) {
    if (userId == null) return;

    meals.remove(meal);

    final today = HealthReading.todayDate();
    caloriesConsumed = meals
        .where((m) => HealthReading.formatDate(m.time) == today)
        .fold(0.0, (sum, m) => sum + m.calories);

    if (meal.id.isNotEmpty) {
      FirestoreService.instance.deleteReading(userId!, meal.id).catchError((e) {
        debugPrint('🔥 [HealthData] removeMeal deleteReading ERROR: $e');
      });
    } else {
      FirestoreService.instance.deleteMatchingReading(
        uid: userId!,
        metric: HealthReading.calories,
        timestamp: meal.time,
        value: meal.calories.toDouble(),
      ).catchError((e) {
        debugPrint('🔥 [HealthData] removeMeal deleteMatchingReading ERROR: $e');
      });
    }

    _updateTodayInHistory();
    _saveCurrentData();
    _saveHistoryData();
    _refreshDailyScore();
    if (username != null) _updateSocialScore();
    notifyListeners();
  }

  void removeSleepReading(SleepReading reading) {
    if (userId == null) return;

    sleepReadingHistory.remove(reading);

    final today = HealthReading.todayDate();
    final todaySleeps = sleepReadingHistory
        .where((r) => HealthReading.formatDate(r.date) == today)
        .toList();
    sleepHours = todaySleeps.isNotEmpty ? todaySleeps.last.hours : 0.0;

    if (reading.id.isNotEmpty) {
      FirestoreService.instance.deleteReading(userId!, reading.id).catchError((e) {
        debugPrint('🔥 [HealthData] removeSleepReading deleteReading ERROR: $e');
      });
    } else {
      FirestoreService.instance.deleteMatchingReading(
        uid: userId!,
        metric: HealthReading.sleep,
        timestamp: reading.date,
        value: reading.hours,
      ).catchError((e) {
        debugPrint('🔥 [HealthData] removeSleepReading deleteMatchingReading ERROR: $e');
      });
    }

    _updateTodayInSleepHistory();
    _updateTodayInHistory();
    _saveCurrentData();
    _saveHistoryData();
    _refreshDailyScore();

    if (username != null) _updateSocialScore();
    notifyListeners();
  }

  void removeWaterIntake(WaterIntakeReading reading) {
    if (userId == null) return;

    waterIntakeHistory.remove(reading);

    final today = HealthReading.todayDate();
    waterMl = waterIntakeHistory
        .where((r) => HealthReading.formatDate(r.timestamp) == today)
        .fold(0, (sum, r) => sum + r.amount);

    if (reading.id.isNotEmpty) {
      FirestoreService.instance.deleteReading(userId!, reading.id).catchError((e) {
        debugPrint('🔥 [HealthData] removeWaterIntake deleteReading ERROR: $e');
      });
    } else {
      FirestoreService.instance.deleteMatchingReading(
        uid: userId!,
        metric: HealthReading.water,
        timestamp: reading.timestamp,
        value: reading.amount.toDouble(),
      ).catchError((e) {
        debugPrint('🔥 [HealthData] removeWaterIntake deleteMatchingReading ERROR: $e');
      });
    }

    _updateTodayInWaterHistory();
    _updateTodayInHistory();
    _saveCurrentData();
    _saveHistoryData();
    _refreshDailyScore();

    if (username != null) _updateSocialScore();
    notifyListeners();
  }

  List<WaterIntakeReading> getTodayWaterIntake() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return waterIntakeHistory.where((r) => r.timestamp.isAfter(today)).toList();
  }

  void updateSteps(int steps) {
    if (userId == null) return;

    stepsToday = steps;
    _updateTodayInHistory();
    _saveCurrentData();
    _refreshDailyScore();

    if (steps > 0) {
      final today = HealthReading.todayDate();
      FirestoreService.instance.setReading(
        HealthReading(
          id: 'steps_${userId}_$today',
          userId: userId!,
          metric: HealthReading.steps,
          value: steps.toDouble(),
          date: today,
          timestamp: DateTime.now(),
        ),
        docId: 'steps_${userId}_$today',
      );
    }

    if (username != null) _updateSocialScore();
    notifyListeners();
  }

  void _updateTodayInHistory() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final idx = history.indexWhere((entry) {
      final ed = DateTime(entry.date.year, entry.date.month, entry.date.day);
      return ed.isAtSameMomentAs(today);
    });

    final updatedEntry = ActivityEntry(
      date: idx != -1 ? history[idx].date : today,
      steps: stepsToday,
      calories: caloriesConsumed.round(),
      sleepHours: sleepHours,
      waterMl: waterMl,
      stressLevel: stressLevel,
      mindfulnessMinutes: mindfulnessMinutes,
    );

    if (idx != -1) {
      history[idx] = updatedEntry;
    } else if (stepsToday > 0 || waterMl > 0 || caloriesConsumed > 0 || sleepHours > 0) {
      history.add(updatedEntry);
    }
  }

  void checkDailyReset() {
    final now = DateTime.now();
    final lastReset =
        DateTime(_lastResetDate.year, _lastResetDate.month, _lastResetDate.day);
    final today = DateTime(now.year, now.month, now.day);

    if (today.isAfter(lastReset)) {
      _saveTodayToHistory();
      _resetDailyMetrics();
      _lastResetDate = now;
    }
  }

  void _saveTodayToHistory() {
    if (userId == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (stepsToday > 0) {
      stepHistory.add(DailyStepRecord(date: today, steps: stepsToday));
      if (stepHistory.length > 30) stepHistory.removeAt(0);
    }
    if (waterMl > 0) {
      waterHistory.add(DailyWaterRecord(date: today, amount: waterMl));
      if (waterHistory.length > 30) waterHistory.removeAt(0);
    }
    if (sleepHours > 0) {
      sleepHistory.add(DailySleepRecord(date: today, hours: sleepHours));
      if (sleepHistory.length > 30) sleepHistory.removeAt(0);
    }

    _saveHistoryData();
  }

  void _resetDailyMetrics() {
    stepsToday = 0;
    caloriesConsumed = 0;
    waterMl = 0;
    sleepHours = 0;
    heartRate = 0;
    stressLevel = 0;
    mindfulnessMinutes = 0;
    bloodSugar = 0;
    _systolic = 0;
    _diastolic = 0;

    meals.clear();
    sleepReadingHistory.clear();
    waterIntakeHistory.clear();

    StepTrackingService.instance.resetDailySteps();
    _saveCurrentData();
    notifyListeners();
  }

  Future<void> _loadInsights() async {
    if (_isLoadingInsights) return;
    _isLoadingInsights = true;
    notifyListeners();

    try {
      _cachedInsights = await AIInsightEngine.generate(this);
    } catch (e) {
      _cachedInsights = [
        'Stay hydrated and keep moving toward your goals.',
        'Great progress today! Keep up the momentum.',
        'Balance is key. Make time for rest and recovery.',
      ];
    }

    _isLoadingInsights = false;
    notifyListeners();
  }

  Future<void> _updateSocialScore() async {
    if (userId == null || username == null) return;

    try {
      await SocialService.updateUserScore(
        userId: userId!,
        username: username!,
        steps: stepsToday,
        waterMl: waterMl,
        calories: caloriesConsumed,
        sleepHours: sleepHours,
      );

      // Continuously sync real health data into active challenges
      await SocialService.syncAllActiveChallengesForUser(
        userId: userId!,
        waterMl: waterMl,
        stepsToday: stepsToday,
        caloriesConsumed: caloriesConsumed.round(),
        sleepHours: sleepHours,
      );
    } catch (e) {
      debugPrint('Error updating social score/challenges: $e');
    }
  }

  // ── Firestore helpers ──────────────────────────────────────────────────

  /// Write a reading to Firestore. Fire-and-forget (non-blocking).
  void _writeReading(HealthReading reading) {
    if (userId == null) return;
    FirestoreService.instance.addReading(reading).catchError((e) {
      debugPrint('🔥 [HealthData] _writeReading ERROR: $e');
      return null;
    });
  }

  /// Recalculate and persist the deterministic daily score.
  /// Called after every metric update or when data loads.
  void _refreshDailyScore() {
    String? authUid;
    String? authEmail;
    String? authName;
    String? authPhoto;
    try {
      final u = FirebaseAuth.instance.currentUser;
      authUid = u?.uid;
      authEmail = u?.email;
      authName = u?.displayName;
      authPhoto = u?.photoURL;
    } catch (_) {}

    final effectiveUid = userId ?? authUid ?? 'local_user';
    final effectiveProfile = (profile ??
        UserProfile(
          uid: effectiveUid,
          email: authEmail ?? '',
          name: username ?? authName ?? 'User',
          avatarUrl: authPhoto ?? '',
        )).copyWith(
          stepGoal: stepGoal,
          waterGoalMl: waterGoal,
          calorieGoal: calorieGoal,
          sleepGoalHours: sleepGoal,
        );

    final score = HealthScoreEngine.calculate(
      profile: effectiveProfile,
      date: HealthReading.todayDate(),
      heartRateBpm: heartRate > 0 ? heartRate : null,
      systolic: _systolic > 0 ? _systolic : null,
      diastolic: _diastolic > 0 ? _diastolic : null,
      sleepHours: sleepHours > 0 ? sleepHours : null,
      waterMl: waterMl > 0 ? waterMl : null,
      caloriesKcal: caloriesConsumed > 0 ? caloriesConsumed : null,
      steps: stepsToday > 0 ? stepsToday : null,
    );

    _todayScore = score;

    // Persist asynchronously if user is signed in
    if (userId != null) {
      try {
        FirestoreService.instance.saveDailyScore(userId!, score).catchError((e) {
          debugPrint('🔥 [HealthData] _refreshDailyScore save ERROR: $e');
        });
      } catch (e) {
        debugPrint('🔥 [HealthData] _refreshDailyScore save ERROR: $e');
      }
    }

    debugPrint('✅ [HealthData] daily score refreshed: ${score.overall}/100 (${score.label}) with ${score.availableMetricCount} active metrics');
  }

  void addBloodPressureReading(int systolic, int diastolic) {
    if (userId == null) return;

    final docId = FirestoreService.instance.newReadingId(userId!);
    final now = DateTime.now();

    _systolic = systolic;
    _diastolic = diastolic;
    bloodPressureHistory.insert(
        0,
        BloodPressureReading(
          id: docId,
          systolic: systolic,
          diastolic: diastolic,
          timestamp: now,
        ));
    if (bloodPressureHistory.length > 30) bloodPressureHistory.removeLast();

    // Write to Firestore with canonical docId
    _writeReading(HealthReading(
      id: docId,
      userId: userId!,
      metric: HealthReading.bloodPressure,
      value: systolic.toDouble(),
      date: HealthReading.todayDate(),
      timestamp: now,
      valueSystolic: systolic,
      valueDiastolic: diastolic,
    ));

    _refreshDailyScore();
    notifyListeners();
  }

  void removeBloodPressureReading(BloodPressureReading reading) {
    if (userId == null) return;

    bloodPressureHistory.remove(reading);
    if (bloodPressureHistory.isNotEmpty) {
      _systolic = bloodPressureHistory.first.systolic;
      _diastolic = bloodPressureHistory.first.diastolic;
    } else {
      _systolic = 0;
      _diastolic = 0;
    }

    if (reading.id.isNotEmpty) {
      FirestoreService.instance.deleteReading(userId!, reading.id).catchError((e) {
        debugPrint('🔥 [HealthData] removeBloodPressureReading deleteReading ERROR: $e');
      });
    } else {
      FirestoreService.instance.deleteMatchingReading(
        uid: userId!,
        metric: HealthReading.bloodPressure,
        timestamp: reading.timestamp,
        value: reading.systolic.toDouble(),
      ).catchError((e) {
        debugPrint('🔥 [HealthData] removeBloodPressureReading deleteMatchingReading ERROR: $e');
      });
    }

    _refreshDailyScore();
    notifyListeners();
  }

  List<BloodPressureReading> getLastWeekBPReadings() {
    if (bloodPressureHistory.isEmpty) return [];
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    return bloodPressureHistory
        .where((r) => r.timestamp.isAfter(sevenDaysAgo))
        .toList();
  }

  List<BloodPressureReading> getLastMonthBPReadings() {
    if (bloodPressureHistory.isEmpty) return [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 29));
    return bloodPressureHistory
        .where((r) => r.timestamp.isAfter(thirtyDaysAgo))
        .toList();
  }

  void updateBloodSugar(double value) {
    if (userId == null) return;

    final docId = FirestoreService.instance.newReadingId(userId!);
    final now = DateTime.now();

    bloodSugar = value;
    bloodSugarHistory
        .add(BloodSugarReading(id: docId, date: now, value: value));
    if (bloodSugarHistory.length > 30) bloodSugarHistory.removeAt(0);

    // Write to Firestore with canonical docId
    _writeReading(HealthReading(
      id: docId,
      userId: userId!,
      metric: HealthReading.bloodSugar,
      value: value,
      date: HealthReading.todayDate(),
      timestamp: now,
    ));

    notifyListeners();
  }

  void removeBloodSugarReading(BloodSugarReading reading) {
    if (userId == null) return;

    bloodSugarHistory.remove(reading);
    bloodSugar = bloodSugarHistory.isNotEmpty ? bloodSugarHistory.last.value : 0.0;

    if (reading.id.isNotEmpty) {
      FirestoreService.instance.deleteReading(userId!, reading.id).catchError((e) {
        debugPrint('🔥 [HealthData] removeBloodSugarReading deleteReading ERROR: $e');
      });
    } else {
      FirestoreService.instance.deleteMatchingReading(
        uid: userId!,
        metric: HealthReading.bloodSugar,
        timestamp: reading.date,
        value: reading.value,
      ).catchError((e) {
        debugPrint('🔥 [HealthData] removeBloodSugarReading deleteMatchingReading ERROR: $e');
      });
    }

    notifyListeners();
  }

  /// Update heart rate and trigger score refresh.
  void updateHeartRate(double bpm) {
    if (userId == null) return;

    final docId = FirestoreService.instance.newReadingId(userId!);
    final now = DateTime.now();

    heartRate = bpm;
    heartRateHistory.insert(
      0,
      HeartRateReading(
        id: docId,
        bpm: bpm,
        timestamp: now,
      ),
    );
    if (heartRateHistory.length > 30) heartRateHistory.removeLast();

    // Write to Firestore with canonical docId
    _writeReading(HealthReading(
      id: docId,
      userId: userId!,
      metric: HealthReading.heartRate,
      value: bpm,
      date: HealthReading.todayDate(),
      timestamp: now,
    ));

    _refreshDailyScore();
    notifyListeners();
  }

  void removeHeartRateReading(HeartRateReading reading) {
    if (userId == null) return;

    heartRateHistory.remove(reading);
    heartRate = heartRateHistory.isNotEmpty ? heartRateHistory.first.bpm : 0.0;

    if (reading.id.isNotEmpty) {
      FirestoreService.instance.deleteReading(userId!, reading.id).catchError((e) {
        debugPrint('🔥 [HealthData] removeHeartRateReading deleteReading ERROR: $e');
      });
    } else {
      FirestoreService.instance.deleteMatchingReading(
        uid: userId!,
        metric: HealthReading.heartRate,
        timestamp: reading.timestamp,
        value: reading.bpm,
      ).catchError((e) {
        debugPrint('🔥 [HealthData] removeHeartRateReading deleteMatchingReading ERROR: $e');
      });
    }

    _refreshDailyScore();
    notifyListeners();
  }

  List<HeartRateReading> getLastWeekHeartRateReadings() {
    if (heartRateHistory.isEmpty) return [];
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    return heartRateHistory
        .where((r) => r.timestamp.isAfter(sevenDaysAgo))
        .toList();
  }

  List<HeartRateReading> getLastMonthHeartRateReadings() {
    if (heartRateHistory.isEmpty) return [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 29));
    return heartRateHistory
        .where((r) => r.timestamp.isAfter(thirtyDaysAgo))
        .toList();
  }

  List<BloodSugarReading> getLastWeekReadings() {
    if (bloodSugarHistory.isEmpty) return [];
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    return bloodSugarHistory
        .where((r) => r.date.isAfter(sevenDaysAgo))
        .toList();
  }

  List<BloodSugarReading> getLastMonthReadings() {
    if (bloodSugarHistory.isEmpty) return [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 29));
    return bloodSugarHistory
        .where((r) => r.date.isAfter(thirtyDaysAgo))
        .toList();
  }

  void toggleReminder(ReminderItem reminder) {
    reminder.enabled = !reminder.enabled;
    notifyListeners();
  }
}

// RECORD CLASSES
class DailyStepRecord {
  final DateTime date;
  final int steps;
  DailyStepRecord({required this.date, required this.steps});
}

class DailySleepRecord {
  final DateTime date;
  final double hours;
  DailySleepRecord({required this.date, required this.hours});
}

class DailyWaterRecord {
  final DateTime date;
  final int amount;
  DailyWaterRecord({required this.date, required this.amount});
}

class BloodSugarReading {
  final String id;
  final DateTime date;
  final double value;
  BloodSugarReading({this.id = '', required this.date, required this.value});
}

class SleepReading {
  final String id;
  final DateTime date;
  final double hours;
  SleepReading({this.id = '', required this.date, required this.hours});
}

class BloodPressureReading {
  final String id;
  final int systolic;
  final int diastolic;
  final DateTime timestamp;
  BloodPressureReading({
    this.id = '',
    required this.systolic,
    required this.diastolic,
    required this.timestamp,
  });
}

class WaterIntakeReading {
  final String id;
  final int amount;
  final DateTime timestamp;
  WaterIntakeReading({this.id = '', required this.amount, required this.timestamp});
}

class HeartRateReading {
  final String id;
  final double bpm;
  final DateTime timestamp;
  HeartRateReading({this.id = '', required this.bpm, required this.timestamp});
}

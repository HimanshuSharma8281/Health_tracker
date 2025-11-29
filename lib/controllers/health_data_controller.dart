import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/activity_models.dart';
import '../models/social_models.dart';
import '../models/analytics_models.dart';
import '../services/ai_insight_engine.dart';
import '../services/goal_planner.dart';
import '../services/predictive_analytics.dart';
import '../services/social_service.dart';
import '../services/step_tracking_service.dart';

class HealthDataController extends ChangeNotifier {
  final Random _random = Random();
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

  DateTime _lastResetDate = DateTime.now();

  List<DailyStepRecord> stepHistory = [];
  List<DailySleepRecord> sleepHistory = [];
  List<DailyWaterRecord> waterHistory = [];

  String pedestrianStatus = 'unknown';
  String? userId;
  String? username;
  int userScore = 0;
  int userRank = 0;

  bool _isDataLoaded = false;

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
    // If same user, don't reload
    if (userId == id && _isDataLoaded) {
      return;
    }

    // Clear all data before loading new user
    _clearAllLocalData();

    userId = id;
    username = name;
    _isDataLoaded = false;

    print('🔥 User info set: ID=$id, Name=$name');

    // Load user-specific data
    _loadUserData();

    notifyListeners();
  }

  void clearUserInfo() {
    // Save current user's data before clearing
    if (userId != null) {
      _saveCurrentData();
      _saveHistoryData();
    }

    // Clear everything
    _clearAllLocalData();

    userId = null;
    username = null;
    userScore = 0;
    userRank = 0;
    _isDataLoaded = false;

    print('🔥 User info cleared');
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
    history.clear();
    reminders.clear();
    challenges.clear();

    // Reset goals to defaults
    stepGoal = 10000;
    waterGoal = 2500;
    calorieGoal = 2000;
    sleepGoal = 8.0;
  }

  // Load user-specific data from SharedPreferences
  Future<void> _loadUserData() async {
    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'user_${userId}_';

      // Load step history
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

      // Load sleep history
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

      // Load water history
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
      stepGoal = prefs.getInt('${prefix}step_goal') ?? 10000;
      waterGoal = prefs.getInt('${prefix}water_goal') ?? 2500;
      calorieGoal = prefs.getDouble('${prefix}calorie_goal') ?? 2000;
      sleepGoal = prefs.getDouble('${prefix}sleep_goal') ?? 8.0;

      // Check if today's data exists
      final savedDate = prefs.getString('${prefix}current_date');
      final today = DateTime.now().toIso8601String().substring(0, 10);

      if (savedDate == today) {
        // Same day - restore current values
        stepsToday = prefs.getInt('${prefix}current_steps') ?? 0;
        waterMl = prefs.getInt('${prefix}current_water') ?? 0;
        sleepHours = prefs.getDouble('${prefix}current_sleep') ?? 0.0;
        caloriesConsumed = prefs.getDouble('${prefix}current_calories') ?? 0.0;
      } else if (savedDate != null) {
        // New day - save yesterday's data to history first
        final yesterdaySteps = prefs.getInt('${prefix}current_steps') ?? 0;
        final yesterdayWater = prefs.getInt('${prefix}current_water') ?? 0;
        final yesterdaySleep = prefs.getDouble('${prefix}current_sleep') ?? 0.0;

        if (yesterdaySteps > 0) {
          final yesterdayDate = DateTime.tryParse(savedDate) ??
              DateTime.now().subtract(const Duration(days: 1));
          stepHistory
              .add(DailyStepRecord(date: yesterdayDate, steps: yesterdaySteps));
          if (stepHistory.length > 30) stepHistory.removeAt(0);
        }

        if (yesterdayWater > 0) {
          final yesterdayDate = DateTime.tryParse(savedDate) ??
              DateTime.now().subtract(const Duration(days: 1));
          waterHistory.add(
              DailyWaterRecord(date: yesterdayDate, amount: yesterdayWater));
          if (waterHistory.length > 30) waterHistory.removeAt(0);
        }

        if (yesterdaySleep > 0) {
          final yesterdayDate = DateTime.tryParse(savedDate) ??
              DateTime.now().subtract(const Duration(days: 1));
          sleepHistory.add(
              DailySleepRecord(date: yesterdayDate, hours: yesterdaySleep));
          if (sleepHistory.length > 30) sleepHistory.removeAt(0);
        }

        // Reset today's values
        stepsToday = 0;
        waterMl = 0;
        sleepHours = 0;
        caloriesConsumed = 0;

        // Save history
        await _saveHistoryData();
      }

      // Update current date
      await prefs.setString('${prefix}current_date', today);

      _isDataLoaded = true;
      _loadInsights();
      notifyListeners();

      print('🔥 User data loaded for: $userId');
    } catch (e) {
      print('Error loading user data: $e');
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
    } catch (e) {
      print('Error saving goals: $e');
    }
  }

  // GOAL UPDATE METHODS
  void updateStepGoal(int goal) {
    stepGoal = goal;
    _saveGoals();
    notifyListeners();
  }

  void updateWaterGoal(int goal) {
    waterGoal = goal;
    _saveGoals();
    notifyListeners();
  }

  void updateCalorieGoal(double goal) {
    calorieGoal = goal;
    _saveGoals();
    notifyListeners();
  }

  void updateSleepGoal(double goal) {
    sleepGoal = goal;
    _saveGoals();
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
    if (stepsToday >= stepGoal)
      insights.add('Great job! You hit your step goal today 🎉');
    if (caloriesConsumed < calorieGoal * 0.8 && caloriesConsumed > 0)
      insights.add('You might need more calories to meet your daily goal');
    if (waterMl >= waterGoal)
      insights.add('Excellent hydration! Keep it up 💧');
    if (sleepHours >= sleepGoal)
      insights.add('Perfect sleep! You\'re well rested 😴');
    return insights.take(3).toList();
  }

  bool get isLoadingInsights => _isLoadingInsights;
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

  void loadProfile(UserProfile profile) {
    this.profile = profile;
  }

  void clearProfile() {
    profile = null;
    notifyListeners();
  }

  Future<void> refreshDailyMetrics() async {
    await Future.delayed(const Duration(milliseconds: 600));
    notifyListeners();
    await _loadInsights();
  }

  void addWater(int milliliters) {
    if (userId == null) return;

    waterMl += milliliters;
    rewardPoints += 5;

    if (milliliters > 0) {
      waterIntakeHistory.add(
          WaterIntakeReading(amount: milliliters, timestamp: DateTime.now()));
      if (waterIntakeHistory.length > 50) waterIntakeHistory.removeAt(0);
    }

    _updateTodayInHistory();
    _saveCurrentData();

    if (username != null) _updateSocialScore();
    notifyListeners();
  }

  void addSleepReading(double hours) {
    if (userId == null) return;

    sleepHours += hours;
    sleepReadingHistory.add(SleepReading(date: DateTime.now(), hours: hours));
    if (sleepReadingHistory.length > 30) sleepReadingHistory.removeAt(0);

    _updateTodayInHistory();
    _saveCurrentData();

    if (username != null) _updateSocialScore();
    notifyListeners();
  }

  void logMeal(MealEntry meal) {
    if (userId == null) return;

    meals.insert(0, meal);
    caloriesConsumed += meal.calories;
    rewardPoints += 8;
    _updateTodayInHistory();
    _saveCurrentData();
    if (username != null) _updateSocialScore();
    notifyListeners();
  }

  void removeMeal(MealEntry meal) {
    meals.remove(meal);
    caloriesConsumed -= meal.calories;
    if (caloriesConsumed < 0) caloriesConsumed = 0;
    _updateTodayInHistory();
    _saveCurrentData();
    notifyListeners();
  }

  void removeSleepReading(SleepReading reading) {
    sleepReadingHistory.remove(reading);
    sleepHours = (sleepHours - reading.hours).clamp(0.0, 24.0);
    _updateTodayInHistory();
    _saveCurrentData();
    notifyListeners();
  }

  void removeWaterIntake(WaterIntakeReading reading) {
    waterIntakeHistory.remove(reading);
    waterMl -= reading.amount;
    if (waterMl < 0) waterMl = 0;
    _updateTodayInHistory();
    _saveCurrentData();
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
    if (username != null) _updateSocialScore();
    notifyListeners();
  }

  void _updateTodayInHistory() {
    if (history.isNotEmpty) {
      final now = DateTime.now();
      final lastEntry = history.last;
      final lastEntryDate = DateTime(
          lastEntry.date.year, lastEntry.date.month, lastEntry.date.day);
      final today = DateTime(now.year, now.month, now.day);

      if (lastEntryDate.isAtSameMomentAs(today)) {
        history[history.length - 1] = ActivityEntry(
          date: lastEntry.date,
          steps: stepsToday,
          calories: caloriesConsumed.round(),
          sleepHours: sleepHours,
          waterMl: waterMl,
          stressLevel: stressLevel,
          mindfulnessMinutes: mindfulnessMinutes,
        );
      }
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
    } catch (e) {
      print('Error updating social score: $e');
    }
  }

  void addBloodPressureReading(int systolic, int diastolic) {
    if (userId == null) return;

    _systolic = systolic;
    _diastolic = diastolic;
    bloodPressureHistory.insert(
        0,
        BloodPressureReading(
          systolic: systolic,
          diastolic: diastolic,
          timestamp: DateTime.now(),
        ));
    if (bloodPressureHistory.length > 30) bloodPressureHistory.removeLast();
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

    bloodSugar = value;
    bloodSugarHistory
        .add(BloodSugarReading(date: DateTime.now(), value: value));
    if (bloodSugarHistory.length > 30) bloodSugarHistory.removeAt(0);
    notifyListeners();
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
  final DateTime date;
  final double value;
  BloodSugarReading({required this.date, required this.value});
}

class SleepReading {
  final DateTime date;
  final double hours;
  SleepReading({required this.date, required this.hours});
}

class BloodPressureReading {
  final int systolic;
  final int diastolic;
  final DateTime timestamp;
  BloodPressureReading(
      {required this.systolic,
      required this.diastolic,
      required this.timestamp});
}

class WaterIntakeReading {
  final int amount;
  final DateTime timestamp;
  WaterIntakeReading({required this.amount, required this.timestamp});
}

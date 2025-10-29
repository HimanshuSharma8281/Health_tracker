import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../models/activity_models.dart';
import '../models/social_models.dart';
import '../models/analytics_models.dart';
import '../services/ai_insight_engine.dart';
import '../services/goal_planner.dart';
import '../services/predictive_analytics.dart';

class HealthDataController extends ChangeNotifier {
  final Random _random = Random();
  UserProfile? profile;
  int stepsToday = 0;
  int stepGoal = 11000;
  int waterMl = 0;
  int waterGoal = 2800;
  int caloriesConsumed = 0;
  int calorieGoal = 2200;
  double sleepHours = 7.2;
  double sleepGoal = 7.5;
  double heartRate = 72;
  double stressLevel = 0.34;
  int mindfulnessMinutes = 14;
  int rewardPoints = 420;
  int streakDays = 8;
  String? lastFoodLabel;
  int? lastFoodCalories;
  final List<ActivityEntry> history = [];
  final List<MealEntry> meals = [];
  final List<ReminderItem> reminders = [];
  final List<Challenge> challenges = [];

  final List<MindfulnessSession> sessions = [];
  final List<LeaderboardEntry> leaderboard = [];
  final List<DeviceSyncItem> devices = [];

  List<String> _cachedInsights = [];
  bool _isLoadingInsights = false;

  HealthDataController() {
    _seedData();
    _loadInsights(); // Load insights on initialization
  }

  List<FlSpot> get stepTrend => List.generate(history.length,
      (index) => FlSpot(index.toDouble(), history[index].steps.toDouble()));

  List<String> get topInsights => _cachedInsights;
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

  void loadProfile(UserProfile profile) {
    this.profile = profile;
    devices
      ..clear()
      ..addAll(profile.devices
          .map((name) => DeviceSyncItem(name: name, connected: true)));
    notifyListeners();
  }

  void clearProfile() {
    profile = null;
    notifyListeners();
  }

  Future<void> refreshDailyMetrics() async {
    await Future.delayed(const Duration(milliseconds: 600));
    stepsToday = 8500 + _random.nextInt(4500);
    waterMl = 2000 + _random.nextInt(1200);
    caloriesConsumed = 1700 + _random.nextInt(800);
    sleepHours =
        double.parse((6 + _random.nextDouble() * 3).toStringAsFixed(1));
    stressLevel =
        double.parse((0.25 + _random.nextDouble() * 0.35).toStringAsFixed(2));
    heartRate = (62 + _random.nextInt(25)).toDouble();
    mindfulnessMinutes = 12 + _random.nextInt(12);
    history.removeAt(0);
    history.add(ActivityEntry(
      date: DateTime.now(),
      steps: stepsToday,
      calories: caloriesConsumed,
      sleepHours: sleepHours,
      waterMl: waterMl,
      stressLevel: stressLevel,
      mindfulnessMinutes: mindfulnessMinutes,
    ));
    notifyListeners();

    // Refresh AI insights after updating metrics
    await _loadInsights();
  }

  void incrementWater(int amount) {
    waterMl += amount;
    rewardPoints += 5;
    notifyListeners();
  }

  void logMeal(MealEntry meal) {
    meals.insert(0, meal);
    caloriesConsumed += meal.calories;
    rewardPoints += 8;
    notifyListeners();
  }

  void removeMeal(MealEntry meal) {
    meals.remove(meal);
    caloriesConsumed -= meal.calories;
    if (caloriesConsumed < 0) caloriesConsumed = 0;
    notifyListeners();
  }

  Future<int> estimateCaloriesFromImage(XFile file) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final sampleLabels = [
      'Protein Bowl',
      'Avocado Toast',
      'Grilled Salmon',
      'Quinoa Salad',
      'Berry Smoothie'
    ];
    final calories = 280 + _random.nextInt(320);
    lastFoodLabel = sampleLabels[_random.nextInt(sampleLabels.length)];
    lastFoodCalories = calories;
    logMeal(MealEntry(
        name: lastFoodLabel!, calories: calories, time: DateTime.now()));
    return calories;
  }

  void toggleReminder(ReminderItem reminder) {
    reminder.enabled = !reminder.enabled;
    notifyListeners();
  }

  void toggleDevice(DeviceSyncItem device) {
    device.connected = !device.connected;
    notifyListeners();
  }

  void completeMindfulnessSession(MindfulnessSession session) {
    mindfulnessMinutes += session.duration;
    rewardPoints += 15;
    adjustStress(-0.07);
    notifyListeners();
  }

  void adjustStress(double delta) {
    stressLevel = (stressLevel + delta).clamp(0.05, 0.95);
    notifyListeners();
  }

  void updateHeartRate(double value) {
    heartRate = value;
    notifyListeners();
  }

  void incrementChallenge(Challenge challenge) {
    challenge.progress = min(challenge.target, challenge.progress + 1);
    notifyListeners();
  }

  void _seedData() {
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final steps = 7800 + _random.nextInt(4200);
      final calories = 1800 + _random.nextInt(700);
      final sleep =
          double.parse((6 + _random.nextDouble() * 2.8).toStringAsFixed(1));
      final water = 2100 + _random.nextInt(900);
      final stress =
          double.parse((0.25 + _random.nextDouble() * 0.35).toStringAsFixed(2));
      final mindful = 10 + _random.nextInt(12);
      history.add(ActivityEntry(
          date: date,
          steps: steps,
          calories: calories,
          sleepHours: sleep,
          waterMl: water,
          stressLevel: stress,
          mindfulnessMinutes: mindful));
    }
    stepsToday = history.last.steps;
    waterMl = history.last.waterMl;
    caloriesConsumed = history.last.calories;
    sleepHours = history.last.sleepHours;
    mindfulnessMinutes = history.last.mindfulnessMinutes;
    reminders
      ..add(ReminderItem(
          title: 'Hydration Boost',
          time: const TimeOfDay(hour: 10, minute: 30),
          type: ReminderType.hydration))
      ..add(ReminderItem(
          title: 'Midday Fuel',
          time: const TimeOfDay(hour: 13, minute: 0),
          type: ReminderType.meal))
      ..add(ReminderItem(
          title: 'Sunset Run',
          time: const TimeOfDay(hour: 18, minute: 15),
          type: ReminderType.workout))
      ..add(ReminderItem(
          title: 'Wind Down',
          time: const TimeOfDay(hour: 21, minute: 30),
          type: ReminderType.sleep));
    challenges
      ..add(Challenge(
          title: '70000 Step Sprint',
          progress: 56,
          target: 70,
          members: const ['You', 'Evan', 'Priya']))
      ..add(Challenge(
          title: 'Hydration Heroes',
          progress: 18,
          target: 21,
          members: const ['You', 'Alexis', 'Kai']))
      ..add(Challenge(
          title: 'Mindful May',
          progress: 9,
          target: 14,
          members: const ['You', 'Mira', 'Leo']));

    sessions
      ..add(MindfulnessSession(
          title: 'Morning Alignment', duration: 8, focus: 'Energy'))
      ..add(MindfulnessSession(
          title: 'Focused Flow', duration: 12, focus: 'Productivity'))
      ..add(MindfulnessSession(
          title: 'Evening Release', duration: 10, focus: 'Recovery'));
    leaderboard
      ..add(LeaderboardEntry(name: 'Jordan Parker', score: 540, streak: 8))
      ..add(LeaderboardEntry(name: 'Alexis Reed', score: 520, streak: 6))
      ..add(LeaderboardEntry(name: 'Priya Singh', score: 498, streak: 5))
      ..add(LeaderboardEntry(name: 'Evan Moore', score: 470, streak: 4));
    devices
      ..add(DeviceSyncItem(name: 'Pixel Watch'))
      ..add(DeviceSyncItem(name: 'Oura Ring', connected: false))
      ..add(DeviceSyncItem(name: 'iPhone', connected: true))
      ..add(DeviceSyncItem(name: 'Web Dashboard', connected: true));
    meals
      ..add(MealEntry(
          name: 'Steel-cut oats',
          calories: 360,
          time: DateTime.now().subtract(const Duration(hours: 5))))
      ..add(MealEntry(
          name: 'Grilled chicken salad',
          calories: 540,
          time: DateTime.now().subtract(const Duration(hours: 2))))
      ..add(MealEntry(
          name: 'Matcha latte',
          calories: 180,
          time:
              DateTime.now().subtract(const Duration(hours: 1, minutes: 10))));
  }

  // Load AI insights asynchronously
  Future<void> _loadInsights() async {
    if (_isLoadingInsights) return;

    _isLoadingInsights = true;
    notifyListeners();

    try {
      _cachedInsights = await AIInsightEngine.generate(this);
    } catch (e) {
      print('Error loading insights: $e');
      _cachedInsights = [
        'Stay hydrated and keep moving toward your goals.',
        'Great progress today! Keep up the momentum.',
        'Balance is key. Make time for rest and recovery.',
      ];
    }

    _isLoadingInsights = false;
    notifyListeners();
  }

  // Refresh insights manually
  Future<void> refreshInsights() async {
    await _loadInsights();
  }
}

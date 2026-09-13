import 'package:flutter/material.dart';

class ActivityEntry {
  ActivityEntry({
    required this.date,
    required this.steps,
    required this.calories,
    required this.sleepHours,
    required this.waterMl,
    required this.stressLevel,
    required this.mindfulnessMinutes,
  });

  final DateTime date;
  final int steps;
  final int calories;
  final double sleepHours;
  final int waterMl;
  final double stressLevel;
  final int mindfulnessMinutes;
}

class MealEntry {
  MealEntry({
    this.id = '',
    required this.name,
    required this.calories,
    required this.time,
    this.mealType = MealType.snack, // default to snack
  });

  final String id;
  final String name;
  final int calories;
  final DateTime time;
  final MealType mealType;
}

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  IconData get icon {
    switch (this) {
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.cookie;
    }
  }

  Color get color {
    switch (this) {
      case MealType.breakfast:
        return const Color(0xFFFFB300);
      case MealType.lunch:
        return const Color(0xFF00C853);
      case MealType.dinner:
        return const Color(0xFFD500F9);
      case MealType.snack:
        return const Color(0xFFFF6D00);
    }
  }
}

enum ReminderType {
  meal,
  workout,
  hydration,
  sleep,
}

extension ReminderTypeExtension on ReminderType {
  String get label {
    switch (this) {
      case ReminderType.meal:
        return 'Meal';
      case ReminderType.workout:
        return 'Workout';
      case ReminderType.hydration:
        return 'Hydration';
      case ReminderType.sleep:
        return 'Sleep';
    }
  }
}

class ReminderItem {
  final String title;
  final TimeOfDay time;
  final ReminderType type;
  bool enabled;

  ReminderItem({
    required this.title,
    required this.time,
    required this.type,
    this.enabled = true,
  });
}

class MindfulnessSession {
  MindfulnessSession({
    required this.title,
    required this.duration,
    required this.focus,
  });

  final String title;
  final int duration;
  final String focus;
}

class DeviceSyncItem {
  DeviceSyncItem({required this.name, this.connected = true});

  final String name;
  bool connected;
}

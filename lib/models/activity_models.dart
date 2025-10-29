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
  MealEntry({required this.name, required this.calories, required this.time});

  final String name;
  final int calories;
  final DateTime time;
}

enum ReminderType { meal, workout, hydration, sleep }

extension ReminderTypeLabel on ReminderType {
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
  ReminderItem({
    required this.title,
    required this.time,
    required this.type,
    this.enabled = true,
  });

  final String title;
  final TimeOfDay time;
  final ReminderType type;
  bool enabled;
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

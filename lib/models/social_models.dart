import 'package:flutter/material.dart';

class Challenge {
  final String title;
  int progress;
  final int target;
  final List<String> members;

  Challenge({
    required this.title,
    required this.progress,
    required this.target,
    required this.members,
  });
}

class Badge {
  Badge({
    required this.label,
    required this.description,
    required this.unlocked,
    required this.icon,
  });

  final String label;
  final String description;
  final bool unlocked;
  final IconData icon;
}

class LeaderboardEntry {
  final String name;
  final int score;
  final int streak;

  LeaderboardEntry({
    required this.name,
    required this.score,
    required this.streak,
  });
}

class DeviceSyncItem {
  final String name;
  bool connected;

  DeviceSyncItem({
    required this.name,
    this.connected = false,
  });
}

class MindfulnessSession {
  final String title;
  final int duration;
  final String focus;

  MindfulnessSession({
    required this.title,
    required this.duration,
    required this.focus,
  });
}

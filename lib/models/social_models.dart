import 'package:flutter/material.dart';

class Challenge {
  Challenge({
    required this.title,
    required this.progress,
    required this.target,
    required this.members,
  });

  final String title;
  int progress;
  final int target;
  final List<String> members;
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
  LeaderboardEntry({
    required this.name,
    required this.score,
    required this.streak,
  });

  final String name;
  final int score;
  final int streak;
}

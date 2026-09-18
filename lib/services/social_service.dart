import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_reading.dart';

class SocialService {
  static DatabaseReference get _database => FirebaseDatabase.instance.ref();
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _resetFlagKey = 'challenges_reset_20260912_v1';

  // Update user's daily score
  static Future<void> updateUserScore({
    required String userId,
    required String username,
    required int steps,
    required int waterMl,
    required double calories,
    required double sleepHours,
  }) async {
    // Calculate health score (0-100 scale)
    final score = _calculateHealthScore(
      steps: steps,
      waterMl: waterMl,
      calories: calories,
      sleepHours: sleepHours,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    try {
      await _database.child('users/$userId').update({
        'username': username,
        'score': score,
        'steps': steps,
        'waterMl': waterMl,
        'calories': calories,
        'sleepHours': sleepHours,
        'lastUpdated': ServerValue.timestamp,
        'date': today,
      });
    } on FirebaseException catch (e) {
      debugPrint('🏆 [SocialService] updateUserScore FAILED for uid=$userId: code=${e.code} message=${e.message}');
    } catch (e) {
      debugPrint('🏆 [SocialService] updateUserScore ERROR for uid=$userId: $e');
    }
  }

  // Calculate health score based on metrics
  static int _calculateHealthScore({
    required int steps,
    required int waterMl,
    required double calories,
    required double sleepHours,
  }) {
    int score = 0;

    // Steps (max 30 points)
    score += ((steps / 10000) * 30).clamp(0, 30).toInt();

    // Water (max 20 points)
    score += ((waterMl / 2500) * 20).clamp(0, 20).toInt();

    // Calories (max 25 points) - ideal range 1800-2200
    final calorieScore = calories >= 1800 && calories <= 2200
        ? 25
        : (25 - ((calories - 2000).abs() / 100)).clamp(0, 25);
    score += calorieScore.toInt();

    // Sleep (max 25 points)
    score += ((sleepHours / 8) * 25).clamp(0, 25).toInt();

    return score.clamp(0, 100);
  }

  // Get leaderboard
  static Stream<List<LeaderboardUser>> getLeaderboard() {
    return _database
        .child('users')
        .orderByChild('score')
        .limitToLast(20)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <LeaderboardUser>[];

      final users = <LeaderboardUser>[];
      data.forEach((key, value) {
        if (value is Map) {
          users.add(
              LeaderboardUser.fromMap(key, Map<String, dynamic>.from(value)));
        }
      });

      // Sort by score descending
      users.sort((a, b) => b.score.compareTo(a.score));
      return users;
    });
  }

  /// Permanently removes a user's record from Realtime Database.
  static Future<void> deleteUserScore(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _database.child('users/$userId').remove();
      debugPrint('🗑️ [SocialService] Deleted Realtime Database user entry for uid=$userId');
    } on FirebaseException catch (e) {
      debugPrint('⚠️ [SocialService] deleteUserScore FirebaseException: code=${e.code} msg=${e.message}');
    } catch (e) {
      debugPrint('⚠️ [SocialService] deleteUserScore note: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // CHALLENGE MANAGEMENT & RESET (NEW CLEAN ARCHITECTURE)
  // ════════════════════════════════════════════════════════════════════════

  /// Checks if the one-time cleanup of old challenge data has executed.
  /// If not, deletes all old challenges from Firestore so challenges start from 0.
  static Future<void> checkAndClearOldChallengesOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasReset = prefs.getBool(_resetFlagKey) ?? false;
      if (!hasReset) {
        debugPrint('🧹 [SocialService] Performing one-time cleanup of old challenge data...');
        await clearAllOldChallenges();
        await prefs.setBool(_resetFlagKey, true);
        debugPrint('✅ [SocialService] Old challenge data successfully cleared. System starting from zero.');
      }
    } catch (e) {
      debugPrint('🔴 [SocialService] checkAndClearOldChallengesOnce ERROR: $e');
    }
  }

  /// Completely clears all old challenge documents from Firestore.
  /// Preserves all user profiles, healthReadings, dailyScores, and global leaderboards.
  static Future<int> clearAllOldChallenges() async {
    try {
      final snapshot = await _firestore.collection('challenges').get();
      if (snapshot.docs.isEmpty) {
        debugPrint('🏆 [SocialService] clearAllOldChallenges: No old challenges to delete.');
        return 0;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('🏆 [SocialService] clearAllOldChallenges: Deleted ${snapshot.docs.length} old challenge documents.');
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('🔴 [SocialService] clearAllOldChallenges ERROR: $e');
      return 0;
    }
  }

  /// Create a new challenge starting from now.
  static Future<void> createChallenge({
    required String challengeId,
    required String title,
    required String creatorId,
    required String creatorName,
    required int targetValue,
    required String metricType, // 'steps', 'water', 'calories', 'sleep'
    String rankingType = 'highest', // 'highest', 'closestToTarget'
    String description = '',
    DateTime? startDate,
    required DateTime endDate,
    int initialProgress = 0,
  }) async {
    final start = startDate ?? DateTime.now();
    final todayKey = HealthReading.todayDate();

    await _firestore.collection('challenges').doc(challengeId).set({
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'targetValue': targetValue,
      'metricType': metricType,
      'rankingType': rankingType,
      'startDate': Timestamp.fromDate(start),
      'endDate': Timestamp.fromDate(endDate),
      'participants': [creatorId],
      'participantNames': {creatorId: creatorName},
      'progress': {creatorId: initialProgress},
      'dailyProgress': {
        creatorId: {todayKey: initialProgress}
      },
      'joinedAt': {creatorId: FieldValue.serverTimestamp()},
      'lastUpdated': {creatorId: FieldValue.serverTimestamp()},
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    debugPrint('✅ [SocialService] Challenge created: id=$challengeId title="$title" metric=$metricType target=$targetValue ranking=$rankingType');
  }

  /// Join an existing active challenge. Prevents duplicate joining or joining expired challenges.
  /// Initializes participant's progress from their actual current day total.
  static Future<void> joinChallenge({
    required String challengeId,
    required String userId,
    required String username,
    int initialProgress = 0,
  }) async {
    final docRef = _firestore.collection('challenges').doc(challengeId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception('Challenge not found');

    final data = doc.data()!;
    final isActive = data['isActive'] as bool? ?? true;
    final endDate = (data['endDate'] as Timestamp).toDate();

    if (!isActive || DateTime.now().isAfter(endDate)) {
      throw Exception('This challenge has already ended and cannot be joined.');
    }

    final participants = List<String>.from(data['participants'] ?? []);
    if (participants.contains(userId)) {
      throw Exception('You are already a participant in this challenge.');
    }

    final todayKey = HealthReading.todayDate();

    await docRef.update({
      'participants': FieldValue.arrayUnion([userId]),
      'participantNames.$userId': username,
      'progress.$userId': initialProgress,
      'dailyProgress.$userId': {todayKey: initialProgress},
      'joinedAt.$userId': FieldValue.serverTimestamp(),
      'lastUpdated.$userId': FieldValue.serverTimestamp(),
    });
    debugPrint('✅ [SocialService] User $userId ($username) joined challenge $challengeId with initialProgress=$initialProgress');
  }

  /// Normalizes any metric name variant into canonical format.
  static String normalizeMetricType(String metric) {
    final m = metric.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (m) {
      case 'step':
      case 'steps':
        return 'steps';
      case 'water':
      case 'water_intake':
      case 'waterintake':
      case 'water_ml':
        return 'water';
      case 'calorie':
      case 'calories':
      case 'calories_burned':
      case 'diet':
      case 'meals':
        return 'calories';
      case 'sleep':
      case 'sleep_hours':
      case 'sleep_duration':
        return 'sleep';
      case 'heart_rate':
      case 'heartrate':
      case 'heart':
      case 'bpm':
        return 'heart_rate';
      case 'blood_pressure':
      case 'bloodpressure':
      case 'bp':
      case 'systolic':
        return 'blood_pressure';
      case 'blood_sugar':
      case 'bloodsugar':
      case 'glucose':
      case 'sugar':
        return 'blood_sugar';
      case 'mindfulness':
      case 'meditation':
        return 'mindfulness';
      default:
        return m;
    }
  }

  /// Synchronize real health readings for a user into all active challenges they participate in.
  ///
  /// Continuously aggregates the user's daily total without overwriting historical days,
  /// strictly bounded within the challenge's active date window.
  static Future<void> syncUserChallengeProgress({
    required String userId,
    required String metricType,
    required int todayTotal,
    String? date,
  }) async {
    if (userId.isEmpty) return;

    try {
      final dateKey = date ?? HealthReading.todayDate();
      final targetMetric = normalizeMetricType(metricType);

      final snapshot = await _firestore
          .collection('challenges')
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      final now = DateTime.now();
      bool hasUpdates = false;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final docMetric = normalizeMetricType(data['metricType']?.toString() ?? '');
        if (docMetric != targetMetric) continue;

        // Check expiration
        final endDate = (data['endDate'] as Timestamp?)?.toDate();
        if (endDate != null && now.isAfter(endDate)) {
          batch.update(doc.reference, {'isActive': false});
          hasUpdates = true;
          continue;
        }

        // Check if owner has left
        final creatorId = data['creatorId'] as String? ?? '';
        final participants = List<String>.from(data['participants'] ?? []);
        if (creatorId.isNotEmpty && !participants.contains(creatorId)) {
          batch.update(doc.reference, {'isActive': false});
          hasUpdates = true;
          continue;
        }

        final startDate = (data['startDate'] as Timestamp?)?.toDate();
        final startDay = startDate != null
            ? DateTime(startDate.year, startDate.month, startDate.day)
            : null;
        final endDay = endDate != null
            ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
            : null;

        // Get user's daily progress map
        final dailyMapRaw = (data['dailyProgress'] as Map<String, dynamic>?)?[userId];
        final userDailyMap = <String, int>{};
        if (dailyMapRaw is Map) {
          dailyMapRaw.forEach((k, v) {
            if (v is num) userDailyMap[k.toString()] = v.toInt();
          });
        }

        // Update today's total
        userDailyMap[dateKey] = todayTotal;

        // Cumulative progress across all days within the challenge window
        int cumulativeTotal = 0;
        for (final entry in userDailyMap.entries) {
          final entryDate = DateTime.tryParse(entry.key);
          if (entryDate != null) {
            final entryDay = DateTime(entryDate.year, entryDate.month, entryDate.day);
            if (startDay != null && entryDay.isBefore(startDay)) continue;
            if (endDay != null && entryDay.isAfter(endDay)) continue;
          }
          cumulativeTotal += entry.value;
        }

        batch.update(doc.reference, {
          'progress.$userId': cumulativeTotal,
          'dailyProgress.$userId': userDailyMap,
          'lastUpdated.$userId': FieldValue.serverTimestamp(),
        });
        hasUpdates = true;
      }

      if (hasUpdates) {
        await batch.commit();
        debugPrint('🏆 [SocialService] Synced $targetMetric progress for uid=$userId | today=$todayTotal units');
      }
    } catch (e) {
      debugPrint('🔴 [SocialService] syncUserChallengeProgress ERROR for uid=$userId: $e');
    }
  }

  /// Real-time stream of a single challenge by ID.
  static Stream<ChallengeData?> getChallengeStream(String challengeId) {
    return _firestore
        .collection('challenges')
        .doc(challengeId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return ChallengeData.fromFirestore(snapshot);
    });
  }

  /// Batch sync all metrics for a user from controller state into active challenges.
  static Future<void> syncAllActiveChallengesForUser({
    required String userId,
    required int waterMl,
    required int stepsToday,
    required int caloriesConsumed,
    required double sleepHours,
    int? heartRate,
    int? systolic,
    int? bloodSugar,
    int? mindfulnessMinutes,
  }) async {
    if (userId.isEmpty) return;

    try {
      final futures = <Future<void>>[
        syncUserChallengeProgress(userId: userId, metricType: 'water', todayTotal: waterMl),
        syncUserChallengeProgress(userId: userId, metricType: 'steps', todayTotal: stepsToday),
        syncUserChallengeProgress(userId: userId, metricType: 'calories', todayTotal: caloriesConsumed),
        syncUserChallengeProgress(userId: userId, metricType: 'sleep', todayTotal: sleepHours.round()),
      ];
      if (heartRate != null && heartRate > 0) {
        futures.add(syncUserChallengeProgress(userId: userId, metricType: 'heart_rate', todayTotal: heartRate));
      }
      if (systolic != null && systolic > 0) {
        futures.add(syncUserChallengeProgress(userId: userId, metricType: 'blood_pressure', todayTotal: systolic));
      }
      if (bloodSugar != null && bloodSugar > 0) {
        futures.add(syncUserChallengeProgress(userId: userId, metricType: 'blood_sugar', todayTotal: bloodSugar));
      }
      if (mindfulnessMinutes != null && mindfulnessMinutes > 0) {
        futures.add(syncUserChallengeProgress(userId: userId, metricType: 'mindfulness', todayTotal: mindfulnessMinutes));
      }

      await Future.wait(futures);
    } catch (e) {
      debugPrint('🔴 [SocialService] syncAllActiveChallengesForUser ERROR: $e');
    }
  }

  /// Leave an existing challenge. If owner leaves, terminates challenge canonical state.
  static Future<void> leaveChallenge({
    required String challengeId,
    required String userId,
  }) async {
    final docRef = _firestore.collection('challenges').doc(challengeId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};
    final creatorId = data['creatorId'] as String? ?? '';
    final isOwner = creatorId == userId;

    if (isOwner) {
      // If owner/creator leaves, the competition is terminated/marked inactive and removed from Browse All
      await docRef.update({
        'isActive': false,
        'terminatedAt': FieldValue.serverTimestamp(),
        'participants': FieldValue.arrayRemove([userId]),
        'participantNames.$userId': FieldValue.delete(),
        'progress.$userId': FieldValue.delete(),
        'dailyProgress.$userId': FieldValue.delete(),
      });
      debugPrint('🛑 [SocialService] Owner $userId left challenge $challengeId -> challenge terminated');
    } else {
      await docRef.update({
        'participants': FieldValue.arrayRemove([userId]),
        'participantNames.$userId': FieldValue.delete(),
        'progress.$userId': FieldValue.delete(),
        'dailyProgress.$userId': FieldValue.delete(),
      });
      debugPrint('🚪 [SocialService] User $userId left challenge $challengeId');
    }
  }

  /// Real-time stream of all challenges joined by [userId].
  static Stream<List<ChallengeData>> getUserChallenges(String userId) {
    return _firestore
        .collection('challenges')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final challenges = snapshot.docs.map((doc) {
        return ChallengeData.fromFirestore(doc);
      }).toList();

      challenges.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return challenges;
    });
  }

  /// Real-time stream of active challenges joined by [userId] that have not expired or completed.
  static Stream<List<ChallengeData>> getActiveChallenges(String userId) {
    return getUserChallenges(userId).map((challenges) {
      return challenges.where((c) => c.isActiveForUser(userId)).toList();
    });
  }

  /// Real-time stream of completed challenges joined by [userId].
  static Stream<List<ChallengeData>> getCompletedChallenges(String userId) {
    return getUserChallenges(userId).map((challenges) {
      return challenges.where((c) => c.isCompletedByUser(userId)).toList();
    });
  }

  /// Pure helper to calculate active and completed counts deterministically.
  static ({int active, int completed}) calculateUserChallengeCounts({
    required List<ChallengeData> challenges,
    required String userId,
  }) {
    int active = 0;
    int completed = 0;
    for (final c in challenges) {
      if (!c.participants.contains(userId)) continue;
      if (c.isActiveForUser(userId)) {
        active++;
      } else if (c.isCompletedByUser(userId)) {
        completed++;
      }
    }
    return (active: active, completed: completed);
  }

  // Get all active challenges (browse tab)
  static Stream<List<ChallengeData>> getAllActiveChallenges() {
    return _firestore
        .collection('challenges')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final challenges = snapshot.docs.map((doc) {
        return ChallengeData.fromFirestore(doc);
      }).where((c) {
        if (!c.isActive) return false;
        if (c.isExpired) return false;
        if (c.creatorId.isNotEmpty && !c.participants.contains(c.creatorId)) return false;
        return true;
      }).toList();

      challenges.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return challenges;
    });
  }

  // Calculate user's streak
  static Future<int> calculateStreak(String userId) async {
    final snapshot = await _database
        .child('users/$userId/daily_logs')
        .orderByKey()
        .limitToLast(30)
        .once();

    if (snapshot.snapshot.value == null) return 0;

    final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
    final dates = data.keys.toList()..sort();

    int streak = 0;
    DateTime? lastDate;

    for (int i = dates.length - 1; i >= 0; i--) {
      final dateStr = dates[i] as String;
      final date = DateTime.parse(dateStr);

      if (lastDate == null) {
        lastDate = date;
        streak = 1;
      } else {
        final diff = lastDate.difference(date).inDays;
        if (diff == 1) {
          streak++;
          lastDate = date;
        } else {
          break;
        }
      }
    }

    return streak;
  }
}

class LeaderboardUser {
  final String id;
  final String username;
  final int score;
  final int steps;
  final int waterMl;
  final double calories;
  final double sleepHours;
  final int streak;

  LeaderboardUser({
    required this.id,
    required this.username,
    required this.score,
    required this.steps,
    required this.waterMl,
    required this.calories,
    required this.sleepHours,
    this.streak = 0,
  });

  factory LeaderboardUser.fromMap(String id, Map<String, dynamic> map) {
    return LeaderboardUser(
      id: id,
      username: map['username'] ?? 'Unknown',
      score: map['score'] ?? 0,
      steps: map['steps'] ?? 0,
      waterMl: map['waterMl'] ?? 0,
      calories: (map['calories'] ?? 0).toDouble(),
      sleepHours: (map['sleepHours'] ?? 0).toDouble(),
      streak: map['streak'] ?? 0,
    );
  }
}

class ChallengeData {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String creatorName;
  final int targetValue;
  final String metricType; // 'steps', 'water', 'calories', 'sleep'
  final String rankingType; // 'highest', 'closestToTarget'
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final List<String> participants;
  final Map<String, int> progress; // Cumulative total progress
  final Map<String, Map<String, int>> dailyProgress; // uid -> { date: progress }
  final Map<String, String> participantNames;
  final bool isActive;

  ChallengeData({
    required this.id,
    required this.title,
    this.description = '',
    this.creatorId = '',
    required this.creatorName,
    required this.targetValue,
    required this.metricType,
    this.rankingType = 'highest',
    DateTime? startDate,
    required this.endDate,
    DateTime? createdAt,
    required this.participants,
    this.progress = const {},
    this.dailyProgress = const {},
    required this.participantNames,
    this.isActive = true,
  })  : startDate = startDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory ChallengeData.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    DateTime parseTimestamp(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    final start = parseTimestamp(data['startDate'], DateTime.now());
    final end = parseTimestamp(data['endDate'], DateTime.now().add(const Duration(days: 7)));
    final created = parseTimestamp(data['createdAt'], DateTime.now());

    // Parse progress map
    final rawProgress = data['progress'] as Map<String, dynamic>? ?? {};
    final progressMap = <String, int>{};
    rawProgress.forEach((k, v) {
      if (v is num) progressMap[k] = v.toInt();
    });

    // Parse dailyProgress map
    final rawDaily = data['dailyProgress'] as Map<String, dynamic>? ?? {};
    final dailyMap = <String, Map<String, int>>{};
    rawDaily.forEach((uid, days) {
      if (days is Map) {
        final userDays = <String, int>{};
        days.forEach((dayKey, val) {
          if (val is num) userDays[dayKey.toString()] = val.toInt();
        });
        dailyMap[uid] = userDays;
      }
    });

    // Parse participantNames map
    final rawNames = data['participantNames'] as Map<String, dynamic>? ?? {};
    final namesMap = <String, String>{};
    rawNames.forEach((k, v) => namesMap[k] = v.toString());

    final participantsList = List<String>.from(data['participants'] ?? []);

    return ChallengeData(
      id: doc.id,
      title: data['title'] ?? 'Challenge',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? 'Creator',
      targetValue: (data['targetValue'] as num?)?.toInt() ?? 1,
      metricType: data['metricType'] ?? 'steps',
      rankingType: data['rankingType'] ?? 'highest',
      startDate: start,
      endDate: end,
      createdAt: created,
      participants: participantsList,
      progress: progressMap,
      dailyProgress: dailyMap,
      participantNames: namesMap,
      isActive: data['isActive'] ?? true,
    );
  }

  /// Whether the challenge has passed its end date.
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// Whether the user has achieved or exceeded the target value for this challenge.
  bool isGoalAchieved(String userId) {
    if (targetValue <= 0) return false;
    final userProgress = getUserProgress(userId);
    return userProgress >= targetValue;
  }

  /// Whether this challenge is currently active for [userId]:
  /// - User has joined (in participants)
  /// - Challenge is marked active (isActive == true)
  /// - Challenge has not expired (!isExpired)
  /// - User has not already achieved the target (!isGoalAchieved)
  bool isActiveForUser(String userId) {
    if (!participants.contains(userId)) return false;
    if (!isActive || isExpired) return false;
    return !isGoalAchieved(userId);
  }

  /// Whether this challenge is completed for [userId]:
  /// - User has joined (in participants)
  /// - AND (goal is achieved OR challenge has expired OR challenge is marked inactive)
  bool isCompletedByUser(String userId) {
    if (!participants.contains(userId)) return false;
    return isGoalAchieved(userId) || isExpired || !isActive;
  }

  /// Get cumulative total progress for a user.
  int getUserProgress(String userId) => progress[userId] ?? 0;

  /// Get progress for a specific day.
  int getUserDailyProgress(String userId, String date) {
    return dailyProgress[userId]?[date] ?? 0;
  }

  /// Get average daily progress across recorded days.
  double getUserAverageProgress(String userId) {
    final days = dailyProgress[userId];
    if (days == null || days.isEmpty) return 0.0;
    final total = days.values.fold<int>(0, (acc, val) => acc + val);
    return total / days.length;
  }

  /// Progress percentage towards target (0.0 to 1.0+).
  double getProgressPercentage(String userId) {
    if (targetValue <= 0) return 0.0;
    final userProgress = progress[userId] ?? 0;
    return (userProgress / targetValue).clamp(0.0, 1.0);
  }

  /// Get daily breakdown for a specific user: date (YYYY-MM-DD) -> progress.
  Map<String, int> getDailyBreakdown(String userId) {
    return dailyProgress[userId] ?? {};
  }

  /// Get sorted participants with accurate competition rank.
  /// 1. Primary sort depends on rankingType:
  ///    - 'highest': descending progress
  ///    - 'closestToTarget': ascending absolute distance |progress - targetValue|
  /// 2. Ties in performance receive equal rank (Standard Competition Ranking, e.g. #1, #1, #3).
  /// 3. Secondary ordering is deterministic by userId to ensure perfectly stable list presentation.
  List<Map<String, dynamic>> getRankedParticipants() {
    if (participants.isEmpty) return [];

    final List<Map<String, dynamic>> list = participants.map((uid) {
      return <String, dynamic>{
        'userId': uid,
        'name': participantNames[uid] ?? 'User',
        'progress': progress[uid] ?? 0,
      };
    }).toList();

    // Sort participants
    list.sort((a, b) {
      final progA = a['progress'] as int;
      final progB = b['progress'] as int;

      int cmp;
      if (rankingType == 'closestToTarget') {
        final diffA = (progA - targetValue).abs();
        final diffB = (progB - targetValue).abs();
        cmp = diffA.compareTo(diffB);
      } else {
        cmp = progB.compareTo(progA);
      }

      if (cmp != 0) return cmp;

      // Deterministic secondary tie-breaker for ordering
      return (a['userId'] as String).compareTo(b['userId'] as String);
    });

    // Assign competition ranks
    for (int i = 0; i < list.length; i++) {
      if (i > 0) {
        final prevProg = list[i - 1]['progress'] as int;
        final currProg = list[i]['progress'] as int;

        bool isTie;
        if (rankingType == 'closestToTarget') {
          isTie = (currProg - targetValue).abs() == (prevProg - targetValue).abs();
        } else {
          isTie = currProg == prevProg;
        }

        if (isTie) {
          list[i]['rank'] = list[i - 1]['rank'];
        } else {
          list[i]['rank'] = i + 1;
        }
      } else {
        list[i]['rank'] = 1;
      }
    }

    return list;
  }

  /// Get current rank for a specific participant (#1, #2, etc.).
  int getRank(String userId) {
    final ranked = getRankedParticipants();
    for (final p in ranked) {
      if (p['userId'] == userId) {
        return p['rank'] as int;
      }
    }
    return ranked.length + 1;
  }

  /// Get top N participants with deterministic rank assigned.
  List<Map<String, dynamic>> getTopParticipants(int count) {
    final ranked = getRankedParticipants();
    return ranked.take(count).toList();
  }

  /// Get participant display name.
  String getParticipantName(String userId) {
    return participantNames[userId] ?? 'User';
  }
}

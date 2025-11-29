import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SocialService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Create or join challenge
  static Future<void> createChallenge({
    required String challengeId,
    required String title,
    required String creatorId,
    required String creatorName,
    required int targetValue,
    required String metricType, // 'steps', 'water', 'calories', 'sleep'
    required DateTime endDate,
  }) async {
    await _firestore.collection('challenges').doc(challengeId).set({
      'title': title,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'targetValue': targetValue,
      'metricType': metricType,
      'endDate': Timestamp.fromDate(endDate),
      'participants': [creatorId],
      'progress': {creatorId: 0},
      'participantNames': {creatorId: creatorName}, // Already added
      'createdAt': Timestamp.now(), // Changed from FieldValue.serverTimestamp()
      'isActive': true,
    });
  }

  // Join challenge - Updated to include username
  static Future<void> joinChallenge(
      String challengeId, String userId, String username) async {
    await _firestore.collection('challenges').doc(challengeId).update({
      'participants': FieldValue.arrayUnion([userId]),
      'progress.$userId': 0,
      'participantNames.$userId': username, // Store username
    });
  }

  // Get active challenges for a specific user
  static Stream<List<ChallengeData>> getActiveChallenges(String userId) {
    return _firestore
        .collection('challenges')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .snapshots() // Removed orderBy to avoid index issues
        .map((snapshot) {
      final challenges = snapshot.docs.map((doc) {
        return ChallengeData.fromFirestore(doc);
      }).toList();

      // Sort manually by creation date
      challenges.sort((a, b) =>
          b.id.compareTo(a.id)); // Sort by ID (which contains timestamp)
      return challenges;
    });
  }

  // Get all active challenges (not just user's challenges)
  static Stream<List<ChallengeData>> getAllActiveChallenges() {
    return _firestore
        .collection('challenges')
        .where('isActive', isEqualTo: true)
        .snapshots() // Removed orderBy to avoid index issues
        .map((snapshot) {
      final challenges = snapshot.docs.map((doc) {
        return ChallengeData.fromFirestore(doc);
      }).toList();

      // Sort manually by creation date
      challenges.sort((a, b) =>
          b.id.compareTo(a.id)); // Sort by ID (which contains timestamp)
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

  // Update all active challenge progress for a user
  static Future<void> updateAllChallengeProgress({
    required String userId,
    required int steps,
    required int waterMl,
    required int calories,
    required int sleepHours,
  }) async {
    try {
      // Get all active challenges for this user
      final snapshot = await _firestore
          .collection('challenges')
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      // Batch update for better performance
      final batch = _firestore.batch();

      // Update progress for each challenge based on metric type
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final metricType = data['metricType'] as String;

        // Get current date as string for storing daily progress
        final today = DateTime.now();
        final dateKey =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        int newProgress = 0;
        switch (metricType) {
          case 'steps':
            newProgress = steps;
            break;
          case 'water':
            newProgress = waterMl;
            break;
          case 'calories':
            newProgress = calories;
            break;
          case 'sleep':
            newProgress = sleepHours;
            break;
        }

        // Update the progress for THIS USER ONLY in this challenge
        // Store it under a nested structure: progress.userId.date
        batch.update(doc.reference, {
          'progress.$userId': newProgress,
          'dailyProgress.$userId.$dateKey':
              newProgress, // Store daily progress separately
          'lastUpdated.$userId': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error updating challenge progress: $e');
    }
  }

  // Update specific challenge progress (manual update)
  static Future<void> updateChallengeProgress({
    required String challengeId,
    required String userId,
    required int progress,
  }) async {
    await _firestore.collection('challenges').doc(challengeId).update({
      'progress.$userId': progress,
    });
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
  final String creatorName;
  final int targetValue;
  final String metricType;
  final DateTime endDate;
  final List<String> participants;
  final Map<String, int> progress;
  final Map<String, String> participantNames; // Add this
  final bool isActive;

  ChallengeData({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.targetValue,
    required this.metricType,
    required this.endDate,
    required this.participants,
    required this.progress,
    required this.participantNames, // Add this
    required this.isActive,
  });

  factory ChallengeData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeData(
      id: doc.id,
      title: data['title'] ?? '',
      creatorName: data['creatorName'] ?? '',
      targetValue: data['targetValue'] ?? 0,
      metricType: data['metricType'] ?? 'steps',
      endDate: (data['endDate'] as Timestamp).toDate(),
      participants: List<String>.from(data['participants'] ?? []),
      progress: Map<String, int>.from(data['progress'] ?? {}),
      participantNames:
          Map<String, String>.from(data['participantNames'] ?? {}), // Add this
      isActive: data['isActive'] ?? true,
    );
  }

  int getUserProgress(String userId) => progress[userId] ?? 0;

  double getProgressPercentage(String userId) {
    final userProgress = getUserProgress(userId);
    return (userProgress / targetValue).clamp(0.0, 1.0);
  }

  int getRank(String userId) {
    final sortedParticipants = participants.toList()
      ..sort((a, b) => (progress[b] ?? 0).compareTo(progress[a] ?? 0));
    return sortedParticipants.indexOf(userId) + 1;
  }

  // Get top participants with their names
  List<Map<String, dynamic>> getTopParticipants(int count) {
    final sorted = participants
        .map((userId) => {
              'userId': userId,
              'name': participantNames[userId] ?? 'Unknown',
              'progress': progress[userId] ?? 0,
            })
        .toList()
      ..sort((a, b) => (b['progress'] as int).compareTo(a['progress'] as int));

    return sorted.take(count).toList();
  }

  // Get participant name by userId
  String getParticipantName(String userId) {
    return participantNames[userId] ?? 'Unknown';
  }
}

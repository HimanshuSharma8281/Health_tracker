import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/services/social_service.dart';
import 'package:tracker/models/health_reading.dart';

void main() {
  group('Social Challenges Dynamic Synchronization & Ranking Tests', () {
    test('TEST 1: Initial Ranking (User X = 0h, User Y = 7h)', () {
      final challenge = ChallengeData(
        id: 'challenge_sleep_1',
        title: 'Sleep Competition',
        targetValue: 8,
        metricType: 'sleep',
        rankingType: 'highest',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 0, 'user_y': 7},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        creatorId: 'user_y',
        creatorName: 'User Y',
      );

      final ranked = challenge.getRankedParticipants();
      expect(ranked.length, equals(2));

      // User Y (7h) is Rank 1
      expect(ranked[0]['userId'], equals('user_y'));
      expect(ranked[0]['progress'], equals(7));
      expect(ranked[0]['rank'], equals(1));
      expect(challenge.getRank('user_y'), equals(1));

      // User X (0h) is Rank 2
      expect(ranked[1]['userId'], equals('user_x'));
      expect(ranked[1]['progress'], equals(0));
      expect(ranked[1]['rank'], equals(2));
      expect(challenge.getRank('user_x'), equals(2));
    });

    test('TEST 2: User X Increases (0h -> 8h)', () {
      // User X changes sleep: 0 -> 8 hours.
      final challengeAfterIncrease = ChallengeData(
        id: 'challenge_sleep_1',
        title: 'Sleep Competition',
        targetValue: 8,
        metricType: 'sleep',
        rankingType: 'highest',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 8, 'user_y': 7},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        creatorId: 'user_y',
        creatorName: 'User Y',
      );

      final ranked = challengeAfterIncrease.getRankedParticipants();

      // User X (8h) moves to Rank 1
      expect(ranked[0]['userId'], equals('user_x'));
      expect(ranked[0]['progress'], equals(8));
      expect(ranked[0]['rank'], equals(1));
      expect(challengeAfterIncrease.getRank('user_x'), equals(1));

      // User Y (7h) moves to Rank 2
      expect(ranked[1]['userId'], equals('user_y'));
      expect(ranked[1]['progress'], equals(7));
      expect(ranked[1]['rank'], equals(2));
      expect(challengeAfterIncrease.getRank('user_y'), equals(2));
    });

    test('TEST 3: User X Decreases (8h -> 5h)', () {
      // User X changes sleep: 8 -> 5 hours.
      final challengeAfterDecrease = ChallengeData(
        id: 'challenge_sleep_1',
        title: 'Sleep Competition',
        targetValue: 8,
        metricType: 'sleep',
        rankingType: 'highest',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 5, 'user_y': 7},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        creatorId: 'user_y',
        creatorName: 'User Y',
      );

      final ranked = challengeAfterDecrease.getRankedParticipants();

      // User Y (7h) moves above User X (5h)
      expect(ranked[0]['userId'], equals('user_y'));
      expect(ranked[0]['progress'], equals(7));
      expect(ranked[0]['rank'], equals(1));
      expect(challengeAfterDecrease.getRank('user_y'), equals(1));

      // User X (5h) is Rank 2
      expect(ranked[1]['userId'], equals('user_x'));
      expect(ranked[1]['progress'], equals(5));
      expect(ranked[1]['rank'], equals(2));
      expect(challengeAfterDecrease.getRank('user_x'), equals(2));
    });

    test('TEST 4: Delete Reading (User X removes sleep reading -> 0h)', () {
      // User X deletes sleep record -> progress becomes 0
      final challengeAfterDelete = ChallengeData(
        id: 'challenge_sleep_1',
        title: 'Sleep Competition',
        targetValue: 8,
        metricType: 'sleep',
        rankingType: 'highest',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 0, 'user_y': 7},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        creatorId: 'user_y',
        creatorName: 'User Y',
      );

      final ranked = challengeAfterDelete.getRankedParticipants();

      expect(ranked[0]['userId'], equals('user_y'));
      expect(ranked[0]['progress'], equals(7));
      expect(ranked[0]['rank'], equals(1));

      expect(ranked[1]['userId'], equals('user_x'));
      expect(ranked[1]['progress'], equals(0));
      expect(ranked[1]['rank'], equals(2));
    });

    test('TEST 5: App Restart Simulation (Reconstruct from canonical health readings)', () {
      final now = DateTime.now();
      final todayStr = HealthReading.todayDate();

      // Simulate canonical HealthReading documents in Firestore
      final rawReadings = [
        HealthReading(
          id: 's1',
          userId: 'user_x',
          metric: HealthReading.sleep,
          value: 8.0,
          date: todayStr,
          timestamp: now,
        ),
      ];

      // On app restart, HealthDataController loads readings and computes sleepHours
      final sleepReadings = rawReadings.where((r) => r.metric == HealthReading.sleep).toList();
      final sleepByDate = <String, double>{};
      for (final r in sleepReadings) {
        sleepByDate[r.date] = (sleepByDate[r.date] ?? 0.0) + r.value;
      }
      final reconstructedSleepHours = sleepByDate[todayStr] ?? 0.0;
      expect(reconstructedSleepHours, equals(8.0));

      // Challenge synced with reconstructed value
      final challenge = ChallengeData(
        id: 'c_sleep_restart',
        title: 'Sleep Tracker',
        targetValue: 8,
        metricType: 'sleep',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': reconstructedSleepHours.round(), 'user_y': 6},
        endDate: now.add(const Duration(days: 5)),
        creatorName: 'User Y',
      );

      expect(challenge.getUserProgress('user_x'), equals(8));
      expect(challenge.getRank('user_x'), equals(1));
    });

    test('TEST 6: Multiple Participants Dynamic Recalculation', () {
      // Step 1: Initial (X=0, Y=7, Z=5)
      var challenge = ChallengeData(
        id: 'c_multi',
        title: 'Multi Participant Challenge',
        targetValue: 10,
        metricType: 'sleep',
        rankingType: 'highest',
        participants: ['user_x', 'user_y', 'user_z'],
        participantNames: {'user_x': 'X', 'user_y': 'Y', 'user_z': 'Z'},
        progress: {'user_x': 0, 'user_y': 7, 'user_z': 5},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Y',
      );

      var ranked = challenge.getRankedParticipants();
      expect(ranked[0]['userId'], equals('user_y')); // 7
      expect(ranked[1]['userId'], equals('user_z')); // 5
      expect(ranked[2]['userId'], equals('user_x')); // 0

      // Step 2: X changes: 0 -> 8
      challenge = ChallengeData(
        id: 'c_multi',
        title: 'Multi Participant Challenge',
        targetValue: 10,
        metricType: 'sleep',
        rankingType: 'highest',
        participants: ['user_x', 'user_y', 'user_z'],
        participantNames: {'user_x': 'X', 'user_y': 'Y', 'user_z': 'Z'},
        progress: {'user_x': 8, 'user_y': 7, 'user_z': 5},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Y',
      );

      ranked = challenge.getRankedParticipants();
      expect(ranked[0]['userId'], equals('user_x')); // 8
      expect(ranked[1]['userId'], equals('user_y')); // 7
      expect(ranked[2]['userId'], equals('user_z')); // 5

      // Step 3: Z changes: 5 -> 10
      challenge = ChallengeData(
        id: 'c_multi',
        title: 'Multi Participant Challenge',
        targetValue: 10,
        metricType: 'sleep',
        rankingType: 'highest',
        participants: ['user_x', 'user_y', 'user_z'],
        participantNames: {'user_x': 'X', 'user_y': 'Y', 'user_z': 'Z'},
        progress: {'user_x': 8, 'user_y': 7, 'user_z': 10},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Y',
      );

      ranked = challenge.getRankedParticipants();
      expect(ranked[0]['userId'], equals('user_z')); // 10 -> Rank 1
      expect(ranked[1]['userId'], equals('user_x')); // 8  -> Rank 2
      expect(ranked[2]['userId'], equals('user_y')); // 7  -> Rank 3
    });

    test('TEST 7: Different Metrics Synchronization', () {
      // Water challenge
      final waterChallenge = ChallengeData(
        id: 'c_water',
        title: 'Hydration Challenge',
        targetValue: 3000,
        metricType: 'water',
        participants: ['u1', 'u2'],
        participantNames: {'u1': 'User 1', 'u2': 'User 2'},
        progress: {'u1': 2500, 'u2': 1800},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'User 1',
      );
      expect(waterChallenge.getRank('u1'), equals(1));
      expect(waterChallenge.getRank('u2'), equals(2));

      // Steps challenge
      final stepsChallenge = ChallengeData(
        id: 'c_steps',
        title: 'Step Master',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['u1', 'u2'],
        participantNames: {'u1': 'User 1', 'u2': 'User 2'},
        progress: {'u1': 4500, 'u2': 8200},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'User 1',
      );
      expect(stepsChallenge.getRank('u2'), equals(1));
      expect(stepsChallenge.getRank('u1'), equals(2));

      // Calories challenge
      final calChallenge = ChallengeData(
        id: 'c_calories',
        title: 'Calorie Burn',
        targetValue: 2000,
        metricType: 'calories',
        participants: ['u1', 'u2'],
        participantNames: {'u1': 'User 1', 'u2': 'User 2'},
        progress: {'u1': 1950, 'u2': 1400},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'User 1',
      );
      expect(calChallenge.getRank('u1'), equals(1));
      expect(calChallenge.getRank('u2'), equals(2));

      // Heart rate challenge
      final hrChallenge = ChallengeData(
        id: 'c_hr',
        title: 'Cardio Focus',
        targetValue: 70,
        metricType: 'heart_rate',
        rankingType: 'closestToTarget',
        participants: ['u1', 'u2'],
        participantNames: {'u1': 'User 1', 'u2': 'User 2'},
        progress: {'u1': 72, 'u2': 85},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'User 1',
      );
      expect(hrChallenge.getRank('u1'), equals(1));
      expect(hrChallenge.getRank('u2'), equals(2));

      // Blood pressure challenge
      final bpChallenge = ChallengeData(
        id: 'c_bp',
        title: 'Blood Pressure Control',
        targetValue: 120,
        metricType: 'blood_pressure',
        rankingType: 'closestToTarget',
        participants: ['u1', 'u2'],
        participantNames: {'u1': 'User 1', 'u2': 'User 2'},
        progress: {'u1': 118, 'u2': 135},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'User 1',
      );
      expect(bpChallenge.getRank('u1'), equals(1));
      expect(bpChallenge.getRank('u2'), equals(2));

      // Blood sugar challenge
      final bsChallenge = ChallengeData(
        id: 'c_bs',
        title: 'Glucose Balance',
        targetValue: 95,
        metricType: 'blood_sugar',
        rankingType: 'closestToTarget',
        participants: ['u1', 'u2'],
        participantNames: {'u1': 'User 1', 'u2': 'User 2'},
        progress: {'u1': 98, 'u2': 115},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'User 1',
      );
      expect(bsChallenge.getRank('u1'), equals(1));
      expect(bsChallenge.getRank('u2'), equals(2));
    });

    test('TEST 8: Steps Dynamic Transitions (5000 vs 7000 -> 10000 vs 7000)', () {
      var stepsChallenge = ChallengeData(
        id: 'c_steps_test',
        title: 'Steps Test',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 5000, 'user_y': 7000},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Admin',
      );
      expect(stepsChallenge.getRank('user_y'), equals(1));
      expect(stepsChallenge.getRank('user_x'), equals(2));

      // User X reaches 10,000 steps
      stepsChallenge = ChallengeData(
        id: 'c_steps_test',
        title: 'Steps Test',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 10000, 'user_y': 7000},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Admin',
      );
      expect(stepsChallenge.getRank('user_x'), equals(1));
      expect(stepsChallenge.getRank('user_y'), equals(2));
    });

    test('TEST 9: Water Dynamic Transitions (750 vs 500 -> 1000 vs 1200)', () {
      var waterChallenge = ChallengeData(
        id: 'c_water_test',
        title: 'Water Test',
        targetValue: 2000,
        metricType: 'water',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 750, 'user_y': 500},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Admin',
      );
      expect(waterChallenge.getRank('user_x'), equals(1));
      expect(waterChallenge.getRank('user_y'), equals(2));

      // User X becomes 1000, User Y becomes 1200
      waterChallenge = ChallengeData(
        id: 'c_water_test',
        title: 'Water Test',
        targetValue: 2000,
        metricType: 'water',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 1000, 'user_y': 1200},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Admin',
      );
      expect(waterChallenge.getRank('user_y'), equals(1));
      expect(waterChallenge.getRank('user_x'), equals(2));
    });

    test('TEST 10: Calories Dynamic Transitions (500 vs 800 -> 1000 vs 800)', () {
      var calChallenge = ChallengeData(
        id: 'c_cal_test',
        title: 'Calories Test',
        targetValue: 2000,
        metricType: 'calories',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 500, 'user_y': 800},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Admin',
      );
      expect(calChallenge.getRank('user_y'), equals(1));
      expect(calChallenge.getRank('user_x'), equals(2));

      // User X reaches 1000
      calChallenge = ChallengeData(
        id: 'c_cal_test',
        title: 'Calories Test',
        targetValue: 2000,
        metricType: 'calories',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 1000, 'user_y': 800},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Admin',
      );
      expect(calChallenge.getRank('user_x'), equals(1));
      expect(calChallenge.getRank('user_y'), equals(2));
    });

    test('TEST 11: Dynamic Ranking Re-sorting and Ties (750->400->600->500 with Y=500)', () {
      // Phase 1: X=750, Y=500 -> X #1, Y #2
      var challenge = ChallengeData(
        id: 'c_tie_test',
        title: 'Tie and Transition Test',
        targetValue: 1000,
        metricType: 'water',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 750, 'user_y': 500},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Admin',
      );
      expect(challenge.getRank('user_x'), equals(1));
      expect(challenge.getRank('user_y'), equals(2));

      // Phase 2: X decreases to 400 -> Y #1, X #2
      challenge = ChallengeData(
        id: 'c_tie_test',
        title: 'Tie and Transition Test',
        targetValue: 1000,
        metricType: 'water',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 400, 'user_y': 500},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Admin',
      );
      expect(challenge.getRank('user_y'), equals(1));
      expect(challenge.getRank('user_x'), equals(2));

      // Phase 3: X increases to 600 -> X #1, Y #2
      challenge = ChallengeData(
        id: 'c_tie_test',
        title: 'Tie and Transition Test',
        targetValue: 1000,
        metricType: 'water',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 600, 'user_y': 500},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Admin',
      );
      expect(challenge.getRank('user_x'), equals(1));
      expect(challenge.getRank('user_y'), equals(2));

      // Phase 4: X adjusts to 500 (Tie with Y=500) -> Both #1
      challenge = ChallengeData(
        id: 'c_tie_test',
        title: 'Tie and Transition Test',
        targetValue: 1000,
        metricType: 'water',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 500, 'user_y': 500},
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorName: 'Admin',
      );
      final ranked = challenge.getRankedParticipants();
      expect(ranked[0]['rank'], equals(1));
      expect(ranked[1]['rank'], equals(1));
      expect(challenge.getRank('user_x'), equals(1));
      expect(challenge.getRank('user_y'), equals(1));
    });

    test('TEST 12: Metric Normalization Test', () {
      expect(SocialService.normalizeMetricType('steps'), equals('steps'));
      expect(SocialService.normalizeMetricType('Steps'), equals('steps'));
      expect(SocialService.normalizeMetricType('STEP'), equals('steps'));
      expect(SocialService.normalizeMetricType('water'), equals('water'));
      expect(SocialService.normalizeMetricType('water_intake'), equals('water'));
      expect(SocialService.normalizeMetricType('water-intake'), equals('water'));
      expect(SocialService.normalizeMetricType('heart_rate'), equals('heart_rate'));
      expect(SocialService.normalizeMetricType('heartRate'), equals('heart_rate'));
      expect(SocialService.normalizeMetricType('blood_pressure'), equals('blood_pressure'));
      expect(SocialService.normalizeMetricType('bloodPressure'), equals('blood_pressure'));
      expect(SocialService.normalizeMetricType('blood_sugar'), equals('blood_sugar'));
      expect(SocialService.normalizeMetricType('bloodsugar'), equals('blood_sugar'));
      expect(SocialService.normalizeMetricType('glucose'), equals('blood_sugar'));
    });

    test('TEST 13: BUG 1 Exact Verification Matrix (Water 500/750 -> 1000/750 -> 1000/1200)', () {
      // User X: 500ml, User Y: 750ml -> Y is #1, X is #2
      var challenge = ChallengeData(
        id: 'c_water_matrix',
        title: '30 Day Water Challenge',
        targetValue: 2000,
        metricType: 'water',
        rankingType: 'highest',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 500, 'user_y': 750},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 29)),
        creatorId: 'user_x',
        creatorName: 'User X',
      );
      var ranked = challenge.getRankedParticipants();
      expect(ranked[0]['userId'], equals('user_y'));
      expect(ranked[0]['progress'], equals(750));
      expect(ranked[0]['rank'], equals(1));
      expect(ranked[1]['userId'], equals('user_x'));
      expect(ranked[1]['progress'], equals(500));
      expect(ranked[1]['rank'], equals(2));

      // User X drinks water -> reaches 1000ml -> X is #1, Y is #2
      challenge = ChallengeData(
        id: 'c_water_matrix',
        title: '30 Day Water Challenge',
        targetValue: 2000,
        metricType: 'water',
        rankingType: 'highest',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 1000, 'user_y': 750},
        startDate: challenge.startDate,
        endDate: challenge.endDate,
        creatorId: 'user_x',
        creatorName: 'User X',
      );
      ranked = challenge.getRankedParticipants();
      expect(ranked[0]['userId'], equals('user_x'));
      expect(ranked[0]['progress'], equals(1000));
      expect(ranked[0]['rank'], equals(1));
      expect(ranked[1]['userId'], equals('user_y'));
      expect(ranked[1]['progress'], equals(750));
      expect(ranked[1]['rank'], equals(2));

      // User Y drinks water -> reaches 1200ml -> Y is #1, X is #2
      challenge = ChallengeData(
        id: 'c_water_matrix',
        title: '30 Day Water Challenge',
        targetValue: 2000,
        metricType: 'water',
        rankingType: 'highest',
        participants: ['user_x', 'user_y'],
        participantNames: {'user_x': 'User X', 'user_y': 'User Y'},
        progress: {'user_x': 1000, 'user_y': 1200},
        startDate: challenge.startDate,
        endDate: challenge.endDate,
        creatorId: 'user_x',
        creatorName: 'User X',
      );
      ranked = challenge.getRankedParticipants();
      expect(ranked[0]['userId'], equals('user_y'));
      expect(ranked[0]['progress'], equals(1200));
      expect(ranked[0]['rank'], equals(1));
      expect(ranked[1]['userId'], equals('user_x'));
      expect(ranked[1]['progress'], equals(1000));
      expect(ranked[1]['rank'], equals(2));
    });

    test('TEST 14: BUG 2 Owner Leaves Challenge -> Terminated & Excluded from Browse All', () {
      // Step A: User X creates challenge (owner: User X)
      final cOwnerActive = ChallengeData(
        id: 'c_owner_test',
        title: 'Owner Test Challenge',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['user_x', 'user_y', 'user_z'],
        participantNames: {'user_x': 'Owner X', 'user_y': 'User Y', 'user_z': 'User Z'},
        progress: {'user_x': 5000, 'user_y': 6000, 'user_z': 7000},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_x',
        creatorName: 'Owner X',
        isActive: true,
      );

      // Verify initially active and valid for Browse All
      expect(cOwnerActive.isActive, isTrue);
      expect(cOwnerActive.isExpired, isFalse);
      expect(cOwnerActive.participants.contains(cOwnerActive.creatorId), isTrue);

      // Step B: User X (Owner) leaves -> Challenge marked isActive = false, user_x removed
      final cOwnerLeft = ChallengeData(
        id: 'c_owner_test',
        title: 'Owner Test Challenge',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['user_y', 'user_z'], // user_x removed
        participantNames: {'user_y': 'User Y', 'user_z': 'User Z'},
        progress: {'user_y': 6000, 'user_z': 7000},
        startDate: cOwnerActive.startDate,
        endDate: cOwnerActive.endDate,
        creatorId: 'user_x',
        creatorName: 'Owner X',
        isActive: false, // Terminated on owner leave
      );

      // Verify canonical state: isActive == false
      expect(cOwnerLeft.isActive, isFalse);
      expect(cOwnerLeft.participants.contains('user_x'), isFalse);

      // Verify it is excluded from Browse All filtering
      final bool isDiscoverable = cOwnerLeft.isActive &&
          !cOwnerLeft.isExpired &&
          (cOwnerLeft.creatorId.isEmpty || cOwnerLeft.participants.contains(cOwnerLeft.creatorId));
      expect(isDiscoverable, isFalse, reason: 'Owner-left challenge must not be discoverable in Browse All');

      // Verify it is no longer active for remaining participants Y and Z
      expect(cOwnerLeft.isActiveForUser('user_y'), isFalse);
      expect(cOwnerLeft.isActiveForUser('user_z'), isFalse);
    });

    test('TEST 15: Non-owner leaves challenge -> Challenge remains active for owner and others', () {
      // User X creates, User Y & Z join. User Y leaves.
      final cParticipantLeft = ChallengeData(
        id: 'c_participant_leave',
        title: 'Community Walk',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['user_x', 'user_z'], // user_y left
        participantNames: {'user_x': 'Owner X', 'user_z': 'User Z'},
        progress: {'user_x': 5000, 'user_z': 7000},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_x',
        creatorName: 'Owner X',
        isActive: true, // Still active
      );

      expect(cParticipantLeft.isActive, isTrue);
      expect(cParticipantLeft.participants.contains('user_x'), isTrue);
      expect(cParticipantLeft.isActiveForUser('user_x'), isTrue);
      expect(cParticipantLeft.isActiveForUser('user_z'), isTrue);
      expect(cParticipantLeft.isActiveForUser('user_y'), isFalse);
    });

    test('Cumulative vs Date Range Bounding Rule', () {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 2));
      final endDate = now.add(const Duration(days: 3));

      final startDay = DateTime(startDate.year, startDate.month, startDate.day);
      final endDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      // Daily map has entries: 5 days ago (before start), yesterday, today, tomorrow, and 10 days later (after end)
      final dBefore = HealthReading.formatDate(now.subtract(const Duration(days: 5)));
      final dYesterday = HealthReading.formatDate(now.subtract(const Duration(days: 1)));
      final dToday = HealthReading.formatDate(now);
      final dTomorrow = HealthReading.formatDate(now.add(const Duration(days: 1)));
      final dAfter = HealthReading.formatDate(now.add(const Duration(days: 10)));

      final userDailyMap = <String, int>{
        dBefore: 100, // Should NOT count (before start)
        dYesterday: 7, // Should count
        dToday: 8,     // Should count
        dTomorrow: 6,  // Should count
        dAfter: 50,    // Should NOT count (after end)
      };

      int cumulativeTotal = 0;
      for (final entry in userDailyMap.entries) {
        final entryDate = DateTime.tryParse(entry.key);
        if (entryDate != null) {
          final entryDay = DateTime(entryDate.year, entryDate.month, entryDate.day);
          if (entryDay.isBefore(startDay)) continue;
          if (entryDay.isAfter(endDay)) continue;
        }
        cumulativeTotal += entry.value;
      }

      // Expected sum: 7 + 8 + 6 = 21 (100 and 50 excluded)
      expect(cumulativeTotal, equals(21));
    });
  });
}

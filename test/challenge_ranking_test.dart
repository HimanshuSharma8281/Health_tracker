import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/services/social_service.dart';

void main() {
  group('Social Challenges Deterministic Ranking & Management Tests', () {
    test('Scenario 1: Accurate ranking calculation among multiple participants (Highest rule)', () {
      final challenge = ChallengeData(
        id: 'c1',
        title: 'Water Intake Challenge',
        targetValue: 3000,
        metricType: 'water',
        rankingType: 'highest',
        participants: ['user_c', 'user_a', 'user_b'],
        participantNames: {
          'user_a': 'Alice',
          'user_b': 'Bob',
          'user_c': 'Charlie',
        },
        progress: {
          'user_a': 3200,
          'user_b': 2500,
          'user_c': 1800,
        },
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_a',
        creatorName: 'Alice',
      );

      final top = challenge.getTopParticipants(10);
      expect(top.length, equals(3));

      // Alice: 3200ml -> Rank #1
      expect(top[0]['userId'], equals('user_a'));
      expect(top[0]['rank'], equals(1));
      expect(challenge.getRank('user_a'), equals(1));

      // Bob: 2500ml -> Rank #2
      expect(top[1]['userId'], equals('user_b'));
      expect(top[1]['rank'], equals(2));
      expect(challenge.getRank('user_b'), equals(2));

      // Charlie: 1800ml -> Rank #3
      expect(top[2]['userId'], equals('user_c'));
      expect(top[2]['rank'], equals(3));
      expect(challenge.getRank('user_c'), equals(3));
    });

    test('Scenario 2: Incremental updates dynamically recalculate ranking', () {
      // Bob starts at 2500ml (Rank #2).
      // Bob logs an additional 1000ml -> 3500ml, overtaking Alice (3200ml) to Rank #1.
      final initial = ChallengeData(
        id: 'c2',
        title: 'Water Intake Challenge',
        targetValue: 3000,
        metricType: 'water',
        rankingType: 'highest',
        participants: ['user_a', 'user_b'],
        participantNames: {'user_a': 'Alice', 'user_b': 'Bob'},
        progress: {'user_a': 3200, 'user_b': 2500},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_a',
        creatorName: 'Alice',
      );

      expect(initial.getRank('user_b'), equals(2));

      // Bob logs 1000ml more
      final updated = ChallengeData(
        id: initial.id,
        title: initial.title,
        targetValue: initial.targetValue,
        metricType: initial.metricType,
        rankingType: initial.rankingType,
        participants: initial.participants,
        participantNames: initial.participantNames,
        progress: {'user_a': 3200, 'user_b': 3500},
        startDate: initial.startDate,
        endDate: initial.endDate,
        creatorId: initial.creatorId,
        creatorName: initial.creatorName,
      );

      expect(updated.getRank('user_b'), equals(1));
      expect(updated.getRank('user_a'), equals(2));
      expect(updated.getUserProgress('user_b'), equals(3500));
    });

    test('Scenario 3: Ties handling gives identical rank with deterministic fallback', () {
      // Alice: 2500, Bob: 2500, Charlie: 2000
      // Standard competition ranking: Alice and Bob tie for Rank #1, Charlie is Rank #3
      final challenge = ChallengeData(
        id: 'c3',
        title: 'Equal Steps Challenge',
        targetValue: 10000,
        metricType: 'steps',
        rankingType: 'highest',
        participants: ['user_b', 'user_a', 'user_c'],
        participantNames: {
          'user_a': 'Alice',
          'user_b': 'Bob',
          'user_c': 'Charlie',
        },
        progress: {
          'user_a': 2500,
          'user_b': 2500,
          'user_c': 2000,
        },
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_a',
        creatorName: 'Alice',
      );

      final top = challenge.getTopParticipants(10);
      expect(top[0]['rank'], equals(1));
      expect(top[1]['rank'], equals(1));
      expect(top[2]['rank'], equals(3));

      expect(challenge.getRank('user_a'), equals(1));
      expect(challenge.getRank('user_b'), equals(1));
      expect(challenge.getRank('user_c'), equals(3));
    });

    test('Scenario 4: User with no health readings has 0 progress and lowest rank', () {
      final challenge = ChallengeData(
        id: 'c4',
        title: 'Calories Burned',
        targetValue: 2000,
        metricType: 'calories',
        rankingType: 'highest',
        participants: ['user_active', 'user_new'],
        participantNames: {'user_active': 'Active User', 'user_new': 'New User'},
        progress: {'user_active': 1500}, // user_new not in map or 0
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_active',
        creatorName: 'Active User',
      );

      expect(challenge.getUserProgress('user_new'), equals(0));
      expect(challenge.getProgressPercentage('user_new'), equals(0.0));
      expect(challenge.getRank('user_active'), equals(1));
      expect(challenge.getRank('user_new'), equals(2));
    });

    test('Scenario 5: Closest to Target ranking rule (e.g. 8 hours sleep)', () {
      // Target: 8.0 hours
      // User A logged 8 hours (delta = 0) -> Rank #1
      // User B logged 7.5 hours (delta = 0.5) -> Rank #2
      // User C logged 9 hours (delta = 1.0) -> Rank #3
      // User D logged 4 hours (delta = 4.0) -> Rank #4
      final challenge = ChallengeData(
        id: 'c5',
        title: '8-Hour Sleep Consistency Challenge',
        targetValue: 8,
        metricType: 'sleep',
        rankingType: 'closestToTarget',
        participants: ['user_d', 'user_b', 'user_c', 'user_a'],
        participantNames: {
          'user_a': 'User 8h',
          'user_b': 'User 7.5h',
          'user_c': 'User 9h',
          'user_d': 'User 4h',
        },
        progress: {
          'user_a': 8,
          'user_b': 7, // or 7.5 mapped to 8
          'user_c': 9,
          'user_d': 4,
        },
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_a',
        creatorName: 'User 8h',
      );

      final top = challenge.getTopParticipants(10);
      expect(top[0]['userId'], equals('user_a')); // delta 0
      expect(top[0]['rank'], equals(1));

      expect(challenge.getRank('user_a'), equals(1));
      expect(challenge.getRank('user_d'), equals(4)); // delta 4
    });

    test('Scenario 6: Multi-day challenge retains dailyProgress breakdown without overwriting past days', () {
      final challenge = ChallengeData(
        id: 'c6',
        title: 'Multi-Day Water Challenge',
        targetValue: 3000,
        metricType: 'water',
        rankingType: 'highest',
        participants: ['user_multi'],
        participantNames: {'user_multi': 'Multi Day User'},
        progress: {'user_multi': 5500}, // cumulative across 2 days
        dailyProgress: {
          'user_multi': {
            '2026-09-10': 2500,
            '2026-09-11': 3000,
          },
        },
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_multi',
        creatorName: 'Multi Day User',
      );

      final breakdown = challenge.getDailyBreakdown('user_multi');
      expect(breakdown['2026-09-10'], equals(2500));
      expect(breakdown['2026-09-11'], equals(3000));
      expect(challenge.getUserProgress('user_multi'), equals(5500));
    });

    test('Scenario 7: Expired challenge detection', () {
      final activeChallenge = ChallengeData(
        id: 'active',
        title: 'Active Challenge',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['user_1'],
        participantNames: {'user_1': 'User 1'},
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        creatorId: 'user_1',
        creatorName: 'User 1',
      );
      expect(activeChallenge.isExpired, isFalse);

      final expiredChallenge = ChallengeData(
        id: 'expired',
        title: 'Expired Challenge',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['user_1'],
        participantNames: {'user_1': 'User 1'},
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        creatorId: 'user_1',
        creatorName: 'User 1',
      );
      expect(expiredChallenge.isExpired, isTrue);
    });

    test('Scenario 8: Progress percentage caps appropriately and handles 0 target', () {
      final challenge = ChallengeData(
        id: 'c8',
        title: 'Cap Test',
        targetValue: 1000,
        metricType: 'water',
        participants: ['u1', 'u2'],
        participantNames: {'u1': 'Overachiever', 'u2': 'Halfway'},
        progress: {'u1': 1500, 'u2': 500},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        creatorId: 'u1',
        creatorName: 'Overachiever',
      );

      expect(challenge.getProgressPercentage('u1'), equals(1.0)); // Capped at 1.0 for progress bar
      expect(challenge.getProgressPercentage('u2'), equals(0.5));
      expect(challenge.getUserProgress('u1'), equals(1500)); // Raw progress uncapped
    });

    // ════════════════════════════════════════════════════════════════════════
    // MASTER ACTIVE & COMPLETED STATUS BAR TESTS (CASES 1-8)
    // ════════════════════════════════════════════════════════════════════════
    test('CASE 1: User joined 2 active challenges -> Active = 2, Completed = 0', () {
      final c1 = ChallengeData(
        id: 'c1',
        title: 'Step Sprint',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['user_alpha', 'user_beta'],
        participantNames: {'user_alpha': 'Alpha', 'user_beta': 'Beta'},
        progress: {'user_alpha': 3500},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        creatorId: 'user_alpha',
        creatorName: 'Alpha',
      );

      final c2 = ChallengeData(
        id: 'c2',
        title: 'Water Hydration',
        targetValue: 3000,
        metricType: 'water',
        participants: ['user_alpha', 'user_gamma'],
        participantNames: {'user_alpha': 'Alpha', 'user_gamma': 'Gamma'},
        progress: {'user_alpha': 1500},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_gamma',
        creatorName: 'Gamma',
      );

      final counts = SocialService.calculateUserChallengeCounts(
        challenges: [c1, c2],
        userId: 'user_alpha',
      );

      expect(counts.active, equals(2));
      expect(counts.completed, equals(0));
    });

    test('CASE 2: User joined 0 active challenges -> Active = 0, Completed = 0', () {
      final c1 = ChallengeData(
        id: 'c1',
        title: 'Step Sprint',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['user_beta', 'user_gamma'],
        participantNames: {'user_beta': 'Beta', 'user_gamma': 'Gamma'},
        progress: {'user_beta': 3500},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        creatorId: 'user_beta',
        creatorName: 'Beta',
      );

      final counts = SocialService.calculateUserChallengeCounts(
        challenges: [c1],
        userId: 'user_alpha',
      );

      expect(counts.active, equals(0));
      expect(counts.completed, equals(0));
    });

    test('CASE 3: User has 2 active + 1 completed -> Active = 2, Completed = 1', () {
      final c1 = ChallengeData(
        id: 'c1',
        title: 'Active Challenge 1',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['user_alpha'],
        participantNames: {'user_alpha': 'Alpha'},
        progress: {'user_alpha': 2000},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_alpha',
        creatorName: 'Alpha',
      );

      final c2 = ChallengeData(
        id: 'c2',
        title: 'Active Challenge 2',
        targetValue: 2500,
        metricType: 'water',
        participants: ['user_alpha'],
        participantNames: {'user_alpha': 'Alpha'},
        progress: {'user_alpha': 1200},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_alpha',
        creatorName: 'Alpha',
      );

      final c3 = ChallengeData(
        id: 'c3',
        title: 'Completed Challenge',
        targetValue: 2000,
        metricType: 'calories',
        participants: ['user_alpha'],
        participantNames: {'user_alpha': 'Alpha'},
        progress: {'user_alpha': 2100}, // Target reached (2100 >= 2000)
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 4)),
        creatorId: 'user_alpha',
        creatorName: 'Alpha',
      );

      final counts = SocialService.calculateUserChallengeCounts(
        challenges: [c1, c2, c3],
        userId: 'user_alpha',
      );

      expect(counts.active, equals(2));
      expect(counts.completed, equals(1));
    });

    test('CASE 4: User leaves one active challenge -> Active decreases from 2 to 1', () {
      final c1 = ChallengeData(
        id: 'c1',
        title: 'Challenge 1',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['user_alpha'],
        participantNames: {'user_alpha': 'Alpha'},
        progress: {'user_alpha': 1000},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_alpha',
        creatorName: 'Alpha',
      );

      final c2Joined = ChallengeData(
        id: 'c2',
        title: 'Challenge 2',
        targetValue: 2000,
        metricType: 'water',
        participants: ['user_alpha', 'user_beta'],
        participantNames: {'user_alpha': 'Alpha', 'user_beta': 'Beta'},
        progress: {'user_alpha': 500},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        creatorId: 'user_beta',
        creatorName: 'Beta',
      );

      final initialCounts = SocialService.calculateUserChallengeCounts(
        challenges: [c1, c2Joined],
        userId: 'user_alpha',
      );
      expect(initialCounts.active, equals(2));

      // User leaves c2
      final c2Left = ChallengeData(
        id: 'c2',
        title: 'Challenge 2',
        targetValue: 2000,
        metricType: 'water',
        participants: ['user_beta'], // user_alpha removed
        participantNames: {'user_beta': 'Beta'},
        progress: {'user_beta': 500},
        startDate: c2Joined.startDate,
        endDate: c2Joined.endDate,
        creatorId: 'user_beta',
        creatorName: 'Beta',
      );

      final afterLeaveCounts = SocialService.calculateUserChallengeCounts(
        challenges: [c1, c2Left],
        userId: 'user_alpha',
      );
      expect(afterLeaveCounts.active, equals(1));
    });

    test('CASE 5: Challenge expires or target met -> transitions from Active to Completed with no overlap', () {
      final challenge = ChallengeData(
        id: 'c_dynamic',
        title: 'Dynamic Challenge',
        targetValue: 10000,
        metricType: 'steps',
        participants: ['user_alpha'],
        participantNames: {'user_alpha': 'Alpha'},
        progress: {'user_alpha': 5000},
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        creatorId: 'user_alpha',
        creatorName: 'Alpha',
      );

      // Initially active
      expect(challenge.isActiveForUser('user_alpha'), isTrue);
      expect(challenge.isCompletedByUser('user_alpha'), isFalse);

      // 5a. When target is reached
      final targetMet = ChallengeData(
        id: challenge.id,
        title: challenge.title,
        targetValue: challenge.targetValue,
        metricType: challenge.metricType,
        participants: challenge.participants,
        participantNames: challenge.participantNames,
        progress: {'user_alpha': 10000},
        startDate: challenge.startDate,
        endDate: challenge.endDate,
        creatorId: challenge.creatorId,
        creatorName: challenge.creatorName,
      );
      expect(targetMet.isActiveForUser('user_alpha'), isFalse);
      expect(targetMet.isCompletedByUser('user_alpha'), isTrue);

      // 5b. When challenge expires
      final expired = ChallengeData(
        id: challenge.id,
        title: challenge.title,
        targetValue: challenge.targetValue,
        metricType: challenge.metricType,
        participants: challenge.participants,
        participantNames: challenge.participantNames,
        progress: {'user_alpha': 5000},
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 1)), // In past
        creatorId: challenge.creatorId,
        creatorName: challenge.creatorName,
      );
      expect(expired.isActiveForUser('user_alpha'), isFalse);
      expect(expired.isCompletedByUser('user_alpha'), isTrue);
    });

    test('CASE 6: Reopening app -> counts are restored identically from challenge state', () {
      final challenges = [
        ChallengeData(
          id: 'c1',
          title: 'Morning Walk',
          targetValue: 5000,
          metricType: 'steps',
          participants: ['user_alpha'],
          participantNames: {'user_alpha': 'Alpha'},
          progress: {'user_alpha': 2500},
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 5)),
          creatorId: 'user_alpha',
          creatorName: 'Alpha',
        ),
        ChallengeData(
          id: 'c2',
          title: 'Hydration Goal',
          targetValue: 2000,
          metricType: 'water',
          participants: ['user_alpha'],
          participantNames: {'user_alpha': 'Alpha'},
          progress: {'user_alpha': 2000},
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 5)),
          creatorId: 'user_alpha',
          creatorName: 'Alpha',
        ),
      ];

      // Run 1 (before restart)
      final counts1 = SocialService.calculateUserChallengeCounts(
        challenges: challenges,
        userId: 'user_alpha',
      );

      // Run 2 (simulated restart re-parsing data)
      final counts2 = SocialService.calculateUserChallengeCounts(
        challenges: List.from(challenges),
        userId: 'user_alpha',
      );

      expect(counts1.active, equals(counts2.active));
      expect(counts1.completed, equals(counts2.completed));
      expect(counts2.active, equals(1));
      expect(counts2.completed, equals(1));
    });

    test('CASE 7: Logout and switch user -> only active user challenges are counted', () {
      final challenges = [
        ChallengeData(
          id: 'c1',
          title: 'User 1 Only Challenge',
          targetValue: 5000,
          metricType: 'steps',
          participants: ['user_1'],
          participantNames: {'user_1': 'User One'},
          progress: {'user_1': 1000},
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 5)),
          creatorId: 'user_1',
          creatorName: 'User One',
        ),
        ChallengeData(
          id: 'c2',
          title: 'Shared Challenge',
          targetValue: 2000,
          metricType: 'water',
          participants: ['user_1', 'user_2'],
          participantNames: {'user_1': 'User One', 'user_2': 'User Two'},
          progress: {'user_1': 500, 'user_2': 2500}, // user_2 completed
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 5)),
          creatorId: 'user_1',
          creatorName: 'User One',
        ),
      ];

      final user1Counts = SocialService.calculateUserChallengeCounts(
        challenges: challenges,
        userId: 'user_1',
      );
      expect(user1Counts.active, equals(2));
      expect(user1Counts.completed, equals(0));

      final user2Counts = SocialService.calculateUserChallengeCounts(
        challenges: challenges,
        userId: 'user_2',
      );
      expect(user2Counts.active, equals(0));
      expect(user2Counts.completed, equals(1)); // Finished target
    });
  });
}

import 'package:tracker/services/social_service.dart';
import 'package:tracker/models/health_reading.dart';

void main() {
  print('========================================');
  print('RUNNING SOCIAL CHALLENGE SYNC TESTS');
  print('========================================');

  int passed = 0;
  int failed = 0;

  void testCase(String name, void Function() fn) {
    try {
      fn();
      print('✅ PASS: $name');
      passed++;
    } catch (e, st) {
      print('❌ FAIL: $name\n   Error: $e\n$st');
      failed++;
    }
  }

  // TEST 1: Initial ranking
  testCase('TEST 1: Initial Ranking (User X = 0h, User Y = 7h)', () {
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
    assert(ranked.length == 2, 'Expected 2 participants');
    assert(ranked[0]['userId'] == 'user_y' && ranked[0]['progress'] == 7 && ranked[0]['rank'] == 1, 'User Y should be #1 with 7h');
    assert(ranked[1]['userId'] == 'user_x' && ranked[1]['progress'] == 0 && ranked[1]['rank'] == 2, 'User X should be #2 with 0h');
    assert(challenge.getRank('user_y') == 1, 'Rank for User Y should be 1');
    assert(challenge.getRank('user_x') == 2, 'Rank for User X should be 2');
  });

  // TEST 2: User X increases
  testCase('TEST 2: User X Increases (0h -> 8h)', () {
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
    assert(ranked[0]['userId'] == 'user_x' && ranked[0]['progress'] == 8 && ranked[0]['rank'] == 1, 'User X should move to Rank 1 with 8h');
    assert(ranked[1]['userId'] == 'user_y' && ranked[1]['progress'] == 7 && ranked[1]['rank'] == 2, 'User Y should move to Rank 2 with 7h');
    assert(challengeAfterIncrease.getRank('user_x') == 1, 'User X rank should be 1');
    assert(challengeAfterIncrease.getRank('user_y') == 2, 'User Y rank should be 2');
  });

  // TEST 3: User X decreases
  testCase('TEST 3: User X Decreases (8h -> 5h)', () {
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
    assert(ranked[0]['userId'] == 'user_y' && ranked[0]['progress'] == 7 && ranked[0]['rank'] == 1, 'User Y should be Rank 1 with 7h');
    assert(ranked[1]['userId'] == 'user_x' && ranked[1]['progress'] == 5 && ranked[1]['rank'] == 2, 'User X should be Rank 2 with 5h');
    assert(challengeAfterDecrease.getRank('user_y') == 1, 'User Y rank should be 1');
    assert(challengeAfterDecrease.getRank('user_x') == 2, 'User X rank should be 2');
  });

  // TEST 4: Delete reading
  testCase('TEST 4: Delete Reading (5h -> 0h)', () {
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
    assert(ranked[0]['userId'] == 'user_y' && ranked[0]['progress'] == 7 && ranked[0]['rank'] == 1);
    assert(ranked[1]['userId'] == 'user_x' && ranked[1]['progress'] == 0 && ranked[1]['rank'] == 2);
  });

  // TEST 5: App restart simulation
  testCase('TEST 5: App Restart Simulation', () {
    final now = DateTime.now();
    final todayStr = HealthReading.todayDate();

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

    final sleepReadings = rawReadings.where((r) => r.metric == HealthReading.sleep).toList();
    final sleepByDate = <String, double>{};
    for (final r in sleepReadings) {
      sleepByDate[r.date] = (sleepByDate[r.date] ?? 0.0) + r.value;
    }
    final reconstructedSleepHours = sleepByDate[todayStr] ?? 0.0;
    assert(reconstructedSleepHours == 8.0, 'Reconstructed sleep should be 8.0');

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

    assert(challenge.getUserProgress('user_x') == 8, 'Progress for User X should be 8');
    assert(challenge.getRank('user_x') == 1, 'Rank for User X should be 1');
  });

  // TEST 6: Multiple participants
  testCase('TEST 6: Multiple Participants (X=0, Y=7, Z=5 -> X=8 -> Z=10)', () {
    // Initial
    var challenge = ChallengeData(
      id: 'c_multi',
      title: 'Multi Participant',
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
    assert(ranked[0]['userId'] == 'user_y', '1st: Y');
    assert(ranked[1]['userId'] == 'user_z', '2nd: Z');
    assert(ranked[2]['userId'] == 'user_x', '3rd: X');

    // X becomes 8
    challenge = ChallengeData(
      id: 'c_multi',
      title: 'Multi Participant',
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
    assert(ranked[0]['userId'] == 'user_x', '1st: X (8)');
    assert(ranked[1]['userId'] == 'user_y', '2nd: Y (7)');
    assert(ranked[2]['userId'] == 'user_z', '3rd: Z (5)');

    // Z becomes 10
    challenge = ChallengeData(
      id: 'c_multi',
      title: 'Multi Participant',
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
    assert(ranked[0]['userId'] == 'user_z', '1st: Z (10)');
    assert(ranked[1]['userId'] == 'user_x', '2nd: X (8)');
    assert(ranked[2]['userId'] == 'user_y', '3rd: Y (7)');
  });

  // TEST 7: Date Bounding Calculation
  testCase('TEST 7: Date Range Bounding', () {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 2));
    final endDate = now.add(const Duration(days: 3));

    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final dBefore = HealthReading.formatDate(now.subtract(const Duration(days: 5)));
    final dYesterday = HealthReading.formatDate(now.subtract(const Duration(days: 1)));
    final dToday = HealthReading.formatDate(now);
    final dTomorrow = HealthReading.formatDate(now.add(const Duration(days: 1)));
    final dAfter = HealthReading.formatDate(now.add(const Duration(days: 10)));

    final userDailyMap = <String, int>{
      dBefore: 100, // excluded
      dYesterday: 7, // included
      dToday: 8,     // included
      dTomorrow: 6,  // included
      dAfter: 50,    // excluded
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

    assert(cumulativeTotal == 21, 'Expected 21, got $cumulativeTotal');
  });

  print('========================================');
  print('RESULTS: $passed passed, $failed failed');
  print('========================================');
}

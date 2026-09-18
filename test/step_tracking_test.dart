import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hardware Step Tracking & Background Accumulation Logic Tests', () {
    test('Scenario 1: Initial Baseline Setup (First run on Day 1)', () {
      // Hardware sensor starts at 1,000,000 steps since boot
      int initialStepsForToday = 0;
      int stepsBeforeReboot = 0;
      int lastCalculatedTodaySteps = 0;

      int rawSensorSteps = 1000000;

      // First event establishes baseline
      initialStepsForToday = rawSensorSteps;
      final stepsSinceBaseline = rawSensorSteps - initialStepsForToday;
      lastCalculatedTodaySteps = stepsBeforeReboot + (stepsSinceBaseline > 0 ? stepsSinceBaseline : 0);

      expect(lastCalculatedTodaySteps, equals(0));
      expect(initialStepsForToday, equals(1000000));
    });

    test('Scenario 2: User walks 2,000 steps with app open', () {
      int initialStepsForToday = 1000000;
      int stepsBeforeReboot = 0;
      int lastCalculatedTodaySteps = 0;

      // Hardware sensor reports 1,002,000
      int rawSensorSteps = 1002000;
      final stepsSinceBaseline = rawSensorSteps - initialStepsForToday;
      lastCalculatedTodaySteps = stepsBeforeReboot + (stepsSinceBaseline > 0 ? stepsSinceBaseline : 0);

      expect(lastCalculatedTodaySteps, equals(2000));
    });

    test('Scenario 3: App CLOSED, user walks 3,000 steps, then REOPENS app', () {
      // Previous state saved before closing app:
      int initialStepsForToday = 1000000;
      int stepsBeforeReboot = 0;
      int lastCalculatedTodaySteps = 2000;

      // While app was closed, Android hardware sensor accumulated 3,000 steps -> 1,005,000
      int rawSensorStepsOnReopen = 1005000;

      // On app reopen:
      final stepsSinceBaseline = rawSensorStepsOnReopen - initialStepsForToday;
      final calculated = stepsBeforeReboot + (stepsSinceBaseline > 0 ? stepsSinceBaseline : 0);
      if (calculated >= lastCalculatedTodaySteps) {
        lastCalculatedTodaySteps = calculated;
      }

      // Authoritative step count on reopen must be 5,000
      expect(lastCalculatedTodaySteps, equals(5000));
    });

    test('Scenario 4: Device Reboots Mid-day (Hardware counter resets to 20)', () {
      // State before reboot: 5,000 steps walked today, last known sensor reading 1,005,000
      int initialStepsForToday = 1000000;
      int stepsBeforeReboot = 0;
      int lastKnownSensorSteps = 1005000;
      int lastCalculatedTodaySteps = 5000;

      // After reboot, hardware sensor restarts from 20
      int rawSensorStepsAfterReboot = 20;

      // Detection of reboot: rawSensorSteps < lastKnownSensorSteps
      if (lastKnownSensorSteps > 0 && rawSensorStepsAfterReboot < lastKnownSensorSteps) {
        stepsBeforeReboot = lastCalculatedTodaySteps; // preserve 5,000
        initialStepsForToday = rawSensorStepsAfterReboot; // 20
      }

      int stepsSinceBaseline = rawSensorStepsAfterReboot - initialStepsForToday;
      int calculated = stepsBeforeReboot + (stepsSinceBaseline > 0 ? stepsSinceBaseline : 0);
      if (calculated >= lastCalculatedTodaySteps) {
        lastCalculatedTodaySteps = calculated;
      }

      // Immediately after reboot, today steps should still be 5,000
      expect(lastCalculatedTodaySteps, equals(5000));
      expect(stepsBeforeReboot, equals(5000));
      expect(initialStepsForToday, equals(20));

      // User walks 400 more steps after reboot -> raw sensor becomes 420
      int rawSensorStepsLater = 420;
      stepsSinceBaseline = rawSensorStepsLater - initialStepsForToday; // 420 - 20 = 400
      calculated = stepsBeforeReboot + (stepsSinceBaseline > 0 ? stepsSinceBaseline : 0); // 5,000 + 400 = 5,400
      if (calculated >= lastCalculatedTodaySteps) {
        lastCalculatedTodaySteps = calculated;
      }

      expect(lastCalculatedTodaySteps, equals(5400));
    });

    test('Scenario 5: Midnight / New Calendar Day Transition', () {
      String previousDate = '2026-09-16';
      int initialStepsForToday = 1000000;
      int stepsBeforeReboot = 0;
      int lastCalculatedTodaySteps = 8500;

      // Next morning (2026-09-17)
      String currentDate = '2026-09-17';
      int rawSensorStepsNextDay = 1009000;

      if (previousDate != currentDate) {
        // Rollover: baseline reset to current sensor count
        initialStepsForToday = rawSensorStepsNextDay;
        stepsBeforeReboot = 0;
        lastCalculatedTodaySteps = 0;
      }

      expect(lastCalculatedTodaySteps, equals(0));
      expect(initialStepsForToday, equals(1009000));

      // User takes first 150 steps on new day -> 1,009,150
      int rawSensorStepsAfterWalking = 1009150;
      int stepsSinceBaseline = rawSensorStepsAfterWalking - initialStepsForToday;
      lastCalculatedTodaySteps = stepsBeforeReboot + (stepsSinceBaseline > 0 ? stepsSinceBaseline : 0);

      expect(lastCalculatedTodaySteps, equals(150));
    });
  });
}

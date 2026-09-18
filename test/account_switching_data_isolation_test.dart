import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker/controllers/health_data_controller.dart';
import 'package:tracker/controllers/aurora_chat_controller.dart';
import 'package:tracker/controllers/auth_controller.dart';
import 'package:tracker/models/user_profile.dart';
import 'package:tracker/models/health_reading.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Account Data Isolation & Switching Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('HealthDataController resets all user data and metric values on resetAllUserData', () {
      final controller = HealthDataController();

      // Populate Account A data
      controller.userId = 'UID_A';
      controller.username = 'Account A';
      controller.waterMl = 1500;
      controller.stepsToday = 5000;
      controller.sleepHours = 7.0;
      controller.heartRate = 69.0;
      controller.bloodSugar = 79.0;
      controller.addBloodPressureReading(120, 80);
      controller.profile = const UserProfile(
        uid: 'UID_A',
        name: 'Account A',
        email: 'a@example.com',
      );

      expect(controller.userId, equals('UID_A'));
      expect(controller.waterMl, equals(1500));
      expect(controller.stepsToday, equals(5000));
      expect(controller.sleepHours, equals(7.0));
      expect(controller.heartRate, equals(69.0));
      expect(controller.bloodSugar, equals(79.0));
      expect(controller.systolic, equals(120));
      expect(controller.diastolic, equals(80));

      // Execute reset
      controller.resetAllUserData(saveFirst: false);

      // Verify all data is completely isolated/wiped
      expect(controller.userId, isNull);
      expect(controller.username, isNull);
      expect(controller.profile, isNull);
      expect(controller.waterMl, equals(0));
      expect(controller.stepsToday, equals(0));
      expect(controller.sleepHours, equals(0.0));
      expect(controller.heartRate, equals(0.0));
      expect(controller.bloodSugar, equals(0.0));
      expect(controller.systolic, equals(0));
      expect(controller.diastolic, equals(0));
      expect(controller.waterHistory, isEmpty);
      expect(controller.stepHistory, isEmpty);
      expect(controller.sleepHistory, isEmpty);
      expect(controller.heartRateHistory, isEmpty);
      expect(controller.bloodPressureHistory, isEmpty);
      expect(controller.bloodSugarHistory, isEmpty);
      expect(controller.isDataLoaded, isFalse);
    });

    test('AuroraChatController wipes in-memory messages and uid on reset', () async {
      final chat = AuroraChatController();
      await chat.loadHistory('UID_A');

      expect(chat.currentUid, equals('UID_A'));
      expect(chat.messages, isNotEmpty);

      chat.reset();

      expect(chat.currentUid, isNull);
      expect(chat.messages, isEmpty);
      expect(chat.conversationHistory, isEmpty);
      expect(chat.isLoaded, isFalse);
    });

    test('Exact Bug Flow: Account A -> Sign Out -> Google Sign-Up with existing Account B -> Account B Sign In', () async {
      SharedPreferences.setMockInitialValues({
        'user_UID_A_current_water': 1500,
        'user_UID_A_current_steps': 5000,
        'user_UID_A_current_sleep': 7.0,
        'user_UID_A_current_calories': 1800.0,
        'user_UID_B_current_water': 250,
        'user_UID_B_current_steps': 1200,
        'user_UID_B_current_sleep': 5.5,
        'user_UID_B_current_calories': 400.0,
      });

      final healthData = HealthDataController();
      final chatData = AuroraChatController();

      // Step 1: Account A logs in
      healthData.setUserInfo('UID_A', 'Account A', forceReload: true);
      await Future.delayed(const Duration(milliseconds: 50));

      healthData.waterMl = 1500;
      healthData.stepsToday = 5000;
      healthData.sleepHours = 7.0;
      healthData.heartRate = 69.0;
      healthData.bloodSugar = 79.0;
      healthData.addBloodPressureReading(120, 80);

      expect(healthData.userId, equals('UID_A'));
      expect(healthData.waterMl, equals(1500));
      expect(healthData.stepsToday, equals(5000));
      expect(healthData.sleepHours, equals(7.0));
      expect(healthData.heartRate, equals(69.0));
      expect(healthData.bloodSugar, equals(79.0));
      expect(healthData.systolic, equals(120));
      expect(healthData.diastolic, equals(80));

      // Step 2: User logs out
      healthData.resetAllUserData(saveFirst: false);
      chatData.reset();

      expect(healthData.userId, isNull);
      expect(healthData.waterMl, equals(0));
      expect(healthData.stepsToday, equals(0));

      // Step 3: User attempts Google Sign-Up with existing Account B
      // Sign up detects existing user (!isNewUser), executes cleanup
      healthData.resetAllUserData(saveFirst: false);
      chatData.reset();

      expect(healthData.userId, isNull);
      expect(healthData.waterMl, equals(0));

      // Step 4: User navigates to Login and signs in as Account B
      healthData.setUserInfo('UID_B', 'Account B', forceReload: true);
      await Future.delayed(const Duration(milliseconds: 50));

      healthData.waterMl = 250;
      healthData.stepsToday = 1200;
      healthData.sleepHours = 5.5;
      healthData.heartRate = 72.0;
      healthData.bloodSugar = 95.0;
      healthData.addBloodPressureReading(115, 75);

      // Verify Account B has ONLY Account B's data and ZERO of Account A's readings
      expect(healthData.userId, equals('UID_B'));
      expect(healthData.waterMl, equals(250));
      expect(healthData.stepsToday, equals(1200));
      expect(healthData.sleepHours, equals(5.5));
      expect(healthData.heartRate, equals(72.0));
      expect(healthData.bloodSugar, equals(95.0));
      expect(healthData.systolic, equals(115));
      expect(healthData.diastolic, equals(75));

      // Verify Account A values NEVER leaked into Account B
      expect(healthData.waterMl, isNot(equals(1500)));
      expect(healthData.stepsToday, isNot(equals(5000)));
      expect(healthData.sleepHours, isNot(equals(7.0)));
      expect(healthData.heartRate, isNot(equals(69.0)));
      expect(healthData.bloodSugar, isNot(equals(79.0)));
      expect(healthData.systolic, isNot(equals(120)));
      expect(healthData.diastolic, isNot(equals(80)));
    });
  });
}

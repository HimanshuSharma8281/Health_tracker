import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tracker/controllers/auth_controller.dart';
import 'package:tracker/controllers/health_data_controller.dart';
import 'package:tracker/controllers/theme_controller.dart';
import 'package:tracker/models/activity_models.dart';
import 'package:tracker/models/user_profile.dart';
import 'package:tracker/screens/settings_tab.dart';

class MockAuthController extends ChangeNotifier implements AuthController {
  @override
  UserProfile? user = const UserProfile(
    uid: 'test_user_id',
    name: 'Himanshu Test',
    email: 'test@aurora.com',
    avatarUrl: '',
    devices: [],
  );

  @override
  bool loading = false;

  @override
  String? error;

  @override
  bool get isAuthenticated => user != null;

  @override
  Future<bool> deleteAccount() async {
    user = null;
    notifyListeners();
    return true;
  }

  @override
  Future<void> signOut() async {
    user = null;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Settings & Account Deletion Wiping Tests', () {
    test('HealthDataController.resetAllUserData() completely purges all in-memory state', () {
      final controller = HealthDataController();

      // Populate test metrics
      controller.stepsToday = 8500;
      controller.waterMl = 1500;
      controller.sleepHours = 7.5;
      controller.caloriesConsumed = 2200;
      controller.userId = 'user_123';
      controller.username = 'TestUser';

      controller.bloodPressureHistory.add(
        BloodPressureReading(
          systolic: 120,
          diastolic: 80,
          timestamp: DateTime.now(),
        ),
      );
      controller.bloodSugarHistory.add(
        BloodSugarReading(
          value: 95.0,
          date: DateTime.now(),
        ),
      );
      controller.heartRateHistory.add(
        HeartRateReading(
          bpm: 72,
          timestamp: DateTime.now(),
        ),
      );
      controller.meals.add(
        MealEntry(
          name: 'Chicken Salad',
          calories: 450,
          time: DateTime.now(),
          mealType: MealType.lunch,
        ),
      );
      controller.history.add(
        ActivityEntry(
          date: DateTime.now(),
          steps: 4000,
          calories: 250,
          sleepHours: 7.0,
          waterMl: 1200,
          stressLevel: 2.0,
          mindfulnessMinutes: 15,
        ),
      );

      // Verify data is present
      expect(controller.stepsToday, equals(8500));
      expect(controller.waterMl, equals(1500));
      expect(controller.sleepHours, equals(7.5));
      expect(controller.caloriesConsumed, equals(2200));
      expect(controller.userId, equals('user_123'));
      expect(controller.username, equals('TestUser'));
      expect(controller.bloodPressureHistory.isNotEmpty, isTrue);
      expect(controller.bloodSugarHistory.isNotEmpty, isTrue);
      expect(controller.heartRateHistory.isNotEmpty, isTrue);
      expect(controller.meals.isNotEmpty, isTrue);
      expect(controller.history.isNotEmpty, isTrue);

      // Perform permanent wipe
      controller.resetAllUserData();

      // Verify all data is completely wiped forever
      expect(controller.stepsToday, equals(0));
      expect(controller.waterMl, equals(0));
      expect(controller.sleepHours, equals(0.0));
      expect(controller.caloriesConsumed, equals(0));
      expect(controller.userId, isNull);
      expect(controller.username, isNull);
      expect(controller.profile, isNull);
      expect(controller.bloodPressureHistory.isEmpty, isTrue);
      expect(controller.bloodSugarHistory.isEmpty, isTrue);
      expect(controller.heartRateHistory.isEmpty, isTrue);
      expect(controller.waterIntakeHistory.isEmpty, isTrue);
      expect(controller.sleepReadingHistory.isEmpty, isTrue);
      expect(controller.meals.isEmpty, isTrue);
      expect(controller.history.isEmpty, isTrue);
    });

    testWidgets('Settings screen renders only genuine sections and no dummy/fake tiles', (tester) async {
      final mockAuth = MockAuthController();
      final healthController = HealthDataController();
      final themeController = ThemeController();

      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: mockAuth),
            ChangeNotifierProvider<HealthDataController>.value(value: healthController),
            ChangeNotifierProvider<ThemeController>.value(value: themeController),
          ],
          child: const MaterialApp(
            home: SettingsTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Genuine Sections exist
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Notifications & Alerts'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);

      expect(find.text('Account & Cloud Sync'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Cloud Synchronization'), findsOneWidget);

      expect(find.text('About & System'), findsOneWidget);
      expect(find.text('About Aurora Health'), findsOneWidget);

      expect(find.text('Account Actions'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);

      // Verify dummy/non-working items are NOT present
      expect(find.text('Language'), findsNothing);
      expect(find.text('Accessibility'), findsNothing);
      expect(find.text('Privacy & Security'), findsNothing);
      expect(find.text('Help Center'), findsNothing);
      expect(find.text('Report a Bug'), findsNothing);
    });

    testWidgets('Delete Account dialog displays permanent erasure warnings', (tester) async {
      final mockAuth = MockAuthController();
      final healthController = HealthDataController();
      final themeController = ThemeController();

      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: mockAuth),
            ChangeNotifierProvider<HealthDataController>.value(value: healthController),
            ChangeNotifierProvider<ThemeController>.value(value: themeController),
          ],
          child: const MaterialApp(
            home: SettingsTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final deleteTile = find.text('Delete Account');
      expect(deleteTile, findsOneWidget);
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();

      // Verify Confirmation Dialog elements
      expect(find.text('Delete Account Forever'), findsOneWidget);
      expect(find.text('Permanent & Irreversible'), findsOneWidget);
      expect(find.text('Delete Forever'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('The following data will be erased forever:'), findsOneWidget);
      expect(find.text('User profile, email & credentials'), findsOneWidget);
      expect(find.text('All health logs (steps, water, sleep, calories, BP, sugar, heart rate)'), findsOneWidget);
      expect(find.text('All deterministic health scores & history'), findsOneWidget);
      expect(find.text('Leaderboard standings & challenge progress'), findsOneWidget);
    });
  });
}

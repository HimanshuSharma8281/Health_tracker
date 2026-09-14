import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tracker/models/user_profile.dart';
import 'package:tracker/controllers/auth_controller.dart';
import 'package:tracker/controllers/health_data_controller.dart';
import 'package:tracker/screens/health_onboarding_screen.dart';
import 'package:tracker/services/health_score_engine.dart';

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
  Future<void> saveFullProfile(UserProfile updatedProfile, [HealthDataController? healthData]) async {
    user = updatedProfile;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('User Profile & Onboarding Contract Tests', () {
    test('New user profile defaults to isComplete == false', () {
      final newProfile = UserProfile.fromFirebaseAuth(
        uid: 'user_123',
        name: 'Himanshu',
        email: 'himanshu@example.com',
      );

      expect(newProfile.isComplete, isFalse);
      expect(newProfile.bmi, isNull);
      expect(newProfile.bmiCategory, equals('Unknown'));
    });

    test('Completed user profile has isComplete == true and calculates BMI deterministically', () {
      const completedProfile = UserProfile(
        uid: 'user_123',
        name: 'Himanshu',
        email: 'himanshu@example.com',
        age: 25,
        sex: 'male',
        heightCm: 180.0,
        weightKg: 75.0,
        activityLevel: 'moderately_active',
        fitnessGoal: 'maintain',
      );

      expect(completedProfile.isComplete, isTrue);
      // BMI = 75 / (1.80 * 1.80) = 75 / 3.24 = 23.148...
      expect(completedProfile.bmi, isNotNull);
      expect(completedProfile.bmi!, closeTo(23.15, 0.05));
      expect(completedProfile.bmiCategory, equals('Normal'));
    });

    test('BMI categories map correctly for all ranges', () {
      // Underweight (< 18.5)
      const underweight = UserProfile(
        uid: 'u1',
        name: 'Test',
        email: 'test@example.com',
        heightCm: 180,
        weightKg: 55,
      );
      expect(underweight.bmiCategory, equals('Underweight'));

      // Normal (18.5 - 24.9)
      const normal = UserProfile(
        uid: 'u2',
        name: 'Test',
        email: 'test@example.com',
        heightCm: 175,
        weightKg: 68,
      );
      expect(normal.bmiCategory, equals('Normal'));

      // Overweight (25.0 - 29.9)
      const overweight = UserProfile(
        uid: 'u3',
        name: 'Test',
        email: 'test@example.com',
        heightCm: 170,
        weightKg: 78,
      );
      expect(overweight.bmiCategory, equals('Overweight'));

      // Obese (>= 30.0)
      const obese = UserProfile(
        uid: 'u4',
        name: 'Test',
        email: 'test@example.com',
        heightCm: 165,
        weightKg: 95,
      );
      expect(obese.bmiCategory, equals('Obese'));
    });

    test('Deterministic baseline goal formulas adhere to Mifflin-St Jeor & clinical standards', () {
      // Male, 25 yo, 180cm, 75kg, moderately_active (1.55), maintain
      const maleProfile = UserProfile(
        uid: 'u_male',
        name: 'Male User',
        email: 'male@test.com',
        age: 25,
        sex: 'male',
        heightCm: 180,
        weightKg: 75,
        activityLevel: 'moderately_active',
        fitnessGoal: 'maintain',
      );

      // Hydration: 75 * 35 * 1.2 = 3150 ml
      final hydrationScore = HealthScoreEngine.calculateHydrationScore(
        waterMl: 3150,
        weightKg: maleProfile.weightKg,
        activityLevel: maleProfile.activityLevel,
      );
      expect(hydrationScore.score, equals(10));
      expect(hydrationScore.target, contains('3150ml'));

      // Calorie score using Mifflin-St Jeor
      final calorieScore = HealthScoreEngine.calculateCalorieScore(
        consumed: 2720,
        profile: maleProfile,
      );
      expect(calorieScore.score, equals(10));
      expect(calorieScore.target, contains('2720 kcal'));
    });
  });

  group('HealthOnboardingScreen Widget Tests', () {
    testWidgets('Renders all required onboarding input fields', (tester) async {
      final mockAuth = MockAuthController();
      final healthDataController = HealthDataController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: mockAuth),
            ChangeNotifierProvider.value(value: healthDataController),
          ],
          child: const MaterialApp(
            home: HealthOnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and titles
      expect(find.text('Health Profile Setup'), findsOneWidget);
      expect(find.text('Personal Info'), findsOneWidget);
      expect(find.text('Body Measurements'), findsOneWidget);
      expect(find.text('Lifestyle & Fitness Goal'), findsOneWidget);

      // Check fields
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('Height (cm)'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('Complete Health Setup'), findsOneWidget);
    });
  });

  group('OAuth & Authentication Resilience Tests', () {
    test('Twitter OAuth new user profile preserves isComplete=false for onboarding flow', () {
      final twitterProfile = UserProfile.fromFirebaseAuth(
        uid: 'twitter_uid_999',
        name: 'Twitter User',
        email: 'twitter_user@example.com',
        avatarUrl: 'https://pbs.twimg.com/profile_images/sample.jpg',
      );

      expect(twitterProfile.uid, equals('twitter_uid_999'));
      expect(twitterProfile.name, equals('Twitter User'));
      expect(twitterProfile.isComplete, isFalse);
    });

    test('Twitter OAuth existing user profile preserves isComplete=true to bypass onboarding', () {
      const existingTwitterProfile = UserProfile(
        uid: 'twitter_uid_999',
        name: 'Twitter User',
        email: 'twitter_user@example.com',
        avatarUrl: 'https://pbs.twimg.com/profile_images/sample.jpg',
        age: 28,
        sex: 'female',
        heightCm: 165,
        weightKg: 60,
        activityLevel: 'active',
        fitnessGoal: 'maintain',
      );

      expect(existingTwitterProfile.isComplete, isTrue);
      expect(existingTwitterProfile.bmi, isNotNull);
      expect(existingTwitterProfile.bmiCategory, equals('Normal'));
    });
  });
}

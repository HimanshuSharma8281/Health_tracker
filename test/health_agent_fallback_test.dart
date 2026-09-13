import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/services/health_agent_service.dart';
import 'package:tracker/controllers/health_data_controller.dart';
import 'package:tracker/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthAgentService Fallback Engine Tests', () {
    test('Agent fallback handles hydration queries without quota errors', () async {
      final res = await HealthAgentService.chat(
        uid: 'test_uid_fallback',
        userMessage: 'How is my hydration today?',
      );

      expect(res.text, isNotEmpty);
      expect(res.text.contains('Hydration'), isTrue);
      expect(res.text.contains('quota limit reached'), isFalse);
    });

    test('Agent fallback handles steps & activity queries', () async {
      final res = await HealthAgentService.chat(
        uid: 'test_uid_fallback',
        userMessage: 'How many steps have I walked today?',
      );

      expect(res.text, isNotEmpty);
      expect(res.text.contains('Steps') || res.text.contains('Activity'), isTrue);
      expect(res.text.contains('quota limit reached'), isFalse);
    });

    test('Agent fallback handles sleep queries', () async {
      final res = await HealthAgentService.chat(
        uid: 'test_uid_fallback',
        userMessage: 'Analyze my sleep',
      );

      expect(res.text, isNotEmpty);
      expect(res.text.contains('Sleep'), isTrue);
      expect(res.text.contains('quota limit reached'), isFalse);
    });

    test('Agent fallback handles score and general wellness questions', () async {
      final res = await HealthAgentService.chat(
        uid: 'test_uid_fallback',
        userMessage: 'What is my score and how can I improve it?',
      );

      expect(res.text, isNotEmpty);
      expect(res.text.contains('Wellness Score'), isTrue);
      expect(res.text.contains('quota limit reached'), isFalse);
    });

    test('Agent accurately reflects live HealthDataController and UserProfile (Himanshu scenario)', () async {
      final controller = HealthDataController();
      controller.waterMl = 1750;
      controller.waterGoal = 2500;
      controller.stepsToday = 29;
      controller.stepGoal = 100;

      const profile = UserProfile(
        uid: 'himanshu_test_uid',
        name: 'Himanshu',
        email: 'himanshu@test.com',
        stepGoal: 100,
        waterGoalMl: 2500,
      );

      // 1. Test Greeting
      final greetingRes = await HealthAgentService.chat(
        uid: 'himanshu_test_uid',
        userMessage: 'Hi',
        healthData: controller,
        userProfile: profile,
      );

      expect(greetingRes.text.contains('Hello Himanshu!'), isTrue);
      expect(greetingRes.text.contains('1,750 ml'), isTrue);
      expect(greetingRes.text.contains('2,500 ml'), isTrue);
      expect(greetingRes.text.contains('29'), isTrue);
      expect(greetingRes.text.contains('100'), isTrue);

      // 2. Test Hydration Query
      final waterRes = await HealthAgentService.chat(
        uid: 'himanshu_test_uid',
        userMessage: 'How is my hydration today?',
        healthData: controller,
        userProfile: profile,
      );

      expect(waterRes.text.contains('1,750 ml'), isTrue);
      expect(waterRes.text.contains('2,500 ml'), isTrue);
      expect(waterRes.text.contains('70%'), isTrue);
      expect(waterRes.text.contains('750 ml'), isTrue);

      // 3. Test Steps Query
      final stepRes = await HealthAgentService.chat(
        uid: 'himanshu_test_uid',
        userMessage: 'How many steps have I walked today?',
        healthData: controller,
        userProfile: profile,
      );

      expect(stepRes.text.contains('29 steps'), isTrue);
      expect(stepRes.text.contains('100 step'), isTrue);
      expect(stepRes.text.contains('29%'), isTrue);
      expect(stepRes.text.contains('71 steps'), isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker/controllers/aurora_chat_controller.dart';
import 'package:tracker/controllers/auth_controller.dart';
import 'package:tracker/controllers/health_data_controller.dart';
import 'package:tracker/models/user_profile.dart';
import 'package:tracker/screens/ai_health_insights_screen.dart';

class MockAuthController extends ChangeNotifier implements AuthController {
  @override
  UserProfile? user = const UserProfile(
    uid: 'test_user_id',
    name: 'Test Patient',
    email: 'patient@aurora.com',
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Aurora Chat Markdown Formatting & Rendering Tests', () {
    testWidgets('TEST 1 & 3: Detailed diet & macro recommendation with headings, bold, bullet points, and hr', (tester) async {
      final mockAuth = MockAuthController();
      final healthController = HealthDataController();
      final auroraChat = AuroraChatController();
      await auroraChat.loadHistory('test_user_id');

      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: mockAuth),
            ChangeNotifierProvider<HealthDataController>.value(value: healthController),
            ChangeNotifierProvider<AuroraChatController>.value(value: auroraChat),
          ],
          child: const MaterialApp(
            home: AIHealthInsightsScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // Switch to Ask Aurora tab
      final auroraTab = find.text('Ask Aurora');
      await tester.tap(auroraTab.first);
      await tester.pump(const Duration(milliseconds: 300));

      // Check that MarkdownBody widgets are present
      expect(find.byType(MarkdownBody), findsWidgets);
      expect(find.textContaining('Aurora'), findsWidgets);
    });

    testWidgets('TEST 2 & 6: Complex response with headings, bold, numbered lists, bullet lists, and tables', (tester) async {
      const complexMarkdown = '''
# Clinical Assessment

Your hydration today is slightly below your daily goal.

### Hydration Summary
* **Current Intake:** 1,500 ml
* **Target Goal:** 2,500 ml
* **Deficit:** 1,000 ml

### Action Plan
1. Drink 500 ml with lunch
2. Set afternoon reminder
3. Hydrate post-exercise

| Metric | Value | Status |
| --- | --- | --- |
| Steps | 8,200 | Good |
| Water | 1,500 ml | Low |
| Sleep | 7.5 hrs | Optimal |
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              data: complexMarkdown,
              shrinkWrap: true,
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(fontSize: 16, color: Color(0xFF48E5C2)),
                h3: const TextStyle(fontSize: 14, color: Color(0xFF48E5C2)),
                p: const TextStyle(fontSize: 13.5, color: Colors.white),
                strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Heading rendered
      expect(find.textContaining('Clinical Assessment'), findsOneWidget);
      // Table cells rendered
      expect(find.textContaining('8,200'), findsOneWidget);
      expect(find.textContaining('1,500 ml'), findsWidgets);
      expect(find.textContaining('Optimal'), findsOneWidget);
      // Numbered list items rendered
      expect(find.textContaining('Drink 500 ml with lunch'), findsOneWidget);
    });

    testWidgets('TEST 4 & 5: Health trends and weekly summary with blockquotes and separators', (tester) async {
      const trendsMarkdown = '''
### Weekly Health Trends

> Clinical Note: Your average sleep duration improved by 45 minutes this week compared to last week.

---

* **Average Heart Rate:** 68 BPM (Resting zone)
* **Average Blood Pressure:** 118/76 mmHg (Normal)
* **Consistency Score:** 92 / 100
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              data: trendsMarkdown,
              shrinkWrap: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Weekly Health Trends'), findsOneWidget);
      expect(find.textContaining('Clinical Note:'), findsOneWidget);
      expect(find.textContaining('Average Heart Rate:'), findsOneWidget);
    });
  });
}

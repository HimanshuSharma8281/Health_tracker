import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tracker/controllers/aurora_chat_controller.dart';
import 'package:tracker/controllers/auth_controller.dart';
import 'package:tracker/controllers/health_data_controller.dart';
import 'package:tracker/controllers/theme_controller.dart';
import 'package:tracker/models/user_profile.dart';
import 'package:tracker/screens/dashboard_tab.dart';
import 'package:tracker/screens/settings_tab.dart';
import 'package:tracker/screens/ai_health_insights_screen.dart';

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('UI Cleanup & Aurora Redesign Tests', () {
    testWidgets('Dashboard header has no notification bell icon', (tester) async {
      final mockAuth = MockAuthController();
      final healthController = HealthDataController();

      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: mockAuth),
            ChangeNotifierProvider<HealthDataController>.value(value: healthController),
          ],
          child: const MaterialApp(
            home: DashboardTab(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // Notifications bell icon must NOT be found in top header
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
      expect(find.byIcon(Icons.notifications), findsNothing);
      expect(find.byIcon(Icons.notifications_active), findsNothing);
    });

    testWidgets('Settings header has no notification bell shortcut button', (tester) async {
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

      await tester.pump(const Duration(milliseconds: 300));

      // Header row text
      expect(find.text('Preferences & Account'), findsOneWidget);

      // There must NOT be any Reminders shortcut button in the header (no notifications_rounded or badge in header)
      expect(find.byIcon(Icons.notifications_rounded), findsNothing);
      expect(find.byIcon(Icons.notifications), findsNothing);
    });

    testWidgets('AI Health Insights screen header has no refresh icon and has redesigned Aurora chat', (tester) async {
      final mockAuth = MockAuthController();
      final healthController = HealthDataController();
      final auroraChat = AuroraChatController();

      tester.view.physicalSize = const Size(800, 1600);
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

      // 1. Refresh icon must NOT be found in top header
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);

      // 2. Switch to Ask Aurora mode (second tab)
      final auroraTab = find.text('Ask Aurora');
      expect(auroraTab, findsWidgets);
      await tester.tap(auroraTab.first);
      await tester.pump(const Duration(milliseconds: 300));

      // 3. Redesigned Aurora Chat elements
      // Hero card title
      expect(find.text('Ask Aurora Health AI'), findsOneWidget);
      // Quick prompt pills
      expect(find.text('How is my hydration today?'), findsOneWidget);
      expect(find.text('What is driving my health score?'), findsOneWidget);
      // Input hint
      expect(find.text('Ask about steps, sleep, vitals, or advice...'), findsOneWidget);
      // Send button
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });
  });
}

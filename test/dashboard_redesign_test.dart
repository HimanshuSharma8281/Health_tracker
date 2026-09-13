import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tracker/widgets/glass_container.dart';
import 'package:tracker/widgets/circular_score_gauge.dart';
import 'package:tracker/controllers/health_data_controller.dart';
import 'package:tracker/screens/heart_rate_screen.dart';
import 'package:tracker/screens/calorie_detail_screen.dart';

void main() {
  group('Dashboard Redesign UI & Contract Tests', () {
    testWidgets('CircularScoreGauge renders score, status label, and metric count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularScoreGauge(
                score: 88,
                label: 'Good',
                activeMetricsCount: 5,
                size: 200,
              ),
            ),
          ),
        ),
      );

      // Verify label and wellness score title appear
      expect(find.text('YOUR WELLNESS SCORE'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Overall 88'), findsOneWidget);

      // Advance animation to completion
      await tester.pumpAndSettle();

      // Verify final score number
      expect(find.text('88'), findsOneWidget);
    });

    testWidgets('CircularScoreGauge handles unscored state gracefully without fake numbers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularScoreGauge(
                score: null,
                label: 'Unscored',
                activeMetricsCount: 0,
                size: 200,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display dash and unscored prompt, never fake 0
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Unscored'), findsOneWidget);
      expect(find.text('Log readings to calculate'), findsOneWidget);
    });

    testWidgets('GlassContainer renders child with backdrop filter and decorations',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassContainer(
              onTap: () => tapped = true,
              child: const Text('Frosted Glass Content'),
            ),
          ),
        ),
      );

      expect(find.text('Frosted Glass Content'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);

      // Tap test
      await tester.tap(find.text('Frosted Glass Content'));
      expect(tapped, isTrue);
    });

    test('Dashboard metric formatting contract: missing data returns dashes, never fake zeros', () {
      // Helper formatter simulating dashboard logic
      String formatMetric(double val, String unit) {
        return val > 0 ? '${val.round()} $unit' : '—';
      }

      String formatBP(int systolic, int diastolic) {
        return (systolic > 0 && diastolic > 0) ? '$systolic/$diastolic' : '—/—';
      }

      // When values are missing (0)
      expect(formatMetric(0, 'bpm'), equals('—'));
      expect(formatMetric(0, 'h'), equals('—'));
      expect(formatMetric(0, 'mg/dL'), equals('—'));
      expect(formatBP(0, 0), equals('—/—'));

      // When values exist
      expect(formatMetric(68, 'bpm'), equals('68 bpm'));
      expect(formatMetric(7.5, 'h'), equals('8 h'));
      expect(formatMetric(110, 'mg/dL'), equals('110 mg/dL'));
      expect(formatBP(120, 80), equals('120/80'));
    });

    testWidgets('HeartRateScreen renders hero card, cardiovascular zones, and log action',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = HealthDataController();
      controller.heartRate = 74;

      await tester.pumpWidget(
        ChangeNotifierProvider<HealthDataController>.value(
          value: controller,
          child: const MaterialApp(
            home: HeartRateScreen(),
          ),
        ),
      );

      // Verify app bar title
      expect(find.text('Heart Rate'), findsOneWidget);

      // Verify hero card components
      expect(find.text('RESTING HEART RATE'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(find.text('Normal Resting'), findsOneWidget);

      // Verify cardiovascular zones
      expect(find.text('Cardiovascular Zones'), findsOneWidget);
      expect(find.text('Resting Zone'), findsOneWidget);
      expect(find.text('Fat Burn / Normal'), findsOneWidget);

      // Verify FAB for logging
      expect(find.text('Log Heart Rate'), findsOneWidget);
    });

    testWidgets('CircularScoreGauge dynamically renders 3 rings when 3 cards tracked, and 4 rings when 4th card tracked',
        (WidgetTester tester) async {
      // 1. Initially 3 cards tracked (Steps, Water, Sleep)
      final rings3 = [
        const MetricRingData(
          key: 'steps',
          label: 'Steps',
          progress: 0.85,
          score: 9,
          color: Color(0xFFFFAA4C),
          isTracked: true,
        ),
        const MetricRingData(
          key: 'water',
          label: 'Water',
          progress: 0.60,
          score: 6,
          color: Color(0xFF3A86FF),
          isTracked: true,
        ),
        const MetricRingData(
          key: 'sleep',
          label: 'Sleep',
          progress: 0.90,
          score: 9,
          color: Color(0xFF9B86EC),
          isTracked: true,
        ),
        const MetricRingData(
          key: 'heart_rate',
          label: 'Heart',
          progress: 0.0,
          score: 0,
          color: Color(0xFFFF5C7A),
          isTracked: false,
        ),
        const MetricRingData(
          key: 'calories',
          label: 'Calories',
          progress: 0.0,
          score: 0,
          color: Color(0xFFFFBE0B),
          isTracked: false,
        ),
        const MetricRingData(
          key: 'blood_pressure',
          label: 'BP',
          progress: 0.0,
          score: 0,
          color: Color(0xFF48E5C2),
          isTracked: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularScoreGauge(
              score: 82,
              label: 'Good',
              activeMetricsCount: 3,
              rings: rings3,
              size: 220,
            ),
          ),
        ),
      );

      // Verify tracking counter
      expect(find.text('3 of 6 tracked'), findsOneWidget);
      expect(find.text('Steps 85%'), findsOneWidget);
      expect(find.text('Water 60%'), findsOneWidget);
      expect(find.text('Sleep 90%'), findsOneWidget);
      expect(find.text('Heart 0%'), findsNothing);

      // 2. Now 4th card (Heart Rate) is tracked
      final rings4 = [
        ...rings3.take(3),
        const MetricRingData(
          key: 'heart_rate',
          label: 'Heart',
          progress: 0.72,
          score: 7,
          color: Color(0xFFFF5C7A),
          isTracked: true,
        ),
        ...rings3.skip(4),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularScoreGauge(
              score: 85,
              label: 'Good',
              activeMetricsCount: 4,
              rings: rings4,
              size: 220,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify 4th ring appears with its score
      expect(find.text('4 of 6 tracked'), findsOneWidget);
      expect(find.text('Heart 72%'), findsOneWidget);
    });

    testWidgets('CalorieDetailScreen renders hero card, quick add chips, and dark glass elements',
        (WidgetTester tester) async {
      final controller = HealthDataController();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HealthDataController>.value(
            value: controller,
            child: const CalorieDetailScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title and hero card
      expect(find.text('CALORIE TRACKER'), findsOneWidget);
      expect(find.text('TODAY\'S CALORIES'), findsOneWidget);
      expect(find.text('QUICK ADD TO'), findsOneWidget);

      // Verify search input placeholder
      expect(find.text('Search food items...'), findsOneWidget);

      // Verify FAB for scanning
      expect(find.text('Scan Food'), findsOneWidget);
    });
  });
}

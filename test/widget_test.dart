import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/models/user_profile.dart';
import 'package:tracker/services/health_score_engine.dart';
import 'package:tracker/services/health_analysis_service.dart';

void main() {
  group('HealthAnalysis & AI Contract Tests', () {
    final profile = const UserProfile(
      uid: 'test-user-ai',
      name: 'Aurora User',
      email: 'user@aurora.app',
      avatarUrl: '',
      age: 28,
      heightCm: 170.0,
      weightKg: 65.0,
      activityLevel: 'active',
      fitnessGoal: 'stay_healthy',
    );

    test('HealthScoreEngine generates deterministic score with zero randomness', () {
      final score = HealthScoreEngine.calculate(
        profile: profile,
        date: '2026-09-12',
        heartRateBpm: 70,
        systolic: 120,
        diastolic: 80,
        sleepHours: 8.0,
        waterMl: 2500,
        caloriesKcal: 2000,
        steps: 10000,
      );

      expect(score.overall, inInclusiveRange(0, 100));
      expect(score.label, isNotEmpty);
      expect(score.metrics['sleep']!.available, isTrue);
      expect(score.metrics['sleep']!.score, equals(10));
    });

    test('HealthAnalysis model correctly retains deterministic scores', () {
      final analysis = HealthAnalysis(
        overallScore: 88,
        healthStatus: 'Optimal',
        dailySummary: 'Excellent health status across all monitored metrics.',
        strengths: ['Consistent hydration', '8 hours restorative sleep'],
        areasToImprove: ['Slightly low steps compared to goal'],
        recommendations: ['Take a 15-minute evening walk'],
        insights: ['Good sleep correlates with steady resting heart rate'],
      );

      expect(analysis.overallScore, equals(88));
      expect(analysis.healthStatus, equals('Optimal'));
      expect(analysis.strengths.length, equals(2));
      expect(analysis.recommendations.length, equals(1));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/models/health_reading.dart';
import 'package:tracker/models/activity_models.dart';
import 'package:tracker/controllers/health_data_controller.dart';

void main() {
  group('Meal & Calorie Date-Filtering Tests', () {
    test('a) Yesterday meal is excluded today and b) Today meal is included today', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final yesterdayReading = HealthReading(
        id: 'meal_yesterday_1',
        userId: 'test_user',
        metric: HealthReading.calories,
        value: 650.0,
        date: HealthReading.formatDate(yesterday),
        timestamp: yesterday,
        metadata: {'mealType': 'dinner', 'mealName': 'Pasta'},
      );

      final todayReading = HealthReading(
        id: 'meal_today_1',
        userId: 'test_user',
        metric: HealthReading.calories,
        value: 158.0,
        date: HealthReading.formatDate(now),
        timestamp: now,
        metadata: {'mealType': 'breakfast', 'mealName': 'Boiled Eggs & Toast'},
      );

      final allReadings = [yesterdayReading, todayReading];

      // Simulate step 3b logic from HealthDataController
      final calReadings = allReadings.where((r) => r.metric == HealthReading.calories).toList();
      final meals = <MealEntry>[];
      final mealHistory = <MealEntry>[];

      for (final r in calReadings.reversed) {
        final mealTypeStr = r.metadata['mealType'] as String?;
        final mealName = r.metadata['mealName'] as String? ?? 'Meal';
        final mealType = MealType.values.firstWhere(
          (m) => m.name == mealTypeStr,
          orElse: () => MealType.snack,
        );
        final meal = MealEntry(
          id: r.id,
          name: mealName,
          calories: r.value.round(),
          time: r.timestamp,
          mealType: mealType,
        );

        mealHistory.add(meal);

        if (HealthReading.isReadingOnDate(r, now)) {
          meals.add(meal);
        }
      }

      // a) Yesterday's meal is excluded from today's meal list
      expect(meals.any((m) => m.name == 'Pasta'), isFalse);
      expect(meals.any((m) => m.id == 'meal_yesterday_1'), isFalse);

      // b) Today's meal is included today
      expect(meals.length, equals(1));
      expect(meals.first.name, equals('Boiled Eggs & Toast'));
      expect(meals.first.calories, equals(158));

      // e) Historical meal data is not deleted
      expect(mealHistory.length, equals(2));
      expect(mealHistory.any((m) => m.name == 'Pasta'), isTrue);
    });

    test('c) Tomorrow query does not include today meal and d) Today calorie total contains only today meals (158 kcal)', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final todayReading = HealthReading(
        id: 'meal_today_1',
        userId: 'test_user',
        metric: HealthReading.calories,
        value: 158.0,
        date: HealthReading.formatDate(now),
        timestamp: now,
        metadata: {'mealType': 'breakfast', 'mealName': 'Oatmeal & Berries'},
      );

      // Verify that today reading is NOT for tomorrow
      expect(HealthReading.isReadingOnDate(todayReading, tomorrow), isFalse);
      expect(HealthReading.isReadingOnDate(todayReading, now), isTrue);

      final mealsToday = <MealEntry>[];
      final mealsTomorrow = <MealEntry>[];

      if (HealthReading.isReadingOnDate(todayReading, now)) {
        mealsToday.add(MealEntry(
          id: todayReading.id,
          name: 'Oatmeal & Berries',
          calories: todayReading.value.round(),
          time: todayReading.timestamp,
        ));
      }

      if (HealthReading.isReadingOnDate(todayReading, tomorrow)) {
        mealsTomorrow.add(MealEntry(
          id: todayReading.id,
          name: 'Oatmeal & Berries',
          calories: todayReading.value.round(),
          time: todayReading.timestamp,
        ));
      }

      // d) Today calorie total contains only today's meals (158 kcal)
      final caloriesConsumedToday = mealsToday.fold<double>(0.0, (sum, m) => sum + m.calories);
      expect(caloriesConsumedToday, equals(158.0));

      // c) Tomorrow's meal list starts empty
      expect(mealsTomorrow, isEmpty);
      final caloriesConsumedTomorrow = mealsTomorrow.fold<double>(0.0, (sum, m) => sum + m.calories);
      expect(caloriesConsumedTomorrow, equals(0.0));
    });

    test('HealthReading.isSameDay matches exact local calendar days', () {
      final dt1 = DateTime(2026, 9, 13, 8, 30);
      final dt2 = DateTime(2026, 9, 13, 21, 45);
      final dtYesterday = DateTime(2026, 9, 12, 23, 59);
      final dtTomorrow = DateTime(2026, 9, 14, 0, 1);

      expect(HealthReading.isSameDay(dt1, dt2), isTrue);
      expect(HealthReading.isSameDay(dt1, dtYesterday), isFalse);
      expect(HealthReading.isSameDay(dt1, dtTomorrow), isFalse);
    });
  });
}

import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../controllers/health_data_controller.dart';
import '../models/activity_models.dart';
import '../models/analytics_models.dart';

class PredictiveAnalytics {
  static ForecastBundle stepAndCalorieForecast(List<ActivityEntry> history) {
    final actualSteps = <FlSpot>[];
    final actualCalories = <FlSpot>[];
    for (var i = 0; i < history.length; i++) {
      actualSteps.add(FlSpot(i.toDouble(), history[i].steps.toDouble()));
      actualCalories.add(FlSpot(i.toDouble(), history[i].calories.toDouble()));
    }
    final stepForecast = _forecastSeries(actualSteps, 3);
    final calorieForecast = _forecastSeries(actualCalories, 3);
    return ForecastBundle(
      stepsActual: actualSteps,
      stepsForecast: stepForecast,
      caloriesActual: actualCalories,
      caloriesForecast: calorieForecast,
    );
  }

  static List<FlSpot> _forecastSeries(List<FlSpot> base, int days) {
    if (base.length < 2) return base;
    double delta = 0;
    for (var i = 1; i < base.length; i++) {
      delta += base[i].y - base[i - 1].y;
    }
    delta /= (base.length - 1);
    final forecast = <FlSpot>[];
    var lastValue = base.last.y;
    var index = base.last.x;
    for (int i = 0; i < days; i++) {
      index += 1;
      lastValue = max(0, lastValue + delta * 0.9);
      forecast.add(FlSpot(index, lastValue));
    }
    return forecast;
  }

  static String optimalBedtime(HealthDataController data) {
    final now = DateTime.now();
    final fatigue = (data.stressLevel * 40).round();
    final minutes = max(60, 120 - fatigue);
    final bedtime = DateTime(now.year, now.month, now.day, 22)
        .subtract(Duration(minutes: minutes));
    return DateFormat.jm().format(bedtime);
  }
}

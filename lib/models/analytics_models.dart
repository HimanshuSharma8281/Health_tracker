import 'package:fl_chart/fl_chart.dart';

class GoalPlan {
  GoalPlan({
    required this.stepGoal,
    required this.waterGoal,
    required this.calorieGoal,
    required this.sleepGoal,
    required this.mindfulnessGoal,
  });

  final int stepGoal;
  final int waterGoal;
  final int calorieGoal;
  final double sleepGoal;
  final int mindfulnessGoal;
}

class ForecastBundle {
  ForecastBundle({
    required this.stepsActual,
    required this.stepsForecast,
    required this.caloriesActual,
    required this.caloriesForecast,
  });

  final List<FlSpot> stepsActual;
  final List<FlSpot> stepsForecast;
  final List<FlSpot> caloriesActual;
  final List<FlSpot> caloriesForecast;
}

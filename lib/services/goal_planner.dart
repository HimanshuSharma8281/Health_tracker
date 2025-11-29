import '../controllers/health_data_controller.dart';
import '../models/analytics_models.dart';

class GoalPlanner {
  static GoalPlan generate(HealthDataController data) {
    final stepAdjustment = data.stepsToday < data.stepGoal ? 1200 : 400;
    final waterAdjustment = data.waterMl < data.waterGoal ? 300 : 0;
    final calorieTarget = data.caloriesConsumed > data.calorieGoal
        ? data.calorieGoal - 150
        : data.calorieGoal;
    final mindfulnessTarget =
        data.mindfulnessMinutes < 20 ? 20 : data.mindfulnessMinutes + 5;
    final sleepTarget = data.sleepHours < data.sleepGoal
        ? data.sleepGoal + 0.3
        : data.sleepGoal;
    return GoalPlan(
      stepGoal: (data.stepsToday + stepAdjustment).clamp(8500, 15000),
      waterGoal: data.waterGoal + waterAdjustment,
      calorieGoal: calorieTarget.round(),
      sleepGoal: double.parse(sleepTarget.toStringAsFixed(1)),
      mindfulnessGoal: mindfulnessTarget,
    );
  }
}

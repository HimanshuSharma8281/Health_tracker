import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepTrackingService {
  static StepTrackingService? _instance;
  static StepTrackingService get instance =>
      _instance ??= StepTrackingService._();

  StepTrackingService._();

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  int _initialStepsForToday = 0;
  int _totalStepsFromSensor = 0;
  String _pedestrianStatus = 'unknown';

  Function(int steps)? onStepsUpdated;
  Function(String status)? onStatusChanged;

  Future<void> initialize() async {
    // Load saved initial steps for today
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('step_date');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (savedDate != today) {
      // New day - reset initial steps
      _initialStepsForToday = 0;
      await prefs.setString('step_date', today);
      await prefs.setInt('initial_steps', 0);
    } else {
      _initialStepsForToday = prefs.getInt('initial_steps') ?? 0;
    }

    _startListening();
  }

  void _startListening() {
    // Listen to step count stream
    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: false,
    );

    // Listen to pedestrian status stream (walking/stopped)
    _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatusChanged,
      onError: _onPedestrianStatusError,
      cancelOnError: false,
    );
  }

  void _onStepCount(StepCount event) async {
    _totalStepsFromSensor = event.steps;

    // If this is the first reading of the day, set initial steps
    if (_initialStepsForToday == 0) {
      _initialStepsForToday = event.steps;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('initial_steps', _initialStepsForToday);
    }

    // Calculate today's steps
    final todaySteps = _totalStepsFromSensor - _initialStepsForToday;

    // Notify listeners
    onStepsUpdated?.call(todaySteps > 0 ? todaySteps : 0);
  }

  void _onStepCountError(error) {
    print('Step count error: $error');
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    _pedestrianStatus = event.status.toString().split('.').last;
    onStatusChanged?.call(_pedestrianStatus);
  }

  void _onPedestrianStatusError(error) {
    print('Pedestrian status error: $error');
    _pedestrianStatus = 'unknown';
  }

  String get pedestrianStatus => _pedestrianStatus;

  int get todaySteps {
    final steps = _totalStepsFromSensor - _initialStepsForToday;
    return steps > 0 ? steps : 0;
  }

  Future<void> resetDailySteps() async {
    _initialStepsForToday = _totalStepsFromSensor;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('step_date', today);
    await prefs.setInt('initial_steps', _initialStepsForToday);
    onStepsUpdated?.call(0);
  }

  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_reading.dart';

/// Service responsible for managing hardware step counter sensors on Android & iOS.
/// Accurately tracks daily steps across app backgrounding, app termination, and phone reboots.
class StepTrackingService {
  static StepTrackingService? _instance;
  static StepTrackingService get instance =>
      _instance ??= StepTrackingService._();

  StepTrackingService._();

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  String _currentTrackingDate = '';
  int _dayBaselineSensorSteps = 0;
  int _stepsBeforeReboot = 0;
  int _lastKnownSensorSteps = 0;
  int _todaySteps = 0;
  String _pedestrianStatus = 'unknown';
  bool _isListening = false;

  Function(int steps)? onStepsUpdated;
  Function(String status)? onStatusChanged;

  // Persistent storage keys
  static const _kStepDate = 'step_tracking_date';
  static const _kDayBaseline = 'day_baseline_sensor_steps';
  static const _kStepsBeforeReboot = 'steps_before_reboot';
  static const _kLastKnownSensor = 'last_known_sensor_steps';
  static const _kTodaySteps = 'today_steps_total';

  /// Initialize step tracking service and restore state from persistent storage.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final today = HealthReading.todayDate();
    final savedDate = prefs.getString(_kStepDate);

    _currentTrackingDate = today;

    if (savedDate == null || savedDate.isEmpty) {
      // First app launch ever
      _dayBaselineSensorSteps = 0;
      _stepsBeforeReboot = 0;
      _lastKnownSensorSteps = 0;
      _todaySteps = 0;
      await _saveState(prefs);
      debugPrint('👟 [StepTracking] Fresh initialization for date=$today');
    } else if (savedDate != today) {
      // Midnight / Calendar day rollover
      final previousLastSensor = prefs.getInt(_kLastKnownSensor) ?? 0;
      _dayBaselineSensorSteps = previousLastSensor;
      _stepsBeforeReboot = 0;
      _lastKnownSensorSteps = previousLastSensor;
      _todaySteps = 0;
      await _saveState(prefs);
      debugPrint('👟 [StepTracking] Day rollover initialized for date=$today with baseline=$previousLastSensor');
    } else {
      // Same day restoration
      _dayBaselineSensorSteps = prefs.getInt(_kDayBaseline) ?? 0;
      _stepsBeforeReboot = prefs.getInt(_kStepsBeforeReboot) ?? 0;
      _lastKnownSensorSteps = prefs.getInt(_kLastKnownSensor) ?? 0;
      _todaySteps = prefs.getInt(_kTodaySteps) ?? 0;
      debugPrint('👟 [StepTracking] Restored state for date=$today: baseline=$_dayBaselineSensorSteps, todaySteps=$_todaySteps, lastSensor=$_lastKnownSensorSteps');
    }

    // Immediately broadcast restored step count so UI displays instantly
    if (_todaySteps > 0) {
      onStepsUpdated?.call(_todaySteps);
    }

    await _startListening();
  }

  /// Request permissions and subscribe to hardware pedometer streams.
  Future<void> _startListening() async {
    try {
      final status = await Permission.activityRecognition.status;
      if (!status.isGranted) {
        final requestResult = await Permission.activityRecognition.request();
        if (!requestResult.isGranted) {
          debugPrint('⚠️ [StepTracking] Activity recognition permission not granted ($requestResult)');
          return;
        }
      }

      // Always cancel existing subscriptions before re-subscribing
      await _stepCountSubscription?.cancel();
      await _pedestrianStatusSubscription?.cancel();

      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
        cancelOnError: false,
      );

      _isListening = true;
      debugPrint('👟 [StepTracking] Hardware pedometer stream listeners active');
    } catch (e) {
      debugPrint('🔴 [StepTracking] Error starting pedometer streams: $e');
      _isListening = false;
    }
  }

  /// Called on each hardware step counter event.
  void _onStepCount(StepCount event) {
    _processSensorReading(event.steps);
  }

  /// Authoritative calculation of today's steps from cumulative hardware sensor steps.
  void _processSensorReading(int rawSensorSteps) {
    if (rawSensorSteps <= 0) return;

    final today = HealthReading.todayDate();

    // 1. Check for Midnight Day Rollover
    if (_currentTrackingDate != today) {
      debugPrint('👟 [StepTracking] Day rollover detected: $_currentTrackingDate -> $today');
      _currentTrackingDate = today;
      _dayBaselineSensorSteps = _lastKnownSensorSteps > 0 ? _lastKnownSensorSteps : rawSensorSteps;
      _stepsBeforeReboot = 0;
      _lastKnownSensorSteps = rawSensorSteps;
      _todaySteps = (rawSensorSteps - _dayBaselineSensorSteps).clamp(0, 1000000);
      _saveStateAsync();
      onStepsUpdated?.call(_todaySteps);
      return;
    }

    // 2. Same-day initial baseline calibration
    if (_dayBaselineSensorSteps <= 0) {
      _dayBaselineSensorSteps = rawSensorSteps;
      _lastKnownSensorSteps = rawSensorSteps;
      _saveStateAsync();
      debugPrint('👟 [StepTracking] First baseline set for $today: $rawSensorSteps');
    }

    // 3. Check for Device Reboot (hardware step counter resets to 0 after reboot)
    if (_lastKnownSensorSteps > 0 && rawSensorSteps < _lastKnownSensorSteps) {
      debugPrint('🔄 [StepTracking] Device reboot detected! rawSensorSteps=$rawSensorSteps < lastKnown=$_lastKnownSensorSteps. Saving previous today total $_todaySteps.');
      _stepsBeforeReboot = _todaySteps;
      _dayBaselineSensorSteps = rawSensorSteps;
    }

    _lastKnownSensorSteps = rawSensorSteps;

    // 4. Calculate steps accumulated today
    final int stepsSinceBaseline = rawSensorSteps - _dayBaselineSensorSteps;
    final int calculatedToday = _stepsBeforeReboot + (stepsSinceBaseline > 0 ? stepsSinceBaseline : 0);

    // Monotonic guarantee for today's step count
    if (calculatedToday >= _todaySteps) {
      _todaySteps = calculatedToday;
      _saveStateAsync();
    }

    onStepsUpdated?.call(_todaySteps);
  }

  Future<void> _saveState(SharedPreferences prefs) async {
    try {
      await prefs.setString(_kStepDate, _currentTrackingDate);
      await prefs.setInt(_kDayBaseline, _dayBaselineSensorSteps);
      await prefs.setInt(_kStepsBeforeReboot, _stepsBeforeReboot);
      await prefs.setInt(_kLastKnownSensor, _lastKnownSensorSteps);
      await prefs.setInt(_kTodaySteps, _todaySteps);
    } catch (e) {
      debugPrint('⚠️ [StepTracking] _saveState error: $e');
    }
  }

  void _saveStateAsync() {
    SharedPreferences.getInstance().then((prefs) {
      _saveState(prefs);
    }).catchError((e) {
      debugPrint('⚠️ [StepTracking] _saveStateAsync error: $e');
    });
  }

  void _onStepCountError(dynamic error) {
    debugPrint('⚠️ [StepTracking] Step count stream error: $error');
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    _pedestrianStatus = event.status.toString().split('.').last;
    onStatusChanged?.call(_pedestrianStatus);
  }

  void _onPedestrianStatusError(dynamic error) {
    debugPrint('⚠️ [StepTracking] Pedestrian status error: $error');
    _pedestrianStatus = 'unknown';
  }

  String get pedestrianStatus => _pedestrianStatus;

  bool get isListening => _isListening;

  int get todaySteps => _todaySteps;

  /// Check date transition and force re-bind hardware sensor when app resumes from background.
  Future<void> checkAndSyncOnResume() async {
    final today = HealthReading.todayDate();
    if (_currentTrackingDate != today) {
      await initialize();
    } else {
      // Always re-bind the hardware sensor listener upon resume so Android delivers updated steps immediately
      await _startListening();
      if (_todaySteps > 0) {
        onStepsUpdated?.call(_todaySteps);
      }
    }
  }

  /// Manually reset daily steps (e.g. for testing or calendar reset).
  Future<void> resetDailySteps() async {
    _dayBaselineSensorSteps = _lastKnownSensorSteps;
    _stepsBeforeReboot = 0;
    _todaySteps = 0;

    final today = HealthReading.todayDate();
    _currentTrackingDate = today;

    final prefs = await SharedPreferences.getInstance();
    await _saveState(prefs);

    onStepsUpdated?.call(0);
    debugPrint('👟 [StepTracking] Daily steps reset to 0');
  }

  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _isListening = false;
  }
}

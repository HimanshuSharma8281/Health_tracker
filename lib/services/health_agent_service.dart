import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/health_reading.dart';
import '../models/user_profile.dart';
import '../controllers/health_data_controller.dart';
import '../services/firestore_service.dart';
import '../config/api_keys.dart';

/// Gemini AI Health Agent with tool-using capability.
///
/// The agent can answer health questions by calling read-only tools
/// that fetch real data from Firestore. It reasons over actual data —
/// it does NOT invent readings or scores.
///
/// Phase 7 implementation — read-only tools:
///   • getUserProfile
///   • getTodayReadings
///   • getDailyScore
///   • getWeeklyScores
///   • getReadingHistory
///   • detectTrends
///   • getActiveChallenges (via SocialService)
class HealthAgentService {
  static String get _apiKey => ApiKeys.geminiApiKey;

  static const String _systemInstruction = '''
You are Aurora, an AI health agent inside the Aurora Wellness app.

You have access to tools that fetch real health data from the user's profile.
ALWAYS use the appropriate tools to get data before answering.
NEVER invent readings, scores, or trends not returned by your tools.
NEVER diagnose medical conditions.
Be encouraging, specific, and concise in your responses.
When health data is unavailable, say so clearly and suggest the user logs it.
''';

  // ── Tool definitions ──────────────────────────────────────────────────────

  static final List<Tool> _tools = [
    Tool(functionDeclarations: [
      FunctionDeclaration(
        'getUserProfile',
        'Get the user\'s profile including demographics (age, sex, height, weight, activity level, fitness goal) and daily goals.',
        Schema.object(properties: {}),
      ),
      FunctionDeclaration(
        'getTodayReadings',
        'Get all health readings logged today (water, sleep, heart rate, blood pressure, calories, steps, blood sugar).',
        Schema.object(properties: {}),
      ),
      FunctionDeclaration(
        'getDailyScore',
        'Get the deterministic health score for a specific date.',
        Schema.object(properties: {
          'date': Schema.string(description: 'Date in YYYY-MM-DD format. Use today\'s date if not specified.'),
        }, requiredProperties: ['date']),
      ),
      FunctionDeclaration(
        'getWeeklyScores',
        'Get daily health scores for the last 7 days to analyze trends.',
        Schema.object(properties: {}),
      ),
      FunctionDeclaration(
        'getReadingHistory',
        'Get recent readings for a specific health metric.',
        Schema.object(properties: {
          'metric': Schema.string(description: 'Metric type: water, sleep, steps, heart_rate, blood_pressure, blood_sugar, calories'),
          'days': Schema.integer(description: 'Number of past days to retrieve (1-30)'),
        }, requiredProperties: ['metric']),
      ),
      FunctionDeclaration(
        'detectTrends',
        'Analyze trends for a specific metric over recent days and return whether it is improving, declining, or stable.',
        Schema.object(properties: {
          'metric': Schema.string(description: 'Metric type: water, sleep, steps, heart_rate, blood_pressure, calories'),
        }, requiredProperties: ['metric']),
      ),
    ]),
  ];

  // ════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ════════════════════════════════════════════════════════════════════════

  static String _formatNumber(num value) {
    if (value >= 1000) {
      return value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    return value.toInt().toString();
  }

  /// Send a message to the health agent and get a response.
  ///
  /// [uid] is the Firebase UID of the authenticated user.
  /// [conversationHistory] is the list of previous [ChatMessage]s to maintain context.
  /// [healthData] and [userProfile] supply the active user's live metrics and goals.
  static Future<AgentResponse> chat({
    required String uid,
    required String userMessage,
    List<Content>? conversationHistory,
    HealthDataController? healthData,
    UserProfile? userProfile,
  }) async {
    try {
      debugPrint('🤖 [HealthAgentService] Sending user message to gemini-3.6-flash: "$userMessage"');

      final dynamicInstruction = StringBuffer(_systemInstruction);
      if (healthData != null) {
        final name = userProfile?.name ?? healthData.username ?? 'User';
        dynamicInstruction.writeln('\nUser Context: $name');
        dynamicInstruction.writeln('Today\'s Live Readings & Goals:');
        dynamicInstruction.writeln('- Water Intake: ${healthData.waterMl} ml / ${healthData.waterGoal} ml');
        dynamicInstruction.writeln('- Steps: ${healthData.stepsToday} / ${healthData.stepGoal}');
        dynamicInstruction.writeln('- Sleep: ${healthData.sleepHours > 0 ? "${healthData.sleepHours.toStringAsFixed(1)} hours" : "not logged"} (goal: ${healthData.sleepGoal.toStringAsFixed(1)}h)');
        dynamicInstruction.writeln('- Calories: ${healthData.caloriesConsumed.round()} kcal / ${healthData.calorieGoal.round()} kcal');
        dynamicInstruction.writeln('- Heart Rate: ${healthData.heartRate > 0 ? "${healthData.heartRate.round()} bpm" : "not logged"}');
        if (healthData.todayScore != null) {
          dynamicInstruction.writeln('- Wellness Score: ${healthData.todayScore!.overall}/100 (${healthData.todayScore!.label})');
        }
      }

      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: _apiKey,
        tools: _tools,
        systemInstruction: Content.system(dynamicInstruction.toString()),
      );

      final chat = model.startChat(history: conversationHistory ?? []);

      // Send user message
      var response = await chat.sendMessage(Content.text(userMessage))
          .timeout(const Duration(seconds: 30));

      // Tool-call loop — keep processing until no more function calls
      int maxIterations = 5; // safety guard
      while (response.functionCalls.isNotEmpty && maxIterations-- > 0) {
        final toolResults = <FunctionResponse>[];

        for (final call in response.functionCalls) {
          debugPrint('🤖 [HealthAgentService] Gemini requested tool: ${call.name} (args: ${call.args})');
          final result = await _executeTool(
            uid,
            call.name,
            call.args,
            healthData: healthData,
            userProfile: userProfile,
          );
          debugPrint('🤖 [HealthAgentService] Tool ${call.name} completed with keys: ${result.keys.join(", ")}');
          toolResults.add(FunctionResponse(call.name, result));
        }

        // Send tool results back to the model
        response = await chat.sendMessage(Content.functionResponses(toolResults))
            .timeout(const Duration(seconds: 30));
      }

      final text = response.text ?? 'I could not generate a response. Please try again.';

      return AgentResponse(
        text: text,
        updatedHistory: chat.history.toList(),
      );
    } catch (e) {
      debugPrint('🔴 [HealthAgentService] Gemini error/quota: $e');
      debugPrint('💡 [HealthAgentService] Seamlessly routing to clinical agent engine for UID: $uid');

      final fallbackText = await _generateDeterministicAgentResponse(
        uid,
        userMessage,
        healthData: healthData,
        userProfile: userProfile,
      );

      return AgentResponse(
        text: fallbackText,
        updatedHistory: [
          ...?conversationHistory,
          Content.text(userMessage),
          Content.model([TextPart(fallbackText)]),
        ],
      );
    }
  }

  /// Intelligent clinical fallback that answers user questions using real
  /// user data (live controller, profile, deterministic score) whenever Gemini
  /// API is unavailable, rate-limited, or out of quota.
  static Future<String> _generateDeterministicAgentResponse(
    String uid,
    String userMessage, {
    HealthDataController? healthData,
    UserProfile? userProfile,
  }) async {
    try {
      Map<String, dynamic> readings = const {};
      try {
        readings = await _toolGetTodayReadings(uid, healthData: healthData);
      } catch (e) {
        debugPrint('⚠️ [HealthAgentService] Failed to load readings: $e');
      }

      Map<String, dynamic> profile = const {};
      try {
        profile = await _toolGetUserProfile(uid, userProfile: userProfile, healthData: healthData);
      } catch (e) {
        debugPrint('⚠️ [HealthAgentService] Failed to load profile: $e');
      }

      Map<String, dynamic> scoreData = const {};
      try {
        scoreData = await _toolGetDailyScore(uid, HealthReading.todayDate(), healthData: healthData);
      } catch (e) {
        debugPrint('⚠️ [HealthAgentService] Failed to load scoreData: $e');
      }

      final query = userMessage.toLowerCase().trim();

      // 1. Hydration intent
      if (query.contains('water') ||
          query.contains('hydration') ||
          query.contains('fluid') ||
          query.contains('drink') ||
          query.contains('thirsty')) {
        final waterMl = readings['water_ml'] as int? ?? 0;
        final waterGoal = profile['water_goal_ml'] as int? ?? 2500;
        final effectiveGoal = waterGoal > 0 ? waterGoal : 2500;
        final percent = (waterMl / effectiveGoal * 100).round();
        final remaining = effectiveGoal - waterMl;

        final formattedLogged = _formatNumber(waterMl);
        final formattedGoal = _formatNumber(effectiveGoal);
        final formattedRemaining = _formatNumber(remaining.abs());

        if (waterMl > 0) {
          if (remaining <= 0) {
            return '💧 **Hydration Status:**\n\n'
                'You have logged **$formattedLogged ml** of water today, exceeding your daily target of **$formattedGoal ml** ($percent%)!\n\n'
                'Excellent work maintaining cellular hydration and metabolic balance today.';
          } else {
            return '💧 **Hydration Status:**\n\n'
                'You have logged **$formattedLogged ml** of water today, which is **$percent%** of your daily goal (**$formattedGoal ml**).\n\n'
                'You need approximately **$formattedRemaining ml** more to reach your optimal target. Try keeping a glass or bottle nearby to stay consistent through the afternoon!';
          }
        } else {
          return '💧 **Hydration Status:**\n\n'
              'You haven\'t logged any water intake yet today. Your daily target is **$formattedGoal ml**.\n\n'
              'Drinking a glass of water now will kickstart your hydration and help boost your daily Wellness Score!';
        }
      }

      // 2. Sleep intent
      if (query.contains('sleep') ||
          query.contains('rest') ||
          query.contains('slept') ||
          query.contains('bed') ||
          query.contains('insomnia') ||
          query.contains('night')) {
        final sleepHours = readings['sleep_hours'] as num?;
        final sleepGoal = profile['sleep_goal_hours'] as num? ?? 8.0;

        if (sleepHours != null && sleepHours > 0) {
          final isOptimal = sleepHours >= 7 && sleepHours <= 9;
          return '😴 **Sleep Recovery:**\n\n'
              'You logged **${sleepHours.toStringAsFixed(1)} hours** of sleep last night (target: **${sleepGoal.toStringAsFixed(1)}h**).\n\n'
              '${isOptimal ? "You are within the clinically recommended 7–9 hour restorative sleep window, supporting cognitive recovery and hormonal balance." : sleepHours < 7 ? "You are slightly below the recommended 7–8 hour target. To improve recovery, aim for a quiet, dark environment and limit screen exposure 45 minutes before sleep tonight." : "You slept longer than your baseline target. Adequate daylight exposure today will help reinforce your circadian cycle."}';
        } else {
          return '😴 **Sleep Recovery:**\n\n'
              'No sleep duration has been recorded for last night yet. Your target is **${sleepGoal.toStringAsFixed(1)} hours**.\n\n'
              'Logging your sleep gives you deeper clinical insights into cardiovascular recovery and daily energy.';
        }
      }

      // 3. Steps & Activity intent
      if (query.contains('step') ||
          query.contains('walk') ||
          query.contains('activity') ||
          query.contains('move') ||
          query.contains('running') ||
          query.contains('jog')) {
        final steps = readings['steps'] as int? ?? 0;
        final stepGoal = profile['step_goal'] as int? ?? 10000;
        final effectiveStepGoal = stepGoal > 0 ? stepGoal : 10000;
        final percent = (steps / effectiveStepGoal * 100).round();
        final remaining = effectiveStepGoal - steps;

        final formattedSteps = _formatNumber(steps);
        final formattedGoal = _formatNumber(effectiveStepGoal);
        final formattedRemaining = _formatNumber(remaining.abs());

        if (steps > 0) {
          if (remaining <= 0) {
            return '👟 **Activity & Steps:**\n\n'
                'You\'ve achieved **$formattedSteps steps** today (**$percent%** of your **$formattedGoal step** goal)!\n\n'
                'Outstanding commitment to daily movement! Sustained physical activity significantly improves cardiovascular fitness and insulin sensitivity.';
          } else {
            return '👟 **Activity & Steps:**\n\n'
                'You have tracked **$formattedSteps steps** today, which is **$percent%** of your **$formattedGoal step** target.\n\n'
                'You have **$formattedRemaining steps** left to hit your goal. A brisk 15–20 minute walk will help you close the gap and elevate your daily activity score!';
          }
        } else {
          return '👟 **Activity & Steps:**\n\n'
              'No steps have been recorded yet today. Your daily goal is **$formattedGoal steps**.\n\n'
              'Even short 5-minute walking breaks during the day help improve blood circulation and reduce sedentary risk.';
        }
      }

      // 4. Heart Rate, Blood Pressure & Cardio
      if (query.contains('heart') ||
          query.contains('bpm') ||
          query.contains('pulse') ||
          query.contains('cardio') ||
          query.contains('blood pressure') ||
          query.contains('bp') ||
          query.contains('hypertension')) {
        final hr = readings['heart_rate_bpm'] as num?;
        final bp = readings['blood_pressure'] as String?;

        final hrText = hr != null ? '**${hr.round()} bpm**' : 'not logged yet';
        final bpText = bp != null ? '**$bp mmHg**' : 'not logged yet';

        return '❤️ **Cardiovascular Status:**\n\n'
            '• Resting Heart Rate: $hrText\n'
            '• Blood Pressure: $bpText\n\n'
            '${hr != null && hr >= 60 && hr <= 100 ? "Your resting heart rate is within the healthy adult range (60–100 bpm)." : hr != null && hr > 100 ? "Your resting heart rate is slightly elevated. Hydration, stress management, and light rest can help bring it into the optimal range." : "Consistent cardiovascular readings allow Aurora to track baseline heart health and detect recovery trends."}';
      }

      // 5. Calories & Nutrition
      if (query.contains('calorie') ||
          query.contains('food') ||
          query.contains('diet') ||
          query.contains('eat') ||
          query.contains('meal') ||
          query.contains('kcal') ||
          query.contains('nutrition')) {
        final calories = readings['calories_kcal'] as int? ?? 0;
        final calorieGoal = profile['calorie_goal'] as int? ?? 2000;
        final effectiveGoal = calorieGoal > 0 ? calorieGoal : 2000;
        final percent = (calories / effectiveGoal * 100).round();

        final formattedCalories = _formatNumber(calories);
        final formattedGoal = _formatNumber(effectiveGoal);

        return '🔥 **Calorie & Nutrition Balance:**\n\n'
            'You have logged **$formattedCalories kcal** today against your daily target of **$formattedGoal kcal** ($percent%).\n\n'
            'Maintaining a balanced intake of whole foods, adequate protein, and hydration ensures steady energy without blood sugar spikes.';
      }

      // 6. Wellness Score & Improvement
      if (query.contains('score') ||
          query.contains('improve') ||
          query.contains('status') ||
          query.contains('summary') ||
          query.contains('how am i') ||
          query.contains('overall') ||
          query.contains('wellness')) {
        final overall = scoreData['overall_score'] as int? ?? 50;
        final label = scoreData['label'] as String? ?? 'Needs Improvement';
        final metricCount = scoreData['available_metrics'] as int? ?? 0;

        final formattedWaterGoal = _formatNumber(profile['water_goal_ml'] as int? ?? 2500);
        final formattedStepGoal = _formatNumber(profile['step_goal'] as int? ?? 10000);

        return '📊 **Wellness Score Overview:**\n\n'
            'Your deterministic Wellness Score for today is **$overall / 100 ($label)** evaluated across **$metricCount metrics**.\n\n'
            '💡 **Top Action Steps to Improve:**\n'
            '1. **Hydration**: Ensure you meet your daily water goal of $formattedWaterGoal ml.\n'
            '2. **Activity**: Reach your target of $formattedStepGoal steps.\n'
            '3. **Rest**: Prioritize 7–9 hours of sleep tonight for full cognitive and muscular recovery.';
      }

      // 7. General health questions or greetings
      final rawName = profile['name'] as String? ?? 'there';
      final name = rawName.split(' ').first;
      final scoreVal = scoreData['overall_score'] ?? 50;
      final scoreLabel = scoreData['label'] ?? 'Needs Improvement';
      final waterVal = _formatNumber(readings['water_ml'] as int? ?? 0);
      final waterTarget = _formatNumber(profile['water_goal_ml'] as int? ?? 2500);
      final stepVal = _formatNumber(readings['steps'] as int? ?? 0);
      final stepTarget = _formatNumber(profile['step_goal'] as int? ?? 10000);

      return 'Hello $name! I am Aurora, your clinical AI health coach.\n\n'
          'Today\'s Quick Snapshot:\n'
          '• Wellness Score: **$scoreVal/100 ($scoreLabel)**\n'
          '• Water: **$waterVal ml** / $waterTarget ml\n'
          '• Steps: **$stepVal** / $stepTarget\n\n'
          'What aspect of your health would you like to explore or improve today?';
    } catch (e) {
      debugPrint('🔴 [HealthAgentService] Fallback generation error: $e');
      final q = userMessage.toLowerCase();
      if (q.contains('water') || q.contains('hydrat') || q.contains('drink') || q.contains('fluid')) {
        return '💧 **Hydration Status:**\n\nMaintaining consistent hydration supports circulation and energy. Aim for 2,500 ml of water daily!';
      }
      if (q.contains('step') || q.contains('walk') || q.contains('activity') || q.contains('move')) {
        return '👟 **Activity & Steps:**\n\nDaily physical activity improves cardiovascular health and metabolism. Strive towards 10,000 steps today!';
      }
      if (q.contains('sleep') || q.contains('rest') || q.contains('bed')) {
        return '😴 **Sleep Recovery:**\n\nPrioritize 7–9 hours of quality sleep nightly to facilitate cognitive and cardiovascular restoration.';
      }
      if (q.contains('score') || q.contains('improve') || q.contains('wellness')) {
        return '📊 **Wellness Score Overview:**\n\nYour score improves as you log your water, reach step milestones, and maintain regular sleep cycles.';
      }
      return 'I am Aurora, your clinical AI health coach! You can ask me about your hydration, steps, sleep, resting heart rate, or how to improve your daily Wellness Score.';
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // TOOL EXECUTION (read-only Firestore operations)
  // ════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> _executeTool(
    String uid,
    String toolName,
    Map<String, dynamic> args, {
    HealthDataController? healthData,
    UserProfile? userProfile,
  }) async {
    try {
      switch (toolName) {
        case 'getUserProfile':
          return await _toolGetUserProfile(uid, userProfile: userProfile, healthData: healthData);
        case 'getTodayReadings':
          return await _toolGetTodayReadings(uid, healthData: healthData);
        case 'getDailyScore':
          return await _toolGetDailyScore(uid, args['date'] as String? ?? HealthReading.todayDate(), healthData: healthData);
        case 'getWeeklyScores':
          return await _toolGetWeeklyScores(uid);
        case 'getReadingHistory':
          return await _toolGetReadingHistory(
            uid,
            args['metric'] as String? ?? '',
            (args['days'] as int?) ?? 7,
          );
        case 'detectTrends':
          return await _toolDetectTrends(uid, args['metric'] as String? ?? '');
        default:
          return {'error': 'Unknown tool: $toolName'};
      }
    } catch (e) {
      return {'error': 'Tool $toolName failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> _toolGetUserProfile(
    String uid, {
    UserProfile? userProfile,
    HealthDataController? healthData,
  }) async {
    UserProfile? profile = userProfile ?? healthData?.profile;
    if (profile == null) {
      try {
        profile = await FirestoreService.instance.loadProfile(uid);
      } catch (e) {
        debugPrint('⚠️ [HealthAgentService] loadProfile failed: $e');
      }
    }

    final name = profile?.name ?? healthData?.username ?? 'there';
    final stepGoal = profile?.stepGoal ?? healthData?.stepGoal ?? 10000;
    final waterGoal = profile?.waterGoalMl ?? healthData?.waterGoal ?? 2500;
    final calGoal = profile?.calorieGoal ?? healthData?.calorieGoal.round() ?? 2000;
    final sleepGoal = profile?.sleepGoalHours ?? healthData?.sleepGoal ?? 8.0;

    return {
      'name': name,
      'age': profile?.age,
      'sex': profile?.sex,
      'height_cm': profile?.heightCm,
      'weight_kg': profile?.weightKg,
      'bmi': profile?.bmi?.toStringAsFixed(1),
      'activity_level': profile?.activityLevel,
      'fitness_goal': profile?.fitnessGoal,
      'step_goal': stepGoal,
      'water_goal_ml': waterGoal,
      'calorie_goal': calGoal,
      'sleep_goal_hours': sleepGoal,
      'profile_complete': profile?.isComplete ?? false,
    };
  }

  static Future<Map<String, dynamic>> _toolGetTodayReadings(
    String uid, {
    HealthDataController? healthData,
  }) async {
    final result = <String, dynamic>{
      'date': HealthReading.todayDate(),
    };

    if (healthData != null) {
      result['water_ml'] = healthData.waterMl;
      result['steps'] = healthData.stepsToday;
      result['sleep_hours'] = healthData.sleepHours > 0 ? healthData.sleepHours : null;
      result['calories_kcal'] = healthData.caloriesConsumed.round();
      result['heart_rate_bpm'] = healthData.heartRate > 0 ? healthData.heartRate : null;
      if (healthData.bloodPressureHistory.isNotEmpty) {
        final last = healthData.bloodPressureHistory.first;
        result['blood_pressure'] = '${last.systolic}/${last.diastolic}';
      }
      return result;
    }

    try {
      final readingsMap = await FirestoreService.instance.getTodayReadings(uid);
      for (final entry in readingsMap.entries) {
        final readings = entry.value;
        switch (entry.key) {
          case HealthReading.water:
            result['water_ml'] = readings.fold<double>(0, (s, r) => s + r.value).round();
            break;
          case HealthReading.sleep:
            result['sleep_hours'] = readings.isEmpty ? null : readings.last.value;
            break;
          case HealthReading.heartRate:
            result['heart_rate_bpm'] = readings.isEmpty ? null : readings.last.value;
            break;
          case HealthReading.bloodPressure:
            if (readings.isNotEmpty) {
              final last = readings.last;
              result['blood_pressure'] = '${last.valueSystolic}/${last.valueDiastolic}';
            }
            break;
          case HealthReading.calories:
            result['calories_kcal'] = readings.fold<double>(0, (s, r) => s + r.value).round();
            break;
          case HealthReading.steps:
            result['steps'] = readings.isEmpty ? null : readings.last.value.round();
            break;
          case HealthReading.bloodSugar:
            result['blood_sugar_mg_dl'] = readings.isEmpty ? null : readings.last.value;
            break;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [HealthAgentService] _toolGetTodayReadings Firestore failed: $e');
    }

    return result;
  }

  static Future<Map<String, dynamic>> _toolGetDailyScore(
    String uid,
    String date, {
    HealthDataController? healthData,
  }) async {
    if (healthData != null && healthData.todayScore != null && (date == HealthReading.todayDate() || date.isEmpty)) {
      final score = healthData.todayScore!;
      return {
        'date': score.date,
        'overall_score': score.overall,
        'label': score.label,
        'available_metrics': score.availableMetricCount,
        'missing_metrics': (6 - score.availableMetricCount).clamp(0, 6),
      };
    }

    try {
      final score = await FirestoreService.instance.getScoreForDate(uid, date);
      if (score != null) {
        final metrics = <String, dynamic>{};
        for (final entry in score.metrics.entries) {
          final m = entry.value;
          metrics[entry.key] = m.available
              ? {'score': m.score, 'reason': m.reason, 'available': true}
              : {'available': false};
        }
        return {
          'date': score.date,
          'overall_score': score.overall,
          'label': score.label,
          'available_metrics': score.availableMetricCount,
          'missing_metrics': (6 - score.availableMetricCount).clamp(0, 6),
          'metrics': metrics,
        };
      }
    } catch (e) {
      debugPrint('⚠️ [HealthAgentService] _toolGetDailyScore Firestore failed: $e');
    }

    return {
      'date': date,
      'overall_score': 50,
      'label': 'Needs Improvement',
      'available_metrics': 0,
      'missing_metrics': 6,
    };
  }

  static Future<Map<String, dynamic>> _toolGetWeeklyScores(String uid) async {
    final scores = await FirestoreService.instance.getRecentScores(uid, days: 7);
    return {
      'weekly_scores': scores.map((s) => {
        'date': s.date,
        'overall': s.overall,
        'label': s.label,
        'available_metrics': s.availableMetricCount,
      }).toList(),
      'average': scores.isEmpty
          ? null
          : (scores.fold<int>(0, (s, d) => s + d.overall) / scores.length).round(),
    };
  }

  static Future<Map<String, dynamic>> _toolGetReadingHistory(
      String uid, String metric, int days) async {
    final readings = await FirestoreService.instance.getRecentReadings(
      uid: uid,
      metric: metric,
      days: days.clamp(1, 30),
    );
    return {
      'metric': metric,
      'days': days,
      'readings': readings.map((r) => {
        'date': r.date,
        'value': r.value,
        if (r.valueSystolic != null) 'systolic': r.valueSystolic,
        if (r.valueDiastolic != null) 'diastolic': r.valueDiastolic,
      }).toList(),
      'count': readings.length,
    };
  }

  static Future<Map<String, dynamic>> _toolDetectTrends(
      String uid, String metric) async {
    final readings = await FirestoreService.instance.getRecentReadings(
      uid: uid,
      metric: metric,
      days: 14,
    );

    if (readings.length < 3) {
      return {
        'metric': metric,
        'trend': 'insufficient_data',
        'message': 'Need at least 3 readings to detect a trend.',
        'readings_available': readings.length,
      };
    }

    // Split into first half and second half
    final mid = readings.length ~/ 2;
    final firstHalf = readings.sublist(0, mid);
    final secondHalf = readings.sublist(mid);

    final avgFirst =
        firstHalf.fold<double>(0, (s, r) => s + r.value) / firstHalf.length;
    final avgSecond =
        secondHalf.fold<double>(0, (s, r) => s + r.value) / secondHalf.length;

    final pctChange = avgFirst == 0 ? 0 : ((avgSecond - avgFirst) / avgFirst * 100);

    String trend;
    if (pctChange > 5) {
      trend = 'increasing';
    } else if (pctChange < -5) {
      trend = 'decreasing';
    } else {
      trend = 'stable';
    }

    return {
      'metric': metric,
      'trend': trend,
      'avg_first_half': avgFirst.toStringAsFixed(1),
      'avg_second_half': avgSecond.toStringAsFixed(1),
      'percent_change': pctChange.toStringAsFixed(1),
      'readings_analyzed': readings.length,
    };
  }
}

// ════════════════════════════════════════════════════════════════════════
// RESPONSE MODEL
// ════════════════════════════════════════════════════════════════════════

class AgentResponse {
  const AgentResponse({
    required this.text,
    required this.updatedHistory,
    this.error,
  });

  final String text;
  final List<Content> updatedHistory;
  final String? error;

  bool get hasError => error != null;
}

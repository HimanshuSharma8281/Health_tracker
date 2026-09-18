import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/health_data_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/user_profile.dart';
import '../services/health_analysis_service.dart';
import '../services/health_score_engine.dart';
import '../widgets/glass_container.dart';
import '../widgets/circular_score_gauge.dart';

import '../screens/calorie_detail_screen.dart';
import '../screens/water_detail_screen.dart';
import '../screens/sleep_detail_screen.dart';
import '../screens/blood_pressure_screen.dart';
import '../screens/blood_sugar_screen.dart';
import '../screens/heart_rate_screen.dart';
import '../screens/step_detail_screen.dart';
import '../screens/ai_health_insights_screen.dart';
import '../screens/health_report_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  HealthAnalysis? _cachedAnalysis;
  bool _isLoadingAnalysis = false;
  String? _lastAnalysisUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalysisIfNeeded();
    });
  }

  void _loadAnalysisIfNeeded() async {
    if (!mounted) return;
    final healthData = context.read<HealthDataController>();
    if (healthData.userId == null) return;

    // Load only once per user session
    if (_cachedAnalysis != null && _lastAnalysisUserId == healthData.userId) {
      return;
    }

    setState(() => _isLoadingAnalysis = true);
    try {
      final analysis = await HealthAnalysisService.analyzeHealthData(healthData);
      if (mounted) {
        setState(() {
          _cachedAnalysis = analysis;
          _lastAnalysisUserId = healthData.userId;
          _isLoadingAnalysis = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAnalysis = false);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showGoalSettingsDialog(BuildContext context) {
    final data = context.read<HealthDataController>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: GlassContainer(
          blur: 24,
          padding: EdgeInsets.zero,
          color: const Color(0xE6141A20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF48E5C2).withValues(alpha: 0.2),
                      const Color(0xFF3A86FF).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF48E5C2).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          color: Color(0xFF48E5C2), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Customize Goals',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Inputs list
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      _buildGoalInputField(
                        label: 'Daily Steps',
                        initialValue: data.stepGoal.toString(),
                        suffix: 'steps',
                        icon: Icons.directions_walk_rounded,
                        accentColor: const Color(0xFF48E5C2),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            data.updateStepGoal(parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildGoalInputField(
                        label: 'Daily Hydration',
                        initialValue: data.waterGoal.toString(),
                        suffix: 'ml',
                        icon: Icons.water_drop_rounded,
                        accentColor: const Color(0xFF2EC4B6),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            data.updateWaterGoal(parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildGoalInputField(
                        label: 'Daily Calories',
                        initialValue: data.calorieGoal.round().toString(),
                        suffix: 'kcal',
                        icon: Icons.local_fire_department_rounded,
                        accentColor: const Color(0xFFFFBE0B),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            data.updateCalorieGoal(parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildGoalInputField(
                        label: 'Target Sleep',
                        initialValue: data.sleepGoal.toStringAsFixed(1),
                        suffix: 'hours',
                        icon: Icons.nightlight_round,
                        accentColor: const Color(0xFF8338EC),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            data.updateSleepGoal(parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF48E5C2),
                            foregroundColor: const Color(0xFF090D10),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Save Targets',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalInputField({
    required String label,
    required String initialValue,
    required String suffix,
    required IconData icon,
    required Color accentColor,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: initialValue),
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          onChanged: onChanged,
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthData = context.watch<HealthDataController>();
    final auth = context.watch<AuthController>();
    final todayScore = healthData.todayScore;
    final greeting = _getGreeting();
    final firstName = auth.user?.name.split(' ').first ?? 'Explorer';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF090D10),
        gradient: RadialGradient(
          center: Alignment(-0.8, -0.6),
          radius: 1.2,
          colors: [
            Color(0xFF0D2420), // Subtle deep teal atmosphere
            Color(0xFF090D10), // Deep charcoal black
          ],
        ),
      ),
      child: RefreshIndicator(
        color: const Color(0xFF48E5C2),
        backgroundColor: const Color(0xFF141A20),
        onRefresh: () async {
          _loadAnalysisIfNeeded();
        },
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // 1. Subtle Personalized Greeting Header
            SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $firstName',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your health at a glance',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions: Goals, Reminders & Avatar
                  Row(
                    children: [
                      // Health PDF Report Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HealthReportScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Color(0xFFFF5C7A),
                              size: 19,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Goals Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showGoalSettingsDialog(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF48E5C2),
                              size: 19,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // User Avatar
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFF48E5C2).withValues(alpha: 0.2),
                        backgroundImage: auth.user?.avatarUrl.isNotEmpty == true
                            ? NetworkImage(auth.user!.avatarUrl)
                            : null,
                        child: auth.user?.avatarUrl.isNotEmpty == true
                            ? null
                            : Text(
                                firstName.isNotEmpty ? firstName[0] : 'A',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF48E5C2),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. HERO SECTION — Animated Circular Health Score Card
            Builder(
              builder: (context) {
                final metrics = todayScore?.metrics ?? const {};

                // 1. Steps / Activity — Canonical HealthScoreEngine metric score
                final isStepsTracked = (metrics[MetricKeys.activity]?.available == true) ||
                    (healthData.stepsToday > 0);
                final stepScore = metrics[MetricKeys.activity]?.score ??
                    metrics['steps']?.score ??
                    (healthData.stepsToday > 0
                        ? HealthScoreEngine.calculateActivityScore(
                            steps: healthData.stepsToday,
                            stepGoal: healthData.stepGoal,
                          ).score
                        : 0);
                final stepScoreProg = (stepScore / 10.0).clamp(0.0, 1.0);

                // 2. Water / Hydration — Canonical HealthScoreEngine metric score
                final isWaterTracked = (metrics[MetricKeys.water]?.available == true) ||
                    (healthData.waterMl > 0);
                final waterScore = metrics[MetricKeys.water]?.score ??
                    (healthData.waterMl > 0
                        ? HealthScoreEngine.calculateHydrationScore(
                            waterMl: healthData.waterMl,
                            weightKg: healthData.profile?.weightKg,
                            activityLevel: healthData.profile?.activityLevel,
                          ).score
                        : 0);
                final waterScoreProg = (waterScore / 10.0).clamp(0.0, 1.0);

                // 3. Sleep — Canonical HealthScoreEngine metric score
                final isSleepTracked = (metrics[MetricKeys.sleep]?.available == true) ||
                    (healthData.sleepHours > 0);
                final sleepScore = metrics[MetricKeys.sleep]?.score ??
                    (healthData.sleepHours > 0
                        ? HealthScoreEngine.calculateSleepScore(
                            hours: healthData.sleepHours,
                            age: healthData.profile?.age,
                          ).score
                        : 0);
                final sleepScoreProg = (sleepScore / 10.0).clamp(0.0, 1.0);

                // 4. Heart Rate — Canonical HealthScoreEngine metric score
                final isHeartTracked = (metrics[MetricKeys.heartRate]?.available == true) ||
                    (healthData.heartRate > 0);
                final heartScore = metrics[MetricKeys.heartRate]?.score ??
                    metrics['heart_rate']?.score ??
                    metrics['heartRate']?.score ??
                    (healthData.heartRate > 0
                        ? HealthScoreEngine.calculateHeartRateScore(
                            bpm: healthData.heartRate,
                            age: healthData.profile?.age,
                          ).score
                        : 0);
                final heartScoreProg = (heartScore / 10.0).clamp(0.0, 1.0);

                // 5. Calories — Canonical HealthScoreEngine metric score
                final isCalTracked = (metrics[MetricKeys.calories]?.available == true) ||
                    (healthData.caloriesConsumed > 0);
                final calScore = metrics[MetricKeys.calories]?.score ??
                    (healthData.caloriesConsumed > 0 && healthData.profile != null
                        ? HealthScoreEngine.calculateCalorieScore(
                            consumed: healthData.caloriesConsumed,
                            profile: healthData.profile!,
                          ).score
                        : (healthData.caloriesConsumed > 0
                            ? HealthScoreEngine.calculateCalorieScore(
                                consumed: healthData.caloriesConsumed,
                                profile: UserProfile(
                                  uid: healthData.userId ?? 'local',
                                  email: '',
                                  name: healthData.username ?? 'User',
                                  calorieGoal: healthData.calorieGoal,
                                ),
                              ).score
                            : 0));
                final calScoreProg = (calScore / 10.0).clamp(0.0, 1.0);

                // 6. Blood Pressure — Canonical HealthScoreEngine metric score
                final isBpTracked = (metrics[MetricKeys.bloodPressure]?.available == true) ||
                    (healthData.systolic > 0 && healthData.diastolic > 0);
                final bpScore = metrics[MetricKeys.bloodPressure]?.score ??
                    metrics['blood_pressure']?.score ??
                    metrics['bloodPressure']?.score ??
                    ((healthData.systolic > 0 && healthData.diastolic > 0)
                        ? HealthScoreEngine.calculateBloodPressureScore(
                            systolic: healthData.systolic,
                            diastolic: healthData.diastolic,
                          ).score
                        : 0);
                final bpScoreProg = (bpScore / 10.0).clamp(0.0, 1.0);

                // 7. Blood Sugar — Canonical HealthScoreEngine metric score
                final isSugarTracked = (metrics[MetricKeys.bloodSugar]?.available == true) ||
                    (healthData.bloodSugar > 0);
                final sugarScore = metrics[MetricKeys.bloodSugar]?.score ??
                    metrics['blood_sugar']?.score ??
                    metrics['bloodSugar']?.score ??
                    (healthData.bloodSugar > 0
                        ? HealthScoreEngine.calculateBloodSugarScore(
                            mgDl: healthData.bloodSugar,
                          ).score
                        : 0);
                final sugarScoreProg = (sugarScore / 10.0).clamp(0.0, 1.0);

                final dashboardRings = [
                  MetricRingData(
                    key: 'steps',
                    label: 'Steps',
                    progress: stepScoreProg,
                    score: stepScore,
                    color: const Color(0xFFFFAA4C), // Amber
                    isTracked: isStepsTracked,
                  ),
                  MetricRingData(
                    key: 'water',
                    label: 'Water',
                    progress: waterScoreProg,
                    score: waterScore,
                    color: const Color(0xFF3A86FF), // Electric Blue
                    isTracked: isWaterTracked,
                  ),
                  MetricRingData(
                    key: 'sleep',
                    label: 'Sleep',
                    progress: sleepScoreProg,
                    score: sleepScore,
                    color: const Color(0xFF9B86EC), // Lavender
                    isTracked: isSleepTracked,
                  ),
                  MetricRingData(
                    key: 'heart_rate',
                    label: 'Heart',
                    progress: heartScoreProg,
                    score: heartScore,
                    color: const Color(0xFFFF5C7A), // Rose
                    isTracked: isHeartTracked,
                  ),
                  MetricRingData(
                    key: 'calories',
                    label: 'Calories',
                    progress: calScoreProg,
                    score: calScore,
                    color: const Color(0xFFFFBE0B), // Radiant Yellow
                    isTracked: isCalTracked,
                  ),
                  MetricRingData(
                    key: 'blood_pressure',
                    label: 'BP',
                    progress: bpScoreProg,
                    score: bpScore,
                    color: const Color(0xFF48E5C2), // Mint Teal
                    isTracked: isBpTracked,
                  ),
                  MetricRingData(
                    key: 'blood_sugar',
                    label: 'Sugar',
                    progress: sugarScoreProg,
                    score: sugarScore,
                    color: const Color(0xFFFF6B6B), // Coral Pink
                    isTracked: isSugarTracked,
                  ),
                ];

                return GlassContainer(
                  blur: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x1A48E5C2), // Gentle mint glow tint
                      Color(0x0AFFFFFF),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0x2648E5C2),
                    width: 1.2,
                  ),
                  child: Column(
                    children: [
                      // Dynamic Circular Score Gauge tracking the 6 metric cards (percentage scores only)
                      CircularScoreGauge(
                        score: todayScore?.overall,
                        label: todayScore?.label ?? 'Unscored',
                        activeMetricsCount: todayScore?.availableMetricCount ?? 0,
                        rings: dashboardRings,
                        size: 220,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // 3. Section Header: "TODAY'S HEALTH"
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF48E5C2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'TODAY\'S HEALTH',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Row 1: Water (segmented capsule) & Steps (count-up + 7-bar chart)
            Row(
              children: [
                Expanded(
                  child: _AnimatedWaterCard(
                    data: healthData,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WaterDetailScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _AnimatedStepsCard(
                    data: healthData,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StepDetailScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Row 2: Sleep (circular ring + badge) & Heart rate (animated ECG)
            Row(
              children: [
                Expanded(
                  child: _AnimatedSleepCard(
                    data: healthData,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SleepDetailScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _AnimatedHeartRateCard(
                    data: healthData,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HeartRateScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Row 3: Calories (animated progress) & Blood Pressure
            Row(
              children: [
                Expanded(
                  child: _AnimatedCaloriesCard(
                    data: healthData,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CalorieDetailScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    icon: Icons.monitor_heart_rounded,
                    iconColor: const Color(0xFF3A86FF),
                    title: 'BLOOD PRESSURE',
                    value: healthData.systolic > 0 && healthData.diastolic > 0
                        ? '${healthData.systolic}/${healthData.diastolic}'
                        : '—/—',
                    subtitle: healthData.systolic > 0
                        ? 'mmHg (Recorded)'
                        : 'Not recorded',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BloodPressureScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Row 4: Blood Sugar
            _buildMetricTile(
              context: context,
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFFFF6B6B),
              title: 'BLOOD SUGAR',
              value: healthData.bloodSugar > 0
                  ? '${healthData.bloodSugar.round()} mg/dL'
                  : '—',
              subtitle: healthData.bloodSugar > 0
                  ? 'Target: <140'
                  : 'Not recorded',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BloodSugarScreen(),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 6. Aurora AI Wellness Insight Preview Card
            _buildAiInsightCard(context, healthData),
          ],
        ),
      ),
    );
  }


  /// Compact Glass Metric Tile (for BP and Blood Sugar)
  Widget _buildMetricTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      blur: 14,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 16,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Aurora AI Wellness Insight Preview
  Widget _buildAiInsightCard(BuildContext context, HealthDataController data) {
    String insightText = '';
    if (_cachedAnalysis != null &&
        _cachedAnalysis!.dailySummary.isNotEmpty &&
        !_cachedAnalysis!.dailySummary.contains('fallback')) {
      insightText = _cachedAnalysis!.dailySummary;
    } else if (data.topInsights.isNotEmpty) {
      insightText = data.topInsights.first;
    } else {
      insightText =
          'Stay consistent with your daily hydration and steps to maintain your health score.';
    }

    return GlassContainer(
      blur: 16,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AIHealthInsightsScreen(),
        ),
      ),
      padding: const EdgeInsets.all(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x1F8338EC), // Subtle purple AI glow
          Color(0x0C3A86FF),
        ],
      ),
      border: Border.all(color: const Color(0x338338EC), width: 1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8338EC), Color(0xFF3A86FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AURORA AI INSIGHT',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: const Color(0xFF5CE1E6),
                ),
              ),
              const Spacer(),
              if (_isLoadingAnalysis)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF5CE1E6)),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Daily',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insightText,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'View full analysis',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF48E5C2),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF48E5C2),
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED METRIC CARDS (Matching UI Reference: Screenshot 2026-09-12 134449)
// ═══════════════════════════════════════════════════════════════════════════

/// Water Card: Animated 5-Segmented Capsule Progress Bar (0 -> daily water progress)
class _AnimatedWaterCard extends StatelessWidget {
  final HealthDataController data;
  final VoidCallback onTap;

  const _AnimatedWaterCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress =
        data.waterGoal > 0 ? (data.waterMl / data.waterGoal).clamp(0.0, 1.0) : 0.0;
    final formatter = NumberFormat('#,###');

    return GlassContainer(
      blur: 14,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Droplet Icon + Title
            Row(
              children: [
                const Icon(
                  Icons.water_drop_rounded,
                  size: 16,
                  color: Color(0xFF2EC4B6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Water',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),

            // Value Row: "1,750 / 2,500 ml"
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: formatter.format(data.waterMl),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${formatter.format(data.waterGoal)} ml',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),

            // 5-Capsule Animated Segmented Progress Bar
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProg, _) {
                return Row(
                  children: List.generate(5, (index) {
                    final segProgress =
                        ((animatedProg - (index * 0.2)) / 0.2).clamp(0.0, 1.0);
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index == 4 ? 0 : 5),
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: segProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2EC4B6), Color(0xFF48E5C2)],
                              ),
                              boxShadow: segProgress > 0.6
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF2EC4B6)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 4,
                                        spreadRadius: 0.5,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Steps Card: Animated Count-up + 7-Column Mini Bar Chart
class _AnimatedStepsCard extends StatelessWidget {
  final HealthDataController data;
  final VoidCallback onTap;

  const _AnimatedStepsCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final goalStr = data.stepGoal >= 1000
        ? '${(data.stepGoal / 1000).round()}k'
        : '${data.stepGoal}';

    // Retrieve past 6 days from stepHistory + today
    final now = DateTime.now();
    final List<int> sevenDaySteps = [];
    for (int i = 6; i >= 1; i--) {
      final day = now.subtract(Duration(days: i));
      sevenDaySteps.add(data.getStepsForDay(day));
    }
    sevenDaySteps.add(data.stepsToday);

    final maxVal = [data.stepGoal, ...sevenDaySteps].reduce(math.max);

    return GlassContainer(
      blur: 14,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Sneaker Icon + Title
            Row(
              children: [
                const Icon(
                  Icons.directions_walk_rounded,
                  size: 16,
                  color: Color(0xFFFFAA4C),
                ),
                const SizedBox(width: 6),
                Text(
                  'Steps',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),

            // Value Row: Count-up animation
            TweenAnimationBuilder<double>(
              tween:
                  Tween<double>(begin: 0.0, end: data.stepsToday.toDouble()),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, animatedCount, _) {
                return RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: formatter.format(animatedCount.round()),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: ' / $goalStr',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 7-Bar Mini Animated Chart (Rising columns with highlight on today)
            SizedBox(
              height: 26,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, anim, _) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (idx) {
                      final isToday = idx == 6;
                      final steps = sevenDaySteps[idx];
                      final factor =
                          maxVal > 0 ? (steps / maxVal).clamp(0.08, 1.0) : 0.08;
                      final barHeight =
                          (factor * 26.0 * anim).clamp(3.0, 26.0);

                      return Container(
                        width: 10,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFFFFAA4C)
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: isToday
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFFAA4C)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sleep Card: Circular Progress Ring with % inside + Duration Text
class _AnimatedSleepCard extends StatelessWidget {
  final HealthDataController data;
  final VoidCallback onTap;

  const _AnimatedSleepCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasSleep = data.sleepHours > 0;
    final progress = data.sleepGoal > 0
        ? (data.sleepHours / data.sleepGoal).clamp(0.0, 1.0)
        : 0.0;
    final percentInt = (progress * 100).round();

    return GlassContainer(
      blur: 14,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Moon Icon + Title
            Row(
              children: [
                const Icon(
                  Icons.nightlight_round,
                  size: 16,
                  color: Color(0xFF9B86EC),
                ),
                const SizedBox(width: 6),
                Text(
                  'Sleep',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),

            // Content Row: Ring on left, hours text on right
            Row(
              children: [
                // Circular Progress Ring with centered %
                SizedBox(
                  width: 44,
                  height: 44,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                        begin: 0.0, end: hasSleep ? progress : 0.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, animVal, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(44, 44),
                            painter: _MiniSleepRingPainter(progress: animVal),
                          ),
                          Text(
                            hasSleep ? '$percentInt%' : '—',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Right Info: "7.2 hrs of 8 hr goal"
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasSleep
                            ? '${data.sleepHours.toStringAsFixed(1)} hrs'
                            : '—',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'of ${data.sleepGoal.toStringAsFixed(0)} hr goal',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini Sleep Ring CustomPainter
class _MiniSleepRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _MiniSleepRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;
    const strokeWidth = 4.5;
    const startAngle = -math.pi / 2;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Active Lavender Arc
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final activePaint = Paint()
      ..color = const Color(0xFF9B86EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniSleepRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Heart Rate Card: Animated Clinical ECG Waveform Pulse
class _AnimatedHeartRateCard extends StatefulWidget {
  final HealthDataController data;
  final VoidCallback onTap;

  const _AnimatedHeartRateCard({required this.data, required this.onTap});

  @override
  State<_AnimatedHeartRateCard> createState() => _AnimatedHeartRateCardState();
}

class _AnimatedHeartRateCardState extends State<_AnimatedHeartRateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ecgController;

  @override
  void initState() {
    super.initState();
    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ecgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasHr = widget.data.heartRate > 0;

    return GlassContainer(
      blur: 14,
      onTap: widget.onTap,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Heart Icon + Title
            Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: Color(0xFFFF5C7A),
                ),
                const SizedBox(width: 6),
                Text(
                  'Heart rate',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),

            // Value Row: "68 bpm"
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: hasHr ? '${widget.data.heartRate.round()}' : '—',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: ' bpm',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),

            // Subtle Clinical ECG Waveform Animation
            SizedBox(
              height: 24,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _ecgController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _EcgWaveformPainter(
                      animationValue: _ecgController.value,
                      color: const Color(0xFFFF5C7A),
                      isRecorded: hasHr,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Authentic P-Q-R-S-T Clinical ECG Waveform Painter with travelling pulse
class _EcgWaveformPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0
  final Color color;
  final bool isRecorded;

  _EcgWaveformPainter({
    required this.animationValue,
    required this.color,
    required this.isRecorded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h * 0.65;

    final path = Path();
    path.moveTo(0, midY);

    if (!isRecorded) {
      path.lineTo(w, midY);
      final dimPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, dimPaint);
      return;
    }

    // Authentic P-Q-R-S-T wave path
    path.lineTo(w * 0.16, midY);
    // P-wave
    path.quadraticBezierTo(w * 0.22, midY - h * 0.20, w * 0.28, midY);
    path.lineTo(w * 0.34, midY);
    // Q dip
    path.lineTo(w * 0.38, midY + h * 0.15);
    // R spike
    path.lineTo(w * 0.43, midY - h * 0.80);
    // S dip
    path.lineTo(w * 0.48, midY + h * 0.35);
    // Baseline
    path.lineTo(w * 0.52, midY);
    path.lineTo(w * 0.58, midY);
    // T-wave
    path.quadraticBezierTo(w * 0.66, midY - h * 0.35, w * 0.74, midY);
    path.lineTo(w, midY);

    // Glow underlay
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, glowPaint);

    // Active line
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Travelling pulse gradient
    final pulseX = (animationValue * (w + 40)) - 20;
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color.withValues(alpha: 0.45),
        color,
        color.withValues(alpha: 0.45),
      ],
      stops: [
        ((pulseX - 25) / w).clamp(0.0, 1.0),
        (pulseX / w).clamp(0.0, 1.0),
        ((pulseX + 25) / w).clamp(0.0, 1.0),
      ],
    );
    strokePaint.shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _EcgWaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.isRecorded != isRecorded;
  }
}

/// Calories Card: Animated Progress Bar to Daily Goal
class _AnimatedCaloriesCard extends StatelessWidget {
  final HealthDataController data;
  final VoidCallback onTap;

  const _AnimatedCaloriesCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasCal = data.caloriesConsumed > 0;
    final progress = data.calorieGoal > 0
        ? (data.caloriesConsumed / data.calorieGoal).clamp(0.0, 1.0)
        : 0.0;
    final formatter = NumberFormat('#,###');

    return GlassContainer(
      blur: 14,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Flame Icon + Title
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 16,
                  color: Color(0xFFFFBE0B),
                ),
                const SizedBox(width: 6),
                Text(
                  'Calories',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),

            // Value Row
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: hasCal
                        ? formatter.format(data.caloriesConsumed.round())
                        : '—',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${formatter.format(data.calorieGoal.round())} kcal',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),

            // Animated Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: hasCal ? progress : 0.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProg, _) {
                  return Container(
                    height: 6,
                    color: Colors.white.withValues(alpha: 0.12),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: animatedProg,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFBE0B), Color(0xFFFF9F1C)],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

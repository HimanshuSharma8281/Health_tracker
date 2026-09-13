import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/glass_container.dart';

class StepDetailScreen extends StatefulWidget {
  const StepDetailScreen({super.key});

  @override
  State<StepDetailScreen> createState() => _StepDetailScreenState();
}

class _StepDetailScreenState extends State<StepDetailScreen> {
  String selectedFilter = 'Weekly';

  static const Color _bgCharcoal = Color(0xFF090D10);
  static const Color _ambientAmber = Color(0xFF22150C);
  static const Color _stepPrimary = Color(0xFFFFAA4C);
  static const Color _stepSecondary = Color(0xFFFF8E53);
  static const Color _caloriePink = Color(0xFFFF5C7A);
  static const Color _distanceCyan = Color(0xFF2EC4B6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCharcoal,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.25,
            colors: [_ambientAmber, _bgCharcoal],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: Consumer<HealthDataController>(
                  builder: (context, data, _) {
                    final progress = (data.stepsToday / (data.stepGoal > 0 ? data.stepGoal : 10000)).clamp(0.0, 1.0);
                    final remaining = data.stepGoal - data.stepsToday;
                    final distanceKm = (data.stepsToday * 0.0007).toStringAsFixed(2);
                    final caloriesKcal = (data.stepsToday * 0.04).round();

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      children: [
                        // Hero Step Card
                        _buildHeroStepCard(data, progress, remaining),
                        const SizedBox(height: 18),

                        // Auto-Tracking Sensor Status Card
                        _buildSensorStatusCard(data),
                        const SizedBox(height: 18),

                        // Metrics Summary 3-Grid
                        _buildMetricsRow(data, distanceKm, caloriesKcal),
                        const SizedBox(height: 22),

                        // Chart Section
                        _buildChartSection(data),
                        const SizedBox(height: 28),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _stepPrimary,
                  boxShadow: [
                    BoxShadow(
                      color: _stepPrimary,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'STEP TRACKER',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 40), // Balanced visual spacing
        ],
      ),
    );
  }

  Widget _buildHeroStepCard(HealthDataController data, double progress, int remaining) {
    final pct = (progress * 100).toInt();

    return GlassContainer(
      blur: 16,
      color: const Color(0xE6141A20),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: _stepPrimary.withValues(alpha: 0.25),
        width: 1.2,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _stepPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _stepPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        color: _stepPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TODAY\'S ACTIVITY',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: _stepPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Daily Movement',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  '$pct%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _stepPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Big Steps Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${data.stepsToday}',
                style: GoogleFonts.inter(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'steps',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Target: ${data.stepGoal} steps',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),

          // Progress Bar with rounded gradient
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_stepSecondary, _stepPrimary],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _stepPrimary.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Goal status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: remaining <= 0
                  ? _distanceCyan.withValues(alpha: 0.12)
                  : _stepPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: remaining <= 0
                    ? _distanceCyan.withValues(alpha: 0.3)
                    : _stepPrimary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  remaining <= 0
                      ? Icons.check_circle_rounded
                      : Icons.directions_walk_rounded,
                  color: remaining <= 0 ? _distanceCyan : _stepPrimary,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  remaining <= 0
                      ? 'Goal achieved! Amazing work! 🎉'
                      : '$remaining steps remaining to goal',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: remaining <= 0 ? _distanceCyan : _stepPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorStatusCard(HealthDataController data) {
    final isWalking = data.pedestrianStatus == 'walking';
    final statusColor = isWalking ? _distanceCyan : _stepPrimary;

    return GlassContainer(
      blur: 16,
      color: const Color(0xE6141A20),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isWalking
            ? _distanceCyan.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.08),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Icon(
              isWalking ? Icons.directions_walk_rounded : Icons.sensors_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isWalking ? 'Walking Detected' : 'Auto-Tracking Active',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isWalking ? _distanceCyan : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isWalking
                      ? 'Steps are counting continuously in real-time'
                      : 'Hardware step counter active in background',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(HealthDataController data, String distanceKm, int caloriesKcal) {
    return Row(
      children: [
        // Calories Card
        Expanded(
          child: GlassContainer(
            blur: 16,
            color: const Color(0xE6141A20),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _caloriePink.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: _caloriePink,
                        size: 18,
                      ),
                    ),
                    Text(
                      'BURNED',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: _caloriePink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$caloriesKcal',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'kcal energy',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Distance Card
        Expanded(
          child: GlassContainer(
            blur: 16,
            color: const Color(0xE6141A20),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _distanceCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: _distanceCyan,
                        size: 18,
                      ),
                    ),
                    Text(
                      'DISTANCE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: _distanceCyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  distanceKm,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'km traversed',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(HealthDataController data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _stepPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'STEP ACTIVITY HISTORY',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            // Segmented Filter Control
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: ['Weekly', 'Monthly'].map((filter) {
                  final isSelected = selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? _stepPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFF090D10) : Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Chart Container
        GlassContainer(
          blur: 16,
          color: const Color(0xE6141A20),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: SizedBox(
            height: 220,
            child: selectedFilter == 'Weekly'
                ? _buildWeeklyChart(data)
                : _buildMonthlyChart(data),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(HealthDataController data) {
    final now = DateTime.now();

    final Map<int, int> stepsByDay = {};
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      stepsByDay[i] = data.getStepsForDay(day);
    }

    final hasRealData = stepsByDay.values.any((v) => v > 0);

    if (!hasRealData) {
      return _buildEmptyChartState(
        'No step activity recorded yet',
        'Walk with your device to view your dynamic cadence',
      );
    }

    final maxSteps = stepsByDay.values.reduce((a, b) => a > b ? a : b);
    final goal = data.stepGoal > 0 ? data.stepGoal : 10000;
    final maxY = maxSteps > goal ? (maxSteps * 1.25) : (goal * 1.25);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF141A20),
            tooltipBorder: BorderSide(
              color: _stepPrimary.withValues(alpha: 0.4),
              width: 1,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final isToday = groupIndex == 6;
              return BarTooltipItem(
                rod.toY > 0
                    ? '${rod.toY.toInt()} steps${isToday ? ' (Today)' : ''}'
                    : '0 steps',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final day = now.subtract(Duration(days: 6 - value.toInt()));
                final dayIndex = day.weekday - 1;
                final isToday = value.toInt() == 6;

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    isToday ? 'Today' : days[dayIndex % 7],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? _stepPrimary : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  '${(value / 1000).toStringAsFixed(1)}k',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          final steps = stepsByDay[index] ?? 0;
          final isToday = index == 6;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: steps.toDouble(),
                gradient: LinearGradient(
                  colors: steps > 0
                      ? isToday
                          ? [_stepSecondary, _stepPrimary]
                          : [
                              _stepSecondary.withValues(alpha: 0.6),
                              _stepPrimary.withValues(alpha: 0.8),
                            ]
                      : [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: isToday ? 22 : 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthlyChart(HealthDataController data) {
    final now = DateTime.now();
    final Map<int, int> stepsByWeek = {0: 0, 1: 0, 2: 0, 3: 0};
    final Map<int, int> daysInWeek = {0: 0, 1: 0, 2: 0, 3: 0};

    for (int i = 0; i < 28; i++) {
      final day = now.subtract(Duration(days: i));
      final steps = data.getStepsForDay(day);
      final weekIndex = 3 - (i ~/ 7);

      if (weekIndex >= 0 && weekIndex < 4 && steps > 0) {
        stepsByWeek[weekIndex] = (stepsByWeek[weekIndex] ?? 0) + steps;
        daysInWeek[weekIndex] = (daysInWeek[weekIndex] ?? 0) + 1;
      }
    }

    final Map<int, int> avgStepsByWeek = {};
    for (int i = 0; i < 4; i++) {
      final days = daysInWeek[i] ?? 0;
      avgStepsByWeek[i] = days > 0 ? ((stepsByWeek[i] ?? 0) / days).round() : 0;
    }

    final hasRealData = avgStepsByWeek.values.any((v) => v > 0);

    if (!hasRealData) {
      return _buildEmptyChartState(
        'No 4-week step history',
        'Weekly averages will populate as step logs accumulate',
      );
    }

    final maxSteps = avgStepsByWeek.values.reduce((a, b) => a > b ? a : b);
    final goal = data.stepGoal > 0 ? data.stepGoal : 10000;
    final maxY = maxSteps > goal ? (maxSteps * 1.25) : (goal * 1.25);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF141A20),
            tooltipBorder: BorderSide(
              color: _stepPrimary.withValues(alpha: 0.4),
              width: 1,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final isCurrentWeek = groupIndex == 3;
              return BarTooltipItem(
                isCurrentWeek && rod.toY > 0
                    ? '${rod.toY.toInt()} steps/day (This week)'
                    : '${rod.toY.toInt()} steps/day',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final labels = ['Wk 1', 'Wk 2', 'Wk 3', 'Current'];
                final isCurrentWeek = value.toInt() == 3;

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[value.toInt()],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: isCurrentWeek ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrentWeek ? _stepPrimary : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  '${(value / 1000).toStringAsFixed(1)}k',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(4, (index) {
          final avgSteps = avgStepsByWeek[index] ?? 0;
          final isCurrentWeek = index == 3;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: avgSteps.toDouble(),
                gradient: LinearGradient(
                  colors: avgSteps > 0
                      ? isCurrentWeek
                          ? [_stepSecondary, _stepPrimary]
                          : [
                              _stepSecondary.withValues(alpha: 0.6),
                              _stepPrimary.withValues(alpha: 0.8),
                            ]
                      : [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: isCurrentWeek ? 34 : 26,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyChartState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_walk_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

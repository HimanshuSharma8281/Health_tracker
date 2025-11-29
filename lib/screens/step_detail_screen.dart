import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/health_data_controller.dart';

class StepDetailScreen extends StatefulWidget {
  const StepDetailScreen({super.key});

  @override
  State<StepDetailScreen> createState() => _StepDetailScreenState();
}

class _StepDetailScreenState extends State<StepDetailScreen> {
  String selectedFilter = 'Weekly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Text('Step Tracker',
            style:
                GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<HealthDataController>(
        builder: (context, data, _) {
          final progress = (data.stepsToday / data.stepGoal).clamp(0.0, 1.0);
          final remaining = data.stepGoal - data.stepsToday;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Hero Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3A86FF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_walk,
                          size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${data.stepsToday}',
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'of ${data.stepGoal} steps goal',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          remaining <= 0
                              ? Icons.check_circle
                              : Icons.directions_walk,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          remaining <= 0
                              ? 'Goal achieved! 🎉'
                              : '$remaining steps to goal',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Auto-tracking info card - Update this section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: data.pedestrianStatus == 'walking'
                        ? const Color(0xFF2EC4B6)
                        : const Color(0xFFFFBE0B).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: data.pedestrianStatus == 'walking'
                            ? const Color(0xFF2EC4B6).withOpacity(0.1)
                            : const Color(0xFFFFBE0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        data.pedestrianStatus == 'walking'
                            ? Icons.directions_walk
                            : Icons.accessibility_new,
                        color: data.pedestrianStatus == 'walking'
                            ? const Color(0xFF2EC4B6)
                            : const Color(0xFFFFBE0B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.pedestrianStatus == 'walking'
                                ? 'Walking Detected 🚶'
                                : 'Auto-Tracking Active',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: data.pedestrianStatus == 'walking'
                                  ? const Color(0xFF2EC4B6)
                                  : const Color(0xFFFFBE0B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.pedestrianStatus == 'walking'
                                ? 'Steps are being counted in real-time'
                                : 'Start walking to count steps',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: data.pedestrianStatus == 'walking'
                            ? const Color(0xFF2EC4B6)
                            : const Color(0xFFFFBE0B),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        data.pedestrianStatus == 'walking'
                            ? Icons.trending_up
                            : Icons.sensors,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Chart Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart,
                          color: const Color(0xFF3A86FF), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Step History',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3A86FF).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedFilter,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF3A86FF)),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A86FF),
                        ),
                        items: ['Weekly', 'Monthly'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => selectedFilter = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chart Container
              Container(
                height: 240,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3A86FF).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: selectedFilter == 'Weekly'
                    ? _buildWeeklyChart(data)
                    : _buildMonthlyChart(data),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Today',
                      '${data.stepsToday}',
                      'steps',
                      Icons.today,
                      const Color(0xFF3A86FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Goal',
                      '${data.stepGoal}',
                      'steps target',
                      Icons.flag,
                      const Color(0xFFFFBE0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Calories Burned Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF006E).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF006E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_fire_department,
                          color: Color(0xFFFF006E), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calories Burned',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(data.stepsToday * 0.04).round()} kcal',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFF006E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Distance',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(data.stepsToday * 0.0007).toStringAsFixed(2)} km',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeeklyChart(HealthDataController data) {
    final now = DateTime.now();

    // Create a map for the last 7 days using getStepsForDay helper
    final Map<int, int> stepsByDay = {};
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      stepsByDay[i] = data.getStepsForDay(day);
    }

    // Check if we have any real data
    final hasRealData = stepsByDay.values.any((v) => v > 0);

    if (!hasRealData) {
      return _buildEmptyChartState(
        'No step data yet',
        'Start walking to see your step count',
      );
    }

    // Calculate max Y value based on real data
    final maxSteps = stepsByDay.values.reduce((a, b) => a > b ? a : b);
    final maxY =
        maxSteps > data.stepGoal ? (maxSteps * 1.2) : (data.stepGoal * 1.2);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final isToday = groupIndex == 6;
              return BarTooltipItem(
                rod.toY > 0
                    ? '${rod.toY.toInt()} steps${isToday ? ' (Today)' : ''}'
                    : 'No data',
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
                    isToday ? 'Today' : days[dayIndex],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? const Color(0xFF3A86FF) : Colors.black38,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  '${(value / 1000).toStringAsFixed(1)}k',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.black45),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
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
                          ? [const Color(0xFF3A86FF), const Color(0xFF8338EC)]
                          : [
                              const Color(0xFF3A86FF).withOpacity(0.7),
                              const Color(0xFF8338EC).withOpacity(0.7)
                            ]
                      : [Colors.grey.shade200, Colors.grey.shade200],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: isToday ? 28 : 20,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
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

    // Aggregate steps by week using historical data
    for (int i = 0; i < 28; i++) {
      final day = now.subtract(Duration(days: i));
      final steps = data.getStepsForDay(day);
      final weekIndex = 3 - (i ~/ 7);

      if (weekIndex >= 0 && weekIndex < 4 && steps > 0) {
        stepsByWeek[weekIndex] = (stepsByWeek[weekIndex] ?? 0) + steps;
        daysInWeek[weekIndex] = (daysInWeek[weekIndex] ?? 0) + 1;
      }
    }

    // Calculate averages
    final Map<int, int> avgStepsByWeek = {};
    for (int i = 0; i < 4; i++) {
      final days = daysInWeek[i] ?? 0;
      avgStepsByWeek[i] = days > 0 ? ((stepsByWeek[i] ?? 0) / days).round() : 0;
    }

    final hasRealData = avgStepsByWeek.values.any((v) => v > 0);

    if (!hasRealData) {
      return _buildEmptyChartState(
        'No step data yet',
        'Start walking to see your monthly patterns',
      );
    }

    final maxSteps = avgStepsByWeek.values.reduce((a, b) => a > b ? a : b);
    final maxY =
        maxSteps > data.stepGoal ? (maxSteps * 1.2) : (data.stepGoal * 1.2);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final isCurrentWeek = groupIndex == 3;
              return BarTooltipItem(
                isCurrentWeek && rod.toY > 0
                    ? '${rod.toY.toInt()} steps (This week)'
                    : 'No data',
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
                final labels = ['Week 1', 'Week 2', 'Week 3', 'This Week'];
                final isCurrentWeek = value.toInt() == 3;

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[value.toInt()],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight:
                          isCurrentWeek ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrentWeek
                          ? const Color(0xFF3A86FF)
                          : Colors.black38,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  '${(value / 1000).toStringAsFixed(1)}k',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.black45),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
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
                          ? [const Color(0xFF3A86FF), const Color(0xFF8338EC)]
                          : [
                              const Color(0xFF3A86FF).withOpacity(0.7),
                              const Color(0xFF8338EC).withOpacity(0.7)
                            ]
                      : [Colors.grey.shade200, Colors.grey.shade200],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: isCurrentWeek ? 48 : 36,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
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
            Icons.bar_chart_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          Text(unit,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }
}

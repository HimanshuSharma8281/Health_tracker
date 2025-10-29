import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/health_data_controller.dart';
import '../models/activity_models.dart';
import '../widgets/common_widgets.dart';
import '../utils/formatters.dart';

class TrackersTab extends StatefulWidget {
  const TrackersTab({super.key});

  @override
  State<TrackersTab> createState() => _TrackersTabState();
}

class _TrackersTabState extends State<TrackersTab> {
  final TextEditingController mealController = TextEditingController();
  final TextEditingController calorieController = TextEditingController();
  String activityLogFilter = 'Weekly'; // Weekly, Monthly, Yearly

  @override
  void dispose() {
    mealController.dispose();
    calorieController.dispose();
    super.dispose();
  }

  List<ActivityEntry> _getFilteredHistory(List<ActivityEntry> history) {
    final now = DateTime.now();
    switch (activityLogFilter) {
      case 'Weekly':
        return history.where((entry) {
          final diff = now.difference(entry.date).inDays;
          return diff <= 7;
        }).toList();
      case 'Monthly':
        return history.where((entry) {
          final diff = now.difference(entry.date).inDays;
          return diff <= 30;
        }).toList();
      case 'Yearly':
        return history.where((entry) {
          final diff = now.difference(entry.date).inDays;
          return diff <= 365;
        }).toList();
      default:
        return history;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthDataController>(
      builder: (context, data, _) {
        final goal = data.recommendedGoals;
        final hydrationPercent =
            (data.waterMl / goal.waterGoal).clamp(0.0, 1.2);
        final filteredHistory = _getFilteredHistory(data.history);
        final forecast = data.forecastBundle;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            SectionCard(
              title: 'Personalized Goals',
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GoalChip(label: 'Steps', value: '${goal.stepGoal}'),
                    const SizedBox(width: 12),
                    GoalChip(label: 'Water', value: '${goal.waterGoal} ml'),
                    const SizedBox(width: 12),
                    GoalChip(
                        label: 'Calories', value: '${goal.calorieGoal} kcal'),
                    const SizedBox(width: 12),
                    GoalChip(
                        label: 'Sleep',
                        value: '${goal.sleepGoal.toStringAsFixed(1)} h'),
                    const SizedBox(width: 12),
                    GoalChip(
                        label: 'Mindfulness',
                        value: '${goal.mindfulnessGoal} min'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              title: 'Sleep Tracker',
              trailing: Text(
                  '${data.sleepHours.toStringAsFixed(1)} h last night',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Suggested bedtime: ${data.bedtimeSuggestion}',
                        style: GoogleFonts.inter(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                        'Smart sleep recommendation factors in fatigue, stress, and activity.',
                        style: GoogleFonts.inter(color: Colors.black54)),
                  ]),
            ),
            const SizedBox(height: 18),
            SectionCard(
              title: 'Activity Log',
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: activityLogFilter,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Color(0xFF3A86FF)),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A86FF),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        activityLogFilter = newValue;
                      });
                    }
                  },
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Steps Chart
                  Text('Steps Activity',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  filteredHistory.isEmpty
                      ? Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Text('No data available',
                              style: GoogleFonts.inter(color: Colors.black45)),
                        )
                      : SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 2000,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.black12,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 2000,
                                    getTitlesWidget: (value, meta) => Text(
                                      '${(value ~/ 1000)}k',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: Colors.black45),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= filteredHistory.length)
                                        return const SizedBox.shrink();
                                      final date = filteredHistory[index].date;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          DateFormat('M/d').format(date),
                                          style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: Colors.black54),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    filteredHistory.length,
                                    (index) => FlSpot(
                                      index.toDouble(),
                                      filteredHistory[index].steps.toDouble(),
                                    ),
                                  ),
                                  isCurved: true,
                                  color: const Color(0xFF3A86FF),
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF3A86FF)
                                            .withOpacity(0.3),
                                        const Color(0xFF3A86FF)
                                            .withOpacity(0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                  // Calories Chart
                  Text('Calories Burned',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  filteredHistory.isEmpty
                      ? Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Text('No data available',
                              style: GoogleFonts.inter(color: Colors.black45)),
                        )
                      : SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 500,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.black12,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 500,
                                    getTitlesWidget: (value, meta) => Text(
                                      '${value.toInt()}',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: Colors.black45),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= filteredHistory.length)
                                        return const SizedBox.shrink();
                                      final date = filteredHistory[index].date;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          DateFormat('M/d').format(date),
                                          style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: Colors.black54),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              barGroups: List.generate(
                                filteredHistory.length,
                                (index) => BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: filteredHistory[index]
                                          .calories
                                          .toDouble(),
                                      color: const Color(0xFFFF006E),
                                      width: 16,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                  // Sleep & Water Chart
                  Text('Sleep & Hydration',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  filteredHistory.isEmpty
                      ? Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Text('No data available',
                              style: GoogleFonts.inter(color: Colors.black45)),
                        )
                      : SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.black12,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) => Text(
                                      '${value.toInt()}h',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: Colors.black45),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= filteredHistory.length)
                                        return const SizedBox.shrink();
                                      final date = filteredHistory[index].date;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          DateFormat('M/d').format(date),
                                          style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: Colors.black54),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    filteredHistory.length,
                                    (index) => FlSpot(
                                      index.toDouble(),
                                      filteredHistory[index].sleepHours,
                                    ),
                                  ),
                                  isCurved: true,
                                  color: const Color(0xFFFFBE0B),
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              title: 'Predictive Analytics',
              child: forecast.stepsActual.isEmpty
                  ? Container(
                      height: 240,
                      alignment: Alignment.center,
                      child: Text('Insufficient data for predictions',
                          style: GoogleFonts.inter(color: Colors.black45)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3A86FF),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('Steps',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF006E),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('Calories',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 240,
                          child: LineChart(
                            LineChartData(
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                  show: true,
                                  horizontalInterval: 1500,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.black12,
                                      dashArray: [4, 4],
                                      strokeWidth: 1)),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 46,
                                        interval: 1500,
                                        getTitlesWidget: (value, meta) => Text(
                                            '${value ~/ 1}',
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.black45)))),
                                bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) => Text(
                                            'D${value.toInt() + 1}',
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.black45)))),
                                rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: forecast.stepsActual,
                                  isCurved: true,
                                  color: const Color(0xFF3A86FF),
                                  barWidth: 3,
                                  dotData: FlDotData(show: false),
                                ),
                                LineChartBarData(
                                  spots: forecast.stepsForecast,
                                  isCurved: true,
                                  color: const Color(0xFF3A86FF),
                                  barWidth: 3,
                                  dotData: FlDotData(
                                      show: true,
                                      checkToShowDot: (spot, data) =>
                                          spot.x >=
                                          forecast.stepsActual.last.x),
                                  dashArray: [6, 4],
                                ),
                                LineChartBarData(
                                  spots: forecast.caloriesActual,
                                  isCurved: true,
                                  color: const Color(0xFFFF006E),
                                  barWidth: 3,
                                  dotData: FlDotData(show: false),
                                ),
                                LineChartBarData(
                                  spots: forecast.caloriesForecast,
                                  isCurved: true,
                                  color: const Color(0xFFFF006E),
                                  barWidth: 3,
                                  dotData: FlDotData(
                                      show: true,
                                      checkToShowDot: (spot, data) =>
                                          spot.x >=
                                          forecast.caloriesActual.last.x),
                                  dashArray: [6, 4],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

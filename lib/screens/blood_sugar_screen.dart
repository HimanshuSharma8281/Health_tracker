import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/health_data_controller.dart';
import '../screens/add_blood_sugar_screen.dart';
import '../widgets/glass_container.dart';

class BloodSugarScreen extends StatefulWidget {
  const BloodSugarScreen({super.key});

  @override
  State<BloodSugarScreen> createState() => _BloodSugarScreenState();
}

class _BloodSugarScreenState extends State<BloodSugarScreen> {
  String _selectedFilter = 'Weekly';

  static const Color _bgCharcoal = Color(0xFF090D10);
  static const Color _ambientRuby = Color(0xFF220D12);
  static const Color _sugarCoral = Color(0xFFFF5C7A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCharcoal,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.25,
            colors: [_ambientRuby, _bgCharcoal],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: Consumer<HealthDataController>(
                  builder: (context, data, _) {
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      children: [
                        // Current Reading Hero Card
                        _buildHeroCard(data),
                        const SizedBox(height: 22),

                        // Trend Chart Section
                        _buildTrendSection(data),
                        const SizedBox(height: 24),

                        // Normal Ranges Section
                        _buildRangesSection(),
                        const SizedBox(height: 24),

                        // Health Tips Section
                        _buildTipsSection(),
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
                  color: _sugarCoral,
                  boxShadow: [
                    BoxShadow(
                      color: _sugarCoral,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'BLOOD SUGAR',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddBloodSugarScreen(),
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _sugarCoral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _sugarCoral.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 18,
                color: _sugarCoral,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(HealthDataController data) {
    final status = data.bloodSugar == 0 ? 'No Reading Yet' : _getBloodSugarStatus(data.bloodSugar);
    final statusColor = _getStatusColor(status);

    return GlassContainer(
      blur: 16,
      color: const Color(0xE6141A20),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: _sugarCoral.withValues(alpha: 0.25),
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
                        color: _sugarCoral.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _sugarCoral.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: _sugarCoral,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GLUCOSE LEVEL',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: _sugarCoral,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Current Reading',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
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
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Big Metric Number Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                data.bloodSugar == 0 ? '—' : '${data.bloodSugar.round()}',
                style: GoogleFonts.inter(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'mg/dL',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _sugarCoral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.bloodSugar == 0
                ? 'Tap + to log your latest glucose level'
                : 'Optimal fasting reference: 70–100 mg/dL',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection(HealthDataController data) {
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
                    color: _sugarCoral,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'BLOOD SUGAR TREND',
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
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? _sugarCoral : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
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

        GlassContainer(
          blur: 16,
          color: const Color(0xE6141A20),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          child: Column(
            children: [
              SizedBox(
                height: 190,
                child: _buildBloodSugarChart(data),
              ),
              const SizedBox(height: 14),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Normal', const Color(0xFF2EC4B6)),
                  const SizedBox(width: 16),
                  _buildLegendItem('Elevated', const Color(0xFFFFBE0B)),
                  const SizedBox(width: 16),
                  _buildLegendItem('High', const Color(0xFFFF5C7A)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBloodSugarChart(HealthDataController data) {
    final isWeekly = _selectedFilter == 'Weekly';
    final int totalDays = isWeekly ? 7 : 30;
    final rangeStart = isWeekly
        ? HealthDataController.getWeeklyStartDate()
        : HealthDataController.getMonthlyStartDate();
    final readings = isWeekly
        ? data.getLastWeekReadings()
        : data.getLastMonthReadings();

    if (readings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 40,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 10),
            Text(
              'No blood sugar data yet',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Log readings to see your glycemic trends',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      );
    }

    final Map<int, List<double>> dayGroups = {};
    for (final r in readings) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      final s = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
      final offset = d.difference(s).inDays;
      if (offset >= 0 && offset < totalDays) {
        dayGroups.putIfAbsent(offset, () => []).add(r.value);
      }
    }

    final spots = <FlSpot>[];
    final sortedOffsets = dayGroups.keys.toList()..sort();
    for (final offset in sortedOffsets) {
      final vals = dayGroups[offset]!;
      final avg = vals.reduce((a, b) => a + b) / vals.length;
      spots.add(FlSpot(offset.toDouble(), avg));
    }

    final values = readings.map((r) => r.value).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final yMin = (minValue - 20).clamp(40.0, 200.0).toDouble();
    final yMax = (maxValue + 25).clamp(100.0, 280.0).toDouble();
    final double maxX = (totalDays - 1).toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 30,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: isWeekly ? 1.0 : 5.0,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= totalDays) {
                  return const SizedBox();
                }
                final date = rangeStart.add(Duration(days: idx));
                final now = DateTime.now();
                final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                String label;
                if (isWeekly) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  label = isToday ? 'Today' : days[date.weekday - 1];
                } else {
                  label = '${date.month}/${date.day}';
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      color: isToday ? _sugarCoral : Colors.white.withValues(alpha: 0.4),
                      fontSize: 9,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: maxX,
        minY: yMin,
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: _sugarCoral,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                Color dotColor;
                if (spot.y < 70) {
                  dotColor = const Color(0xFF5CE1E6);
                } else if (spot.y <= 100) {
                  dotColor = const Color(0xFF2EC4B6);
                } else if (spot.y <= 125) {
                  dotColor = const Color(0xFFFFBE0B);
                } else {
                  dotColor = const Color(0xFFFF5C7A);
                }

                return FlDotCirclePainter(
                  radius: 3.5,
                  color: dotColor,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF090D10),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _sugarCoral.withValues(alpha: 0.25),
                  _sugarCoral.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
          // Target 100 mg/dL line
          if (yMin <= 100 && yMax >= 100)
            LineChartBarData(
              spots: [
                const FlSpot(0, 100),
                FlSpot(maxX, 100),
              ],
              isCurved: false,
              color: const Color(0xFF2EC4B6).withValues(alpha: 0.3),
              barWidth: 1.5,
              dashArray: [4, 4],
              dotData: const FlDotData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF141A20),
            tooltipBorder: BorderSide(
              color: _sugarCoral.withValues(alpha: 0.4),
              width: 1,
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex != 0) return null;
                final offset = spot.x.toInt();
                final date = rangeStart.add(Duration(days: offset));
                return LineTooltipItem(
                  '${spot.y.toInt()} mg/dL\n',
                  GoogleFonts.inter(
                    color: _sugarCoral,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: _formatDate(date),
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  Widget _buildRangesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _sugarCoral,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'NORMAL REFERENCE RANGES',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRangeCard('Fasting Glucose', '70 – 100 mg/dL', Icons.wb_sunny_rounded, const Color(0xFF2EC4B6)),
        const SizedBox(height: 10),
        _buildRangeCard('Post-Meal (2 hrs)', '< 140 mg/dL', Icons.restaurant_rounded, const Color(0xFFFFBE0B)),
        const SizedBox(height: 10),
        _buildRangeCard('Random Measurement', '< 200 mg/dL', Icons.access_time_rounded, const Color(0xFFA663FF)),
      ],
    );
  }

  Widget _buildRangeCard(String title, String range, IconData icon, Color color) {
    return GlassContainer(
      blur: 14,
      color: const Color(0xE6141A20),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  range,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _sugarCoral,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'GLUCOSE STABILITY PROTOCOLS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassContainer(
          blur: 14,
          color: const Color(0xE6141A20),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _buildTipItem('Log readings consistently before meals & 2 hours postprandial'),
              _buildTipItem('Prioritize complex carbohydrates with high dietary fiber'),
              _buildTipItem('Engage in light 10–15 min post-meal walks to improve insulin uptake'),
              _buildTipItem('Maintain steady daily hydration to support healthy kidney clearance'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, color: Color(0xFF2EC4B6), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final readingDay = DateTime(date.year, date.month, date.day);
    if (_selectedFilter == 'Weekly') {
      if (readingDay == today) return 'Today';
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    }
    return '${date.day}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _getBloodSugarStatus(double value) {
    if (value < 70) return 'Low';
    if (value <= 100) return 'Normal (Fasting)';
    if (value <= 125) return 'Elevated';
    return 'High';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Normal (Fasting)':
      case 'Normal':
        return const Color(0xFF2EC4B6);
      case 'Elevated':
        return const Color(0xFFFFBE0B);
      case 'High':
        return const Color(0xFFFF5C7A);
      case 'Low':
        return const Color(0xFF5CE1E6);
      default:
        return Colors.white54;
    }
  }
}

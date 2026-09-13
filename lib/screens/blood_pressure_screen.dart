import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/glass_container.dart';
import '../widgets/notification_widget.dart';

class BloodPressureScreen extends StatefulWidget {
  const BloodPressureScreen({super.key});

  @override
  State<BloodPressureScreen> createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Weekly';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  static const Color _bgCharcoal = Color(0xFF090D10);
  static const Color _ambientSapphire = Color(0xFF0D182A);
  static const Color _sysColor = Color(0xFFA663FF);
  static const Color _diaColor = Color(0xFF3A86FF);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<BloodPressureReading> _getFilteredReadings(HealthDataController controller) {
    return _selectedFilter == 'Weekly'
        ? controller.getLastWeekBPReadings()
        : controller.getLastMonthBPReadings();
  }

  String _getStatus(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return 'Normal';
    if (systolic < 130 && diastolic < 80) return 'Elevated';
    if (systolic < 140 || diastolic < 90) return 'Stage 1 High';
    return 'Stage 2 High';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Normal':
        return const Color(0xFF2EC4B6);
      case 'Elevated':
        return const Color(0xFFFFBE0B);
      case 'Stage 1 High':
        return const Color(0xFFFF5C7A);
      case 'Stage 2 High':
        return const Color(0xFFFF3355);
      default:
        return Colors.white54;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Normal':
        return Icons.check_circle_rounded;
      case 'Elevated':
        return Icons.warning_amber_rounded;
      case 'Stage 1 High':
      case 'Stage 2 High':
        return Icons.error_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  void _showAddReadingDialog() {
    final systolicController = TextEditingController(text: '120');
    final diastolicController = TextEditingController(text: '80');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF141A22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: Color(0x338338EC), width: 1.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _sysColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        color: _sysColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Log Blood Pressure',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Systolic & Diastolic Inputs
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _sysColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'SYSTOLIC (SYS)',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: _sysColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _sysColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: TextField(
                              controller: systolicController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: '120',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white24,
                                ),
                                suffixText: 'mmHg ',
                                suffixStyle: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white38,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _diaColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'DIASTOLIC (DIA)',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: _diaColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _diaColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: TextField(
                              controller: diastolicController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: '80',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white24,
                                ),
                                suffixText: 'mmHg ',
                                suffixStyle: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white38,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Clinical Info Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF2EC4B6),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Standard Optimal: < 120 SYS / < 80 DIA mmHg',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Save Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8338EC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final systolic = int.tryParse(systolicController.text);
                      final diastolic = int.tryParse(diastolicController.text);

                      if (systolic != null && diastolic != null) {
                        context.read<HealthDataController>().addBloodPressureReading(
                              systolic,
                              diastolic,
                            );

                        Navigator.pop(modalContext);
                        CustomNotification.show(
                          context,
                          message: 'Blood pressure recorded: $systolic/$diastolic mmHg',
                          type: NotificationType.success,
                          title: 'Reading Added',
                        );
                      }
                    },
                    child: Text(
                      'Save Measurement',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCharcoal,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.25,
            colors: [_ambientSapphire, _bgCharcoal],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: Consumer<HealthDataController>(
                  builder: (context, data, _) {
                    if (data.bloodPressureHistory.isEmpty) {
                      return _buildEmptyState();
                    }

                    final latestReading = data.bloodPressureHistory.first;
                    final status = _getStatus(latestReading.systolic, latestReading.diastolic);
                    final statusColor = _getStatusColor(status);
                    final statusIcon = _getStatusIcon(status);

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      children: [
                        // Hero Card
                        _buildHeroCard(latestReading, status, statusColor, statusIcon),
                        const SizedBox(height: 22),

                        // Trend Chart Section
                        _buildTrendSection(data),
                        const SizedBox(height: 24),

                        // Reading History
                        _buildHistorySection(data),
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
                  color: _sysColor,
                  boxShadow: [
                    BoxShadow(
                      color: _sysColor,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'BLOOD PRESSURE',
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
            onPressed: _showAddReadingDialog,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _sysColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _sysColor.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 18,
                color: _sysColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    BloodPressureReading reading,
    String status,
    Color statusColor,
    IconData statusIcon,
  ) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GlassContainer(
        blur: 16,
        color: const Color(0xE6141A20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _sysColor.withValues(alpha: 0.25),
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
                          color: _sysColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _sysColor.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(
                          Icons.speed_rounded,
                          color: _sysColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LATEST READING',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: _sysColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              DateFormat('MMM d, h:mm a').format(reading.timestamp),
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
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SYS / DIA Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '${reading.systolic}',
                      style: GoogleFonts.inter(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _sysColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SYS mmHg',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: _sysColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '/',
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${reading.diastolic}',
                      style: GoogleFonts.inter(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _diaColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'DIA mmHg',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: _diaColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendSection(HealthDataController data) {
    final filteredData = _getFilteredReadings(data);

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
                    color: _sysColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'PRESSURE TRENDS',
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
                        color: isSelected ? _sysColor : Colors.transparent,
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
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildLegendIndicator('SYS', _sysColor),
                  const SizedBox(width: 14),
                  _buildLegendIndicator('DIA', _diaColor),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: _buildChartWidget(filteredData),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
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

  Widget _buildChartWidget(List<BloodPressureReading> filteredData) {
    if (filteredData.isEmpty) {
      return Center(
        child: Text(
          'No readings for this timeframe',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    final allValues = [
      ...filteredData.map((r) => r.systolic),
      ...filteredData.map((r) => r.diastolic),
    ];
    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);

    double minY = (minValue - 10).toDouble().clamp(40.0, 200.0);
    double maxY = (maxValue + 15).toDouble().clamp(minY + 30, 240.0);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= filteredData.length) {
                  return const SizedBox();
                }
                final date = filteredData[index].timestamp;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MM/dd').format(date),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (filteredData.length - 1).toDouble().clamp(0.0, 50.0),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          // Systolic line
          LineChartBarData(
            spots: filteredData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.systolic.toDouble());
            }).toList(),
            isCurved: true,
            color: _sysColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: _sysColor,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF090D10),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _sysColor.withValues(alpha: 0.08),
            ),
          ),
          // Diastolic line
          LineChartBarData(
            spots: filteredData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.diastolic.toDouble());
            }).toList(),
            isCurved: true,
            color: _diaColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: _diaColor,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF090D10),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _diaColor.withValues(alpha: 0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF141A20),
            tooltipBorder: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isSys = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isSys ? 'SYS' : 'DIA'}: ${spot.y.toInt()} mmHg',
                  GoogleFonts.inter(
                    color: isSys ? _sysColor : _diaColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(HealthDataController data) {
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
                    color: _sysColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'READING LOGS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            Text(
              '${data.bloodPressureHistory.length} logs',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...data.bloodPressureHistory.map((reading) {
          final readingStatus = _getStatus(reading.systolic, reading.diastolic);
          final readingColor = _getStatusColor(readingStatus);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassContainer(
              blur: 12,
              color: const Color(0xE6141A20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: readingColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: readingColor,
                      size: 18,
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
                              '${reading.systolic}/${reading.diastolic}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'mmHg',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(reading.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: readingColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: readingColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      readingStatus,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: readingColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _sysColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _sysColor.withValues(alpha: 0.25)),
            ),
            child: const Icon(
              Icons.speed_rounded,
              size: 42,
              color: _sysColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No blood pressure records',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log your systolic and diastolic measurements\nto track cardiovascular trends',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddReadingDialog,
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: Text(
              'Add First Reading',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8338EC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

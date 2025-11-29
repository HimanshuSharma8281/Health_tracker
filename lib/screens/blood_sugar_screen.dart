import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/health_data_controller.dart';
import '../screens/add_blood_sugar_screen.dart';

class BloodSugarScreen extends StatefulWidget {
  const BloodSugarScreen({super.key});

  @override
  State<BloodSugarScreen> createState() => _BloodSugarScreenState();
}

class _BloodSugarScreenState extends State<BloodSugarScreen> {
  String _selectedFilter = 'Weekly'; // 'Weekly' or 'Monthly'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Sugar',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<HealthDataController>(
        builder: (context, data, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Current Reading Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Current Reading',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          data.bloodSugar == 0
                              ? '--'
                              : '${data.bloodSugar.round()}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'mg/dL',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.bloodSugar == 0
                            ? 'No Reading Yet'
                            : _getBloodSugarStatus(data.bloodSugar),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Blood Sugar Trend Graph
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Blood Sugar Trend',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        // Filter Dropdown
                        InkWell(
                          onTap: _showFilterOptions,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedFilter,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFF6B6B),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: const Color(0xFFFF6B6B),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: _buildBloodSugarChart(),
                    ),
                    const SizedBox(height: 16),
                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Normal', const Color(0xFF4CAF50)),
                        const SizedBox(width: 20),
                        _buildLegendItem('Elevated', const Color(0xFFFF9800)),
                        const SizedBox(width: 20),
                        _buildLegendItem('High', const Color(0xFFF44336)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Range Information
              Text(
                'Normal Ranges',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _buildRangeCard(
                'Fasting',
                '70-100 mg/dL',
                Icons.wb_sunny_outlined,
                const Color(0xFF2EC4B6),
              ),
              const SizedBox(height: 12),
              _buildRangeCard(
                'After Meals (2 hours)',
                '<140 mg/dL',
                Icons.restaurant,
                const Color(0xFFFFBE0B),
              ),
              const SizedBox(height: 12),
              _buildRangeCard(
                'Random',
                '<200 mg/dL',
                Icons.access_time,
                const Color(0xFF8338EC),
              ),
              const SizedBox(height: 24),

              // Add Reading Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddBloodSugarScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Reading'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tips Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: Color(0xFFFFBE0B)),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for Healthy Blood Sugar',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTipItem(
                        'Monitor regularly, especially before and after meals'),
                    _buildTipItem(
                        'Maintain a balanced diet with controlled carbohydrates'),
                    _buildTipItem(
                        'Exercise regularly to improve insulin sensitivity'),
                    _buildTipItem('Stay hydrated throughout the day'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRangeCard(
      String title, String range, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  range,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2EC4B6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Time Period',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildFilterOption(
                'Weekly',
                'Last 7 days',
                Icons.calendar_view_week,
              ),
              _buildFilterOption(
                'Monthly',
                'Last 30 days',
                Icons.calendar_month,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String filter, String subtitle, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6B6B).withOpacity(0.05)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFFFF6B6B) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF6B6B).withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filter,
                    style: GoogleFonts.poppins(
                      fontSize: 13, // decreased font size
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? const Color(0xFFFF6B6B) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12, // decreased font size
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFF6B6B),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodSugarChart() {
    return Consumer<HealthDataController>(
      builder: (context, data, _) {
        final readings = _selectedFilter == 'Weekly'
            ? data.getLastWeekReadings()
            : data.getLastMonthReadings();

        if (readings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No readings yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first reading to see the trend',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Sort readings by date
        readings.sort((a, b) => a.date.compareTo(b.date));

        // Create spots for the chart
        final spots = readings.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.value);
        }).toList();

        // Calculate min and max Y values for better scaling
        final values = readings.map((r) => r.value).toList();
        final minValue = values.reduce((a, b) => a < b ? a : b);
        final maxValue = values.reduce((a, b) => a > b ? a : b);
        final yMin = (minValue - 20).clamp(40, 200).toDouble();
        final yMax = (maxValue + 20).clamp(100, 250).toDouble();

        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: _selectedFilter == 'Weekly' ? 1 : 5,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < readings.length) {
                      final reading = readings[value.toInt()];
                      final dayLabel = _getDayLabel(reading.date);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          dayLabel,
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (readings.length - 1).toDouble(),
            minY: yMin,
            maxY: yMax,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: const Color(0xFFFF6B6B),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    Color dotColor;
                    if (spot.y < 70) {
                      dotColor = const Color(0xFF2196F3); // Low - Blue
                    } else if (spot.y <= 100) {
                      dotColor = const Color(0xFF4CAF50); // Normal - Green
                    } else if (spot.y <= 125) {
                      dotColor = const Color(0xFFFF9800); // Elevated - Orange
                    } else {
                      dotColor = const Color(0xFFF44336); // High - Red
                    }

                    return FlDotCirclePainter(
                      radius: 5,
                      color: dotColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFF6B6B).withOpacity(0.3),
                      const Color(0xFFFF6B6B).withOpacity(0.05),
                    ],
                  ),
                ),
              ),
              // Reference lines for normal range (only if they fit in the visible range)
              if (yMin <= 100 && yMax >= 100)
                LineChartBarData(
                  spots: [
                    FlSpot(0, 100),
                    FlSpot((readings.length - 1).toDouble(), 100),
                  ],
                  isCurved: false,
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  barWidth: 2,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              if (yMin <= 70 && yMax >= 70)
                LineChartBarData(
                  spots: [
                    FlSpot(0, 70),
                    FlSpot((readings.length - 1).toDouble(), 70),
                  ],
                  isCurved: false,
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  barWidth: 2,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    final reading = readings[index];
                    return LineTooltipItem(
                      '${spot.y.toInt()} mg/dL\n${_formatDate(reading.date)}',
                      GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
            ),
          ),
        );
      },
    );
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (_selectedFilter == 'Weekly') {
      if (difference == 0) return 'Today';
      if (difference == 1) return 'Yes';
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else {
      // Monthly view - show dates
      return '${date.day}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';

    return '${date.day}/${date.month}';
  }

  String _getBloodSugarStatus(double value) {
    if (value < 70) return 'Low';
    if (value <= 100) return 'Normal (Fasting)';
    if (value <= 125) return 'Pre-diabetes Range';
    return 'High - Consult Doctor';
  }
}

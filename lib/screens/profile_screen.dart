import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/notification_widget.dart';
import 'ai_health_insights_screen.dart';

class SleepDetailScreen extends StatefulWidget {
  const SleepDetailScreen({super.key});

  @override
  State<SleepDetailScreen> createState() => _SleepDetailScreenState();
}

class _SleepDetailScreenState extends State<SleepDetailScreen> {
  String selectedFilter = 'Weekly';

  void _showAddSleepDialog(HealthDataController data) {
    double hours = 7.0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFBE0B).withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFBE0B), Color(0xFFFB8500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.nightlight_round,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Log Sleep',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'How long did you sleep?',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sleep hours display
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFBE0B).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${hours.toStringAsFixed(1)} hours',
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFFBE0B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'of sleep',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Slider
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFFFFBE0B),
                          inactiveTrackColor:
                              const Color(0xFFFFBE0B).withOpacity(0.2),
                          thumbColor: const Color(0xFFFFBE0B),
                          overlayColor:
                              const Color(0xFFFFBE0B).withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12,
                          ),
                          trackHeight: 8,
                        ),
                        child: Slider(
                          value: hours,
                          min: 0.5,
                          max: 12.0,
                          divisions: 23,
                          onChanged: (value) {
                            setState(() => hours = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Min/Max labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0.5h',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                          Text(
                            '12h',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFBE0B),
                                    Color(0xFFFB8500)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFBE0B)
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    // Add sleep reading to controller
                                    data.addSleepReading(hours);

                                    Navigator.pop(context);
                                    CustomNotification.show(
                                      context,
                                      message:
                                          'Logged ${hours.toStringAsFixed(1)} hours of sleep',
                                      type: NotificationType.success,
                                      title: 'Sleep Added',
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Log Sleep',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _removeSleepEntry(SleepReading entry) {
    final data = Provider.of<HealthDataController>(context, listen: false);
    data.removeSleepReading(entry);

    CustomNotification.show(
      context,
      message: 'Removed ${entry.hours.toStringAsFixed(1)}h sleep entry',
      type: NotificationType.info,
      title: 'Sleep Removed',
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text('Sleep Tracker',
            style:
                GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<HealthDataController>(
        builder: (context, data, _) {
          final progress = (data.sleepHours / data.sleepGoal).clamp(0.0, 1.0);
          final remaining = data.sleepGoal - data.sleepHours;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Hero Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFBE0B), Color(0xFFFB8500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFBE0B).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Sleep icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.nightlight_round,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Current sleep hours
                    Text(
                      '${data.sleepHours.toStringAsFixed(1)} h',
                      style: GoogleFonts.inter(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'of ${data.sleepGoal.toStringAsFixed(1)}h goal',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Progress bar
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

                    // Status text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          remaining <= 0 ? Icons.check_circle : Icons.bedtime,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          remaining <= 0
                              ? 'Sleep goal achieved! 😴'
                              : '${remaining.toStringAsFixed(1)}h more to goal',
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

              // Log Sleep Button
              Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFBE0B), Color(0xFFFB8500)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFBE0B).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showAddSleepDialog(data),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Log Sleep',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sleep History
              if (data.sleepReadingHistory.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history,
                            color: const Color(0xFFFFBE0B), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Sleep History',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFBE0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${data.sleepReadingHistory.length} entries',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFFBE0B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...data.sleepReadingHistory.reversed.map((entry) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFBE0B), Color(0xFFFB8500)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.nightlight_round,
                              color: Colors.white, size: 22),
                        ),
                        title: Text(
                          '${entry.hours.toStringAsFixed(1)} hours',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          _formatTime(entry.date),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () => _removeSleepEntry(entry),
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Color(0xFFFF006E)),
                          iconSize: 24,
                        ),
                      ),
                    )),
                const SizedBox(height: 24),
              ],

              // Sleep Chart with Filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart,
                          color: const Color(0xFFFFBE0B), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Sleep Patterns',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  // Dropdown Filter
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFBE0B).withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFBE0B).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedFilter,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFFFFBE0B),
                          size: 24,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFFBE0B),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        dropdownColor: Colors.white,
                        items: [
                          DropdownMenuItem(
                            value: 'Weekly',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_view_week,
                                  color: const Color(0xFFFFBE0B),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text('Weekly'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Monthly',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  color: const Color(0xFFFFBE0B),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text('Monthly'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedFilter = newValue;
                            });
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
                      color: const Color(0xFFFFBE0B).withOpacity(0.1),
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

              // Sleep Stages Pie Chart
              Row(
                children: [
                  Icon(Icons.pie_chart,
                      color: const Color(0xFFFFBE0B), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Sleep Stages',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFBE0B).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: data.sleepHours > 0
                    ? Row(
                        children: [
                          // Pie Chart
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 180,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 50,
                                  sections: [
                                    PieChartSectionData(
                                      value: data.sleepHours * 0.3,
                                      title: '30%',
                                      color: const Color(0xFFFFBE0B),
                                      radius: 50,
                                      titleStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: data.sleepHours * 0.5,
                                      title: '50%',
                                      color: const Color(0xFFFB8500),
                                      radius: 50,
                                      titleStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: data.sleepHours * 0.2,
                                      title: '20%',
                                      color: const Color(0xFFFFD60A),
                                      radius: 50,
                                      titleStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Legend
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendItem(
                                  'Deep',
                                  '${(data.sleepHours * 0.3).toStringAsFixed(1)}h',
                                  const Color(0xFFFFBE0B),
                                ),
                                const SizedBox(height: 12),
                                _buildLegendItem(
                                  'Light',
                                  '${(data.sleepHours * 0.5).toStringAsFixed(1)}h',
                                  const Color(0xFFFB8500),
                                ),
                                const SizedBox(height: 12),
                                _buildLegendItem(
                                  'REM',
                                  '${(data.sleepHours * 0.2).toStringAsFixed(1)}h',
                                  const Color(0xFFFFD60A),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.bedtime_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No sleep data yet',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Log your sleep to see stages breakdown',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              // Sleep Quality Card
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFBE0B).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sleep Quality',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildQualityRow(
                        'Deep Sleep',
                        '${(data.sleepHours * 0.3).toStringAsFixed(1)}h',
                        Icons.nights_stay),
                    const Divider(height: 24),
                    _buildQualityRow(
                        'Light Sleep',
                        '${(data.sleepHours * 0.5).toStringAsFixed(1)}h',
                        Icons.brightness_3),
                    const Divider(height: 24),
                    _buildQualityRow(
                        'REM Sleep',
                        '${(data.sleepHours * 0.2).toStringAsFixed(1)}h',
                        Icons.bedtime),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bedtime Suggestion
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFBE0B).withOpacity(0.1),
                      const Color(0xFFFB8500).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFFBE0B).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFBE0B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lightbulb,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sleep Tips',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFBE0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTip('🌙', 'Maintain consistent sleep schedule'),
                    _buildTip('📱', 'Avoid screens 1 hour before bed'),
                    _buildTip('🛏️', 'Keep bedroom cool and dark'),
                    _buildTip('☕', 'Limit caffeine after 2 PM'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // AI Health Insights Tile
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8338EC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.psychology, color: Color(0xFF8338EC)),
                ),
                title: Text('AI Health Insights',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                subtitle: Text('Get personalized health recommendations',
                    style: GoogleFonts.inter(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIHealthInsightsScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeeklyChart(HealthDataController data) {
    // Get last 7 days of sleep entries
    final sleepHistory = data.sleepReadingHistory;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));

    // Create a map for the last 7 days
    final Map<int, double> sleepByDay = {};

    // Initialize all 7 days with 0
    for (int i = 0; i < 7; i++) {
      sleepByDay[i] = 0.0;
    }

    // Fill in actual sleep data from sleepHistory
    for (var entry in sleepHistory) {
      if (entry.date.isAfter(sevenDaysAgo)) {
        final daysDiff = now.difference(entry.date).inDays;
        final index = 6 - daysDiff; // Reverse index (0 = oldest, 6 = today)
        if (index >= 0 && index < 7) {
          sleepByDay[index] = (sleepByDay[index] ?? 0) + entry.hours;
        }
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 12,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY > 0 ? '${rod.toY.toStringAsFixed(1)}h' : 'No data',
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
                final today = DateTime.now().weekday - 1; // 0 = Monday
                final dayIndex = (today - 6 + value.toInt()) % 7;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    days[dayIndex < 0 ? dayIndex + 7 : dayIndex],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.black45,
                  ),
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
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          final sleepHours = sleepByDay[index] ?? 0.0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: sleepHours > 0
                    ? sleepHours
                    : 0.5, // Minimum height for visibility
                gradient: LinearGradient(
                  colors: sleepHours > 0
                      ? [const Color(0xFFFFBE0B), const Color(0xFFFB8500)]
                      : [Colors.grey.shade300, Colors.grey.shade300],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthlyChart(HealthDataController data) {
    // Get last 4 weeks of sleep entries
    final sleepHistory = data.sleepReadingHistory;
    final now = DateTime.now();
    final Map<int, double> sleepByWeek = {0: 0, 1: 0, 2: 0, 3: 0};

    // Aggregate sleep data by week
    for (var entry in sleepHistory) {
      final daysAgo = now.difference(entry.date).inDays;
      final weekIndex = (daysAgo / 7).floor();
      if (weekIndex >= 0 && weekIndex < 4) {
        sleepByWeek[3 - weekIndex] =
            (sleepByWeek[3 - weekIndex] ?? 0) + entry.hours;
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 70,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY > 0 ? '${rod.toY.toStringAsFixed(1)}h' : 'No data',
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
                const weeks = ['W1', 'W2', 'W3', 'W4'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    weeks[value.toInt()],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.black45,
                  ),
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
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(4, (index) {
          final weeklySleep = sleepByWeek[index] ?? 0.0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: weeklySleep > 0 ? weeklySleep : 2.0, // Minimum height
                gradient: LinearGradient(
                  colors: weeklySleep > 0
                      ? [
                          const Color(0xFFFFBE0B)
                              .withOpacity(0.8 + (index * 0.05)),
                          const Color(0xFFFB8500)
                              .withOpacity(0.8 + (index * 0.05)),
                        ]
                      : [Colors.grey.shade300, Colors.grey.shade300],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 40,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQualityRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFBE0B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFFBE0B), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/notification_widget.dart';
import '../widgets/glass_container.dart';

class SleepDetailScreen extends StatefulWidget {
  const SleepDetailScreen({super.key});

  @override
  State<SleepDetailScreen> createState() => _SleepDetailScreenState();
}

class _SleepDetailScreenState extends State<SleepDetailScreen> {
  String selectedFilter = 'Weekly';

  void _showAddSleepDialog(HealthDataController data) {
    double hours = data.sleepHours > 0 ? data.sleepHours : 7.5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: GlassContainer(
              blur: 24,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              color: const Color(0xE6141A20),
              border: const Border(
                top: BorderSide(color: Color(0x409B86EC), width: 1.5),
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
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
                          color: const Color(0x259B86EC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x409B86EC)),
                        ),
                        child: const Icon(Icons.nightlight_round, color: Color(0xFF9B86EC), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Log Sleep Duration',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'How long did you rest today?',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Duration Display
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: hours.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          TextSpan(
                            text: ' hrs',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9B86EC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF9B86EC),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                      thumbColor: Colors.white,
                      overlayColor: const Color(0x339B86EC),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: hours.clamp(0.0, 14.0),
                      min: 0.0,
                      max: 14.0,
                      divisions: 28,
                      onChanged: (val) {
                        setModalState(() => hours = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick presets
                  Text(
                    'Quick Presets',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [6.0, 7.0, 7.5, 8.0, 8.5, 9.0].map((preset) {
                      final isSelected = (hours - preset).abs() < 0.1;
                      return InkWell(
                        onTap: () => setModalState(() => hours = preset),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF9B86EC).withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF9B86EC) : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            '${preset.toStringAsFixed(1)}h',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF9B86EC) : Colors.white70,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B86EC), Color(0xFF8338EC)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          data.addSleepReading(hours);
                          Navigator.pop(context);
                          CustomNotification.show(
                            context,
                            message: 'Sleep recorded: ${hours.toStringAsFixed(1)} hours',
                            type: NotificationType.success,
                            title: 'Sleep Saved',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Save Sleep Record',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
      backgroundColor: const Color(0xFF090D10),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF090D10),
          gradient: RadialGradient(
            center: Alignment(-0.7, -0.6),
            radius: 1.2,
            colors: [
              Color(0xFF16102A), // Subtle midnight lavender atmosphere
              Color(0xFF090D10),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<HealthDataController>(
            builder: (context, data, _) {
              final progress = data.sleepGoal > 0 ? (data.sleepHours / data.sleepGoal).clamp(0.0, 1.0) : 0.0;
              final diff = data.sleepHours - data.sleepGoal;
              final percentage = (progress * 100).round();

              return ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  // 1. Navigation Header
                  Row(
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
                      Text(
                        'Sleep Tracker',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showAddSleepDialog(data),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x339B86EC)),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Color(0xFF9B86EC),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. HERO GLASS CONTAINER
                  GlassContainer(
                    blur: 16,
                    padding: const EdgeInsets.all(24),
                    color: const Color(0xE6141A20),
                    border: Border.all(color: const Color(0x339B86EC), width: 1.2),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF9B86EC),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'RECORDED SLEEP',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.3,
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      data.sleepHours.toStringAsFixed(1),
                                      style: GoogleFonts.inter(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '/ ${data.sleepGoal.toStringAsFixed(1)} hrs',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Moon Badge
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF9B86EC), Color(0xFF8338EC)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF9B86EC).withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.nightlight_round,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Container(
                                height: 12,
                                width: double.infinity,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF9B86EC), Color(0xFF8338EC)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF9B86EC).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Status Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '$percentage% of sleep target',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF9B86EC),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              diff >= 0
                                  ? 'Target reached'
                                  : '${diff.abs().toStringAsFixed(1)}h short of goal',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. QUICK SLEEP PRESETS
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF9B86EC),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LOG SLEEP REST',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                    children: [
                      ...[6.0, 7.0, 7.5, 8.0, 8.5].map((preset) {
                        return InkWell(
                          onTap: () {
                            data.addSleepReading(preset);
                            CustomNotification.show(
                              context,
                              message: 'Sleep recorded: ${preset.toStringAsFixed(1)} hours',
                              type: NotificationType.success,
                              title: 'Sleep Logged',
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: GlassContainer(
                            blur: 12,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: const Color(0xE6141A20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bedtime_outlined, color: Color(0xFF9B86EC), size: 18),
                                const SizedBox(height: 4),
                                Text(
                                  '${preset.toStringAsFixed(1)}h',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      // Custom Slider Button
                      InkWell(
                        onTap: () => _showAddSleepDialog(data),
                        borderRadius: BorderRadius.circular(16),
                        child: GlassContainer(
                          blur: 12,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: const Color(0x339B86EC),
                          border: Border.all(color: const Color(0x669B86EC)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.tune_rounded, color: Color(0xFF9B86EC), size: 18),
                              const SizedBox(height: 4),
                              Text(
                                'Custom',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF9B86EC),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 4. TRENDS & CHARTS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF9B86EC),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SLEEP PATTERNS',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      // Filter Switcher
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: ['Weekly', 'Monthly'].map((f) {
                            final isSel = selectedFilter == f;
                            return InkWell(
                              onTap: () => setState(() => selectedFilter = f),
                              borderRadius: BorderRadius.circular(9),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF9B86EC) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  f,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? Colors.white : Colors.white60,
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
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    color: const Color(0xE6141A20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    child: SizedBox(
                      height: 190,
                      child: selectedFilter == 'Weekly'
                          ? _buildWeeklyChart(data)
                          : _buildMonthlyChart(data),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 5. TODAY'S SLEEP ENTRIES
                  if (data.sleepReadingHistory.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF9B86EC),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'RECENT SLEEP LOGS',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${data.sleepReadingHistory.length} logs',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...data.sleepReadingHistory.reversed.take(5).map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassContainer(
                          blur: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: const Color(0xE6141A20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0x209B86EC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.nightlight_round, color: Color(0xFF9B86EC), size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.hours.toStringAsFixed(1)} hours',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(entry.date),
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeSleepEntry(entry),
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // 6. CLINICAL SLEEP ARCHITECTURE TIPS
                  GlassContainer(
                    blur: 14,
                    padding: const EdgeInsets.all(20),
                    color: const Color(0xE6141A20),
                    border: Border.all(color: const Color(0x229B86EC)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9B86EC), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Circadian & Rest Guidelines',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTipItem('🌙 Adults require 7 to 9 hours of restorative sleep to maintain metabolic stability.'),
                        _buildTipItem('📵 Blue light exposure within 60 minutes of bedtime delays natural melatonin synthesis.'),
                        _buildTipItem('❄️ Optimal bedroom ambient temperature for deep slow-wave sleep is between 18°C and 21°C.'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          height: 1.45,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(HealthDataController data) {
    final now = DateTime.now();
    final Map<int, double> sleepByDay = {};
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      sleepByDay[i] = data.getSleepForDay(day);
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 12.0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)} hrs',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, _) {
                return Text(
                  '${val.round()}h',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final dIdx = val.toInt().clamp(0, 6);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    days[dIdx],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.04),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (idx) {
          final hrs = sleepByDay[idx] ?? 0.0;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: hrs,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8338EC), Color(0xFF9B86EC)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 12.0,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthlyChart(HealthDataController data) {
    final now = DateTime.now();
    final Map<int, double> sleepByWeek = {0: 0, 1: 0, 2: 0, 3: 0};

    for (int i = 0; i < 28; i++) {
      final day = now.subtract(Duration(days: i));
      final sleep = data.getSleepForDay(day);
      final weekIndex = 3 - (i ~/ 7);
      if (weekIndex >= 0 && weekIndex < 4) {
        sleepByWeek[weekIndex] = (sleepByWeek[weekIndex] ?? 0) + sleep;
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 70.0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)} hrs',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, _) {
                return Text(
                  '${val.round()}h',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                const weeks = ['W1', 'W2', 'W3', 'W4'];
                final wIdx = val.toInt().clamp(0, 3);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    weeks[wIdx],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.04),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(4, (idx) {
          final totalHrs = sleepByWeek[idx] ?? 0.0;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: totalHrs,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8338EC), Color(0xFF9B86EC)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 70.0,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

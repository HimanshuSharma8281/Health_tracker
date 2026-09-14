import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controllers/health_data_controller.dart';
import '../widgets/glass_container.dart';

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Weekly';
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getHeartRateCategory(double bpm) {
    if (bpm <= 0) return 'No Data';
    if (bpm < 60) return 'Resting / Low';
    if (bpm <= 100) return 'Normal Resting';
    if (bpm <= 120) return 'Elevated';
    return 'High / Tachycardia';
  }

  Color _getHeartRateColor(double bpm) {
    if (bpm <= 0) return Colors.white38;
    if (bpm < 60) return const Color(0xFF5CE1E6);
    if (bpm <= 100) return const Color(0xFF48E5C2);
    if (bpm <= 120) return const Color(0xFFFFAA4C);
    return const Color(0xFFFF5C7A);
  }

  void _showAddReadingModal(BuildContext context) {
    final controller = context.read<HealthDataController>();
    double enteredBpm = controller.heartRate > 0 ? controller.heartRate : 72.0;
    final textController = TextEditingController(text: enteredBpm.round().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final category = _getHeartRateCategory(enteredBpm);
            final catColor = _getHeartRateColor(enteredBpm);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF141A22),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(color: Color(0x33FF5C7A), width: 1.5),
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
                            color: const Color(0xFFFF5C7A).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFFF5C7A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Record Heart Rate',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: catColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: catColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: textController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null && parsed >= 30 && parsed <= 250) {
                                  setModalState(() {
                                    enteredBpm = parsed;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'BPM',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF5C7A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFF5C7A),
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                        thumbColor: Colors.white,
                        overlayColor: const Color(0x33FF5C7A),
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: enteredBpm.clamp(40.0, 180.0),
                        min: 40.0,
                        max: 180.0,
                        divisions: 140,
                        onChanged: (val) {
                          setModalState(() {
                            enteredBpm = val;
                            textController.text = val.round().toString();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Quick Presets',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [58, 65, 72, 80, 95, 120].map((preset) {
                        final isSelected = enteredBpm.round() == preset;
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              enteredBpm = preset.toDouble();
                              textController.text = preset.toString();
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF5C7A).withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF5C7A)
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              '$preset bpm',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFFFF5C7A)
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5C7A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          controller.updateHeartRate(enteredBpm);
                          Navigator.pop(modalCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF1B232E),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    color: Color(0xFFFF5C7A),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Heart rate recorded: ${enteredBpm.round()} BPM',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Save Heart Rate',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D10),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.6, -0.7),
            radius: 1.3,
            colors: [
              Color(0x22FF5C7A),
              Color(0xFF090D10),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<HealthDataController>(
            builder: (context, data, _) {
              final hasHr = data.heartRate > 0;
              final currentBpm = hasHr ? data.heartRate.round() : null;
              final category = _getHeartRateCategory(data.heartRate);
              final catColor = _getHeartRateColor(data.heartRate);

              final readings = _selectedFilter == 'Weekly'
                  ? data.getLastWeekHeartRateReadings()
                  : data.getLastMonthHeartRateReadings();

              return CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    pinned: true,
                    leading: IconButton(
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
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF5C7A),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF5C7A),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Heart Rate',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    centerTitle: true,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          onPressed: () => _showAddReadingModal(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5C7A).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFF5C7A).withValues(alpha: 0.3)),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: Color(0xFFFF5C7A),
                            ),
                          ),
                          tooltip: 'Record BPM',
                        ),
                      ),
                    ],
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 1. Hero Live Heart Rate Pulse Card
                        GlassContainer(
                          blur: 16,
                          padding: const EdgeInsets.all(22),
                          border: Border.all(
                            color: const Color(0xFFFF5C7A).withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0x1FFF5C7A),
                              Color(0x08FF5C7A),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        ScaleTransition(
                                          scale: _pulseScale,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF5C7A)
                                                  .withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.favorite_rounded,
                                              color: Color(0xFFFF5C7A),
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'RESTING HEART RATE',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                              color: const Color(0xFFFF5C7A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: catColor.withValues(alpha: 0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      category,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: catColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    currentBpm != null ? '$currentBpm' : '—',
                                    style: GoogleFonts.inter(
                                      fontSize: 64,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -2,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'BPM',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFF5C7A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasHr
                                    ? 'Resting rate within safe physiological zone'
                                    : 'No heart rate recorded today',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Live ECG Strip
                              SizedBox(
                                height: 46,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: _ScreenEcgPainter(
                                    color: const Color(0xFFFF5C7A),
                                    pulseProgress: _pulseController.value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. Trend Chart Section Header & Filter
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
                                    color: Color(0xFFFF5C7A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'HEART RATE TRENDS',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: ['Weekly', 'Monthly'].map((filter) {
                                  final isSel = _selectedFilter == filter;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedFilter = filter);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? const Color(0xFFFF5C7A)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        filter,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
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

                        const SizedBox(height: 12),

                        // 3. FlChart Line Chart
                        GlassContainer(
                          blur: 14,
                          padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF5C7A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'BPM Readings',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Target: 60–100 bpm',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF48E5C2),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 160,
                                child: _buildChart(readings),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 4. Clinical Heart Rate Zones Card
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF5C7A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cardiovascular Zones',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GlassContainer(
                          blur: 14,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildZoneRow(
                                'Resting Zone',
                                '< 60 BPM',
                                'Sleep, recovery, athletic baseline',
                                const Color(0xFF5CE1E6),
                                hasHr && data.heartRate < 60,
                              ),
                              const Divider(color: Colors.white10, height: 16),
                              _buildZoneRow(
                                'Fat Burn / Normal',
                                '60 – 100 BPM',
                                'Everyday baseline & metabolic efficiency',
                                const Color(0xFF48E5C2),
                                hasHr && data.heartRate >= 60 && data.heartRate <= 100,
                              ),
                              const Divider(color: Colors.white10, height: 16),
                              _buildZoneRow(
                                'Cardio / Aerobic',
                                '101 – 140 BPM',
                                'Cardiorespiratory endurance & tempo training',
                                const Color(0xFFFFAA4C),
                                hasHr && data.heartRate > 100 && data.heartRate <= 140,
                              ),
                              const Divider(color: Colors.white10, height: 16),
                              _buildZoneRow(
                                'Peak / Anaerobic',
                                '> 140 BPM',
                                'Maximum exertion & sprint capacity',
                                const Color(0xFFFF5C7A),
                                hasHr && data.heartRate > 140,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 5. Recent Readings History
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
                                    color: Color(0xFFFF5C7A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'READING HISTORY',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            if (data.heartRateHistory.isNotEmpty)
                              Text(
                                '${data.heartRateHistory.length} recorded',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white38,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (data.heartRateHistory.isEmpty)
                          GlassContainer(
                            blur: 12,
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.favorite_border_rounded,
                                    size: 36,
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No heart rate readings logged yet',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap the button below to record your first measurement',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white38,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF5C7A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => _showAddReadingModal(context),
                                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                    label: Text(
                                      'Log BPM Now',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: data.heartRateHistory.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final item = data.heartRateHistory[idx];
                              final itemCat = _getHeartRateCategory(item.bpm);
                              final itemColor = _getHeartRateColor(item.bpm);
                              final timeStr = DateFormat('MMM d, h:mm a').format(item.timestamp);

                              return GlassContainer(
                                blur: 10,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: itemColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.favorite_rounded,
                                        color: itemColor,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.bpm.round()} BPM',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          timeStr,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: itemColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: itemColor.withValues(alpha: 0.3),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        itemCat,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: itemColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF5C7A),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Log Heart Rate',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        onPressed: () => _showAddReadingModal(context),
      ),
    );
  }

  Widget _buildZoneRow(
    String title,
    String bpmRange,
    String desc,
    Color color,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      bpmRange,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<HeartRateReading> readings) {
    if (readings.isEmpty) {
      return Center(
        child: Text(
          'No readings for this period',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white30,
          ),
        ),
      );
    }

    // Sort chronologically
    final sorted = List<HeartRateReading>.from(readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final spots = sorted.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.bpm);
    }).toList();

    return LineChart(
      LineChartData(
        minY: 40,
        maxY: 160,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.07),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 30,
              reservedSize: 32,
              getTitlesWidget: (val, _) {
                return Text(
                  '${val.toInt()}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white30,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: sorted.length <= 7 ? 1.0 : math.max(1, (sorted.length / 4).floor()).toDouble(),
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= sorted.length) return const SizedBox();
                final date = sorted[idx].timestamp;
                return Text(
                  DateFormat('MM/dd').format(date),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: Colors.white30,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFFFF5C7A),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3.5,
                color: const Color(0xFFFF5C7A),
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFF5C7A).withValues(alpha: 0.28),
                  const Color(0xFFFF5C7A).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenEcgPainter extends CustomPainter {
  final Color color;
  final double pulseProgress;

  _ScreenEcgPainter({required this.color, required this.pulseProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h * 0.55;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, midY);

    // Baseline leading
    path.lineTo(w * 0.20, midY);
    // P wave
    path.cubicTo(w * 0.23, midY - 6, w * 0.26, midY - 6, w * 0.29, midY);
    path.lineTo(w * 0.36, midY);
    // Q wave
    path.lineTo(w * 0.40, midY + 5);
    // R wave
    path.lineTo(w * 0.46, h * 0.10);
    // S wave
    path.lineTo(w * 0.52, h * 0.90);
    path.lineTo(w * 0.56, midY);
    // ST segment
    path.lineTo(w * 0.64, midY);
    // T wave
    path.cubicTo(w * 0.69, midY - 9, w * 0.74, midY - 9, w * 0.79, midY);
    // Trailing baseline
    path.lineTo(w, midY);

    canvas.drawPath(path, linePaint);

    // Glowing pulse traversing along the line
    final dotX = (pulseProgress * w).clamp(0.0, w);
    final dotPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    canvas.drawCircle(Offset(dotX, midY), 3.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ScreenEcgPainter oldDelegate) => true;
}

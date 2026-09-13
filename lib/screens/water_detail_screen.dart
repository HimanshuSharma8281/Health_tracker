import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/notification_widget.dart';
import '../widgets/glass_container.dart';

class WaterDetailScreen extends StatefulWidget {
  const WaterDetailScreen({super.key});

  @override
  State<WaterDetailScreen> createState() => _WaterDetailScreenState();
}

class _WaterDetailScreenState extends State<WaterDetailScreen>
    with SingleTickerProviderStateMixin {
  final List<int> quickAddAmounts = [100, 250, 500, 750, 1000];
  int selectedAmount = 250;
  final TextEditingController customAmountController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  String selectedFilter = 'Weekly'; // 'Weekly' or 'Monthly'

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    customAmountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addWater(HealthDataController data, int amount) {
    data.addWater(amount);
    _animationController.forward(from: 0);
    CustomNotification.show(
      context,
      message: 'Added $amount ml to your water intake',
      type: NotificationType.success,
      title: 'Water Added',
    );
  }

  void _removeWater(HealthDataController data, WaterIntakeReading entry) {
    data.removeWaterIntake(entry);
    CustomNotification.show(
      context,
      message: 'Removed ${entry.amount} ml from your water intake',
      type: NotificationType.info,
      title: 'Water Removed',
    );
  }

  void _showCustomAmountDialog(HealthDataController data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          blur: 24,
          padding: EdgeInsets.zero,
          color: const Color(0xE6141A20),
          border: Border.all(color: const Color(0x402EC4B6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2EC4B6), Color(0xFF1A8F8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Intake',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Log specific water amount',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
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
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: customAmountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Water Amount',
                        labelStyle: GoogleFonts.inter(color: const Color(0xFF48E5C2)),
                        hintText: 'e.g. 350',
                        hintStyle: GoogleFonts.inter(color: Colors.white30),
                        suffixText: 'ml',
                        suffixStyle: GoogleFonts.inter(
                          color: const Color(0xFF48E5C2),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF48E5C2), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [300, 500, 750].map((amt) {
                        return InkWell(
                          onTap: () {
                            customAmountController.text = amt.toString();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x3348E5C2)),
                            ),
                            child: Text(
                              '$amt ml',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF48E5C2),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              customAmountController.clear();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF48E5C2), Color(0xFF2EC4B6)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                final amount = int.tryParse(customAmountController.text);
                                if (amount != null && amount > 0 && amount <= 5000) {
                                  _addWater(data, amount);
                                  customAmountController.clear();
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: const Color(0xFF090D10),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                'Log Water',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D10),
      body: Container(
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
        child: SafeArea(
          child: Consumer<HealthDataController>(
            builder: (context, data, _) {
              final progress = data.waterGoal > 0 ? (data.waterMl / data.waterGoal).clamp(0.0, 1.0) : 0.0;
              final remaining = data.waterGoal - data.waterMl;
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
                        'Hydration Tracker',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showCustomAmountDialog(data),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x3348E5C2)),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Color(0xFF48E5C2),
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
                    border: Border.all(color: const Color(0x3348E5C2), width: 1.2),
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
                                        color: Color(0xFF48E5C2),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'TODAY\'S INTAKE',
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
                                      '${data.waterMl}',
                                      style: GoogleFonts.inter(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '/ ${data.waterGoal} ml',
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
                            // Water Droplet Badge with Scale Animation
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF48E5C2), Color(0xFF2EC4B6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF48E5C2).withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.water_drop_rounded,
                                  size: 34,
                                  color: Color(0xFF090D10),
                                ),
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
                                      colors: [Color(0xFF2EC4B6), Color(0xFF48E5C2)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF48E5C2).withValues(alpha: 0.4),
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

                        // Status Note
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '$percentage% of daily goal reached',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF48E5C2),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              remaining <= 0 ? 'Goal Met! 🎉' : '$remaining ml remaining',
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

                  // 3. QUICK ADD SECTION
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2EC4B6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LOG WATER INTAKE',
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
                      ...quickAddAmounts.map((amt) {
                        return InkWell(
                          onTap: () => _addWater(data, amt),
                          borderRadius: BorderRadius.circular(16),
                          child: GlassContainer(
                            blur: 12,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: const Color(0xE6141A20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_rounded, color: Color(0xFF48E5C2), size: 18),
                                const SizedBox(height: 4),
                                Text(
                                  '$amt ml',
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
                      // Custom Entry Tile
                      InkWell(
                        onTap: () => _showCustomAmountDialog(data),
                        borderRadius: BorderRadius.circular(16),
                        child: GlassContainer(
                          blur: 12,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: const Color(0x3348E5C2),
                          border: Border.all(color: const Color(0x6648E5C2)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.tune_rounded, color: Color(0xFF48E5C2), size: 18),
                              const SizedBox(height: 4),
                              Text(
                                'Custom',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF48E5C2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 4. ANALYTICS & TRENDS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                            'HYDRATION TRENDS',
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
                                  color: isSel ? const Color(0xFF48E5C2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  f,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? const Color(0xFF090D10) : Colors.white60,
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

                  // Trend Chart
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

                  // 5. TODAY'S LOGGED ENTRIES
                  if (data.getTodayWaterIntake().isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2EC4B6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TODAY\'S LOGS',
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
                          '${data.getTodayWaterIntake().length} events',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...data.getTodayWaterIntake().reversed.map((entry) {
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
                                  color: const Color(0x2048E5C2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.water_drop_rounded, color: Color(0xFF48E5C2), size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.amount} ml',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(entry.timestamp),
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeWater(data, entry),
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // 6. CLINICAL HYDRATION TIPS
                  GlassContainer(
                    blur: 14,
                    padding: const EdgeInsets.all(20),
                    color: const Color(0xE6141A20),
                    border: Border.all(color: const Color(0x2248E5C2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF48E5C2), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Clinical Hydration Insights',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTipItem('💧 Drink 500 ml upon waking to counteract overnight dehydration.'),
                        _buildTipItem('⚡ Electrolyte balance peaks when fluid intake is spread evenly across your day.'),
                        _buildTipItem('🏃 Increase intake by 350-500 ml for every 30 minutes of aerobic activity.'),
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
    final Map<int, int> waterByDay = {};
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      waterByDay[i] = data.getWaterForDay(day);
    }

    final maxVal = (data.waterGoal * 1.2).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal > 0 ? maxVal : 3000,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()} ml',
                GoogleFonts.inter(
                  color: const Color(0xFF090D10),
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
              reservedSize: 34,
              getTitlesWidget: (val, _) {
                return Text(
                  '${(val / 1000).toStringAsFixed(1)}L',
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
          horizontalInterval: 1000,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.04),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (idx) {
          final amt = waterByDay[idx] ?? 0;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: amt.toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2EC4B6), Color(0xFF48E5C2)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal,
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
    final Map<int, int> waterByWeek = {0: 0, 1: 0, 2: 0, 3: 0};

    for (int i = 0; i < 28; i++) {
      final day = now.subtract(Duration(days: i));
      final water = data.getWaterForDay(day);
      final weekIndex = 3 - (i ~/ 7);
      if (weekIndex >= 0 && weekIndex < 4) {
        waterByWeek[weekIndex] = (waterByWeek[weekIndex] ?? 0) + water;
      }
    }

    final maxVal = (data.waterGoal * 7 * 1.2).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal > 0 ? maxVal : 20000,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${(rod.toY / 1000).toStringAsFixed(1)} L',
                GoogleFonts.inter(
                  color: const Color(0xFF090D10),
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
              reservedSize: 34,
              getTitlesWidget: (val, _) {
                return Text(
                  '${(val / 1000).round()}L',
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
          horizontalInterval: 5000,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.04),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(4, (idx) {
          final amt = waterByWeek[idx] ?? 0;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: amt.toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2EC4B6), Color(0xFF48E5C2)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

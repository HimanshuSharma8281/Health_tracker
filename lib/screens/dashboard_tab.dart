import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/common_widgets.dart';
import '../screens/calorie_detail_screen.dart';
import '../screens/water_detail_screen.dart';
import '../screens/sleep_detail_screen.dart';
import '../screens/blood_pressure_screen.dart';
import '../screens/blood_sugar_screen.dart';
import '../screens/step_detail_screen.dart';
import '../widgets/notification_widget.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  void _showGoalSettingsDialog(BuildContext context) {
    final data = context.read<HealthDataController>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints:
              const BoxConstraints(maxHeight: 600), // Add max height constraint
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
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
                      child:
                          const Icon(Icons.flag, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Set Your Goals',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Steps Goal
                      _buildGoalInput(
                        context: context,
                        label: 'Daily Steps',
                        currentValue: data.stepGoal,
                        icon: Icons.directions_walk,
                        color: const Color(0xFF3A86FF),
                        suffix: 'steps',
                        onChanged: (value) {
                          if (value != null && value > 0) {
                            data.updateStepGoal(value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Calories Goal
                      _buildGoalInput(
                        context: context,
                        label: 'Daily Calories',
                        currentValue: data.calorieGoal.toInt(),
                        icon: Icons.local_fire_department,
                        color: const Color(0xFFFF006E),
                        suffix: 'kcal',
                        onChanged: (value) {
                          if (value != null && value > 0) {
                            data.updateCalorieGoal(value.toDouble());
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Water Goal
                      _buildGoalInput(
                        context: context,
                        label: 'Daily Water',
                        currentValue: data.waterGoal,
                        icon: Icons.water_drop,
                        color: const Color(0xFF2EC4B6),
                        suffix: 'ml',
                        onChanged: (value) {
                          if (value != null && value > 0) {
                            data.updateWaterGoal(value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sleep Goal
                      _buildSleepGoalInput(
                        context: context,
                        label: 'Daily Sleep',
                        currentValue: data.sleepGoal,
                        icon: Icons.nightlight_round,
                        color: const Color(0xFFFFBE0B),
                        onChanged: (value) {
                          if (value != null && value > 0) {
                            data.updateSleepGoal(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Fixed Save Button at Bottom
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A86FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Goals',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalInput({
    required BuildContext context,
    required String label,
    required int currentValue,
    required IconData icon,
    required Color color,
    required String suffix,
    required Function(int?) onChanged,
  }) {
    final controller = TextEditingController(text: currentValue.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (value) => onChanged(int.tryParse(value)),
          decoration: InputDecoration(
            suffixText: suffix,
            filled: true,
            fillColor: color.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepGoalInput({
    required BuildContext context,
    required String label,
    required double currentValue,
    required IconData icon,
    required Color color,
    required Function(double?) onChanged,
  }) {
    final controller =
        TextEditingController(text: currentValue.toStringAsFixed(1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => onChanged(double.tryParse(value)),
          decoration: InputDecoration(
            suffixText: 'hours',
            filled: true,
            fillColor: color.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthDataController>(
      builder: (context, data, _) {
        final insights = data.topInsights;
        final formatter = NumberFormat.compact();
        return ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            HeroSection(data: data),
            const SizedBox(height: 16),

            // Add Settings Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3A86FF).withOpacity(0.1),
                    const Color(0xFF8338EC).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF3A86FF).withOpacity(0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showGoalSettingsDialog(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.flag,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customize Your Goals',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3A86FF),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Set personalized daily targets',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF3A86FF),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (insights.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF3A86FF), Color(0xFF8338EC)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Wellness Insights',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      for (final insight in insights)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.auto_awesome,
                                    color: Colors.white70, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(insight,
                                        style: GoogleFonts.inter(
                                            color: Colors.white
                                                .withOpacity(0.85)))),
                              ]),
                        ),
                    ]),
              ),
            const SizedBox(height: 20),
            _MetricGridWithNavigation(data: data, formatter: formatter),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.1,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BloodSugarScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x11000000),
                              blurRadius: 20,
                              offset: Offset(0, 12))
                        ]),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFF6B6B).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.bloodtype,
                                  color: Color(0xFFFF6B6B))),
                          const Spacer(),
                          Text('Blood Sugar',
                              style: GoogleFonts.inter(color: Colors.black54)),
                          const SizedBox(height: 15),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                  data.bloodSugar == 0
                                      ? '--'
                                      : '${data.bloodSugar.round()}',
                                  style: GoogleFonts.inter(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Text('mg/dL',
                                  style: GoogleFonts.inter(
                                      fontSize: 14, color: Colors.black45)),
                            ],
                          ),
                        ]),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BloodPressureScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x11000000),
                              blurRadius: 20,
                              offset: Offset(0, 12))
                        ]),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF8338EC).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.monitor_heart,
                                  color: Color(0xFF8338EC))),
                          const Spacer(),
                          Text('Blood Pressure',
                              style: GoogleFonts.inter(color: Colors.black54)),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                  data.systolic == 0 && data.diastolic == 0
                                      ? '--/--'
                                      : '${data.systolic}/${data.diastolic}',
                                  style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 1),
                              Text('mmHg',
                                  style: GoogleFonts.inter(
                                      fontSize: 10, color: Colors.black45)),
                            ],
                          ),
                        ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ActivitySummary(data: data),
          ],
        );
      },
    );
  }
}

class _MetricGridWithNavigation extends StatelessWidget {
  const _MetricGridWithNavigation(
      {required this.data, required this.formatter});

  final HealthDataController data;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    // Calculate step delta safely
    final stepDelta = data.history.length >= 2
        ? data.stepsToday - data.history[data.history.length - 2].steps
        : data.stepsToday;

    final cards = [
      MetricCard(
          title: 'Steps',
          value: formatter.format(data.stepsToday),
          delta: '${formatter.format(data.stepGoal)} goal',
          icon: Icons.directions_walk,
          color: const Color(0xFF3A86FF),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StepDetailScreen(),
              ),
            );
          }),
      MetricCard(
          title: 'Calories',
          value: '${data.caloriesConsumed.round()}',
          delta: '${data.calorieGoal.round()} goal',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF006E),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CalorieDetailScreen(),
              ),
            );
          }),
      MetricCard(
          title: 'Water',
          value: '${data.waterMl} ml',
          delta: '${data.waterGoal} ml goal',
          icon: Icons.water_drop_rounded,
          color: const Color(0xFF2EC4B6),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WaterDetailScreen(),
              ),
            );
          }),
      MetricCard(
          title: 'Sleep',
          value: '${data.sleepHours.toStringAsFixed(1)} h',
          delta: '${data.sleepGoal.toStringAsFixed(1)}h goal',
          icon: Icons.nightlight_round,
          color: const Color(0xFFFFBE0B),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SleepDetailScreen(),
              ),
            );
          }),
    ];
    return GridView.builder(
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.1),
      itemBuilder: (context, index) => cards[index],
    );
  }
}

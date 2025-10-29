import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/common_widgets.dart';
import '../screens/calorie_detail_screen.dart';
import '../widgets/notification_widget.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthDataController>(
      builder: (context, data, _) {
        final insights = data.topInsights;
        final formatter = NumberFormat.compact();
        return RefreshIndicator(
          onRefresh: () async {
            await data.refreshDailyMetrics();
            if (context.mounted) {
              CustomNotification.show(
                context,
                message: 'Your health data has been updated',
                type: NotificationType.success,
                title: 'Refreshed',
              );
            }
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            children: [
              HeroSection(data: data),
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
                  Container(
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
                                      const Color(0xFFFF006E).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.favorite,
                                  color: Color(0xFFFF006E))),
                          const Spacer(),
                          Text('Heart Rate',
                              style: GoogleFonts.inter(color: Colors.black54)),
                          const SizedBox(height: 15),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('${data.heartRate.round()}',
                                  style: GoogleFonts.inter(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Text('bpm',
                                  style: GoogleFonts.inter(
                                      fontSize: 14, color: Colors.black45)),
                            ],
                          ),
                        ]),
                  ),
                  Container(
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
                              Text('120/80',
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
                ],
              ),
              const SizedBox(height: 20),
              ActivitySummary(data: data),
            ],
          ),
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
    final cards = [
      MetricCard(
          title: 'Steps',
          value: formatter.format(data.stepsToday),
          delta:
              '+${(data.stepsToday - data.history[data.history.length - 2].steps)} today',
          icon: Icons.directions_walk,
          color: const Color(0xFF3A86FF)),
      MetricCard(
          title: 'Calories',
          value: '${data.caloriesConsumed}',
          delta: '${data.caloriesConsumed - data.calorieGoal} vs goal',
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
          delta: '${(data.waterMl / data.waterGoal * 100).round()}% goal',
          icon: Icons.water_drop_rounded,
          color: const Color(0xFF2EC4B6)),
      MetricCard(
          title: 'Sleep',
          value: '${data.sleepHours.toStringAsFixed(1)} h',
          delta:
              '${(data.sleepHours - data.sleepGoal).toStringAsFixed(1)} vs goal',
          icon: Icons.nightlight_round,
          color: const Color(0xFFFFBE0B)),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/health_data_controller.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.data});

  final HealthDataController data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFBDE0FE), Color(0xFFC8E7FF)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today\'s Snapshot',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                'Steps ${data.stepsToday} • Hydration ${data.waterMl} ml • Sleep ${data.sleepHours.toStringAsFixed(1)} h',
                style: GoogleFonts.inter(color: Colors.black54)),
            const SizedBox(height: 12),
          ]),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.favorite_rounded, size: 52, color: Color(0xFF3A86FF)),
      ]),
    );
  }
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.data, required this.formatter});

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
          color: const Color(0xFFFF006E)),
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

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color)),
          const Spacer(),
          Text(title,
              style: GoogleFonts.inter(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(delta,
              style: GoogleFonts.inter(color: Colors.black45, fontSize: 10)),
        ]),
      ),
    );
  }
}

class AnalyticsCard extends StatelessWidget {
  const AnalyticsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x11000000), blurRadius: 20, offset: Offset(0, 14))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style:
                GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.inter(color: Colors.black45)),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class ActivitySummary extends StatelessWidget {
  const ActivitySummary({super.key, required this.data});

  final HealthDataController data;

  @override
  Widget build(BuildContext context) {
    final entries = data.history.reversed.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x11000000), blurRadius: 20, offset: Offset(0, 12))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Weekly Highlights',
            style:
                GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFFE0F2FF)),
                  child: Center(
                      child: Text(DateFormat.E().format(entry.date),
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${entry.steps} steps • ${entry.calories} kcal',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        Text(
                            'Sleep ${entry.sleepHours} h • Hydration ${entry.waterMl} ml • Mindfulness ${entry.mindfulnessMinutes} min',
                            style: GoogleFonts.inter(color: Colors.black45)),
                      ]),
                ),
              ]),
            )),
      ]),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x11000000), blurRadius: 20, offset: Offset(0, 12))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title,
              style:
                  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class GoalChip extends StatelessWidget {
  const GoalChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: Colors.black54)),
      ]),
    );
  }
}

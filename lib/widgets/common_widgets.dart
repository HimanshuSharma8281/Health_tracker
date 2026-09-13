import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/health_data_controller.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.data});

  final HealthDataController data;

  Color _scoreColor(int score) {
    if (score >= 90) return const Color(0xFF10B981);
    if (score >= 75) return const Color(0xFF3A86FF);
    if (score >= 60) return const Color(0xFFF59E0B);
    if (score >= 40) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final todayScore = data.todayScore;
    final hasScore = todayScore != null && todayScore.availableMetricCount > 0;
    final scoreVal = todayScore?.overall ?? 0;
    final accentColor = hasScore ? _scoreColor(scoreVal) : const Color(0xFF3A86FF);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Score Radial/Circle Badge
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.15),
                      accentColor.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: accentColor, width: 2.5),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasScore ? '$scoreVal' : '—',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        '/100',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: accentColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Daily Health Score',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            hasScore ? todayScore.label : 'Calculating',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasScore
                          ? 'Deterministic clinical score from ${todayScore.availableMetricCount} active metrics'
                          : 'Log water, sleep, steps, or vitals to generate your clinical score',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasScore) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Per-metric breakdown chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: todayScore.metrics.entries.map((entry) {
                  final metric = entry.value;
                  final available = metric.available;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: available
                          ? const Color(0xFFF7F7FB)
                          : Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: available
                            ? Colors.black12
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _metricIcon(entry.key),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _metricLabel(entry.key),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: available
                                ? Colors.black87
                                : Colors.black38,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          available ? '${(metric.score * 10).round()}%' : '—',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: available
                                ? _metricScoreColor(metric.score)
                                : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _metricIcon(String key) {
    switch (key) {
      case 'water':
        return '💧';
      case 'sleep':
        return '😴';
      case 'activity':
      case 'steps':
        return '👟';
      case 'calories':
        return '🔥';
      case 'heart_rate':
        return '❤️';
      case 'blood_pressure':
        return '🩺';
      default:
        return '📊';
    }
  }

  static String _metricLabel(String key) {
    switch (key) {
      case 'water':
        return 'Water';
      case 'sleep':
        return 'Sleep';
      case 'activity':
      case 'steps':
        return 'Steps';
      case 'calories':
        return 'Calories';
      case 'heart_rate':
        return 'Heart Rate';
      case 'blood_pressure':
        return 'BP';
      default:
        return key;
    }
  }

  static Color _metricScoreColor(int score) {
    if (score >= 8) return const Color(0xFF10B981);
    if (score >= 6) return const Color(0xFF3A86FF);
    if (score >= 4) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
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
  final String title;
  final Widget child;
  final Widget? trailing;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
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
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
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

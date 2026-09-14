import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Data model representing a single metric card's circular ring.
class MetricRingData {
  final String key;
  final String label;
  final double progress; // 0.0 to 1.0
  final int score;       // 0 to 10
  final Color color;
  final bool isTracked;

  const MetricRingData({
    required this.key,
    required this.label,
    required this.progress,
    required this.score,
    required this.color,
    required this.isTracked,
  });
}

/// Dynamic animated circular score gauge with up to 6 concentric rings
/// tracking each active dashboard metric card.
///
/// Rings dynamically expand from 1 to 6 as each card is tracked.
class CircularScoreGauge extends StatefulWidget {
  final int? score;
  final String label;
  final int activeMetricsCount;
  final double size;
  final List<MetricRingData>? rings;
  final double? activityProgress;
  final double? sleepProgress;
  final bool showLegend;

  const CircularScoreGauge({
    super.key,
    required this.score,
    required this.label,
    required this.activeMetricsCount,
    this.size = 220,
    this.rings,
    this.activityProgress,
    this.sleepProgress,
    this.showLegend = true,
  });

  @override
  State<CircularScoreGauge> createState() => _CircularScoreGaugeState();
}

class _CircularScoreGaugeState extends State<CircularScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CircularScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score ||
        oldWidget.activeMetricsCount != widget.activeMetricsCount ||
        oldWidget.rings?.length != widget.rings?.length ||
        oldWidget.activityProgress != widget.activityProgress ||
        oldWidget.sleepProgress != widget.sleepProgress) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return const Color(0xFF48E5C2); // Mint Teal
    if (score >= 70) return const Color(0xFF5CE1E6); // Cyan
    if (score >= 55) return const Color(0xFFFFD166); // Amber Gold
    return const Color(0xFFFF6B6B); // Coral / Red
  }

  List<MetricRingData> _resolveRings(bool hasScore, int displayScore) {
    if (widget.rings != null) {
      return widget.rings!.where((r) => r.isTracked).toList();
    }

    // Fallback for callers that don't supply the full ring list (e.g. legacy tests)
    final targetOverall = (displayScore / 100.0).clamp(0.0, 1.0);
    final targetActivity = (widget.activityProgress ?? (hasScore ? targetOverall * 0.88 : 0.0)).clamp(0.0, 1.0);
    final targetSleep = (widget.sleepProgress ?? (hasScore ? targetOverall * 0.92 : 0.0)).clamp(0.0, 1.0);

    return [
      MetricRingData(
        key: 'overall',
        label: 'Overall $displayScore',
        progress: targetOverall,
        score: (displayScore / 10).round(),
        color: const Color(0xFF48E5C2),
        isTracked: hasScore,
      ),
      if (widget.activityProgress != null || hasScore)
        MetricRingData(
          key: 'activity',
          label: 'Activity ${(targetActivity * 100).round()}%',
          progress: targetActivity,
          score: (targetActivity * 10).round(),
          color: const Color(0xFFFFAA4C),
          isTracked: true,
        ),
      if (widget.sleepProgress != null || hasScore)
        MetricRingData(
          key: 'sleep',
          label: 'Sleep ${(targetSleep * 100).round()}%',
          progress: targetSleep,
          score: (targetSleep * 10).round(),
          color: const Color(0xFF9B86EC),
          isTracked: true,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hasScore = widget.score != null && widget.activeMetricsCount > 0;
    final displayScore = widget.score ?? 0;
    final scoreColor = _getScoreColor(displayScore);

    final activeRings = _resolveRings(hasScore, displayScore);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          'YOUR WELLNESS SCORE',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),

        // Concentric Dynamic Rings Container
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Custom Dynamic Multi-Ring Painter
              AnimatedBuilder(
                animation: _curve,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _DynamicConcentricScorePainter(
                      rings: activeRings,
                      animationValue: _curve.value,
                      hasScore: hasScore,
                    ),
                  );
                },
              ),

              // Center Text: ONLY Score and Suggestion / Status
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _curve,
                    builder: (context, _) {
                      final animatedVal = (displayScore * _curve.value).round();
                      return Text(
                        hasScore ? '$animatedVal' : '—',
                        style: GoogleFonts.inter(
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasScore ? widget.label : 'Unscored',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasScore ? scoreColor : Colors.white60,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Number of tracked cards: Outside and below all circles
        Text(
          hasScore
              ? '${activeRings.length} of 7 tracked'
              : 'No metrics tracked',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.3,
          ),
        ),

        const SizedBox(height: 12),

        // Dynamic Legend Row matching the tracked metric cards
        if (widget.showLegend) ...[
          if (hasScore && activeRings.isNotEmpty) ...[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: activeRings.map((ring) {
                final displayVal = ring.label.contains('%') || ring.label.contains(' ')
                    ? ring.label
                    : '${ring.label} ${(ring.progress * 100).round()}%';
                return _buildLegendBadge(
                  color: ring.color,
                  label: displayVal,
                );
              }).toList(),
            ),
          ] else ...[
            Text(
              'Log readings to calculate',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLegendBadge({required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 3,
                  spreadRadius: 0.8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for dynamic concentric health score rings (1 to 6 rings).
class _DynamicConcentricScorePainter extends CustomPainter {
  final List<MetricRingData> rings;
  final double animationValue;
  final bool hasScore;

  _DynamicConcentricScorePainter({
    required this.rings,
    required this.animationValue,
    required this.hasScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const startAngle = -math.pi / 2; // 12 o'clock

    final int n = rings.isEmpty ? 1 : rings.length;
    final maxRadius = (size.width / 2) - 10;

    // Adaptively scale stroke width and spacing based on ring count
    final double strokeWidth;
    final double ringSpacing;

    if (n <= 2) {
      strokeWidth = 8.5;
      ringSpacing = 14.0;
    } else if (n == 3) {
      strokeWidth = 7.5;
      ringSpacing = 12.5;
    } else if (n == 4) {
      strokeWidth = 6.5;
      ringSpacing = 10.5;
    } else if (n == 5) {
      strokeWidth = 5.5;
      ringSpacing = 9.0;
    } else if (n == 6) {
      strokeWidth = 4.8;
      ringSpacing = 8.0;
    } else {
      strokeWidth = 4.2;
      ringSpacing = 7.0;
    }

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (rings.isEmpty || !hasScore) {
      // Draw single inactive track
      canvas.drawCircle(center, maxRadius, trackPaint);
      return;
    }

    // 1. Draw background tracks for all active rings
    for (int i = 0; i < n; i++) {
      final radius = maxRadius - (i * ringSpacing);
      canvas.drawCircle(center, radius, trackPaint);
    }

    // 2. Draw animated active arcs for each tracked card
    for (int i = 0; i < n; i++) {
      final ring = rings[i];
      final radius = maxRadius - (i * ringSpacing);
      final currentProgress = (ring.progress * animationValue).clamp(0.0, 1.0);

      if (currentProgress <= 0.0) continue;

      final sweepAngle = 2 * math.pi * currentProgress;

      // Ambient glow
      final glowPaint = Paint()
        ..color = ring.color.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 3.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );

      // Active sharp stroke
      final activePaint = Paint()
        ..color = ring.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicConcentricScorePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.rings != rings ||
        oldDelegate.hasScore != hasScore;
  }
}

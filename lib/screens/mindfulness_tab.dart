import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/common_widgets.dart';

class MindfulnessTab extends StatelessWidget {
  const MindfulnessTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthDataController>(
      builder: (context, data, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            SectionCard(
              title: 'Heart Rate & Stress',
              trailing: Text('${data.heartRate.round()} bpm',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Slider(
                      value: data.heartRate,
                      min: 55,
                      max: 110,
                      onChanged: data.updateHeartRate,
                      activeColor: const Color(0xFF3A86FF),
                    ),
                    const SizedBox(height: 12),
                    Text('Stress level ${(data.stressLevel * 100).round()}%',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: LinearProgressIndicator(
                        value: data.stressLevel.clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFFFE5EC),
                        valueColor: AlwaysStoppedAnimation(
                            data.stressLevel > 0.6
                                ? const Color(0xFFFF006E)
                                : const Color(0xFF2EC4B6)),
                        minHeight: 14,
                      ),
                    ),
                  ]),
            ),
            const SizedBox(height: 18),
            SectionCard(
              title: 'Smart Sleep Suggestion',
              trailing: Text(data.bedtimeSuggestion,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8338EC))),
              child: Text(
                  'Based on current fatigue markers and stress balance, unwind with breathing practice at least 45 minutes before the suggested time.',
                  style: GoogleFonts.inter(color: Colors.black54)),
            ),
            const SizedBox(height: 18),
            SectionCard(
              title: 'Guided Sessions',
              trailing: Text('Today ${data.mindfulnessMinutes} min',
                  style: GoogleFonts.inter(color: Colors.black54)),
              child: Column(
                children: data.sessions.map((session) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFE0BBE4)),
                      child: const Icon(Icons.self_improvement,
                          color: Color(0xFF8338EC)),
                    ),
                    title: Text(session.title,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${session.duration} min • Focus: ${session.focus}',
                        style: GoogleFonts.inter(color: Colors.black54)),
                    trailing: ElevatedButton(
                      onPressed: () {
                        data.completeMindfulnessSession(session);
                      },
                      child: const Text('Start'),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              title: 'Breathing Coach',
              child: Row(
                children: [
                  const Icon(Icons.air_rounded,
                      color: Color(0xFF3A86FF), size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'Try the 4-7-8 technique for deep relaxation and stress relief. Hold and release following the guided animation.',
                          style: GoogleFonts.inter(color: Colors.black54))),
                  FilledButton(
                    onPressed: () {
                      data.adjustStress(-0.05);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Relaxation boost applied. Keep breathing mindfully.')));
                    },
                    child: const Text('Begin'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

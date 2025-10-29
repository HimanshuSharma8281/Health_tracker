import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:characters/characters.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/common_widgets.dart';

class SocialTab extends StatelessWidget {
  const SocialTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthDataController>(
      builder: (context, data, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            SectionCard(
              title: 'Leaderboard',
              trailing: Text('Points this week',
                  style: GoogleFonts.inter(color: Colors.black54)),
              child: Column(
                children: data.leaderboardSorted.map((entry) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFBEE1FF),
                        child: Text(entry.name.characters.first,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold))),
                    title: Text(entry.name,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    subtitle: Text('${entry.streak} day streak',
                        style: GoogleFonts.inter(color: Colors.black54)),
                    trailing: Text('${entry.score} pts',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              title: 'Social Challenges',
              child: Column(
                children: data.challenges.map((challenge) {
                  final ratio =
                      (challenge.progress / challenge.target).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(challenge.title,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700)),
                              Text('${challenge.progress}/${challenge.target}',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 14,
                              backgroundColor: const Color(0xFFE5E5F5),
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFFFF006E)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                              spacing: 8,
                              children: challenge.members
                                  .map((member) => Chip(label: Text(member)))
                                  .toList()),
                        ]),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

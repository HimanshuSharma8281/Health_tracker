import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/health_data_controller.dart';
import '../services/social_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/notification_widget.dart';

class SocialTab extends StatefulWidget {
  const SocialTab({super.key});

  @override
  State<SocialTab> createState() => _SocialTabState();
}

class _SocialTabState extends State<SocialTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedMetric = 'steps';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    SocialService.checkAndClearOldChallengesOnce();
  }

  int _getCurrentMetricInitialValue(String metric, HealthDataController data) {
    switch (metric) {
      case 'water':
        return data.waterMl;
      case 'steps':
        return data.stepsToday;
      case 'calories':
        return data.caloriesConsumed.round();
      case 'sleep':
        return data.sleepHours.round();
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLeaveChallengeDialog(
      ChallengeData challenge, HealthDataController data) {
    if (data.userId == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: GlassContainer(
          blur: 24,
          color: const Color(0xF2141A20),
          border: Border.all(
            color: const Color(0xFFFF006E).withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(22),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leave Challenge',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF006E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to leave "${challenge.title}"? Your participation will be removed.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(color: Colors.white60)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await SocialService.leaveChallenge(
                          challengeId: challenge.id,
                          userId: data.userId!,
                        );
                        if (context.mounted) {
                          CustomNotification.show(
                            context,
                            message: 'Left "${challenge.title}"',
                            type: NotificationType.info,
                            title: 'Challenge Left',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          CustomNotification.show(
                            context,
                            message: 'Failed to leave challenge',
                            type: NotificationType.error,
                            title: 'Error',
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF006E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Leave',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateChallengeDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int targetValue = 10000;
    String rankingType = 'highest';
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: GlassContainer(
            blur: 24,
            color: const Color(0xF2141A20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF48E5C2).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF48E5C2).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFF48E5C2),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Challenge',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Set goals and invite friends',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Challenge Title
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Challenge Name',
                      labelStyle: GoogleFonts.inter(color: Colors.white70),
                      hintText: 'e.g., 7-Day Step Challenge',
                      hintStyle: GoogleFonts.inter(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF48E5C2),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextField(
                    controller: descController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: GoogleFonts.inter(color: Colors.white70),
                      hintText: 'e.g., Let\'s stay active together!',
                      hintStyle: GoogleFonts.inter(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF48E5C2),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Metric Type
                  DropdownButtonFormField<String>(
                    value: selectedMetric,
                    dropdownColor: const Color(0xFF1B232C),
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Metric Type',
                      labelStyle: GoogleFonts.inter(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF48E5C2),
                          width: 1.5,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'steps', child: Text('Steps')),
                      DropdownMenuItem(value: 'water', child: Text('Water (ml)')),
                      DropdownMenuItem(value: 'calories', child: Text('Calories')),
                      DropdownMenuItem(value: 'sleep', child: Text('Sleep (hours)')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedMetric = value;
                        if (value == 'sleep') {
                          rankingType = 'closestToTarget';
                        } else {
                          rankingType = 'highest';
                        }
                        targetValue = {
                          'steps': 10000,
                          'water': 2500,
                          'calories': 2000,
                          'sleep': 8,
                        }[value]!;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // Ranking Type
                  DropdownButtonFormField<String>(
                    value: rankingType,
                    dropdownColor: const Color(0xFF1B232C),
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Ranking Rule',
                      labelStyle: GoogleFonts.inter(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF48E5C2),
                          width: 1.5,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'highest',
                        child: Text('Highest (Maximum Achieved)'),
                      ),
                      DropdownMenuItem(
                        value: 'closestToTarget',
                        child: Text('Closest to Target (Consistency)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => rankingType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Target Value
                  TextField(
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Daily Target',
                      labelStyle: GoogleFonts.inter(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF48E5C2),
                          width: 1.5,
                        ),
                      ),
                    ),
                    controller: TextEditingController(text: targetValue.toString()),
                    onChanged: (value) {
                      targetValue = int.tryParse(value) ?? targetValue;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Duration selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${endDate.difference(DateTime.now()).inDays} days left',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF48E5C2),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFF48E5C2),
                                      onPrimary: Color(0xFF090D10),
                                      surface: Color(0xFF141A20),
                                      onSurface: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setDialogState(() => endDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF48E5C2).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: Color(0xFF48E5C2),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final data = context.read<HealthDataController>();
                        if (data.userId == null) {
                          CustomNotification.show(
                            context,
                            message: 'Please sign in to create challenges',
                            type: NotificationType.error,
                            title: 'Error',
                          );
                          return;
                        }

                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          CustomNotification.show(
                            context,
                            message: 'Please enter a challenge name',
                            type: NotificationType.warning,
                            title: 'Name Required',
                          );
                          return;
                        }

                        final challengeId =
                            DateTime.now().millisecondsSinceEpoch.toString();

                        final initialProgress = _getCurrentMetricInitialValue(
                          selectedMetric,
                          data,
                        );

                        try {
                          await SocialService.createChallenge(
                            challengeId: challengeId,
                            title: title,
                            description: descController.text.trim(),
                            creatorId: data.userId!,
                            creatorName: data.username ?? 'User',
                            targetValue: targetValue,
                            metricType: selectedMetric,
                            rankingType: rankingType,
                            startDate: DateTime.now(),
                            endDate: endDate,
                            initialProgress: initialProgress,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            CustomNotification.show(
                              context,
                              message: 'Challenge created successfully!',
                              type: NotificationType.success,
                              title: 'Success',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            CustomNotification.show(
                              context,
                              message: 'Failed to create challenge',
                              type: NotificationType.error,
                              title: 'Error',
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF48E5C2),
                        foregroundColor: const Color(0xFF090D10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Create Challenge',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showJoinChallengeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: GlassContainer(
          blur: 24,
          color: const Color(0xF2141A20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A86FF).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF3A86FF).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.group_add_rounded,
                        color: Color(0xFF3A86FF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join Challenge',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Compete with the community',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // All available challenges
                Expanded(
                  child: StreamBuilder<List<ChallengeData>>(
                    stream: SocialService.getAllActiveChallenges(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF48E5C2),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No challenges available',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final data = context.read<HealthDataController>();
                      final challenges = snapshot.data!
                          .where((c) => !c.participants.contains(data.userId))
                          .toList();

                      if (challenges.isEmpty) {
                        return Center(
                          child: Text(
                            'You\'re in all available challenges!',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: challenges.length,
                        itemBuilder: (context, index) {
                          final challenge = challenges[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        challenge.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'By ${challenge.creatorName} • ${challenge.participants.length} players',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${challenge.targetValue} ${_getMetricUnit(challenge.metricType)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF48E5C2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    final initProg =
                                        _getCurrentMetricInitialValue(
                                      challenge.metricType,
                                      data,
                                    );
                                    try {
                                      await SocialService.joinChallenge(
                                        challengeId: challenge.id,
                                        userId: data.userId!,
                                        username: data.username ?? 'User',
                                        initialProgress: initProg,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        CustomNotification.show(
                                          context,
                                          message:
                                              'Joined ${challenge.title}!',
                                          type: NotificationType.success,
                                          title: 'Success',
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        CustomNotification.show(
                                          context,
                                          message: 'Failed to join challenge',
                                          type: NotificationType.error,
                                          title: 'Error',
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF48E5C2),
                                    foregroundColor: const Color(0xFF090D10),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Join',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChallengeLeaderboard(
      ChallengeData challenge, HealthDataController data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: GlassContainer(
          blur: 24,
          color: const Color(0xF2141A20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 580, maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFBE0B).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFBE0B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.leaderboard_rounded,
                        color: Color(0xFFFFBE0B),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leaderboard',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            challenge.title,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Target: ${challenge.targetValue} ${_getMetricUnit(challenge.metricType)} • ${challenge.rankingType == 'closestToTarget' ? 'Closest to Target' : 'Highest Value'}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF48E5C2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // User standing summary if user is in challenge
                if (data.userId != null &&
                    challenge.participants.contains(data.userId))
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF48E5C2).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF48E5C2).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Standing',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF48E5C2),
                          ),
                        ),
                        Text(
                          'Rank #${challenge.getRank(data.userId!)} of ${challenge.participants.length}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Leaderboard list
                Expanded(
                  child: ListView.builder(
                    itemCount: challenge.participants.length,
                    itemBuilder: (context, index) {
                      final sortedParticipants = challenge
                          .getTopParticipants(challenge.participants.length);
                      final participant = sortedParticipants[index];
                      final rank = participant['rank'] as int? ?? (index + 1);
                      final isCurrentUser = participant['userId'] == data.userId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? const Color(0xFF48E5C2).withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrentUser
                                ? const Color(0xFF48E5C2).withValues(alpha: 0.4)
                                : _getRankColor(rank).withValues(alpha: 0.25),
                            width: isCurrentUser ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rank badge
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _getRankColor(rank).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _getRankColor(rank).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Center(
                                child: rank <= 3
                                    ? Text(
                                        _getRankEmoji(rank),
                                        style: const TextStyle(fontSize: 18),
                                      )
                                    : Text(
                                        '$rank',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: _getRankColor(rank),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          participant['name'] ?? 'Unknown',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isCurrentUser) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF48E5C2)
                                                .withValues(alpha: 0.25),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'You',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF48E5C2),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${((participant['progress'] as int) / challenge.targetValue * 100).toStringAsFixed(0)}% complete',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Progress
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${participant['progress']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF48E5C2),
                                  ),
                                ),
                                Text(
                                  _getMetricUnit(challenge.metricType),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataController>();

    return Scaffold(
      backgroundColor: const Color(0xFF090D10),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.2,
            colors: [
              Color(0xFF0D2420),
              Color(0xFF090D10),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Sleek Integrated Dashboard-Themed Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF141A20),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF48E5C2).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: Color(0xFF48E5C2),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Challenges',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Compete with friends & community',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (data.userId != null)
                          // Create challenge button
                          InkWell(
                            onTap: _showCreateChallengeDialog,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF48E5C2),
                                    Color(0xFF3A86FF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Color(0xFF090D10),
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // User Score / Stats Card - Only Active and Completed
                    if (data.userId != null)
                      StreamBuilder<List<ChallengeData>>(
                        stream: SocialService.getUserChallenges(data.userId!),
                        builder: (context, snapshot) {
                          final userChallenges = snapshot.data ?? [];
                          final counts = SocialService.calculateUserChallengeCounts(
                            challenges: userChallenges,
                            userId: data.userId!,
                          );

                          return GlassContainer(
                            blur: 16,
                            color: const Color(0xE6141A20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            borderRadius: BorderRadius.circular(18),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildScoreStat(
                                    'Active',
                                    '${counts.active}',
                                    Icons.emoji_events_rounded,
                                    const Color(0xFF48E5C2),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                Expanded(
                                  child: _buildScoreStat(
                                    'Completed',
                                    '${counts.completed}',
                                    Icons.check_circle_rounded,
                                    const Color(0xFF3A86FF),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      GlassContainer(
                        blur: 16,
                        color: const Color(0xE6141A20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        borderRadius: BorderRadius.circular(18),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white70,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sign in to compete',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Create challenges and track your streak',
                                    style: GoogleFonts.inter(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Segmented Capsule Tab Bar (matching Dashboard & AI Insights theme)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF141A20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF48E5C2).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF48E5C2).withValues(alpha: 0.4),
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF48E5C2),
                  unselectedLabelColor: Colors.white54,
                  labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'My Challenges'),
                    Tab(text: 'Browse All'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChallengesTab(data),
                    _buildAllChallengesTab(data),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreStat(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengesTab(HealthDataController data) {
    if (data.userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to view challenges',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<ChallengeData>>(
      stream: SocialService.getActiveChallenges(data.userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF48E5C2)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'No active challenges',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create one to start competing!',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showCreateChallengeDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Create Challenge', style: GoogleFonts.inter()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF48E5C2),
                    foregroundColor: const Color(0xFF090D10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final challenges = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            final userProgress = challenge.getUserProgress(data.userId!);
            final progressPercent =
                challenge.getProgressPercentage(data.userId!);
            final userRank = challenge.getRank(data.userId!);
            final daysLeft =
                challenge.endDate.difference(DateTime.now()).inDays;

            String currentMetricDisplay = _getCurrentMetricDisplay(
              challenge.metricType,
              data,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: GlassContainer(
                blur: 16,
                color: const Color(0xE6141A20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                borderRadius: BorderRadius.circular(22),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.title,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (challenge.description.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  challenge.description,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF48E5C2).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF48E5C2).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Rank #$userRank of ${challenge.participants.length}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF48E5C2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Created by ${challenge.creatorName} • ${challenge.participants.length} players',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Metric chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getMetricIcon(challenge.metricType),
                            size: 14,
                            color: const Color(0xFF3A86FF),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Today: $currentMetricDisplay',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$userProgress ',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: '/ ${challenge.targetValue}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _getMetricUnit(challenge.metricType),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressPercent.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF48E5C2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showChallengeLeaderboard(challenge, data),
                            icon: const Icon(Icons.leaderboard_rounded, size: 16),
                            label: Text(
                              'Leaderboard',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF48E5C2),
                              side: BorderSide(
                                color: const Color(0xFF48E5C2).withValues(alpha: 0.4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: daysLeft <= 1
                                ? const Color(0xFFFF5722).withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: daysLeft <= 1
                                  ? const Color(0xFFFF5722).withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 15,
                                color: daysLeft <= 1
                                    ? const Color(0xFFFF5722)
                                    : Colors.white54,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                daysLeft > 0 ? '$daysLeft d' : 'Today',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: daysLeft <= 1
                                      ? const Color(0xFFFF5722)
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showLeaveChallengeDialog(challenge, data),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Icon(
                              Icons.exit_to_app_rounded,
                              size: 16,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildAllChallengesTab(HealthDataController data) {
    if (data.userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to browse challenges',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<ChallengeData>>(
      stream: SocialService.getAllActiveChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF48E5C2)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.explore_off_rounded,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'No challenges available',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        }

        final challenges = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            final isJoined = challenge.participants.contains(data.userId);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: GlassContainer(
                blur: 16,
                color: const Color(0xE6141A20),
                border: Border.all(
                  color: isJoined
                      ? const Color(0xFF48E5C2).withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.08),
                  width: isJoined ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(22),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.title,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (challenge.description.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  challenge.description,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'By ${challenge.creatorName}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isJoined)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF48E5C2).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF48E5C2).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '✓ Joined',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF48E5C2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      '${challenge.participants.length} players • ${challenge.targetValue} ${_getMetricUnit(challenge.metricType)} • ${challenge.rankingType == 'closestToTarget' ? 'Closest to Target' : 'Highest Value'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showChallengeLeaderboard(challenge, data),
                            icon: const Icon(Icons.leaderboard_rounded, size: 16),
                            label: Text(
                              'View Rankings',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3A86FF),
                              side: BorderSide(
                                color: const Color(0xFF3A86FF).withValues(alpha: 0.4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (!isJoined) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final initProg = _getCurrentMetricInitialValue(
                                  challenge.metricType,
                                  data,
                                );
                                try {
                                  await SocialService.joinChallenge(
                                    challengeId: challenge.id,
                                    userId: data.userId!,
                                    username: data.username ?? 'User',
                                    initialProgress: initProg,
                                  );
                                  if (context.mounted) {
                                    CustomNotification.show(
                                      context,
                                      message: 'Joined ${challenge.title}!',
                                      type: NotificationType.success,
                                      title: 'Success',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    CustomNotification.show(
                                      context,
                                      message: 'Failed to join challenge',
                                      type: NotificationType.error,
                                      title: 'Error',
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF48E5C2),
                                foregroundColor: const Color(0xFF090D10),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Join',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFF3A86FF);
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  String _getMetricUnit(String metricType) {
    switch (metricType) {
      case 'steps':
        return 'steps/day';
      case 'water':
        return 'ml/day';
      case 'calories':
        return 'kcal/day';
      case 'sleep':
        return 'hours/day';
      default:
        return '';
    }
  }

  String _getCurrentMetricDisplay(
      String metricType, HealthDataController data) {
    switch (metricType) {
      case 'steps':
        return '${data.stepsToday} steps';
      case 'water':
        return '${data.waterMl} ml';
      case 'calories':
        return '${data.caloriesConsumed.toInt()} kcal';
      case 'sleep':
        return '${data.sleepHours.toStringAsFixed(1)} h';
      default:
        return '0';
    }
  }

  IconData _getMetricIcon(String metricType) {
    switch (metricType) {
      case 'steps':
        return Icons.directions_walk_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'calories':
        return Icons.local_fire_department_rounded;
      case 'sleep':
        return Icons.nightlight_round;
      default:
        return Icons.show_chart_rounded;
    }
  }
}

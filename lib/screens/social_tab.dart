import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/health_data_controller.dart';
import '../services/social_service.dart';
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
    _tabController = TabController(length: 2, vsync: this); // Changed to 2 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateChallengeDialog() {
    final titleController = TextEditingController();
    int targetValue = 10000;
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF006E), Color(0xFFFF4081)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.emoji_events,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Create Challenge',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Challenge Title
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Challenge Name',
                    hintText: 'e.g., 7-Day Step Challenge',
                    filled: true,
                    fillColor: const Color(0xFFF7F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Metric Type
                DropdownButtonFormField<String>(
                  value: selectedMetric,
                  decoration: InputDecoration(
                    labelText: 'Metric Type',
                    filled: true,
                    fillColor: const Color(0xFFF7F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'steps', child: Text('Steps')),
                    DropdownMenuItem(value: 'water', child: Text('Water (ml)')),
                    DropdownMenuItem(
                        value: 'calories', child: Text('Calories')),
                    DropdownMenuItem(
                        value: 'sleep', child: Text('Sleep (hours)')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedMetric = value!;
                      // Set default targets
                      targetValue = {
                        'steps': 10000,
                        'water': 2500,
                        'calories': 2000,
                        'sleep': 8,
                      }[value]!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Target Value
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Daily Target',
                    filled: true,
                    fillColor: const Color(0xFFF7F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller:
                      TextEditingController(text: targetValue.toString()),
                  onChanged: (value) {
                    targetValue = int.tryParse(value) ?? targetValue;
                  },
                ),
                const SizedBox(height: 16),

                // Duration
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Duration',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${endDate.difference(DateTime.now()).inDays} days',
                    style: GoogleFonts.inter(color: const Color(0xFFFF006E)),
                  ),
                  trailing: const Icon(Icons.calendar_today,
                      color: Color(0xFFFF006E)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      setState(() => endDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Create Button
                SizedBox(
                  width: double.infinity,
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

                      final challengeId =
                          DateTime.now().millisecondsSinceEpoch.toString();

                      try {
                        await SocialService.createChallenge(
                          challengeId: challengeId,
                          title: titleController.text,
                          creatorId: data.userId!,
                          creatorName: data.username ?? 'User',
                          targetValue: targetValue,
                          metricType: selectedMetric,
                          endDate: endDate,
                        );

                        Navigator.pop(context);
                        CustomNotification.show(
                          context,
                          message: 'Challenge created successfully!',
                          type: NotificationType.success,
                          title: 'Success',
                        );
                      } catch (e) {
                        CustomNotification.show(
                          context,
                          message: 'Failed to create challenge',
                          type: NotificationType.error,
                          title: 'Error',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF006E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Create Challenge',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.group_add,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Join Challenge',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
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
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No challenges available',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.grey[600],
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
                            color: Colors.grey[600],
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
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF3A86FF).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              challenge.title,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'By ${challenge.creatorName}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${challenge.participants.length} participants • ${challenge.targetValue} ${_getMetricUnit(challenge.metricType)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await SocialService.joinChallenge(
                                    challenge.id,
                                    data.userId!,
                                    data.username ?? 'User',
                                  );
                                  Navigator.pop(context);
                                  CustomNotification.show(
                                    context,
                                    message: 'Joined challenge successfully!',
                                    type: NotificationType.success,
                                    title: 'Success',
                                  );
                                } catch (e) {
                                  CustomNotification.show(
                                    context,
                                    message: 'Failed to join challenge',
                                    type: NotificationType.error,
                                    title: 'Error',
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3A86FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Join', style: GoogleFonts.inter()),
                            ),
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
    );
  }

  void _showChallengeLeaderboard(
      ChallengeData challenge, HealthDataController data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF006E), Color(0xFFFF4081)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.leaderboard,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leaderboard',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          challenge.title,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Leaderboard list
              Expanded(
                child: ListView.builder(
                  itemCount: challenge.participants.length,
                  itemBuilder: (context, index) {
                    final sortedParticipants = challenge
                        .getTopParticipants(challenge.participants.length);
                    final participant = sortedParticipants[index];
                    final rank = index + 1;
                    final isCurrentUser = participant['userId'] == data.userId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isCurrentUser
                            ? const LinearGradient(
                                colors: [Color(0xFFFF006E), Color(0xFFFF4081)],
                              )
                            : null,
                        color: isCurrentUser ? null : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrentUser
                              ? Colors.transparent
                              : _getRankColor(rank).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Rank badge
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Colors.white.withOpacity(0.3)
                                  : _getRankColor(rank).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: rank <= 3
                                  ? Text(
                                      _getRankEmoji(rank),
                                      style: const TextStyle(fontSize: 20),
                                    )
                                  : Text(
                                      '$rank',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isCurrentUser
                                            ? Colors.white
                                            : _getRankColor(rank),
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
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isCurrentUser
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'You',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
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
                                    color: isCurrentUser
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Progress
                          Text(
                            '${participant['progress']}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isCurrentUser
                                  ? Colors.white
                                  : const Color(0xFFFF006E),
                            ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataController>();

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF006E), Color(0xFFFF4081)],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challenges',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Compete with friends',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (data.userId != null) ...[
                      IconButton(
                        onPressed: _showJoinChallengeDialog,
                        icon: const Icon(Icons.group_add,
                            color: Colors.white, size: 26),
                        tooltip: 'Join Challenge',
                      ),
                      IconButton(
                        onPressed: _showCreateChallengeDialog,
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.white, size: 28),
                        tooltip: 'Create Challenge',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // User Score Card - Removed global leaderboard stats
                if (data.userId != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildScoreStat('Active', '${data.challenges.length}',
                            Icons.emoji_events),
                        Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3)),
                        _buildScoreStat(
                            'Score', '${data.userScore}', Icons.star),
                        Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3)),
                        _buildScoreStat('Streak', '${data.streakDays}🔥',
                            Icons.local_fire_department),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.white, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Sign in to compete!',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create challenges and compete with friends',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Tabs - Changed from 3 to 2
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF006E), Color(0xFFFF4081)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              labelStyle:
                  GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
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
    );
  }

  Widget _buildScoreStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
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
            Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Sign in to view challenges',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
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
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No active challenges',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create one to start competing!',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _showCreateChallengeDialog,
                  icon: const Icon(Icons.add),
                  label: Text('Create Challenge', style: GoogleFonts.inter()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF006E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final challenges = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            final userProgress = challenge.getUserProgress(data.userId!);
            final progressPercent =
                challenge.getProgressPercentage(data.userId!);
            final userRank = challenge.getRank(data.userId!);
            final daysLeft =
                challenge.endDate.difference(DateTime.now()).inDays;

            // Get current metric value for display
            String currentMetricDisplay = _getCurrentMetricDisplay(
              challenge.metricType,
              data,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                      Expanded(
                        child: Text(
                          challenge.title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF006E), Color(0xFFFF4081)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Rank #$userRank',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created by ${challenge.creatorName} • ${challenge.participants.length} participants',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Current metric value badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A86FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getMetricIcon(challenge.metricType),
                          size: 16,
                          color: const Color(0xFF3A86FF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Today: $currentMetricDisplay',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A86FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$userProgress / ${challenge.targetValue}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFF006E),
                        ),
                      ),
                      Text(
                        _getMetricUnit(challenge.metricType),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFFFE5EE),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFFFF006E)),
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
                          icon: const Icon(Icons.leaderboard, size: 18),
                          label: Text('Leaderboard',
                              style: GoogleFonts.inter(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF006E),
                            side: const BorderSide(
                                color: Color(0xFFFF006E), width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: daysLeft <= 1
                              ? const Color(0xFFFF006E).withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: daysLeft <= 1
                                  ? const Color(0xFFFF006E)
                                  : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              daysLeft > 0 ? '$daysLeft days' : 'Today!',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: daysLeft <= 1
                                    ? const Color(0xFFFF006E)
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
            Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Sign in to browse challenges',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
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
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No challenges available',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final challenges = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            final isJoined = challenge.participants.contains(data.userId);
            final daysLeft =
                challenge.endDate.difference(DateTime.now()).inDays;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isJoined
                      ? const Color(0xFF2EC4B6).withOpacity(0.5)
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              challenge.title,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By ${challenge.creatorName}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isJoined)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2EC4B6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2EC4B6),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '✓ Joined',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2EC4B6),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '${challenge.participants.length} participants • ${challenge.targetValue} ${_getMetricUnit(challenge.metricType)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black54,
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
                          icon: const Icon(Icons.leaderboard, size: 18),
                          label: Text('View Rankings',
                              style: GoogleFonts.inter(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3A86FF),
                            side: const BorderSide(
                                color: Color(0xFF3A86FF), width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (!isJoined) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await SocialService.joinChallenge(
                                  challenge.id,
                                  data.userId!,
                                  data.username ?? 'User',
                                );
                                CustomNotification.show(
                                  context,
                                  message: 'Joined ${challenge.title}!',
                                  type: NotificationType.success,
                                  title: 'Success',
                                );
                              } catch (e) {
                                CustomNotification.show(
                                  context,
                                  message: 'Failed to join challenge',
                                  type: NotificationType.error,
                                  title: 'Error',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A86FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Join',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
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

  // Helper method to get current metric display
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

  // Helper method to get metric icon
  IconData _getMetricIcon(String metricType) {
    switch (metricType) {
      case 'steps':
        return Icons.directions_walk;
      case 'water':
        return Icons.water_drop;
      case 'calories':
        return Icons.local_fire_department;
      case 'sleep':
        return Icons.nightlight_round;
      default:
        return Icons.show_chart;
    }
  }
}

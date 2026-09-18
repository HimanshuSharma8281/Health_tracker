import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/health_data_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/aurora_chat_controller.dart';
import '../services/health_analysis_service.dart';
import '../models/daily_score.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/glass_container.dart';

class AIHealthInsightsScreen extends StatefulWidget {
  const AIHealthInsightsScreen({super.key});

  @override
  State<AIHealthInsightsScreen> createState() => _AIHealthInsightsScreenState();
}

class _AIHealthInsightsScreenState extends State<AIHealthInsightsScreen>
    with SingleTickerProviderStateMixin {
  HealthAnalysis? _analysis;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mode: 0 = Clinical Insights, 1 = AI Health Agent Chat
  int _selectedMode = 0;

  // Agent Chat State
  final TextEditingController _agentTextController = TextEditingController();
  final TextEditingController _inlineAskController = TextEditingController();
  final FocusNode _agentFocusNode = FocusNode();
  final ScrollController _agentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _agentFocusNode.addListener(() {
      if (_agentFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final data = Provider.of<HealthDataController>(context, listen: false);
      final auth = Provider.of<AuthController>(context, listen: false);
      final uid = auth.user?.uid ?? data.userId ?? 'anonymous';
      Provider.of<AuroraChatController>(context, listen: false).loadHistory(uid);

      if (_analysis == null) {
        setState(() {
          _analysis =
              HealthAnalysisService.buildImmediateDeterministicAnalysis(data);
        });
        _animationController.forward();
      }
      _loadAnalysis();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _agentTextController.dispose();
    _inlineAskController.dispose();
    _agentFocusNode.dispose();
    _agentScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    final data = Provider.of<HealthDataController>(context, listen: false);
    _analysis ??=
        HealthAnalysisService.buildImmediateDeterministicAnalysis(data);
    setState(() => _isLoading = true);

    final analysis = await HealthAnalysisService.analyzeHealthData(data);

    if (mounted) {
      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });
      _animationController.forward(from: 0.0);
    }
  }

  Future<void> _sendAgentMessage(String text) async {
    final chat = Provider.of<AuroraChatController>(context, listen: false);
    if (text.trim().isEmpty || chat.isTyping) return;

    final userText = text.trim();
    _agentTextController.clear();
    _inlineAskController.clear();

    setState(() {
      _selectedMode = 1; // Seamlessly jump to Ask Aurora chat view
    });

    _scrollToBottom();

    final auth = Provider.of<AuthController>(context, listen: false);
    final healthData = Provider.of<HealthDataController>(context, listen: false);
    final uid = auth.user?.uid ?? healthData.userId ?? 'anonymous';

    await chat.sendMessage(
      text: userText,
      uid: uid,
      healthData: healthData,
      userProfile: auth.user ?? healthData.profile,
    );

    if (mounted) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_agentScrollController.hasClients) {
        _agentScrollController.animateTo(
          _agentScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D10),
      resizeToAvoidBottomInset: true,
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
          bottom: false,
          child: Column(
            children: [
              // 1. Sleek Integrated Header matching Dashboard
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Aurora AI',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF48E5C2)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF48E5C2)
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF48E5C2),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Active',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF48E5C2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Clinical Intelligence & Health Agent',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Mode Selector Capsule Toggle (Daily Insights vs Ask Aurora)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xE6141A20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMode = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _selectedMode == 0
                                 ? const Color(0xFF48E5C2).withValues(alpha: 0.18)
                                 : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: _selectedMode == 0
                                 ? Border.all(
                                     color: const Color(0xFF48E5C2).withValues(alpha: 0.35),
                                   )
                                 : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.insights_rounded,
                                  size: 16,
                                  color: _selectedMode == 0
                                      ? const Color(0xFF48E5C2)
                                      : Colors.white38,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Daily Insights',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: _selectedMode == 0
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _selectedMode == 0
                                          ? Colors.white
                                          : Colors.white54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMode = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _selectedMode == 1
                                 ? const Color(0xFF8338EC).withValues(alpha: 0.25)
                                 : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: _selectedMode == 1
                                 ? Border.all(
                                     color: const Color(0xFF8338EC).withValues(alpha: 0.4),
                                   )
                                 : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.smart_toy_outlined,
                                  size: 16,
                                  color: _selectedMode == 1
                                      ? const Color(0xFFB388FF)
                                      : Colors.white38,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Ask Aurora',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: _selectedMode == 1
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _selectedMode == 1
                                          ? Colors.white
                                          : Colors.white54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Area
              Expanded(
                child: _selectedMode == 0
                    ? (_isLoading && _analysis == null
                        ? _buildLoadingState()
                        : _analysis == null
                            ? _buildErrorState()
                            : _buildAnalysisView())
                    : _buildAgentChatView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF48E5C2), Color(0xFF3A86FF)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF48E5C2).withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 22),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF48E5C2)),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Evaluating clinical health data...',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Insights',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ensure you have internet connection and try again.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF48E5C2),
                foregroundColor: const Color(0xFF090D10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _loadAnalysis,
              child: Text(
                'Try Again',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisView() {
    final healthData = Provider.of<HealthDataController>(context);
    final todayScore = healthData.todayScore;
    final expectedActivityTarget = '${healthData.stepGoal} steps';

    // Synchronize deterministic analysis if score or stepGoal changed
    if (_analysis == null ||
        (todayScore != null && _analysis!.overallScore != todayScore.overall) ||
        (todayScore != null && todayScore.metrics['activity']?.target != expectedActivityTarget)) {
      _analysis = HealthAnalysisService.buildImmediateDeterministicAnalysis(healthData);
    }
    final analysis = _analysis!;

    return RefreshIndicator(
      onRefresh: _loadAnalysis,
      color: const Color(0xFF48E5C2),
      backgroundColor: const Color(0xFF141A20),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: [
          // Deterministic Score Card
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildHealthScoreCard(analysis),
            ),
          ),
          const SizedBox(height: 16),

          // Per-Metric Score Breakdown
          if (todayScore != null && todayScore.availableMetricCount > 0)
            _buildMetricBreakdownCard(todayScore),

          const SizedBox(height: 16),

          // Daily Summary Card
          _buildDailySummaryCard(analysis),

          const SizedBox(height: 16),

          // Strengths
          if (analysis.strengths.isNotEmpty)
            _buildExpandableSection(
              'What You Did Great Today',
              Icons.stars_rounded,
              const Color(0xFF10B981),
              analysis.strengths
                  .map((s) => _buildListItem(s, const Color(0xFF10B981)))
                  .toList(),
            ),

          const SizedBox(height: 16),

          // Areas to Focus On
          if (analysis.areasToImprove.isNotEmpty)
            _buildExpandableSection(
              'Areas to Focus On',
              Icons.trending_up_rounded,
              const Color(0xFFF59E0B),
              analysis.areasToImprove
                  .map((a) => _buildListItem(a, const Color(0xFFF59E0B)))
                  .toList(),
            ),

          const SizedBox(height: 16),

          // Recommendations
          if (analysis.recommendations.isNotEmpty)
            _buildExpandableSection(
              'Actionable Recommendations',
              Icons.lightbulb_outline_rounded,
              const Color(0xFF8338EC),
              analysis.recommendations
                  .map((r) => _buildRecommendationCard(r))
                  .toList(),
            ),

          const SizedBox(height: 16),

          // Insights
          if (analysis.insights.isNotEmpty)
            _buildExpandableSection(
              'Clinical Trends & Correlations',
              Icons.auto_awesome_rounded,
              const Color(0xFF3A86FF),
              analysis.insights
                  .map((i) => _buildInsightCard(i))
                  .toList(),
            ),

          const SizedBox(height: 16),

          // ── Ask Aurora Interactive Health Coach Section ──
          _buildAskAuroraCard(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAskAuroraCard() {
    return GlassContainer(
      blur: 20,
      color: const Color(0xE6141A20),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: const Color(0xFF8338EC).withValues(alpha: 0.35),
        width: 1.2,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8338EC), Color(0xFF3A86FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8338EC).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ASK AURORA AI',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB388FF),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF48E5C2).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LIVE',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF48E5C2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Interactive Health Coach',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _selectedMode = 1),
                icon: const Icon(Icons.forum_outlined, size: 14, color: Color(0xFF48E5C2)),
                label: Text(
                  'Full Chat',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF48E5C2),
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF48E5C2).withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ask questions about your health score, today\'s readings, hydration, sleep trends, or personalized improvements.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),

          // Suggested quick questions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              {'icon': Icons.trending_up_rounded, 'color': const Color(0xFFFFBE0B), 'text': 'How to improve my score?'},
              {'icon': Icons.water_drop_rounded, 'color': const Color(0xFF48E5C2), 'text': 'Analyze my hydration'},
              {'icon': Icons.bedtime_rounded, 'color': const Color(0xFF8338EC), 'text': 'Tips for better sleep'},
              {'icon': Icons.favorite_rounded, 'color': const Color(0xFFFF006E), 'text': 'Weekly cardio trends'},
            ].map((item) {
              final q = item['text'] as String;
              final icon = item['icon'] as IconData;
              final color = item['color'] as Color;
              return InkWell(
                onTap: () => _sendAgentMessage(q),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 13, color: color),
                      const SizedBox(width: 6),
                      Text(
                        q,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Inline Chat Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1216),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF48E5C2).withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF48E5C2),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _inlineAskController,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ask Aurora about your health metrics...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white38,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (val) => _sendAgentMessage(val),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF48E5C2), Color(0xFF3A86FF)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                    color: const Color(0xFF090D10),
                    padding: EdgeInsets.zero,
                    onPressed: () => _sendAgentMessage(_inlineAskController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(HealthAnalysis analysis) {
    return GlassContainer(
      blur: 20,
      color: const Color(0xE6141A20),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      padding: const EdgeInsets.all(22),
      child: Stack(
        children: [
          // Radial glow matching status color
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: analysis.statusColor.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: analysis.statusColor.withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WELLNESS SCORE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF48E5C2),
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${analysis.overallScore}',
                            style: GoogleFonts.inter(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: -1.0,
                            ),
                          ),
                          Text(
                            ' / 100',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: analysis.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: analysis.statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(analysis.statusIcon, color: analysis.statusColor, size: 34),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 15, color: analysis.statusColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Status: ${analysis.healthStatus}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
  }

  Widget _buildMetricBreakdownCard(DailyScore score) {
    return GlassContainer(
      blur: 16,
      color: const Color(0xE6141A20),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clinical Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF48E5C2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF48E5C2).withValues(alpha: 0.25)),
                ),
                child: Text(
                  '${score.availableMetricCount} Scored',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF48E5C2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...score.metrics.entries.map((entry) {
            final m = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Text(
                    _metricIcon(entry.key),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _metricTitle(entry.key),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (m.available)
                          Text(
                            m.reason,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          )
                        else
                          Text(
                            'No reading logged today',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (m.available)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _scoreColor(m.score).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _scoreColor(m.score).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${(m.score * 10).round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _scoreColor(m.score),
                        ),
                      ),
                    )
                  else
                    const Text('—', style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard(HealthAnalysis analysis) {
    return GlassContainer(
      blur: 16,
      color: const Color(0xE6141A20),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8338EC).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8338EC).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFFB388FF), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Clinical Narrative',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            analysis.dailySummary,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.55,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return GlassContainer(
      blur: 16,
      color: const Color(0xE6141A20),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListItem(String text, Color bulletColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: bulletColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: bulletColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF8338EC).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8338EC).withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: Color(0xFFB388FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3A86FF).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A86FF).withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology_outlined,
              size: 18, color: Color(0xFF3A86FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AI Agent Chat View ──────────────────────────────────────────────────

  Widget _buildAgentChatView() {
    final suggestedPrompts = [
      {'icon': Icons.water_drop_rounded, 'color': const Color(0xFF48E5C2), 'text': 'How is my hydration today?'},
      {'icon': Icons.trending_up_rounded, 'color': const Color(0xFFFFBE0B), 'text': 'What is driving my health score?'},
      {'icon': Icons.bedtime_rounded, 'color': const Color(0xFF8338EC), 'text': 'Analyze my sleep & step trends'},
      {'icon': Icons.favorite_rounded, 'color': const Color(0xFFFF006E), 'text': 'Tips to improve cardio score'},
      {'icon': Icons.restaurant_rounded, 'color': const Color(0xFF3A86FF), 'text': 'Assess my daily calorie intake'},
    ];

    final mediaQuery = MediaQuery.of(context);
    final viewInsetsBottom = mediaQuery.viewInsets.bottom;
    final systemBottomPadding = mediaQuery.padding.bottom;
    final isKeyboardOpen = viewInsetsBottom > 0;
    final bool hasBottomNav = !Navigator.canPop(context);

    final double bottomPadding = isKeyboardOpen
        ? 10.0
        : (hasBottomNav ? 76.0 + systemBottomPadding : (systemBottomPadding > 0 ? systemBottomPadding : 16.0));

    return Consumer<AuroraChatController>(
      builder: (context, chatController, _) {
        final messages = chatController.messages;
        final isTyping = chatController.isTyping;
        final isConversationStarted = messages.length > 1;

        return Column(
          children: [
            // Top Status Bar in Chat Mode: Status Dot + Reset History Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF48E5C2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF48E5C2).withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Aurora Clinical Agent',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  if (messages.length > 1)
                    InkWell(
                      onTap: () {
                        chatController.clearHistory();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.delete_outline_rounded,
                                color: Colors.white38, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Clear',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Suggested Quick Prompts (Horizontal Carousel)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: suggestedPrompts.map((item) {
                  final text = item['text'] as String;
                  final icon = item['icon'] as IconData;
                  final color = item['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _sendAgentMessage(text),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xE6141A22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 13, color: color),
                            const SizedBox(width: 6),
                            Text(
                              text,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Chat Message List
            Expanded(
              child: ListView.builder(
                controller: _agentScrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                itemCount: messages.length + (isTyping ? 1 : 0) + (!isConversationStarted ? 1 : 0),
                itemBuilder: (context, index) {
                  // If fresh conversation, item 0 is the welcome hero
                  if (!isConversationStarted) {
                    if (index == 0) {
                      return _buildChatWelcomeHero();
                    }
                    final msgIndex = index - 1;
                    if (msgIndex == messages.length && isTyping) {
                      return _buildTypingBubble();
                    }
                    final msg = messages[msgIndex];
                    return _buildChatMessageBubble(msg, msg.role == 'user');
                  }

                  if (index == messages.length && isTyping) {
                    return _buildTypingBubble();
                  }

                  final msg = messages[index];
                  return _buildChatMessageBubble(msg, msg.role == 'user');
                },
              ),
            ),

            // Chat Input Box (Elevated above HomeShell floating bottom nav bar)
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
              decoration: BoxDecoration(
                color: const Color(0xF00D1216),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF141A20),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFF48E5C2).withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF48E5C2),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _agentTextController,
                        focusNode: _agentFocusNode,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Ask about steps, sleep, vitals, or advice...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: _sendAgentMessage,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF48E5C2), Color(0xFF3A86FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF48E5C2).withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: isTyping
                            ? null
                            : () => _sendAgentMessage(_agentTextController.text),
                        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                        color: const Color(0xFF090D10),
                        disabledColor: Colors.white24,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatWelcomeHero() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xE6141A22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF48E5C2).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF48E5C2).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF48E5C2), Color(0xFF3A86FF), Color(0xFF8338EC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF48E5C2).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome_rounded, color: Color(0xFF090D10), size: 26),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ask Aurora Health AI',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your intelligent clinical companion with direct real-time access to your biometrics, daily score & activity trends.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF48E5C2).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF48E5C2).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF48E5C2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Clinical Reasoning Engine Active',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF48E5C2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessageBubble(AuroraChatMessage msg, bool isUser) {
    final timeStr = DateFormat('h:mm a').format(msg.timestamp);

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3A86FF).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                msg.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isError = msg.status == 'error';
    return Container(
      margin: const EdgeInsets.only(bottom: 14, right: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF141A20),
              border: Border.all(
                color: isError
                    ? const Color(0xFFFF006E)
                    : const Color(0xFF48E5C2).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isError ? const Color(0xFFFF006E) : const Color(0xFF48E5C2))
                      .withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
                size: 15,
                color: isError ? const Color(0xFFFF006E) : const Color(0xFF48E5C2),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xF2141A22),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: isError
                      ? const Color(0xFFFF006E).withValues(alpha: 0.3)
                      : const Color(0xFF48E5C2).withValues(alpha: 0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Aurora AI',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF48E5C2),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF48E5C2).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'CLINICAL',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF48E5C2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MarkdownBody(
                    data: msg.text,
                    selectable: false,
                    shrinkWrap: true,
                    styleSheet: _buildMarkdownStyleSheet(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    return MarkdownStyleSheet(
      p: GoogleFonts.inter(
        fontSize: 13.5,
        height: 1.5,
        color: Colors.white.withValues(alpha: 0.92),
        fontWeight: FontWeight.w400,
      ),
      strong: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      em: GoogleFonts.inter(
        fontStyle: FontStyle.italic,
        color: Colors.white.withValues(alpha: 0.88),
      ),
      h1: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF48E5C2),
        height: 1.4,
      ),
      h2: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF48E5C2),
        height: 1.4,
      ),
      h3: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF48E5C2),
        height: 1.35,
      ),
      h4: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF48E5C2),
        height: 1.35,
      ),
      h5: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF48E5C2),
      ),
      h6: GoogleFonts.inter(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF48E5C2),
      ),
      h1Padding: const EdgeInsets.only(top: 8, bottom: 4),
      h2Padding: const EdgeInsets.only(top: 8, bottom: 4),
      h3Padding: const EdgeInsets.only(top: 6, bottom: 3),
      h4Padding: const EdgeInsets.only(top: 6, bottom: 2),
      h5Padding: const EdgeInsets.only(top: 4, bottom: 2),
      h6Padding: const EdgeInsets.only(top: 4, bottom: 2),
      pPadding: EdgeInsets.zero,
      listBullet: GoogleFonts.inter(
        fontSize: 13.5,
        color: const Color(0xFF48E5C2),
        fontWeight: FontWeight.w700,
      ),
      listBulletPadding: const EdgeInsets.only(right: 6),
      listIndent: 16.0,
      blockSpacing: 8.0,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
      ),
      blockquote: GoogleFonts.inter(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: Colors.white70,
      ),
      blockquoteDecoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: const Border(
          left: BorderSide(color: Color(0xFF48E5C2), width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      code: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        color: const Color(0xFF48E5C2),
        backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.6),
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      codeblockPadding: const EdgeInsets.all(10),
      tableHead: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF48E5C2),
        fontSize: 12,
      ),
      tableBody: GoogleFonts.inter(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 12,
      ),
      tableBorder: TableBorder.all(
        color: Colors.white.withValues(alpha: 0.15),
        width: 0.8,
      ),
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }

  Widget _buildTypingBubble() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF141A20),
              border: Border.all(
                color: const Color(0xFF48E5C2).withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFF48E5C2)),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xF2141A22),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: const Color(0xFF48E5C2).withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF48E5C2)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Aurora is synthesizing your data...',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
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

  static String _metricTitle(String key) {
    switch (key) {
      case 'water':
        return 'Hydration';
      case 'sleep':
        return 'Sleep Duration';
      case 'activity':
      case 'steps':
        return 'Daily Activity';
      case 'calories':
        return 'Calorie Balance';
      case 'heart_rate':
        return 'Resting Heart Rate';
      case 'blood_pressure':
        return 'Blood Pressure';
      default:
        return key;
    }
  }

  static Color _scoreColor(int score) {
    if (score >= 8) return const Color(0xFF10B981);
    if (score >= 6) return const Color(0xFF3A86FF);
    if (score >= 4) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

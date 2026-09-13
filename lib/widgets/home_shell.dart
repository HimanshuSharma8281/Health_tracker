import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../screens/dashboard_tab.dart';
import '../screens/ai_health_insights_screen.dart';
import '../screens/social_tab.dart';
import '../screens/settings_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    // Handle the returning-user startup case: if the app restarts while a
    // user is already authenticated (Google or Email), _initAuth fires without
    // a context so it cannot call setUserInfo. We do it here once, safely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthController>(context, listen: false);
      auth.initializeHealthDataIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      const DashboardTab(),
      const AIHealthInsightsScreen(),
      const SocialTab(),
      const SettingsTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF090D10),
      appBar: null,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: tabs[index],
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xE60D1216),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.0,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.psychology_outlined,
                      activeIcon: Icons.psychology_rounded,
                      label: 'Insights',
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.emoji_events_outlined,
                      activeIcon: Icons.emoji_events_rounded,
                      label: 'Social',
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings_rounded,
                      label: 'Settings',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = this.index == index;

    return GestureDetector(
      onTap: () => setState(() => this.index = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF48E5C2).withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF48E5C2).withOpacity(0.25),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? const Color(0xFF48E5C2)
                  : Colors.white.withOpacity(0.45),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF48E5C2)
                    : Colors.white.withOpacity(0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

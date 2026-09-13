import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/auth_controller.dart';
import '../controllers/health_data_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/user_profile.dart';
import '../widgets/glass_container.dart';
import '../widgets/notification_widget.dart';
import '../utils/firebase_test.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  // Preferences state
  bool _notificationsEnabled = true;
  bool _waterReminders = true;
  bool _mealReminders = true;
  bool _sleepReminders = true;
  bool _workoutReminders = true;
  String _selectedTheme = 'Dark';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _waterReminders = prefs.getBool('water_reminders') ?? true;
      _mealReminders = prefs.getBool('meal_reminders') ?? true;
      _sleepReminders = prefs.getBool('sleep_reminders') ?? true;
      _workoutReminders = prefs.getBool('workout_reminders') ?? true;
      _selectedTheme = prefs.getString('theme') ?? 'Dark';
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  int _getActiveRemindersCount() {
    int count = 0;
    if (_notificationsEnabled) {
      if (_waterReminders) count++;
      if (_mealReminders) count++;
      if (_sleepReminders) count++;
      if (_workoutReminders) count++;
    }
    return count;
  }

  void _showFirebaseTestDialog(BuildContext context) async {
    final results = await FirebaseTest.testConnection();

    if (!context.mounted) return;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      Icons.cloud_done_rounded,
                      color: Color(0xFF48E5C2),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Firebase Status',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
              const SizedBox(height: 18),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: results.entries.map((e) {
                  final isOk = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isOk
                          ? const Color(0xFF48E5C2).withValues(alpha: 0.08)
                          : const Color(0xFFFF006E).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOk
                            ? const Color(0xFF48E5C2).withValues(alpha: 0.3)
                            : const Color(0xFFFF006E).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOk ? Icons.check_circle_rounded : Icons.error_rounded,
                          color: isOk ? const Color(0xFF48E5C2) : const Color(0xFFFF006E),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.key,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          isOk ? 'Connected' : 'Failed',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isOk ? const Color(0xFF48E5C2) : const Color(0xFFFF006E),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF48E5C2),
                    foregroundColor: const Color(0xFF090D10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(UserProfile? profile) {
    if (profile?.avatarUrl != null && profile!.avatarUrl.isNotEmpty) {
      if (profile.avatarUrl.startsWith('/') ||
          profile.avatarUrl.contains('\\') ||
          profile.avatarUrl.startsWith('file://')) {
        return CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFF141A20),
          backgroundImage: FileImage(File(profile.avatarUrl)),
          onBackgroundImageError: (_, __) {},
        );
      } else {
        return CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFF141A20),
          backgroundImage: NetworkImage(profile.avatarUrl),
        );
      }
    }
    return CircleAvatar(
      radius: 36,
      backgroundColor: const Color(0xFF48E5C2).withValues(alpha: 0.15),
      child: Text(
        profile?.name.characters.first ?? 'A',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 26,
          color: const Color(0xFF48E5C2),
        ),
      ),
    );
  }

  Widget _buildAvatarPreview(
      AuthController auth, String? selectedImagePath, StateSetter setDialogState) {
    ImageProvider? imageProvider;
    Widget? fallbackChild;

    if (selectedImagePath != null && selectedImagePath != 'removed') {
      imageProvider = FileImage(File(selectedImagePath));
    } else if (selectedImagePath != 'removed' &&
        auth.user?.avatarUrl.isNotEmpty == true) {
      if (auth.user!.avatarUrl.startsWith('/') ||
          auth.user!.avatarUrl.contains('\\') ||
          auth.user!.avatarUrl.startsWith('file://')) {
        imageProvider = FileImage(File(auth.user!.avatarUrl));
      } else {
        imageProvider = NetworkImage(auth.user!.avatarUrl);
      }
    } else {
      fallbackChild = Center(
        child: Text(
          auth.user?.name.characters.first ?? 'A',
          style: GoogleFonts.inter(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF48E5C2),
          ),
        ),
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF141A20),
        border: Border.all(
          color: const Color(0xFF48E5C2),
          width: 2.5,
        ),
        image: imageProvider != null
            ? DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: fallbackChild,
    );
  }

  void _showNotificationsDialog(BuildContext context) {
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
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 580),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          Icons.notifications_rounded,
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
                              'Notifications',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Manage reminders & alerts',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white54,
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
                  const SizedBox(height: 18),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Master Toggle
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _notificationsEnabled
                                  ? const Color(0xFF48E5C2).withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _notificationsEnabled
                                    ? const Color(0xFF48E5C2).withValues(alpha: 0.35)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _notificationsEnabled
                                      ? Icons.notifications_active_rounded
                                      : Icons.notifications_off_rounded,
                                  color: _notificationsEnabled
                                      ? const Color(0xFF48E5C2)
                                      : Colors.white38,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'All Notifications',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        _notificationsEnabled ? 'Active' : 'Muted',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _notificationsEnabled,
                                  activeThumbColor: const Color(0xFF48E5C2),
                                  onChanged: (value) {
                                    setDialogState(() => _notificationsEnabled = value);
                                    setState(() {});
                                    _savePreference('notifications_enabled', value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (_notificationsEnabled) ...[
                            _buildNotificationToggle(
                              'Water Reminders',
                              'Stay hydrated throughout the day',
                              Icons.water_drop_rounded,
                              const Color(0xFF48E5C2),
                              _waterReminders,
                              (value) {
                                setDialogState(() => _waterReminders = value);
                                setState(() {});
                                _savePreference('water_reminders', value);
                              },
                            ),
                            const SizedBox(height: 10),
                            _buildNotificationToggle(
                              'Meal Reminders',
                              'Log calories & maintain nutrition',
                              Icons.restaurant_rounded,
                              const Color(0xFFFFBE0B),
                              _mealReminders,
                              (value) {
                                setDialogState(() => _mealReminders = value);
                                setState(() {});
                                _savePreference('meal_reminders', value);
                              },
                            ),
                            const SizedBox(height: 10),
                            _buildNotificationToggle(
                              'Sleep Reminders',
                              'Wind down for restorative rest',
                              Icons.nightlight_round,
                              const Color(0xFF8338EC),
                              _sleepReminders,
                              (value) {
                                setDialogState(() => _sleepReminders = value);
                                setState(() {});
                                _savePreference('sleep_reminders', value);
                              },
                            ),
                            const SizedBox(height: 10),
                            _buildNotificationToggle(
                              'Workout Reminders',
                              'Achieve your daily steps & activity',
                              Icons.directions_run_rounded,
                              const Color(0xFF3A86FF),
                              _workoutReminders,
                              (value) {
                                setDialogState(() => _workoutReminders = value);
                                setState(() {});
                                _savePreference('workout_reminders', value);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF48E5C2),
                        foregroundColor: const Color(0xFF090D10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF48E5C2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context, listen: false);

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
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A86FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF3A86FF).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.palette_rounded,
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
                            'Appearance',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Select display theme',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white54,
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
                Row(
                  children: [
                    _buildThemeOption(
                      'Dark',
                      Icons.dark_mode_rounded,
                      const Color(0xFF48E5C2),
                      setDialogState,
                      themeController,
                    ),
                    const SizedBox(width: 10),
                    _buildThemeOption(
                      'Light',
                      Icons.light_mode_rounded,
                      Colors.orange,
                      setDialogState,
                      themeController,
                    ),
                    const SizedBox(width: 10),
                    _buildThemeOption(
                      'System',
                      Icons.settings_suggest_rounded,
                      Colors.white70,
                      setDialogState,
                      themeController,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF48E5C2),
                      foregroundColor: const Color(0xFF090D10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    String theme,
    IconData icon,
    Color color,
    StateSetter setDialogState,
    ThemeController themeController,
  ) {
    final isSelected = _selectedTheme == theme;
    return Expanded(
      child: InkWell(
        onTap: () {
          setDialogState(() => _selectedTheme = theme);
          setState(() {});
          _savePreference('theme', theme);
          themeController.setTheme(theme);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF48E5C2).withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF48E5C2)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF48E5C2) : Colors.white60, size: 26),
              const SizedBox(height: 8),
              Text(
                theme,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF48E5C2) : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      Icons.health_and_safety_rounded,
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
                          'About Aurora Health',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Version 1.0.0 (Production)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white54,
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
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    _buildAboutRow('AI Intelligence', 'Gemini 3.6 Flash + LangGraph'),
                    const SizedBox(height: 8),
                    _buildAboutRow('Scoring Engine', 'Deterministic HealthScoreEngine'),
                    const SizedBox(height: 8),
                    _buildAboutRow('Database', 'Firebase Firestore & Realtime DB'),
                    const SizedBox(height: 8),
                    _buildAboutRow('Security', 'Encrypted Cloud Storage & Auth'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBE0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFBE0B).withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFFFBE0B), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aurora is an intelligent lifestyle and wellness companion. It is not intended as a substitute for clinical medical diagnosis or emergency healthcare.',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF48E5C2),
                    foregroundColor: const Color(0xFF090D10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  void _showSignOutDialog(
      BuildContext context, AuthController auth, HealthDataController data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: GlassContainer(
          blur: 24,
          color: const Color(0xF2141A20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(22),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to sign out from your account?',
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
                    child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white60)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      auth.signOut();
                      data.clearProfile();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A86FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final auth = Provider.of<AuthController>(context, listen: false);
    final health = Provider.of<HealthDataController>(context, listen: false);
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: GlassContainer(
              blur: 24,
              color: const Color(0xF2141A20),
              border: Border.all(color: const Color(0xFFFF006E).withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF006E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFF006E).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFF006E),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Account Forever',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFF006E),
                              ),
                            ),
                            Text(
                              'Permanent & Irreversible',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Are you sure you want to delete your account? This will permanently wipe your profile and all historical data from the database.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The following data will be erased forever:',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        _buildBulletPoint('User profile, email & credentials'),
                        _buildBulletPoint('All health logs (steps, water, sleep, calories, BP, sugar, heart rate)'),
                        _buildBulletPoint('All deterministic health scores & history'),
                        _buildBulletPoint('Leaderboard standings & challenge progress'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(color: Colors.white60, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () async {
                                setDialogState(() => isDeleting = true);

                                final success = await auth.deleteAccount();
                                health.resetAllUserData();

                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }

                                if (context.mounted) {
                                  if (success) {
                                    CustomNotification.show(
                                      context,
                                      message: 'Your account and database data have been deleted forever.',
                                      type: NotificationType.success,
                                      title: 'Account Deleted',
                                    );
                                  } else {
                                    CustomNotification.show(
                                      context,
                                      message: auth.error ?? 'Failed to delete account. Please try again.',
                                      type: NotificationType.error,
                                      title: 'Deletion Error',
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF006E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.delete_forever_rounded, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Delete Forever',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFFFF006E), fontSize: 12, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white60, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthController auth) {
    final nameController = TextEditingController(text: auth.user?.name ?? '');
    String? selectedImagePath;

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
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          Icons.person_rounded,
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
                              'Edit Profile',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Update your info and avatar',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white54,
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

                  // Avatar Picker
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final source = await showModalBottomSheet<ImageSource>(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => GlassContainer(
                          blur: 24,
                          color: const Color(0xF2141A20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF48E5C2)),
                                title: Text('Take Photo', style: GoogleFonts.inter(color: Colors.white)),
                                onTap: () => Navigator.pop(context, ImageSource.camera),
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF3A86FF)),
                                title: Text('Choose from Gallery', style: GoogleFonts.inter(color: Colors.white)),
                                onTap: () => Navigator.pop(context, ImageSource.gallery),
                              ),
                              if (auth.user?.avatarUrl.isNotEmpty == true)
                                ListTile(
                                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF006E)),
                                  title: Text('Remove Photo', style: GoogleFonts.inter(color: const Color(0xFFFF006E))),
                                  onTap: () {
                                    setDialogState(() => selectedImagePath = 'removed');
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                          ),
                        ),
                      );

                      if (source != null) {
                        final XFile? image = await picker.pickImage(source: source);
                        if (image != null) {
                          setDialogState(() => selectedImagePath = image.path);
                        }
                      }
                    },
                    child: Stack(
                      children: [
                        _buildAvatarPreview(auth, selectedImagePath, setDialogState),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF48E5C2),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF090D10), width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF090D10), size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full name
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: GoogleFonts.inter(color: Colors.white70),
                      hintText: 'Enter your full name',
                      hintStyle: GoogleFonts.inter(color: Colors.white38),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF48E5C2)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF48E5C2), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final newName = nameController.text.trim();
                        if (newName.isEmpty) {
                          CustomNotification.show(
                            context,
                            message: 'Please enter a name',
                            type: NotificationType.warning,
                            title: 'Name Required',
                          );
                          return;
                        }

                        String avatarToSave = '';
                        if (selectedImagePath == 'removed') {
                          avatarToSave = '';
                        } else if (selectedImagePath != null) {
                          avatarToSave = selectedImagePath!;
                        } else {
                          avatarToSave = auth.user?.avatarUrl ?? '';
                        }

                        auth.updateProfile(name: newName, avatarUrl: avatarToSave);
                        Navigator.pop(context);

                        CustomNotification.show(
                          context,
                          message: 'Profile updated successfully',
                          type: NotificationType.success,
                          title: 'Success',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF48E5C2),
                        foregroundColor: const Color(0xFF090D10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final health = context.watch<HealthDataController>();
    final UserProfile? profile = auth.user;

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
              // Sleek Integrated Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
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
                          Icons.tune_rounded,
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
                            'Settings',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Preferences & Account',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Settings Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    // Profile Hero Card
                    GlassContainer(
                      blur: 16,
                      color: const Color(0xE6141A20),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              _buildProfileAvatar(profile),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _showEditProfileDialog(context, auth),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF48E5C2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF090D10),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      size: 13,
                                      color: Color(0xFF090D10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        profile?.name ?? 'Guest User',
                                        style: GoogleFonts.inter(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF48E5C2).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFF48E5C2).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        'Active',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF48E5C2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  profile?.email.isNotEmpty == true
                                      ? profile!.email
                                      : 'Sign in to sync all health metrics',
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Preferences Card
                    _buildSettingsSection(
                      title: 'Preferences',
                      children: [
                        _SettingsTile(
                          icon: Icons.notifications_outlined,
                          iconColor: const Color(0xFF48E5C2),
                          title: 'Notifications & Alerts',
                          subtitle: '${_getActiveRemindersCount()} active alerts',
                          onTap: () => _showNotificationsDialog(context),
                        ),
                        _buildDivider(),
                        _SettingsTile(
                          icon: Icons.palette_outlined,
                          iconColor: const Color(0xFF3A86FF),
                          title: 'Appearance',
                          subtitle: '$_selectedTheme mode',
                          onTap: () => _showAppearanceDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Account & Cloud Sync Card
                    _buildSettingsSection(
                      title: 'Account & Cloud Sync',
                      children: [
                        _SettingsTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: const Color(0xFF48E5C2),
                          title: 'Edit Profile',
                          subtitle: 'Update your display name & avatar',
                          onTap: () => _showEditProfileDialog(context, auth),
                        ),
                        _buildDivider(),
                        _SettingsTile(
                          icon: Icons.cloud_sync_rounded,
                          iconColor: const Color(0xFF3A86FF),
                          title: 'Cloud Synchronization',
                          subtitle: 'Verify Firebase & cloud backup connection',
                          onTap: () => _showFirebaseTestDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // About & System Card
                    _buildSettingsSection(
                      title: 'About & System',
                      children: [
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: const Color(0xFF48E5C2),
                          title: 'About Aurora Health',
                          subtitle: 'Version 1.0.0 • AI Clinical Engine',
                          onTap: () => _showAboutDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Account Actions
                    _buildSettingsSection(
                      title: 'Account Actions',
                      children: [
                        _SettingsTile(
                          icon: Icons.logout_rounded,
                          iconColor: const Color(0xFF3A86FF),
                          title: 'Sign Out',
                          subtitle: 'Sign out of your account on this device',
                          textColor: const Color(0xFF3A86FF),
                          onTap: () => _showSignOutDialog(context, auth, health),
                        ),
                        _buildDivider(),
                        _SettingsTile(
                          icon: Icons.delete_forever_rounded,
                          iconColor: const Color(0xFFFF006E),
                          title: 'Delete Account',
                          subtitle: 'Permanently erase account & all data from database',
                          textColor: const Color(0xFFFF006E),
                          onTap: () => _showDeleteAccountDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Footer
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Aurora Health & Wellness',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your personal intelligent health companion',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white24,
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
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return GlassContainer(
      blur: 16,
      color: const Color(0xE6141A20),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF48E5C2),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.05),
      height: 1,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? const Color(0xFF48E5C2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: effectiveColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}

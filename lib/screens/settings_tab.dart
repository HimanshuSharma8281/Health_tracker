import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:characters/characters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../controllers/auth_controller.dart';
import '../controllers/health_data_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/user_profile.dart';
import '../widgets/common_widgets.dart';
import '../widgets/notification_widget.dart';
import '../models/social_models.dart';
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
  String _selectedTheme = 'Light';
  String _selectedLanguage = 'English (US)';
  double _textScale = 1.0;
  bool _screenReaderEnabled = false;
  bool _highContrastEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _waterReminders = prefs.getBool('water_reminders') ?? true;
      _mealReminders = prefs.getBool('meal_reminders') ?? true;
      _sleepReminders = prefs.getBool('sleep_reminders') ?? true;
      _workoutReminders = prefs.getBool('workout_reminders') ?? true;
      _selectedTheme = prefs.getString('theme') ?? 'Light';
      _selectedLanguage = prefs.getString('language') ?? 'English (US)';
      _textScale = prefs.getDouble('text_scale') ?? 1.0;
      _screenReaderEnabled = prefs.getBool('screen_reader') ?? false;
      _highContrastEnabled = prefs.getBool('high_contrast') ?? false;
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

  void _showFirebaseTestDialog(BuildContext context) async {
    // Show loading dialog

    // Run tests
    final results = await FirebaseTest.testConnection();

    // Close loading dialog
    if (context.mounted) Navigator.pop(context);

    // Show results dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.cloud_done, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Firebase Status',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: results.entries
                .map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: e.value
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: e.value ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            e.value ? Icons.check_circle : Icons.error,
                            color: e.value ? Colors.green : Colors.red,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.key,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  e.value ? 'Connected' : 'Failed',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: e.value ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3A86FF),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProfileAvatar(UserProfile? profile) {
    // Check if avatar URL is a local file path
    if (profile?.avatarUrl != null && profile!.avatarUrl.isNotEmpty) {
      if (profile.avatarUrl.startsWith('/') ||
          profile.avatarUrl.contains('\\') ||
          profile.avatarUrl.startsWith('file://')) {
        // Local file path
        return CircleAvatar(
          radius: 40,
          backgroundImage: FileImage(File(profile.avatarUrl)),
          onBackgroundImageError: (_, __) {
            // If file doesn't exist, show initial
          },
        );
      } else {
        // Network URL
        return CircleAvatar(
          radius: 40,
          backgroundImage: NetworkImage(profile.avatarUrl),
        );
      }
    }
    // No avatar - show initial
    return CircleAvatar(
      radius: 40,
      child: Text(
        profile?.name.characters.first ?? 'A',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
      ),
    );
  }

  Widget _buildAvatarPreview(
      AuthController auth, String? selectedImagePath, StateSetter setState) {
    ImageProvider? imageProvider;
    Widget? fallbackChild;

    if (selectedImagePath != null && selectedImagePath != 'removed') {
      // Show newly selected local image
      imageProvider = FileImage(File(selectedImagePath));
    } else if (selectedImagePath != 'removed' &&
        auth.user?.avatarUrl.isNotEmpty == true) {
      // Check if current avatar is local file or network URL
      if (auth.user!.avatarUrl.startsWith('/') ||
          auth.user!.avatarUrl.contains('\\') ||
          auth.user!.avatarUrl.startsWith('file://')) {
        imageProvider = FileImage(File(auth.user!.avatarUrl));
      } else {
        imageProvider = NetworkImage(auth.user!.avatarUrl);
      }
    } else {
      // No image - show initial
      fallbackChild = Center(
        child: Text(
          auth.user?.name.characters.first ?? 'A',
          style: GoogleFonts.inter(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3A86FF),
          ),
        ),
      );
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF3A86FF),
          width: 3,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Manage your reminders',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Master toggle
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _notificationsEnabled
                                ? const Color(0xFF3A86FF).withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _notificationsEnabled
                                  ? const Color(0xFF3A86FF).withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _notificationsEnabled
                                    ? Icons.notifications_active
                                    : Icons.notifications_off,
                                color: _notificationsEnabled
                                    ? const Color(0xFF3A86FF)
                                    : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'All Notifications',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      _notificationsEnabled
                                          ? 'Enabled'
                                          : 'Disabled',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _notificationsEnabled,
                                onChanged: (value) {
                                  setDialogState(
                                      () => _notificationsEnabled = value);
                                  setState(() {});
                                  _savePreference(
                                      'notifications_enabled', value);
                                },
                                activeColor: const Color(0xFF3A86FF),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Individual toggles
                        if (_notificationsEnabled) ...[
                          _buildNotificationToggle(
                            'Water Reminders',
                            'Stay hydrated throughout the day',
                            Icons.water_drop,
                            const Color(0xFF2EC4B6),
                            _waterReminders,
                            (value) {
                              setDialogState(() => _waterReminders = value);
                              setState(() {});
                              _savePreference('water_reminders', value);
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildNotificationToggle(
                            'Meal Reminders',
                            'Don\'t forget to log your meals',
                            Icons.restaurant,
                            const Color(0xFFFF006E),
                            _mealReminders,
                            (value) {
                              setDialogState(() => _mealReminders = value);
                              setState(() {});
                              _savePreference('meal_reminders', value);
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildNotificationToggle(
                            'Sleep Reminders',
                            'Maintain a healthy sleep schedule',
                            Icons.nightlight_round,
                            const Color(0xFFFFBE0B),
                            _sleepReminders,
                            (value) {
                              setDialogState(() => _sleepReminders = value);
                              setState(() {});
                              _savePreference('sleep_reminders', value);
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildNotificationToggle(
                            'Workout Reminders',
                            'Stay active and reach your goals',
                            Icons.fitness_center,
                            const Color(0xFF8338EC),
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

                // Close button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A86FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context) {
    final themeController =
        Provider.of<ThemeController>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8338EC), Color(0xFFFF006E)],
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.palette,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appearance',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Customize your app look',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildThemeOption(
                            'Light',
                            Icons.light_mode,
                            Colors.orange,
                            setDialogState,
                            themeController,
                          ),
                          const SizedBox(width: 12),
                          _buildThemeOption(
                            'Dark',
                            Icons.dark_mode,
                            Colors.indigo,
                            setDialogState,
                            themeController,
                          ),
                          const SizedBox(width: 12),
                          _buildThemeOption(
                            'System',
                            Icons.settings_suggest,
                            Colors.grey,
                            setDialogState,
                            themeController,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8338EC),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

          // Apply theme immediately
          themeController.setTheme(theme);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(
                theme,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languages = [
      {'code': 'English (US)', 'flag': '🇺🇸', 'name': 'English (US)'},
      {'code': 'English (UK)', 'flag': '🇬🇧', 'name': 'English (UK)'},
      {'code': 'Spanish', 'flag': '🇪🇸', 'name': 'Español'},
      {'code': 'French', 'flag': '🇫🇷', 'name': 'Français'},
      {'code': 'German', 'flag': '🇩🇪', 'name': 'Deutsch'},
      {'code': 'Hindi', 'flag': '🇮🇳', 'name': 'हिंदी'},
      {'code': 'Chinese', 'flag': '🇨🇳', 'name': '中文'},
      {'code': 'Japanese', 'flag': '🇯🇵', 'name': '日本語'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2EC4B6), Color(0xFF3A86FF)],
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.language,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Language',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Select your preferred language',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final lang = languages[index];
                      final isSelected = _selectedLanguage == lang['code'];
                      return InkWell(
                        onTap: () {
                          setDialogState(
                              () => _selectedLanguage = lang['code']!);
                          setState(() {});
                          _savePreference('language', lang['code']!);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2EC4B6).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2EC4B6)
                                  : Colors.grey.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(lang['flag']!,
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang['code']!,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      lang['name']!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: Color(0xFF2EC4B6)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Close button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2EC4B6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

  void _showAccessibilityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFBE0B), Color(0xFFFF006E)],
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.accessibility_new,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Accessibility',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Make the app easier to use',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Size
                      Text(
                        'Text Size',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('A', style: GoogleFonts.inter(fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: _textScale,
                              min: 0.8,
                              max: 1.4,
                              divisions: 6,
                              activeColor: const Color(0xFFFFBE0B),
                              onChanged: (value) {
                                setDialogState(() => _textScale = value);
                                setState(() {});
                                _savePreference('text_scale', value);
                              },
                            ),
                          ),
                          Text('A', style: GoogleFonts.inter(fontSize: 20)),
                        ],
                      ),
                      Center(
                        child: Text(
                          '${(_textScale * 100).round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFBE0B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Screen Reader
                      _buildAccessibilityToggle(
                        'Screen Reader Support',
                        'Optimize for screen readers',
                        Icons.record_voice_over,
                        _screenReaderEnabled,
                        (value) {
                          setDialogState(() => _screenReaderEnabled = value);
                          setState(() {});
                          _savePreference('screen_reader', value);
                        },
                      ),
                      const SizedBox(height: 12),

                      // High Contrast
                      _buildAccessibilityToggle(
                        'High Contrast',
                        'Increase color contrast',
                        Icons.contrast,
                        _highContrastEnabled,
                        (value) {
                          setDialogState(() => _highContrastEnabled = value);
                          setState(() {});
                          _savePreference('high_contrast', value);
                        },
                      ),
                    ],
                  ),
                ),

                // Close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFBE0B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

  Widget _buildAccessibilityToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFBE0B), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFFBE0B),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Consumer<HealthDataController>(
      builder: (context, data, _) {
        final UserProfile? profile = auth.user;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            // Profile Section
            SectionCard(
              title: 'Profile',
              child: Row(children: [
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
                            color: const Color(0xFF3A86FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit,
                              size: 16, color: Colors.white),
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
                      Text(profile?.name ?? 'Guest',
                          style: GoogleFonts.inter(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(profile?.email ?? '',
                          style: GoogleFonts.inter(
                              color: Colors.black54, fontSize: 14)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            // Account Settings
            SectionCard(
              title: 'Account Settings',
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () => _showEditProfileDialog(context, auth),
                  ),
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Privacy & Security',
                    subtitle: 'Manage your privacy settings',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Health Devices

            // Preferences - UPDATED WITH WORKING OPTIONS
            SectionCard(
              title: 'Preferences',
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: '${_getActiveRemindersCount()} active reminders',
                    onTap: () => _showNotificationsDialog(context),
                  ),
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Appearance',
                    subtitle: '$_selectedTheme mode',
                    onTap: () => _showAppearanceDialog(context),
                  ),
                  _SettingsTile(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: _selectedLanguage,
                    onTap: () => _showLanguageDialog(context),
                  ),
                  _SettingsTile(
                    icon: Icons.accessibility_new,
                    title: 'Accessibility',
                    subtitle: 'Text size: ${(_textScale * 100).round()}%',
                    onTap: () => _showAccessibilityDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Support & About
            SectionCard(
              title: 'Support & About',
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    subtitle: 'FAQs and support articles',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Report a Bug',
                    subtitle: 'Help us improve',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.star_outline,
                    title: 'Rate Aurora Wellness',
                    subtitle: 'Share your feedback',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Version 1.0.0',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Danger Zone
            SectionCard(
              title: 'Account Actions',
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Sign out from your account',
                    textColor: const Color(0xFF3A86FF),
                    onTap: () {
                      _showSignOutDialog(context, auth, data);
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    textColor: const Color(0xFFFF006E),
                    onTap: () {
                      _showDeleteAccountDialog(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Developer Section
            SectionCard(
              title: 'Developer',
              trailing: const Icon(Icons.code, color: Colors.black54),
              child: Column(
                children: [
                  // Firebase Connection Test
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cloud_done,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      'Test Firebase Connection',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Check database connectivity',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    trailing:
                        const Icon(Icons.play_arrow, color: Color(0xFF3A86FF)),
                    onTap: () => _showFirebaseTestDialog(context),
                  ),

                  // App Version
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFBE0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Color(0xFFFFBE0B),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      'App Version',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '1.0.0',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Footer
            Center(
              child: Column(
                children: [
                  Text('Aurora Wellness',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text('Your health, your journey',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.black45)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text('Privacy Policy',
                            style: GoogleFonts.inter(fontSize: 12)),
                      ),
                      Text('•',
                          style: GoogleFonts.inter(color: Colors.black45)),
                      TextButton(
                        onPressed: () {},
                        child: Text('Terms of Service',
                            style: GoogleFonts.inter(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSignOutDialog(
      BuildContext context, AuthController auth, HealthDataController data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          FilledButton(
            onPressed: () {
              auth.signOut();
              data.clearProfile();
              Navigator.pop(context);
            },
            child: Text('Sign Out', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: const Color(0xFFFF006E))),
        content: Text(
            'This action cannot be undone. All your data will be permanently deleted.',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF006E)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Account deletion is not implemented yet',
                      style: GoogleFonts.inter()),
                ),
              );
            },
            child: Text('Delete', style: GoogleFonts.inter()),
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
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Profile',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Update your personal information',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Profile Image Picker
                        GestureDetector(
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();

                            // Show image source dialog
                            final source =
                                await showModalBottomSheet<ImageSource>(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt,
                                          color: Color(0xFF3A86FF)),
                                      title: Text('Take Photo',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600)),
                                      onTap: () => Navigator.pop(
                                          context, ImageSource.camera),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library,
                                          color: Color(0xFF8338EC)),
                                      title: Text('Choose from Gallery',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600)),
                                      onTap: () => Navigator.pop(
                                          context, ImageSource.gallery),
                                    ),
                                    if (auth.user?.avatarUrl.isNotEmpty == true)
                                      ListTile(
                                        leading: const Icon(Icons.delete,
                                            color: Color(0xFFFF006E)),
                                        title: Text('Remove Photo',
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600)),
                                        onTap: () {
                                          setState(() =>
                                              selectedImagePath = 'removed');
                                          Navigator.pop(context);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            );

                            if (source != null) {
                              final XFile? image =
                                  await picker.pickImage(source: source);
                              if (image != null) {
                                setState(() => selectedImagePath = image.path);
                              }
                            }
                          },
                          child: Stack(
                            children: [
                              _buildAvatarPreview(
                                  auth, selectedImagePath, setState),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3A86FF),
                                        Color(0xFF8338EC)
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF3A86FF)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Name Input
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle:
                                GoogleFonts.inter(color: Colors.black54),
                            hintText: 'Enter your full name',
                            hintStyle: GoogleFonts.inter(fontSize: 14),
                            prefixIcon: const Icon(Icons.person_outline,
                                color: Color(0xFF3A86FF)),
                            filled: true,
                            fillColor: const Color(0xFFF0F4FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF3A86FF), width: 2),
                            ),
                          ),
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),

                        // Info box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    const Color(0xFF3A86FF).withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Color(0xFF3A86FF), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your profile will be updated immediately',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3A86FF),
                                      Color(0xFF8338EC)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3A86FF)
                                          .withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      final newName =
                                          nameController.text.trim();
                                      if (newName.isEmpty) {
                                        CustomNotification.show(
                                          context,
                                          message: 'Please enter your name',
                                          type: NotificationType.error,
                                          title: 'Invalid Input',
                                        );
                                        return;
                                      }

                                      // Determine the avatar URL to save
                                      String avatarToSave;
                                      if (selectedImagePath == 'removed') {
                                        avatarToSave = '';
                                      } else if (selectedImagePath != null) {
                                        avatarToSave = selectedImagePath!;
                                      } else {
                                        avatarToSave =
                                            auth.user?.avatarUrl ?? '';
                                      }

                                      // Update profile
                                      auth.updateProfile(
                                        name: newName,
                                        avatarUrl: avatarToSave,
                                      );

                                      Navigator.pop(context);

                                      CustomNotification.show(
                                        context,
                                        message: 'Profile updated successfully',
                                        type: NotificationType.success,
                                        title: 'Success',
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.check_circle_outline,
                                              color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Save Changes',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (textColor ?? const Color(0xFF3A86FF)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: textColor ?? const Color(0xFF3A86FF), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onToggle});

  final DeviceSyncItem device; // Changed from HealthDevice to DeviceSyncItem
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: device.connected
                  ? const Color(0xFF3A86FF).withOpacity(0.1)
                  : Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getDeviceIcon(device.name),
              color:
                  device.connected ? const Color(0xFF3A86FF) : Colors.black38,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(device.connected ? 'Connected • Syncing' : 'Not connected',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: device.connected
                            ? const Color(0xFF2E7D32)
                            : Colors.black54)),
              ],
            ),
          ),
          Switch(
            value: device.connected,
            onChanged: (_) => onToggle(),
            activeColor: const Color(0xFF3A86FF),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String name) {
    if (name.toLowerCase().contains('watch')) return Icons.watch;
    if (name.toLowerCase().contains('ring')) return Icons.circle_outlined;
    if (name.toLowerCase().contains('phone')) return Icons.phone_iphone;
    if (name.toLowerCase().contains('web')) return Icons.computer;
    return Icons.device_unknown;
  }
}

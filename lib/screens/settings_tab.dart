import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:characters/characters.dart';
import '../controllers/auth_controller.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/common_widgets.dart';
import '../widgets/notification_widget.dart';
import '../models/activity_models.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Consumer<HealthDataController>(
      builder: (context, data, _) {
        final profile = auth.user;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          children: [
            // Profile Section
            SectionCard(
              title: 'Profile',
              child: Row(children: [
                Stack(
                  children: [
                    CircleAvatar(
                        radius: 40,
                        backgroundImage: profile?.avatarUrl.isNotEmpty == true
                            ? NetworkImage(profile!.avatarUrl)
                            : null,
                        child: profile?.avatarUrl.isNotEmpty == true
                            ? null
                            : Text(profile?.name.characters.first ?? 'A',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28))),
                    Positioned(
                      bottom: 0,
                      right: 0,
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
                      ]),
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
                    onTap: () {},
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
            SectionCard(
              title: 'Connected Devices',
              trailing: Text(
                  '${data.devices.where((d) => d.connected).length} connected',
                  style:
                      GoogleFonts.inter(color: Colors.black54, fontSize: 12)),
              child: Column(
                children: data.devices.map((device) {
                  return _DeviceTile(
                    device: device,
                    onToggle: () => data.toggleDevice(device),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            // Preferences
            SectionCard(
              title: 'Preferences',
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle:
                        '${data.reminders.where((r) => r.enabled).length} active reminders',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Appearance',
                    subtitle: 'Light mode',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English (US)',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.accessibility_new,
                    title: 'Accessibility',
                    subtitle: 'Screen reader & text size',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Data & Storage

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
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onToggle});

  final device;
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

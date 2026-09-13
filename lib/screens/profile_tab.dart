import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/health_data_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/user_profile.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF006E),
            ),
            child: Text('Sign Out',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final auth = Provider.of<AuthController>(context, listen: false);
      await auth.signOut();
    }
  }

  void _showEditProfileSheet(
      BuildContext context, AuthController auth, HealthDataController data) {
    final profile = auth.user ?? data.profile;
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileModal(
        initialProfile: profile,
        onSave: (updated) async {
          await auth.saveFullProfile(updated, data);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Profile updated successfully!',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: const Color(0xFF2EC4B6),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthController, HealthDataController>(
      builder: (context, auth, data, _) {
        final profile = auth.user ?? data.profile;
        final isComplete = profile?.isComplete ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F7FB),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3A86FF).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          profile?.name.isNotEmpty == true
                              ? profile!.name.substring(0, 1).toUpperCase()
                              : 'U',
                          style: GoogleFonts.inter(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF3A86FF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile?.name ?? 'User',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.email ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Complete Profile Banner (if missing required fields)
              if (!isComplete)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFBE0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFBE0B).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFBE0B).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFD48B00),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Your Profile',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Add age, height, and weight for accurate personalized health scoring.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            _showEditProfileSheet(context, auth, data),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A86FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Set Up',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Demographics Summary Card
              _buildSectionTitle('Biometric Demographics'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBiometricStat(
                          'Age',
                          profile?.age != null ? '${profile!.age} yrs' : '—',
                          Icons.cake_outlined,
                        ),
                        _buildBiometricStat(
                          'Sex',
                          profile?.sex != null
                              ? profile!.sex![0].toUpperCase() +
                                  profile.sex!.substring(1)
                              : '—',
                          Icons.person_outline,
                        ),
                        _buildBiometricStat(
                          'Height',
                          profile?.heightCm != null
                              ? '${profile!.heightCm!.round()} cm'
                              : '—',
                          Icons.height,
                        ),
                        _buildBiometricStat(
                          'Weight',
                          profile?.weightKg != null
                              ? '${profile!.weightKg!.round()} kg'
                              : '—',
                          Icons.monitor_weight_outlined,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BMI',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile?.bmi != null
                                  ? profile!.bmi!.toStringAsFixed(1)
                                  : '—',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF3A86FF),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2EC4B6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            profile?.bmiCategory ?? 'Not calculated',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2EC4B6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Gamification Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Streak',
                      '${data.streakDays}',
                      Icons.local_fire_department,
                      const Color(0xFFFF006E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Points',
                      '${data.rewardPoints}',
                      Icons.stars,
                      const Color(0xFFFFBE0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Settings
              _buildSectionTitle('Settings'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.person, color: Color(0xFF3A86FF)),
                      title: Text('Edit Profile & Goals',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Demographics, target calories, water & sleep',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.black45),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showEditProfileSheet(context, auth, data),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications,
                          color: Color(0xFF8338EC)),
                      title: Text('Notifications',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip,
                          color: Color(0xFF2EC4B6)),
                      title: Text('Privacy',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.logout, color: Color(0xFFFF006E)),
                      title: Text('Sign Out',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      onTap: () => _handleSignOut(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Version
              Center(
                child: Text(
                  'Aurora Wellness v1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBiometricStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF3A86FF)),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }
}

class _EditProfileModal extends StatefulWidget {
  final UserProfile initialProfile;
  final ValueChanged<UserProfile> onSave;

  const _EditProfileModal({
    required this.initialProfile,
    required this.onSave,
  });

  @override
  State<_EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<_EditProfileModal> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _stepGoalController;
  late TextEditingController _waterGoalController;
  late TextEditingController _calorieGoalController;
  late TextEditingController _sleepGoalController;

  String? _selectedSex;
  String? _selectedActivity;
  String? _selectedGoal;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameController = TextEditingController(text: p.name);
    _ageController =
        TextEditingController(text: p.age != null ? '${p.age}' : '');
    _heightController = TextEditingController(
        text: p.heightCm != null ? '${p.heightCm!.round()}' : '');
    _weightController = TextEditingController(
        text: p.weightKg != null ? '${p.weightKg!.round()}' : '');
    _stepGoalController = TextEditingController(text: '${p.stepGoal}');
    _waterGoalController = TextEditingController(text: '${p.waterGoalMl}');
    _calorieGoalController =
        TextEditingController(text: '${p.calorieGoal.round()}');
    _sleepGoalController =
        TextEditingController(text: p.sleepGoalHours.toStringAsFixed(1));

    _selectedSex = p.sex;
    _selectedActivity = p.activityLevel ?? 'moderately_active';
    _selectedGoal = p.fitnessGoal ?? 'maintain';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _stepGoalController.dispose();
    _waterGoalController.dispose();
    _calorieGoalController.dispose();
    _sleepGoalController.dispose();
    super.dispose();
  }

  void _save() {
    final age = int.tryParse(_ageController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final stepGoal = int.tryParse(_stepGoalController.text.trim()) ?? 10000;
    final waterGoal = int.tryParse(_waterGoalController.text.trim()) ?? 2500;
    final calorieGoal =
        double.tryParse(_calorieGoalController.text.trim()) ?? 2000;
    final sleepGoal =
        double.tryParse(_sleepGoalController.text.trim()) ?? 8.0;

    final updated = widget.initialProfile.copyWith(
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : widget.initialProfile.name,
      age: age,
      sex: _selectedSex,
      heightCm: height,
      weightKg: weight,
      activityLevel: _selectedActivity,
      fitnessGoal: _selectedGoal,
      stepGoal: stepGoal,
      waterGoalMl: waterGoal,
      calorieGoal: calorieGoal,
      sleepGoalHours: sleepGoal,
    );

    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Health Profile',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSectionHeader('Personal Information'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Display Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _ageController,
                          label: 'Age',
                          icon: Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSexSelector(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Body Composition'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _heightController,
                          label: 'Height (cm)',
                          icon: Icons.height,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _weightController,
                          label: 'Weight (kg)',
                          icon: Icons.monitor_weight_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Activity Level'),
                  const SizedBox(height: 12),
                  _buildActivitySelector(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Fitness Goal'),
                  const SizedBox(height: 12),
                  _buildGoalSelector(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Daily Target Goals'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _stepGoalController,
                          label: 'Steps Goal',
                          icon: Icons.directions_walk,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _waterGoalController,
                          label: 'Water (ml)',
                          icon: Icons.water_drop_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _calorieGoalController,
                          label: 'Calories (kcal)',
                          icon: Icons.local_fire_department_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _sleepGoalController,
                          label: 'Sleep (hours)',
                          icon: Icons.bedtime_outlined,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A86FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Profile',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF3A86FF),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF3A86FF)),
        filled: true,
        fillColor: const Color(0xFFF7F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildSexSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedSex,
      style: GoogleFonts.inter(
          color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Sex',
        labelStyle: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
        prefixIcon: const Icon(Icons.person, size: 20, color: Color(0xFF3A86FF)),
        filled: true,
        fillColor: const Color(0xFFF7F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ],
      onChanged: (val) => setState(() => _selectedSex = val),
    );
  }

  Widget _buildActivitySelector() {
    final levels = [
      {'value': 'sedentary', 'label': 'Sedentary', 'sub': 'Little to no exercise'},
      {
        'value': 'lightly_active',
        'label': 'Lightly Active',
        'sub': '1–3 days/week'
      },
      {
        'value': 'moderately_active',
        'label': 'Moderately Active',
        'sub': '3–5 days/week'
      },
      {
        'value': 'very_active',
        'label': 'Very Active',
        'sub': '6–7 hard days/week'
      },
    ];

    return Column(
      children: levels.map((lvl) {
        final isSelected = _selectedActivity == lvl['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedActivity = lvl['value']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3A86FF).withValues(alpha: 0.1)
                  : const Color(0xFFF7F7FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3A86FF)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? const Color(0xFF3A86FF) : Colors.black26,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lvl['label']!,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      lvl['sub']!,
                      style: GoogleFonts.inter(
                        color: Colors.black45,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalSelector() {
    final goals = [
      {'value': 'maintain', 'label': 'Maintain Current Weight'},
      {'value': 'lose_weight', 'label': 'Lose Weight (Deficit)'},
      {'value': 'gain_weight', 'label': 'Gain Weight / Build Muscle'},
      {'value': 'improve_fitness', 'label': 'Improve Overall Fitness & Energy'},
    ];

    return Column(
      children: goals.map((g) {
        final isSelected = _selectedGoal == g['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedGoal = g['value']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF8338EC).withValues(alpha: 0.1)
                  : const Color(0xFFF7F7FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF8338EC)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? const Color(0xFF8338EC) : Colors.black26,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  g['label']!,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

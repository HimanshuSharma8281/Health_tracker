import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/health_data_controller.dart';
import '../models/user_profile.dart';

class HealthOnboardingScreen extends StatefulWidget {
  const HealthOnboardingScreen({super.key});

  @override
  State<HealthOnboardingScreen> createState() => _HealthOnboardingScreenState();
}

class _HealthOnboardingScreenState extends State<HealthOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedSex = 'male';
  String _selectedActivityLevel = 'moderately_active';
  String _selectedFitnessGoal = 'maintain';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthController>(context, listen: false);
    if (auth.user != null) {
      if (auth.user!.name.isNotEmpty && auth.user!.name != 'User') {
        _nameController.text = auth.user!.name;
      }
      if (auth.user!.age != null) {
        _ageController.text = auth.user!.age.toString();
      }
      if (auth.user!.sex != null && auth.user!.sex!.isNotEmpty) {
        _selectedSex = auth.user!.sex!;
      }
      if (auth.user!.heightCm != null) {
        _heightController.text = auth.user!.heightCm!.toStringAsFixed(0);
      }
      if (auth.user!.weightKg != null) {
        _weightController.text = auth.user!.weightKg!.toStringAsFixed(0);
      }
      if (auth.user!.activityLevel != null) {
        _selectedActivityLevel = auth.user!.activityLevel!;
      }
      if (auth.user!.fitnessGoal != null) {
        _selectedFitnessGoal = auth.user!.fitnessGoal!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// Deterministic clinical calculation for baseline daily goals.
  ({int stepGoal, int waterGoalMl, double calorieGoal, double sleepGoalHours})
      _calculateBaselineGoals({
    required int age,
    required String sex,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String fitnessGoal,
  }) {
    // 1. Calorie Goal via Mifflin-St Jeor
    double bmr;
    if (sex == 'male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }

    double activityMult = 1.2;
    switch (activityLevel) {
      case 'lightly_active':
        activityMult = 1.375;
        break;
      case 'moderately_active':
        activityMult = 1.55;
        break;
      case 'very_active':
        activityMult = 1.725;
        break;
      default:
        activityMult = 1.2;
    }

    double tdee = bmr * activityMult;
    switch (fitnessGoal) {
      case 'lose_weight':
        tdee *= 0.80; // 20% deficit
        break;
      case 'gain_weight':
        tdee *= 1.10; // 10% surplus
        break;
      default:
        break;
    }
    final calorieGoal = max(1200.0, tdee.roundToDouble());

    // 2. Water Goal: 35ml/kg * multiplier
    double waterMult = 1.0;
    switch (activityLevel) {
      case 'lightly_active':
        waterMult = 1.1;
        break;
      case 'moderately_active':
        waterMult = 1.2;
        break;
      case 'very_active':
        waterMult = 1.4;
        break;
      default:
        waterMult = 1.0;
    }
    final waterGoalMl = (weightKg * 35.0 * waterMult).round().clamp(1500, 5000);

    // 3. Step Goal
    int stepGoal = 10000;
    switch (activityLevel) {
      case 'sedentary':
        stepGoal = 6000;
        break;
      case 'lightly_active':
        stepGoal = 8000;
        break;
      case 'moderately_active':
        stepGoal = 10000;
        break;
      case 'very_active':
        stepGoal = 12500;
        break;
    }

    // 4. Sleep Goal
    const sleepGoalHours = 8.0;

    return (
      stepGoal: stepGoal,
      waterGoalMl: waterGoalMl,
      calorieGoal: calorieGoal,
      sleepGoalHours: sleepGoalHours,
    );
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final healthData =
          Provider.of<HealthDataController>(context, listen: false);

      final current = auth.user;
      final uid = current?.uid ?? '';
      final email = current?.email ?? '';
      final name = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : (current?.name ?? 'User');

      final age = int.parse(_ageController.text.trim());
      final heightCm = double.parse(_heightController.text.trim());
      final weightKg = double.parse(_weightController.text.trim());

      final goals = _calculateBaselineGoals(
        age: age,
        sex: _selectedSex,
        heightCm: heightCm,
        weightKg: weightKg,
        activityLevel: _selectedActivityLevel,
        fitnessGoal: _selectedFitnessGoal,
      );

      final updatedProfile = UserProfile(
        uid: uid,
        name: name,
        email: email,
        avatarUrl: current?.avatarUrl ?? '',
        devices: current?.devices ?? const [],
        age: age,
        sex: _selectedSex,
        heightCm: heightCm,
        weightKg: weightKg,
        activityLevel: _selectedActivityLevel,
        fitnessGoal: _selectedFitnessGoal,
        stepGoal: goals.stepGoal,
        waterGoalMl: goals.waterGoalMl,
        calorieGoal: goals.calorieGoal,
        sleepGoalHours: goals.sleepGoalHours,
      );

      debugPrint('🔒 [AUTH] Saving completed onboarding health profile for uid=$uid');
      await auth.saveFullProfile(updatedProfile, healthData);

      debugPrint('✅ [AUTH] Onboarding profile saved successfully: isComplete=${updatedProfile.isComplete}');
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('🔴 [AUTH] Failed to save onboarding profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save health profile: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFFF5C7A),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D10),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF090D10),
          gradient: RadialGradient(
            center: Alignment(0.0, -0.4),
            radius: 1.4,
            colors: [
              Color(0xFF131D24),
              Color(0xFF090D10),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Basic Details Card
                  _buildSectionCard(
                    title: 'Personal Info',
                    icon: Icons.person_rounded,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'e.g. Himanshu Sharma',
                        icon: Icons.badge_outlined,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please enter your name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _ageController,
                              label: 'Age',
                              hint: '25',
                              icon: Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n < 10 || n > 120) {
                                  return 'Valid age';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Sex',
                              value: _selectedSex,
                              items: const [
                                DropdownMenuItem(
                                    value: 'male', child: Text('Male')),
                                DropdownMenuItem(
                                    value: 'female', child: Text('Female')),
                                DropdownMenuItem(
                                    value: 'other', child: Text('Other')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedSex = v);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Body Measurements Card
                  _buildSectionCard(
                    title: 'Body Measurements',
                    icon: Icons.straighten_rounded,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _heightController,
                              label: 'Height (cm)',
                              hint: '175',
                              icon: Icons.height_rounded,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                if (n == null || n < 50 || n > 260) {
                                  return 'Valid height';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _weightController,
                              label: 'Weight (kg)',
                              hint: '70',
                              icon: Icons.monitor_weight_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                if (n == null || n < 20 || n > 350) {
                                  return 'Valid weight';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Lifestyle & Goals Card
                  _buildSectionCard(
                    title: 'Lifestyle & Fitness Goal',
                    icon: Icons.fitness_center_rounded,
                    children: [
                      _buildDropdown(
                        label: 'Activity Level',
                        value: _selectedActivityLevel,
                        items: const [
                          DropdownMenuItem(
                            value: 'sedentary',
                            child: Text(
                              'Sedentary (Little/no exercise)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'lightly_active',
                            child: Text(
                              'Lightly Active (1–3 days/wk)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'moderately_active',
                            child: Text(
                              'Moderately Active (3–5 days/wk)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'very_active',
                            child: Text(
                              'Very Active (6–7 days/wk)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedActivityLevel = v);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildDropdown(
                        label: 'Fitness Goal',
                        value: _selectedFitnessGoal,
                        items: const [
                          DropdownMenuItem(
                            value: 'maintain',
                            child: Text(
                              'Maintain Weight & Vitality',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'lose_weight',
                            child: Text(
                              'Lose Weight (Caloric Deficit)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'gain_weight',
                            child: Text(
                              'Gain Muscle / Weight',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'improve_fitness',
                            child: Text(
                              'Improve Stamina & Health',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedFitnessGoal = v);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // Complete Setup Button
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF48E5C2),
                          Color(0xFF3A86FF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF48E5C2).withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSaving ? null : _handleSaveProfile,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF090D10),
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.health_and_safety_rounded,
                                      color: Color(0xFF090D10),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Complete Health Setup',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF090D10),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Text(
                        'Skip for now',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1C2731),
                Color(0xFF11171E),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF48E5C2).withValues(alpha: 0.25),
                blurRadius: 26,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF48E5C2),
                  Color(0xFF3A86FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Icon(
                Icons.monitor_heart_rounded,
                size: 34,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Health Profile Setup',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Personalize your clinical health telemetry & targets',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xE6141A22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF48E5C2), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF48E5C2), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF48E5C2), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFFF5C7A), width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF141A22),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.white54,
        size: 22,
      ),
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF48E5C2), width: 1.5),
        ),
      ),
    );
  }
}

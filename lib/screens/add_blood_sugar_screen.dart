import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/glass_container.dart';

class AddBloodSugarScreen extends StatefulWidget {
  const AddBloodSugarScreen({super.key});

  @override
  State<AddBloodSugarScreen> createState() => _AddBloodSugarScreenState();
}

class _AddBloodSugarScreenState extends State<AddBloodSugarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDateTime = DateTime.now();
  String _selectedState = 'Default';
  bool _isMmol = true;
  double _sliderValue = 4.4;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  static const Color _bgCharcoal = Color(0xFF090D10);
  static const Color _ambientRuby = Color(0xFF220D12);
  static const Color _sugarCoral = Color(0xFFFF5C7A);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getStatus() {
    if (_isMmol) {
      switch (_selectedState) {
        case 'Fasting':
          if (_sliderValue < 3.9) return 'Low';
          if (_sliderValue <= 5.6) return 'Normal';
          if (_sliderValue <= 6.9) return 'Prediabetes';
          return 'High';
        case 'After Meal':
          if (_sliderValue < 3.9) return 'Low';
          if (_sliderValue <= 7.8) return 'Normal';
          if (_sliderValue <= 11.0) return 'Prediabetes';
          return 'High';
        case 'Before Bed':
          if (_sliderValue < 4.0) return 'Low';
          if (_sliderValue <= 7.0) return 'Normal';
          if (_sliderValue <= 8.5) return 'Elevated';
          return 'High';
        default:
          if (_sliderValue < 3.9) return 'Low';
          if (_sliderValue <= 7.8) return 'Normal';
          if (_sliderValue <= 11.0) return 'Elevated';
          return 'High';
      }
    } else {
      switch (_selectedState) {
        case 'Fasting':
          if (_sliderValue < 70) return 'Low';
          if (_sliderValue <= 100) return 'Normal';
          if (_sliderValue <= 125) return 'Prediabetes';
          return 'High';
        case 'After Meal':
          if (_sliderValue < 70) return 'Low';
          if (_sliderValue <= 140) return 'Normal';
          if (_sliderValue <= 199) return 'Prediabetes';
          return 'High';
        case 'Before Bed':
          if (_sliderValue < 72) return 'Low';
          if (_sliderValue <= 126) return 'Normal';
          if (_sliderValue <= 153) return 'Elevated';
          return 'High';
        default:
          if (_sliderValue < 70) return 'Low';
          if (_sliderValue <= 140) return 'Normal';
          if (_sliderValue <= 199) return 'Elevated';
          return 'High';
      }
    }
  }

  Color _getStatusColor() {
    final status = _getStatus();
    switch (status) {
      case 'Low':
        return const Color(0xFF5CE1E6);
      case 'Normal':
        return const Color(0xFF2EC4B6);
      case 'Prediabetes':
      case 'Elevated':
        return const Color(0xFFFFBE0B);
      case 'High':
        return const Color(0xFFFF5C7A);
      default:
        return const Color(0xFF2EC4B6);
    }
  }

  String _getRangeText() {
    if (_isMmol) {
      switch (_selectedState) {
        case 'Fasting':
          final status = _getStatus();
          switch (status) {
            case 'Low':
              return '< 3.9 mmol/L';
            case 'Normal':
              return '3.9 - 5.6 mmol/L';
            case 'Prediabetes':
              return '5.7 - 6.9 mmol/L';
            case 'High':
              return '≥ 7.0 mmol/L';
            default:
              return '3.9 - 5.6 mmol/L';
          }
        case 'After Meal':
          final status = _getStatus();
          switch (status) {
            case 'Low':
              return '< 3.9 mmol/L';
            case 'Normal':
              return '< 7.8 mmol/L';
            case 'Prediabetes':
              return '7.8 - 11.0 mmol/L';
            case 'High':
              return '≥ 11.1 mmol/L';
            default:
              return '< 7.8 mmol/L';
          }
        case 'Before Bed':
          final status = _getStatus();
          switch (status) {
            case 'Low':
              return '< 4.0 mmol/L';
            case 'Normal':
              return '4.0 - 7.0 mmol/L';
            case 'Elevated':
              return '7.1 - 8.5 mmol/L';
            case 'High':
              return '> 8.5 mmol/L';
            default:
              return '4.0 - 7.0 mmol/L';
          }
        default:
          final status = _getStatus();
          switch (status) {
            case 'Low':
              return '< 3.9 mmol/L';
            case 'Normal':
              return '< 7.8 mmol/L';
            case 'Elevated':
              return '7.8 - 11.0 mmol/L';
            case 'High':
              return '≥ 11.1 mmol/L';
            default:
              return '< 7.8 mmol/L';
          }
      }
    } else {
      switch (_selectedState) {
        case 'Fasting':
          final status = _getStatus();
          switch (status) {
            case 'Low':
              return '< 70 mg/dL';
            case 'Normal':
              return '70 - 100 mg/dL';
            case 'Prediabetes':
              return '101 - 125 mg/dL';
            case 'High':
              return '≥ 126 mg/dL';
            default:
              return '70 - 100 mg/dL';
          }
        case 'After Meal':
          final status = _getStatus();
          switch (status) {
            case 'Low':
              return '< 70 mg/dL';
            case 'Normal':
              return '< 140 mg/dL';
            case 'Prediabetes':
              return '140 - 199 mg/dL';
            case 'High':
              return '≥ 200 mg/dL';
            default:
              return '< 140 mg/dL';
          }
        case 'Before Bed':
          final status = _getStatus();
          switch (status) {
            case 'Low':
              return '< 72 mg/dL';
            case 'Normal':
              return '72 - 126 mg/dL';
            case 'Elevated':
              return '127 - 153 mg/dL';
            case 'High':
              return '> 153 mg/dL';
            default:
              return '72 - 126 mg/dL';
          }
        default:
          final status = _getStatus();
          switch (status) {
            case 'Low':
              return '< 70 mg/dL';
            case 'Normal':
              return '< 140 mg/dL';
            case 'Elevated':
              return '140 - 199 mg/dL';
            case 'High':
              return '≥ 200 mg/dL';
            default:
              return '< 140 mg/dL';
          }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCharcoal,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.25,
            colors: [_ambientRuby, _bgCharcoal],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Date & Time Card
                    _buildConfigCard(
                      icon: Icons.calendar_today_rounded,
                      title: 'Date & Time',
                      trailingText: DateFormat('MMM dd, yyyy • HH:mm').format(_selectedDateTime),
                      onTap: _pickDateTime,
                    ),
                    const SizedBox(height: 12),

                    // State Card
                    _buildConfigCard(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'Measurement State',
                      trailingText: _selectedState,
                      onTap: _selectState,
                    ),
                    const SizedBox(height: 28),

                    // Unit Toggle
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildUnitButton('mg/dL', !_isMmol),
                            _buildUnitButton('mmol/L', _isMmol),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Large Reading Display with Animation
                    Center(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: [
                            Text(
                              _isMmol
                                  ? _sliderValue.toStringAsFixed(1)
                                  : _sliderValue.toStringAsFixed(0),
                              style: GoogleFonts.inter(
                                fontSize: 80,
                                fontWeight: FontWeight.w900,
                                color: _getStatusColor(),
                                height: 1,
                                letterSpacing: -2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isMmol ? 'mmol/L' : 'mg/dL',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Slider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _getStatusColor(),
                              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 26),
                              trackHeight: 6,
                              overlayColor: _getStatusColor().withValues(alpha: 0.25),
                            ),
                            child: Slider(
                              value: _sliderValue,
                              min: _isMmol ? 2.0 : 40,
                              max: _isMmol ? 15.0 : 270,
                              divisions: _isMmol ? 130 : 230,
                              onChanged: (value) {
                                setState(() => _sliderValue = value);
                                _animationController.forward().then((_) {
                                  _animationController.reverse();
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: (_isMmol ? _getSliderLabels() : _getSliderLabelsMgDl())
                                  .map((label) => Text(
                                        label,
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withValues(alpha: 0.35),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Status Display Badge
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _getStatusColor().withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              _getStatus(),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _getStatusColor(),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _getRangeText(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _sugarCoral,
                  boxShadow: [
                    BoxShadow(
                      color: _sugarCoral,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'RECORD GLUCOSE',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _saveReading,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _sugarCoral.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _sugarCoral.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 18,
                color: _sugarCoral,
              ),
            ),
            tooltip: 'Save',
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard({
    required IconData icon,
    required String title,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        blur: 14,
        color: const Color(0xE6141A20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _sugarCoral, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              trailingText,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _sugarCoral,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          final wasMmol = _isMmol;
          _isMmol = label == 'mmol/L';

          if (wasMmol && !_isMmol) {
            _sliderValue = (_sliderValue * 18.0).clamp(40.0, 270.0);
          } else if (!wasMmol && _isMmol) {
            _sliderValue = (_sliderValue / 18.0).clamp(2.0, 15.0);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _sugarCoral : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _sugarCoral.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  List<String> _getSliderLabels() {
    switch (_selectedState) {
      case 'Fasting':
        return ['2.0', '3.9', '5.6', '6.9', '15.0'];
      case 'After Meal':
        return ['2.0', '3.9', '7.8', '11.0', '15.0'];
      case 'Before Bed':
        return ['2.0', '4.0', '7.0', '8.5', '15.0'];
      default:
        return ['2.0', '3.9', '7.8', '11.0', '15.0'];
    }
  }

  List<String> _getSliderLabelsMgDl() {
    switch (_selectedState) {
      case 'Fasting':
        return ['40', '70', '100', '125', '270'];
      case 'After Meal':
        return ['40', '70', '140', '199', '270'];
      case 'Before Bed':
        return ['40', '72', '126', '153', '270'];
      default:
        return ['40', '70', '140', '199', '270'];
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _selectState() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141A22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0x33FF5C7A), width: 1.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Select Measurement State',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            ...['Default', 'Fasting', 'After Meal', 'Before Bed'].map(
              (state) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                title: Text(
                  state,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: _selectedState == state ? FontWeight.w700 : FontWeight.w500,
                    color: _selectedState == state ? _sugarCoral : Colors.white70,
                  ),
                ),
                trailing: _selectedState == state
                    ? const Icon(Icons.check_circle_rounded, color: _sugarCoral, size: 20)
                    : null,
                onTap: () {
                  setState(() => _selectedState = state);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveReading() {
    double valueInMgDl = _isMmol ? _sliderValue * 18.0 : _sliderValue;

    Provider.of<HealthDataController>(context, listen: false)
        .updateBloodSugar(valueInMgDl);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF2EC4B6)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Blood sugar recorded: ${_isMmol ? _sliderValue.toStringAsFixed(1) : _sliderValue.toStringAsFixed(0)} ${_isMmol ? 'mmol/L' : 'mg/dL'}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B232E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

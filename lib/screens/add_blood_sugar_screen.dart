import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/health_data_controller.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Get status based on blood sugar value and measurement state
  String _getStatus() {
    if (_isMmol) {
      // mmol/L ranges
      switch (_selectedState) {
        case 'Fasting':
          if (_sliderValue < 3.9) return 'Low';
          if (_sliderValue <= 5.6) return 'Normal';
          if (_sliderValue <= 6.9) return 'Prediabetes';
          return 'High';
        case 'After Meal':
          // 2 hours after eating
          if (_sliderValue < 3.9) return 'Low';
          if (_sliderValue <= 7.8) return 'Normal';
          if (_sliderValue <= 11.0) return 'Prediabetes';
          return 'High';
        case 'Before Bed':
          if (_sliderValue < 4.0) return 'Low';
          if (_sliderValue <= 7.0) return 'Normal';
          if (_sliderValue <= 8.5) return 'Elevated';
          return 'High';
        default: // Default/Random
          if (_sliderValue < 3.9) return 'Low';
          if (_sliderValue <= 7.8) return 'Normal';
          if (_sliderValue <= 11.0) return 'Elevated';
          return 'High';
      }
    } else {
      // mg/dL ranges
      switch (_selectedState) {
        case 'Fasting':
          if (_sliderValue < 70) return 'Low';
          if (_sliderValue <= 100) return 'Normal';
          if (_sliderValue <= 125) return 'Prediabetes';
          return 'High';
        case 'After Meal':
          // 2 hours after eating
          if (_sliderValue < 70) return 'Low';
          if (_sliderValue <= 140) return 'Normal';
          if (_sliderValue <= 199) return 'Prediabetes';
          return 'High';
        case 'Before Bed':
          if (_sliderValue < 72) return 'Low';
          if (_sliderValue <= 126) return 'Normal';
          if (_sliderValue <= 153) return 'Elevated';
          return 'High';
        default: // Default/Random
          if (_sliderValue < 70) return 'Low';
          if (_sliderValue <= 140) return 'Normal';
          if (_sliderValue <= 199) return 'Elevated';
          return 'High';
      }
    }
  }

  // Get status color
  Color _getStatusColor() {
    final status = _getStatus();
    switch (status) {
      case 'Low':
        return const Color(0xFF2196F3); // Blue
      case 'Normal':
        return const Color(0xFF4CAF50); // Green
      case 'Prediabetes':
      case 'Elevated':
        return const Color(0xFFFF9800); // Orange
      case 'High':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF4CAF50);
    }
  }

  // Get range text based on status and measurement state
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
        default: // Default/Random
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
      // mg/dL ranges
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
        default: // Default/Random
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Blood Sugar Record',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _saveReading,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Date & Time Card
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: _buildCard(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                title: Text(
                  'Date & Time',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm')
                          .format(_selectedDateTime),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right,
                        color: Color(0xFF4CAF50), size: 20),
                  ],
                ),
                onTap: _pickDateTime,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // State Card
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: _buildCard(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                title: Text(
                  'Measurement State',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedState,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFFFF9800),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star,
                              color: Color(0xFFFF9800), size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right,
                        color: Colors.black45, size: 20),
                  ],
                ),
                onTap: _selectState,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Unit Toggle
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
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
          const SizedBox(height: 48),

          // Large Reading Display with Animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Center(
              key: ValueKey<String>('${_sliderValue}_${_isMmol}'),
              child: Text(
                _isMmol
                    ? _sliderValue.toStringAsFixed(1)
                    : _sliderValue.toStringAsFixed(0),
                style: GoogleFonts.poppins(
                  fontSize: 92,
                  fontWeight: FontWeight.w800,
                  color: _getStatusColor(),
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _getStatusColor(),
                    inactiveTrackColor: Colors.grey[200],
                    thumbColor: Colors.white,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 16),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 28),
                    trackHeight: 8,
                    overlayColor: _getStatusColor().withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _sliderValue,
                    min: _isMmol ? 2.0 : 40,
                    max: _isMmol ? 15.0 : 270,
                    divisions: _isMmol ? 130 : 230,
                    onChanged: (value) {
                      setState(() {
                        _sliderValue = value;
                      });
                      _animationController.forward().then((_) {
                        _animationController.reverse();
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        (_isMmol ? _getSliderLabels() : _getSliderLabelsMgDl())
                            .map((label) => Text(
                                  label,
                                  style: GoogleFonts.inter(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ))
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Status Display with Animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Center(
              key: ValueKey<String>(_getStatus()),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _getStatus(),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _getStatusColor(),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getRangeText(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Note Icon with Animation
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  List<String> _getSliderLabels() {
    // mmol/L labels based on state
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
    // mg/dL labels based on state
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

  Widget _buildUnitButton(String label, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: InkWell(
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
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  double _getIndicatorPosition() {
    // This method is no longer needed but keeping it to avoid errors
    final min = _isMmol ? 3.0 : 50.0;
    final max = _isMmol ? 10.0 : 180.0;
    final percentage = (_sliderValue - min) / (max - min);
    final containerWidth = MediaQuery.of(context).size.width - 32;
    return (percentage * containerWidth) - 12;
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select State',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...['Default', 'Fasting', 'After Meal', 'Before Bed'].map(
              (state) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                title: Text(
                  state,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: _selectedState == state
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                trailing: _selectedState == state
                    ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50))
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
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Blood sugar reading saved: ${_isMmol ? _sliderValue.toStringAsFixed(1) : _sliderValue.toStringAsFixed(0)} ${_isMmol ? 'mmol/L' : 'mg/dL'}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

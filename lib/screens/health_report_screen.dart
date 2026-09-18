import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/glass_container.dart';
import '../services/health_report_service.dart';
import '../services/health_report_pdf_generator.dart';
import 'health_report_viewer_screen.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;
  String _selectedPreset = 'Last 30 Days';
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toDate = DateTime(now.year, now.month, now.day);
    _fromDate = _toDate.subtract(const Duration(days: 29));
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _selectedPreset = preset;
      _errorMessage = null;
      switch (preset) {
        case 'Today':
          _fromDate = today;
          _toDate = today;
          break;
        case 'Last 7 Days':
          _fromDate = today.subtract(const Duration(days: 6));
          _toDate = today;
          break;
        case 'Last 30 Days':
          _fromDate = today.subtract(const Duration(days: 29));
          _toDate = today;
          break;
        case 'This Month':
          _fromDate = DateTime(today.year, today.month, 1);
          _toDate = today;
          break;
        case 'Last 90 Days':
          _fromDate = today.subtract(const Duration(days: 89));
          _toDate = today;
          break;
      }
    });
  }

  Future<void> _selectDate({required bool isFromDate}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = isFromDate ? _fromDate : _toDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: today,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF48E5C2),
              onPrimary: Color(0xFF090D10),
              surface: Color(0xFF141A20),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF141A20),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPreset = 'Custom';
        _errorMessage = null;
        if (isFromDate) {
          _fromDate = DateTime(picked.year, picked.month, picked.day);
        } else {
          _toDate = DateTime(picked.year, picked.month, picked.day);
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (_fromDate.isAfter(_toDate)) {
      setState(() {
        _errorMessage = 'From Date cannot be after To Date. Please adjust the range.';
      });
      return;
    }

    // Ensure current Firebase authenticated user UID is used
    final auth = Provider.of<AuthController>(context, listen: false);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? auth.user?.uid;

    if (currentUid == null || currentUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please sign in to generate a personal health report.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFFF5C7A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      debugPrint('📑 [HealthReport] Compiling health report for uid=$currentUid from ${_fromDate.toIso8601String()} to ${_toDate.toIso8601String()}');
      final reportData = await HealthReportService.instance.compileReportData(
        uid: currentUid,
        fromDate: _fromDate,
        toDate: _toDate,
        profile: auth.user,
      );

      final pdfBytes = await HealthReportPdfGenerator.generate(reportData);

      if (mounted) {
        setState(() => _isGenerating = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HealthReportViewerScreen(
              reportData: reportData,
              pdfBytes: pdfBytes,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 [HealthReport] Error generating report: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Unable to generate report: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final totalDays = _toDate.isBefore(_fromDate)
        ? 0
        : _toDate.difference(_fromDate).inDays + 1;
    final isInvalidRange = _fromDate.isAfter(_toDate);

    return Scaffold(
      backgroundColor: const Color(0xFF090D10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1216),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Health PDF Report',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          // Hero Banner
          GlassContainer(
            blur: 16,
            color: const Color(0xFF141A20).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5C7A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF5C7A).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xFFFF5C7A),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Health Report',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generate and export a comprehensive, printable PDF report containing verified health metrics.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Presets Row
          Text(
            'Select Report Period',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'Today',
                'Last 7 Days',
                'Last 30 Days',
                'This Month',
                'Last 90 Days',
              ].map((preset) {
                final isSelected = _selectedPreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _applyPreset(preset),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF48E5C2).withValues(alpha: 0.2)
                            : const Color(0xFF141A20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF48E5C2)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        preset,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF48E5C2) : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Date Pickers Row
          Row(
            children: [
              Expanded(
                child: _buildDateTile(
                  label: 'From Date',
                  dateStr: dateFormat.format(_fromDate),
                  icon: Icons.calendar_today_rounded,
                  onTap: () => _selectDate(isFromDate: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTile(
                  label: 'To Date',
                  dateStr: dateFormat.format(_toDate),
                  icon: Icons.event_rounded,
                  onTap: () => _selectDate(isFromDate: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Error Banner if invalid
          if (isInvalidRange || _errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5C7A).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF5C7A).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5C7A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage ?? 'From Date cannot be after To Date.',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFFF5C7A)),
                    ),
                  ),
                ],
              ),
            ),

          // Period Summary Card
          GlassContainer(
            blur: 16,
            color: const Color(0xFF141A20).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(18),
            padding: const EdgeInsets.all(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Report Scope',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A86FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$totalDays Day${totalDays > 1 ? "s" : ""}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3A86FF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildScopeItem(Icons.verified_outlined, 'Overall Deterministic Wellness Score', const Color(0xFF48E5C2)),
                _buildScopeItem(Icons.directions_walk_rounded, 'Physical Activity & Step Logs', const Color(0xFF3A86FF)),
                _buildScopeItem(Icons.water_drop_outlined, 'Hydration & Daily Water Totals', const Color(0xFF48E5C2)),
                _buildScopeItem(Icons.bedtime_outlined, 'Sleep Duration & Nightly Logs', const Color(0xFF8338EC)),
                _buildScopeItem(Icons.restaurant_outlined, 'Calorie Intake & Meal Breakdown', const Color(0xFFFFBE0B)),
                _buildScopeItem(Icons.favorite_border_rounded, 'Cardiovascular (Heart Rate & Blood Pressure)', const Color(0xFFFF006E)),
                _buildScopeItem(Icons.bloodtype_outlined, 'Metabolic (Blood Sugar / Glycemia)', const Color(0xFFFF5C7A)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Generate CTA Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_isGenerating || isInvalidRange) ? null : _generateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF48E5C2),
                foregroundColor: const Color(0xFF090D10),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                disabledForegroundColor: Colors.white30,
                elevation: 4,
                shadowColor: const Color(0xFF48E5C2).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF090D10),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Generating Report...',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    )
                  : Text(
                      'Generate Health Report',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required String dateStr,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141A20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF48E5C2), size: 14),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeItem(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

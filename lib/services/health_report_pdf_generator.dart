import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'health_report_service.dart';
import '../models/health_reading.dart';
import '../models/activity_models.dart';
import '../controllers/health_data_controller.dart';

class HealthReportPdfGenerator {
  HealthReportPdfGenerator._();

  // Color Palette
  static final PdfColor primaryNavy = PdfColor.fromHex('#0F172A');
  static final PdfColor secondaryBlue = PdfColor.fromHex('#1E40AF');
  static final PdfColor tealAccent = PdfColor.fromHex('#0D9488');
  static final PdfColor slateDark = PdfColor.fromHex('#334155');
  static final PdfColor slateMuted = PdfColor.fromHex('#64748B');
  static final PdfColor slateLight = PdfColor.fromHex('#F8FAFC');
  static final PdfColor slateBorder = PdfColor.fromHex('#E2E8F0');
  static final PdfColor successGreen = PdfColor.fromHex('#10B981');
  static final PdfColor warningAmber = PdfColor.fromHex('#F59E0B');
  static final PdfColor dangerRose = PdfColor.fromHex('#EF4444');

  /// Generates the full PDF byte array from [HealthReportData].
  static Future<Uint8List> generate(HealthReportData data) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final fromStr = dateFormat.format(data.fromDate);
    final toStr = dateFormat.format(data.toDate);
    final genStr = timeFormat.format(data.generatedAt);
    final userName = data.profile?.name ?? 'Aurora User';
    final userEmail = data.profile?.email ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => _buildHeader(
          fromStr: fromStr,
          toStr: toStr,
          userName: userName,
          userEmail: userEmail,
          genStr: genStr,
          data: data,
        ),
        footer: (pw.Context context) => _buildFooter(context),
        build: (pw.Context context) {
          if (!data.hasAnyData) {
            return [
              _buildEmptyReportNotice(fromStr, toStr),
            ];
          }

          return [
            pw.SizedBox(height: 12),

            // Executive Summary & Wellness Score
            _buildExecutiveSummary(data),
            pw.SizedBox(height: 16),

            // Metrics Highlights Grid
            _buildQuickHighlights(data),
            pw.SizedBox(height: 18),

            // 1. Physical Activity / Steps
            _buildSectionHeader('1. Physical Activity & Steps', secondaryBlue),
            _buildStepsSection(data),
            pw.SizedBox(height: 18),

            // 2. Hydration
            _buildSectionHeader('2. Hydration & Water Intake', tealAccent),
            _buildWaterSection(data),
            pw.SizedBox(height: 18),

            // 3. Sleep & Rest
            _buildSectionHeader('3. Sleep & Recovery', PdfColor.fromHex('#6366F1')),
            _buildSleepSection(data),
            pw.SizedBox(height: 18),

            // 4. Nutrition & Calories
            _buildSectionHeader('4. Nutrition & Dietary Intake', PdfColor.fromHex('#F59E0B')),
            _buildCaloriesSection(data),
            pw.SizedBox(height: 18),

            // 5. Cardiovascular (Heart Rate & Blood Pressure)
            _buildSectionHeader('5. Cardiovascular Health (Heart Rate & Blood Pressure)', dangerRose),
            _buildCardiovascularSection(data),
            pw.SizedBox(height: 18),

            // 6. Metabolic Health (Blood Sugar)
            _buildSectionHeader('6. Metabolic Health (Blood Sugar / Glycemia)', PdfColor.fromHex('#8B5CF6')),
            _buildBloodSugarSection(data),
            pw.SizedBox(height: 18),

            // 7. Clinical Observations & Action Plan
            _buildSectionHeader('7. Clinical Observations & Recommendations', primaryNavy),
            _buildObservationsSection(data),
            pw.SizedBox(height: 12),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ── Header Widget ──────────────────────────────────────────────────────────
  static pw.Widget _buildHeader({
    required String fromStr,
    required String toStr,
    required String userName,
    required String userEmail,
    required String genStr,
    required HealthReportData data,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: slateBorder, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 10,
                    height: 10,
                    decoration: pw.BoxDecoration(
                      color: tealAccent,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    'AURORA WELLNESS',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryNavy,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Personal Clinical Health Report',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: slateMuted,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (data.profile?.age != null || data.profile?.sex != null)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    'Demographics: ${[
                      if (data.profile?.age != null) '${data.profile!.age} yrs',
                      if (data.profile?.sex != null) data.profile!.sex!.toUpperCase(),
                      if (data.profile?.heightCm != null) '${data.profile!.heightCm!.round()} cm',
                      if (data.profile?.weightKg != null) '${data.profile!.weightKg!.round()} kg',
                    ].join(" | ")}',
                    style: pw.TextStyle(fontSize: 8, color: slateMuted),
                  ),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Patient: $userName',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryNavy,
                ),
              ),
              if (userEmail.isNotEmpty)
                pw.Text(
                  userEmail,
                  style: pw.TextStyle(fontSize: 8, color: slateMuted),
                ),
              pw.SizedBox(height: 2),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: slateLight,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: slateBorder),
                ),
                child: pw.Text(
                  'Period: $fromStr - $toStr (${data.totalDays} day${data.totalDays > 1 ? "s" : ""})',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: secondaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer Widget ──────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: slateBorder, width: 1.0),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Aurora Health Platform | Clinical Verification & Data Isolation Guaranteed',
            style: pw.TextStyle(fontSize: 7, color: slateMuted),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────
  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 14,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  // ── Executive Summary & Wellness Score ──────────────────────────────────────
  static pw.Widget _buildExecutiveSummary(HealthReportData data) {
    final scoreStr = data.averageScore != null
        ? '${data.averageScore!.round()}'
        : 'N/A';
    final scoreColor = data.averageScore != null
        ? (data.averageScore! >= 70 ? successGreen : (data.averageScore! >= 50 ? warningAmber : dangerRose))
        : slateMuted;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: slateLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: slateBorder, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Score Circle Badge
          pw.Container(
            width: 72,
            height: 72,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: scoreColor.flatten(),
              border: pw.Border.all(color: scoreColor, width: 2),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    scoreStr,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryNavy,
                    ),
                  ),
                  pw.Text(
                    'out of 100',
                    style: pw.TextStyle(fontSize: 7, color: slateMuted),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 14),

          // Score Breakdown Text
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'Overall Period Wellness Score: ',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryNavy,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: scoreColor.flatten(),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        data.scoreLabel,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Deterministic aggregate derived from real physical readings (hydration, activity, sleep, cardiovascular metrics, and nutrition logs) for the selected period.',
                  style: pw.TextStyle(fontSize: 8, color: slateMuted),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                      'Scores Recorded: ${data.dailyScores.length} day(s)',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: slateDark),
                    ),
                    if (data.minScore != null && data.maxScore != null) ...[
                      pw.Text('  |  ', style: pw.TextStyle(fontSize: 8, color: slateMuted)),
                      pw.Text(
                        'Range: ${data.minScore} - ${data.maxScore}',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: slateDark),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Highlights Grid ──────────────────────────────────────────────────
  static pw.Widget _buildQuickHighlights(HealthReportData data) {
    return pw.Row(
      children: [
        _buildMetricSummaryCard(
          title: 'Total Steps',
          value: data.totalSteps.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},"),
          subvalue: 'Avg: ${data.avgSteps} / day',
          color: secondaryBlue,
        ),
        pw.SizedBox(width: 8),
        _buildMetricSummaryCard(
          title: 'Total Hydration',
          value: '${(data.totalWaterMl / 1000).toStringAsFixed(1)} L',
          subvalue: 'Avg: ${data.avgWaterMl} ml / day',
          color: tealAccent,
        ),
        pw.SizedBox(width: 8),
        _buildMetricSummaryCard(
          title: 'Avg Sleep',
          value: '${data.avgSleepHours.toStringAsFixed(1)} hrs',
          subvalue: 'Total: ${data.totalSleepHours.toStringAsFixed(1)} hrs',
          color: PdfColor.fromHex('#6366F1'),
        ),
        pw.SizedBox(width: 8),
        _buildMetricSummaryCard(
          title: 'Blood Pressure',
          value: data.avgSystolic != null ? '${data.avgSystolic!.round()}/${data.avgDiastolic!.round()}' : 'N/A',
          subvalue: data.bpClassification,
          color: dangerRose,
        ),
      ],
    );
  }

  static pw.Widget _buildMetricSummaryCard({
    required String title,
    required String value,
    required String subvalue,
    required PdfColor color,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: slateLight,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: slateBorder),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 8, color: slateMuted, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              subvalue,
              style: pw.TextStyle(fontSize: 7, color: slateDark),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ── Steps Section ──────────────────────────────────────────────────────────
  static pw.Widget _buildStepsSection(HealthReportData data) {
    if (data.dailySteps.isEmpty) {
      return _buildNoDataPlaceholder('No step readings recorded for this period.');
    }

    final dateFormat = DateFormat('EEE, dd MMM');
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: slateBorder),
        children: [
          _buildTableCell('Date', isHeader: true),
          _buildTableCell('Steps Logged', isHeader: true),
          _buildTableCell('Daily Goal (${data.stepGoal})', isHeader: true),
          _buildTableCell('Achievement Rate', isHeader: true),
        ],
      ),
    ];

    for (final record in data.dailySteps) {
      final rate = ((record.steps / data.stepGoal) * 100).round();
      rows.add(
        pw.TableRow(
          children: [
            _buildTableCell(dateFormat.format(record.date)),
            _buildTableCell(record.steps.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")),
            _buildTableCell(data.stepGoal.toString()),
            _buildTableCell('$rate% ${rate >= 100 ? "[Goal Met]" : ""}', textColor: rate >= 100 ? successGreen : slateDark),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Total Steps: ${data.totalSteps}  |  Daily Average: ${data.avgSteps}  |  Highest Day: ${data.highestStepDay?.steps ?? 0}  |  Lowest Day: ${data.lowestStepDay?.steps ?? 0}',
          style: pw.TextStyle(fontSize: 8, color: slateDark, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: slateBorder, width: 0.5),
          children: rows,
        ),
      ],
    );
  }

  // ── Water Section ──────────────────────────────────────────────────────────
  static pw.Widget _buildWaterSection(HealthReportData data) {
    if (data.dailyWater.isEmpty) {
      return _buildNoDataPlaceholder('No water intake readings recorded for this period.');
    }

    final dateFormat = DateFormat('EEE, dd MMM');
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: slateBorder),
        children: [
          _buildTableCell('Date', isHeader: true),
          _buildTableCell('Intake (ml)', isHeader: true),
          _buildTableCell('Target (${data.waterGoal} ml)', isHeader: true),
          _buildTableCell('Status', isHeader: true),
        ],
      ),
    ];

    for (final record in data.dailyWater) {
      final pct = ((record.amount / data.waterGoal) * 100).round();
      rows.add(
        pw.TableRow(
          children: [
            _buildTableCell(dateFormat.format(record.date)),
            _buildTableCell('${record.amount} ml'),
            _buildTableCell('${data.waterGoal} ml'),
            _buildTableCell('$pct% ${pct >= 100 ? "[Goal Met]" : "Under Target"}',
                textColor: pct >= 100 ? successGreen : warningAmber),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Total Hydration: ${data.totalWaterMl} ml  |  Daily Average: ${data.avgWaterMl} ml  |  Target: ${data.waterGoal} ml/day',
          style: pw.TextStyle(fontSize: 8, color: slateDark, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: slateBorder, width: 0.5),
          children: rows,
        ),
      ],
    );
  }

  // ── Sleep Section ──────────────────────────────────────────────────────────
  static pw.Widget _buildSleepSection(HealthReportData data) {
    if (data.dailySleep.isEmpty) {
      return _buildNoDataPlaceholder('No sleep records logged for this period.');
    }

    final dateFormat = DateFormat('EEE, dd MMM');
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: slateBorder),
        children: [
          _buildTableCell('Night', isHeader: true),
          _buildTableCell('Duration (Hours)', isHeader: true),
          _buildTableCell('Target (${data.sleepGoal.toStringAsFixed(1)}h)', isHeader: true),
          _buildTableCell('Evaluation', isHeader: true),
        ],
      ),
    ];

    for (final record in data.dailySleep) {
      final eval = record.hours >= 7.0 && record.hours <= 9.0
          ? 'Optimal Rest'
          : (record.hours < 6.0 ? 'Insufficient' : 'Extended');
      rows.add(
        pw.TableRow(
          children: [
            _buildTableCell(dateFormat.format(record.date)),
            _buildTableCell('${record.hours.toStringAsFixed(1)} hrs'),
            _buildTableCell('${data.sleepGoal.toStringAsFixed(1)} hrs'),
            _buildTableCell(eval, textColor: record.hours >= 7.0 ? successGreen : warningAmber),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Total Sleep: ${data.totalSleepHours.toStringAsFixed(1)} hrs  |  Nightly Average: ${data.avgSleepHours.toStringAsFixed(1)} hrs  |  Target: ${data.sleepGoal.toStringAsFixed(1)} hrs',
          style: pw.TextStyle(fontSize: 8, color: slateDark, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: slateBorder, width: 0.5),
          children: rows,
        ),
      ],
    );
  }

  // ── Calories & Nutrition Section ───────────────────────────────────────────
  static pw.Widget _buildCaloriesSection(HealthReportData data) {
    if (data.meals.isEmpty) {
      return _buildNoDataPlaceholder('No meal / dietary intake records logged for this period.');
    }

    final timeFormat = DateFormat('dd MMM, hh:mm a');
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: slateBorder),
        children: [
          _buildTableCell('Timestamp', isHeader: true),
          _buildTableCell('Meal / Item', isHeader: true),
          _buildTableCell('Category', isHeader: true),
          _buildTableCell('Calories (kcal)', isHeader: true),
        ],
      ),
    ];

    for (final meal in data.meals.take(15)) {
      rows.add(
        pw.TableRow(
          children: [
            _buildTableCell(timeFormat.format(meal.time)),
            _buildTableCell(meal.name),
            _buildTableCell(meal.mealType.name.toUpperCase()),
            _buildTableCell('${meal.calories} kcal'),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Total Calories: ${data.totalCalories.round()} kcal  |  Daily Average: ${data.avgCalories.round()} kcal  |  Meals Logged: ${data.meals.length}',
          style: pw.TextStyle(fontSize: 8, color: slateDark, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: slateBorder, width: 0.5),
          children: rows,
        ),
      ],
    );
  }

  // ── Cardiovascular Section ─────────────────────────────────────────────────
  static pw.Widget _buildCardiovascularSection(HealthReportData data) {
    if (data.heartRateReadings.isEmpty && data.bloodPressureReadings.isEmpty) {
      return _buildNoDataPlaceholder('No cardiovascular (heart rate or blood pressure) readings recorded.');
    }

    final timeFormat = DateFormat('dd MMM, hh:mm a');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (data.bloodPressureReadings.isNotEmpty) ...[
          pw.Text(
            'Blood Pressure Readings: Average ${data.avgSystolic!.round()}/${data.avgDiastolic!.round()} mmHg (${data.bpClassification})',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: slateDark),
          ),
          pw.SizedBox(height: 3),
          pw.Table(
            border: pw.TableBorder.all(color: slateBorder, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: slateBorder),
                children: [
                  _buildTableCell('Timestamp', isHeader: true),
                  _buildTableCell('Systolic (mmHg)', isHeader: true),
                  _buildTableCell('Diastolic (mmHg)', isHeader: true),
                  _buildTableCell('Classification', isHeader: true),
                ],
              ),
              ...data.bloodPressureReadings.take(10).map((bp) {
                final cls = bp.systolic < 120 && bp.diastolic < 80 ? 'Normal' : (bp.systolic <= 129 ? 'Elevated' : 'Hypertension');
                return pw.TableRow(
                  children: [
                    _buildTableCell(timeFormat.format(bp.timestamp)),
                    _buildTableCell('${bp.systolic}'),
                    _buildTableCell('${bp.diastolic}'),
                    _buildTableCell(cls, textColor: cls == 'Normal' ? successGreen : dangerRose),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 8),
        ],
        if (data.heartRateReadings.isNotEmpty) ...[
          pw.Text(
            'Heart Rate Readings: Average ${data.avgHeartRate!.round()} BPM  |  Min: ${data.minHeartRate!.round()} BPM  |  Max: ${data.maxHeartRate!.round()} BPM',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: slateDark),
          ),
          pw.SizedBox(height: 3),
          pw.Table(
            border: pw.TableBorder.all(color: slateBorder, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: slateBorder),
                children: [
                  _buildTableCell('Timestamp', isHeader: true),
                  _buildTableCell('Recorded BPM', isHeader: true),
                  _buildTableCell('Zone / Category', isHeader: true),
                ],
              ),
              ...data.heartRateReadings.take(10).map((hr) {
                final zone = hr.bpm < 60 ? 'Bradycardia' : (hr.bpm <= 100 ? 'Normal Resting' : 'Elevated / Active');
                return pw.TableRow(
                  children: [
                    _buildTableCell(timeFormat.format(hr.timestamp)),
                    _buildTableCell('${hr.bpm.round()} BPM'),
                    _buildTableCell(zone, textColor: zone == 'Normal Resting' ? successGreen : slateDark),
                  ],
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  // ── Blood Sugar Section ────────────────────────────────────────────────────
  static pw.Widget _buildBloodSugarSection(HealthReportData data) {
    if (data.bloodSugarReadings.isEmpty) {
      return _buildNoDataPlaceholder('No blood sugar / glycemic readings recorded for this period.');
    }

    final timeFormat = DateFormat('dd MMM, hh:mm a');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Glycemic Levels: Average ${data.avgBloodSugar!.toStringAsFixed(1)} mg/dL (${data.bloodSugarStatus})  |  Min: ${data.minBloodSugar!.toStringAsFixed(1)}  |  Max: ${data.maxBloodSugar!.toStringAsFixed(1)}',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: slateDark),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: slateBorder, width: 0.5),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: slateBorder),
              children: [
                _buildTableCell('Timestamp', isHeader: true),
                _buildTableCell('Blood Sugar (mg/dL)', isHeader: true),
                _buildTableCell('Clinical Range', isHeader: true),
              ],
            ),
            ...data.bloodSugarReadings.take(10).map((bs) {
              final status = bs.value <= 99 ? 'Normal' : (bs.value <= 125 ? 'Elevated' : 'High');
              return pw.TableRow(
                children: [
                  _buildTableCell(timeFormat.format(bs.date)),
                  _buildTableCell('${bs.value.toStringAsFixed(1)} mg/dL'),
                  _buildTableCell(status, textColor: status == 'Normal' ? successGreen : (status == 'Elevated' ? warningAmber : dangerRose)),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // ── Observations & Recommendations ─────────────────────────────────────────
  static pw.Widget _buildObservationsSection(HealthReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: slateLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: slateBorder),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Key Period Observations:',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryNavy),
          ),
          pw.SizedBox(height: 4),
          ...data.keyObservations.map((obs) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('* ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: secondaryBlue)),
                    pw.Expanded(
                      child: pw.Text(obs, style: pw.TextStyle(fontSize: 8, color: slateDark)),
                    ),
                  ],
                ),
              )),
          pw.SizedBox(height: 6),
          pw.Text(
            'Personalized Action Plan & Guidance:',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryNavy),
          ),
          pw.SizedBox(height: 4),
          ...data.clinicalRecommendations.map((rec) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('> ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: tealAccent)),
                    pw.Expanded(
                      child: pw.Text(rec, style: pw.TextStyle(fontSize: 8, color: slateDark)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────
  static pw.Widget _buildEmptyReportNotice(String fromStr, String toStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      margin: const pw.EdgeInsets.symmetric(vertical: 40),
      decoration: pw.BoxDecoration(
        color: slateLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: slateBorder),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'NO HEALTH DATA RECORDED',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryNavy,
              letterSpacing: 1.1,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'No physical readings (steps, water, sleep, calories, BP, or blood sugar) were logged in the database between $fromStr and $toStr.',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 10, color: slateMuted),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Please select a different date range or record health metrics in the application to generate a comprehensive report.',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 9, color: secondaryBlue),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNoDataPlaceholder(String message) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: slateLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: slateBorder),
      ),
      child: pw.Text(
        message,
        style: pw.TextStyle(fontSize: 8, color: slateMuted, fontStyle: pw.FontStyle.italic),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 7.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? primaryNavy : slateDark),
        ),
      ),
    );
  }
}

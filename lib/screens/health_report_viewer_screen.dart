import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../services/health_report_service.dart';
import '../services/health_report_pdf_generator.dart';

class HealthReportViewerScreen extends StatefulWidget {
  final HealthReportData reportData;
  final Uint8List? pdfBytes;

  const HealthReportViewerScreen({
    super.key,
    required this.reportData,
    this.pdfBytes,
  });

  @override
  State<HealthReportViewerScreen> createState() => _HealthReportViewerScreenState();
}

class _HealthReportViewerScreenState extends State<HealthReportViewerScreen> {
  Uint8List? _pdfData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    if (widget.pdfBytes != null) {
      setState(() {
        _pdfData = widget.pdfBytes;
        _isLoading = false;
      });
      return;
    }

    try {
      final generated = await HealthReportPdfGenerator.generate(widget.reportData);
      if (mounted) {
        setState(() {
          _pdfData = generated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to compile health report: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final fromStr = dateFormat.format(widget.reportData.fromDate);
    final toStr = dateFormat.format(widget.reportData.toDate);
    final fileName = 'Aurora_Health_Report_${DateFormat("yyyyMMdd").format(widget.reportData.fromDate)}_to_${DateFormat("yyyyMMdd").format(widget.reportData.toDate)}.pdf';

    return Scaffold(
      backgroundColor: const Color(0xFF090D10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1216),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Report Preview',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              '$fromStr – $toStr',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF48E5C2),
              ),
            ),
          ],
        ),
        actions: [
          if (_pdfData != null)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Color(0xFF48E5C2)),
              tooltip: 'Share Report',
              onPressed: () async {
                await Printing.sharePdf(
                  bytes: _pdfData!,
                  filename: fileName,
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF48E5C2)),
                  SizedBox(height: 16),
                  Text(
                    'Compiling clinical health data...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5C7A), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _preparePdf();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF48E5C2),
                            foregroundColor: const Color(0xFF090D10),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Theme(
                  data: ThemeData.light(),
                  child: PdfPreview(
                    build: (PdfPageFormat format) => _pdfData!,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    pdfFileName: fileName,
                    previewPageMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    loadingWidget: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF48E5C2)),
                    ),
                  ),
                ),
    );
  }
}

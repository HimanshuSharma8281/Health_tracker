import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../controllers/health_data_controller.dart';
import '../services/ppg_signal_processor.dart';

class CameraHeartRateScanner extends StatefulWidget {
  const CameraHeartRateScanner({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CameraHeartRateScanner(),
    );
  }

  @override
  State<CameraHeartRateScanner> createState() => _CameraHeartRateScannerState();
}

class _CameraHeartRateScannerState extends State<CameraHeartRateScanner>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  final PpgSignalProcessor _processor = PpgSignalProcessor();

  bool _isInitializing = true;
  String _errorMessage = '';

  // Measurement state
  bool _isMeasuring = false;
  bool _isFinished = false;
  double? _finalBpm;
  double? _liveBpm;
  double _signalQuality = 0.0;
  PpgFingerState _fingerState = PpgFingerState.noFinger;
  String _statusMessage = 'Initializing camera sensor...';

  // Metrics
  int _totalFrames = 0;
  double _fps = 0.0;
  int _measurementSeconds = 0;
  Timer? _countdownTimer;
  static const int _targetDurationSeconds = 25;

  late AnimationController _pulseAnimController;
  late Animation<double> _pulseScale;

  final List<double> _waveformPoints = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.96, end: 1.08).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopAndDisposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = '';
    });

    try {
      final camStatus = await Permission.camera.status;
      if (!camStatus.isGranted) {
        final req = await Permission.camera.request();
        if (!req.isGranted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'Camera permission is required to measure heart rate.';
          });
          return;
        }
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No camera device found on this phone.';
        });
        return;
      }

      // Select rear camera
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      if (!mounted) return;

      // Turn on flashlight/torch
      try {
        await controller.setFlashMode(FlashMode.torch);
      } catch (e) {
        debugPrint('⚠️ [PPG Scanner] Torch mode note: $e');
      }

      // Lock exposure if supported to stabilize signal
      try {
        if (controller.value.exposureMode != ExposureMode.locked) {
          await controller.setExposureMode(ExposureMode.locked);
        }
      } catch (e) {
        debugPrint('⚠️ [PPG Scanner] Exposure lock note: $e');
      }

      _cameraController = controller;
      _processor.reset();

      // Start camera image stream
      await controller.startImageStream(_handleCameraFrame);

      setState(() {
        _isInitializing = false;
        _isMeasuring = true;
        _statusMessage = 'Place your index fingertip over rear camera & flash';
      });

      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _measurementSeconds = 0;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_fingerState == PpgFingerState.goodContact) {
        setState(() {
          _measurementSeconds++;
        });

        if (_measurementSeconds >= _targetDurationSeconds) {
          _finishMeasurement();
        }
      }
    });
  }

  void _handleCameraFrame(CameraImage image) {
    if (!_isMeasuring || _isFinished) return;

    final result = _processor.processFrame(image);

    if (!mounted) return;

    setState(() {
      _fingerState = result.fingerState;
      _signalQuality = result.signalQuality;
      _totalFrames = result.totalFrames;
      _fps = result.effectiveFps;
      _statusMessage = result.statusMessage;

      if (result.bpm != null) {
        _liveBpm = result.bpm;
      }

      if (result.recentSamples.isNotEmpty) {
        final lastSample = result.recentSamples.last;
        _waveformPoints.add(lastSample.normalizedIntensity);
        if (_waveformPoints.length > 60) {
          _waveformPoints.removeAt(0);
        }
      }
    });
  }

  void _finishMeasurement() {
    _countdownTimer?.cancel();
    _isMeasuring = false;

    // Use live BPM if valid
    if (_liveBpm != null && _liveBpm! >= 42 && _liveBpm! <= 215) {
      _finalBpm = _liveBpm;
    }

    _stopAndDisposeCamera();

    setState(() {
      _isFinished = true;
    });
  }

  Future<void> _stopAndDisposeCamera() async {
    try {
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        try {
          await _cameraController!.setFlashMode(FlashMode.off);
        } catch (_) {}
        await _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (e) {
      debugPrint('⚠️ [PPG Scanner] Disposal note: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _pulseAnimController.dispose();
    _stopAndDisposeCamera();
    super.dispose();
  }

  String _getCategory(double bpm) {
    if (bpm < 60) return 'Resting / Low';
    if (bpm <= 100) return 'Normal Resting';
    if (bpm <= 120) return 'Elevated';
    return 'High / Tachycardia';
  }

  Color _getCategoryColor(double bpm) {
    if (bpm < 60) return const Color(0xFF5CE1E6);
    if (bpm <= 100) return const Color(0xFF48E5C2);
    if (bpm <= 120) return const Color(0xFFFFAA4C);
    return const Color(0xFFFF5C7A);
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_measurementSeconds / _targetDurationSeconds).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141A22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0x33FF5C7A), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5C7A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFFFF5C7A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PPG Heart Rate Scanner',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Optical fingertip pulse sensor',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isInitializing) ...[
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Color(0xFFFF5C7A)),
            const SizedBox(height: 16),
            Text(
              'Starting camera & flashlight...',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 40),
          ] else if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 20),
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent.shade200),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C7A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _initCamera,
              child: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ] else if (_isFinished) ...[
            // Measurement Complete Screen
            _buildFinishedView(),
          ] else ...[
            // Live Measurement Screen
            _buildLiveMeasurementView(progress),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveMeasurementView(double progress) {
    final bool hasFinger = _fingerState == PpgFingerState.goodContact;

    return Column(
      children: [
        // Central Pulse & Progress Circle
        Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress indicator
            SizedBox(
              width: 170,
              height: 170,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF5C7A)),
              ),
            ),

            // Pulsating heart center
            ScaleTransition(
              scale: hasFinger ? _pulseScale : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasFinger
                      ? const Color(0xFFFF5C7A).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: hasFinger
                        ? const Color(0xFFFF5C7A).withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: hasFinger ? const Color(0xFFFF5C7A) : Colors.white38,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _liveBpm != null && hasFinger ? '${_liveBpm!.round()}' : '—',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'BPM',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF5C7A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Live Real-Time PPG Waveform
        Container(
          height: 52,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: CustomPaint(
            painter: _PpgWaveformPainter(
              samples: _waveformPoints,
              color: hasFinger ? const Color(0xFFFF5C7A) : Colors.white24,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Status message box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: hasFinger
                ? const Color(0xFF48E5C2).withValues(alpha: 0.1)
                : const Color(0xFFFF5C7A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasFinger
                  ? const Color(0xFF48E5C2).withValues(alpha: 0.3)
                  : const Color(0xFFFF5C7A).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasFinger ? Icons.check_circle_outline_rounded : Icons.touch_app_rounded,
                color: hasFinger ? const Color(0xFF48E5C2) : const Color(0xFFFF5C7A),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Quality & Diagnostic Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Signal Quality: ${(_signalQuality * 100).round()}%',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
            ),
            Text(
              '${_targetDurationSeconds - _measurementSeconds}s remaining',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF5C7A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _signalQuality,
            minHeight: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(
              _signalQuality >= 0.6
                  ? const Color(0xFF48E5C2)
                  : (_signalQuality >= 0.35 ? const Color(0xFFFFBE0B) : const Color(0xFFFF5C7A)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Frames: $_totalFrames (${_fps.toStringAsFixed(1)} FPS)',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.35),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              'Duration: ${_measurementSeconds}s / ${_targetDurationSeconds}s',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinishedView() {
    final controller = context.read<HealthDataController>();
    final double? bpm = _finalBpm;
    final bool isValid = bpm != null && bpm >= 45 && bpm <= 200;

    if (!isValid) {
      return Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.warning_amber_rounded, size: 56, color: Colors.amber.shade300),
          const SizedBox(height: 12),
          Text(
            'Inconclusive Reading',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The PPG signal had excessive movement or insufficient optical contact. Please rest your finger gently on the rear camera and try again.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C7A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                setState(() {
                  _isFinished = false;
                  _finalBpm = null;
                  _liveBpm = null;
                });
                _initCamera();
              },
              child: Text(
                'Retest Measurement',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    final category = _getCategory(bpm);
    final catColor = _getCategoryColor(bpm);

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: catColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            category,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: catColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${bpm.round()}',
              style: GoogleFonts.inter(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'BPM',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF5C7A),
              ),
            ),
          ],
        ),
        Text(
          'Measurement verified with ${(_signalQuality * 100).round()}% confidence',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  setState(() {
                    _isFinished = false;
                    _finalBpm = null;
                    _liveBpm = null;
                  });
                  _initCamera();
                },
                child: Text('Retest', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5C7A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  controller.updateHeartRate(bpm);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1B232E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: Color(0xFFFF5C7A), size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Heart rate saved: ${bpm.round()} BPM',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Text('Save Reading', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PpgWaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color color;

  _PpgWaveformPainter({
    required this.samples,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double dx = size.width / (samples.length - 1);
    final double midY = size.height / 2;

    double maxVal = 0.01;
    for (final s in samples) {
      if (s.abs() > maxVal) maxVal = s.abs();
    }

    final double scaleY = (size.height * 0.42) / maxVal;

    for (int i = 0; i < samples.length; i++) {
      final double x = i * dx;
      final double y = (midY - (samples[i] * scaleY)).clamp(2.0, size.height - 2.0);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PpgWaveformPainter oldDelegate) => true;
}

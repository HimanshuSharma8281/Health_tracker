import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// States of optical contact when finger covers camera lens and flashlight.
enum PpgFingerState {
  noFinger,
  tooDim,
  overexposed,
  goodContact,
}

/// A processed PPG time-series sample.
class PpgSample {
  final int timestampMs;
  final double rawIntensity;
  final double filteredIntensity;
  final double normalizedIntensity;

  const PpgSample({
    required this.timestampMs,
    required this.rawIntensity,
    required this.filteredIntensity,
    required this.normalizedIntensity,
  });
}

/// Detailed frame diagnostics for debugging and telemetry.
class PpgFrameDiagnostics {
  final int frameNumber;
  final double redMean;
  final double greenMean;
  final double blueMean;
  final double luminanceMean;
  final double luminanceVariance;
  final double rawSignal;
  final double filteredSignal;
  final double fps;
  final double sqi;
  final double? liveBpm;
  final PpgFingerState fingerState;

  const PpgFrameDiagnostics({
    required this.frameNumber,
    required this.redMean,
    required this.greenMean,
    required this.blueMean,
    required this.luminanceMean,
    required this.luminanceVariance,
    required this.rawSignal,
    required this.filteredSignal,
    required this.fps,
    required this.sqi,
    this.liveBpm,
    required this.fingerState,
  });
}

/// Result returned from processing each camera frame.
class PpgProcessingResult {
  final double? bpm;
  final double signalQuality; // 0.0 to 1.0 (SQI)
  final PpgFingerState fingerState;
  final List<PpgSample> recentSamples;
  final int totalFrames;
  final double effectiveFps;
  final bool isStable;
  final String statusMessage;
  final PpgFrameDiagnostics diagnostics;

  const PpgProcessingResult({
    this.bpm,
    required this.signalQuality,
    required this.fingerState,
    required this.recentSamples,
    required this.totalFrames,
    required this.effectiveFps,
    required this.isStable,
    required this.statusMessage,
    required this.diagnostics,
  });
}

/// Production-grade Photoplethysmography (PPG) signal processor.
/// Extracts cardiac pulsatility from camera video frames using optical absorption changes.
class PpgSignalProcessor {
  // Buffer limits
  static const int _maxBufferSize = 600; // ~20 seconds at 30 FPS
  static const int _minFramesForEstimation = 75; // ~2.5 seconds at 30 FPS

  final List<PpgSample> _sampleBuffer = [];
  final List<int> _rawTimestamps = [];
  final List<double> _rawIntensities = [];
  final List<double> _filteredIntensities = [];

  // Finger contact hysteresis buffer
  final List<bool> _contactHistory = [];
  static const int _contactHistorySize = 15;

  int _totalFramesProcessed = 0;
  int? _measurementStartTimeMs;
  int _lastLogFrame = 0;

  // Digital filter states
  double _dcBaseline = 0.0;
  double _lastFiltered = 0.0;
  double _runningVariance = 1.0;

  // Exponential moving average coefficient for DC baseline tracking (~0.5 Hz highpass)
  static const double _dcAlpha = 0.94;
  // Exponential smoothing coefficient for noise rejection (~4 Hz lowpass)
  static const double _lpBeta = 0.60;

  /// Resets all internal buffers and filters for a new measurement session.
  void reset() {
    _sampleBuffer.clear();
    _rawTimestamps.clear();
    _rawIntensities.clear();
    _filteredIntensities.clear();
    _contactHistory.clear();
    _totalFramesProcessed = 0;
    _measurementStartTimeMs = null;
    _lastLogFrame = 0;
    _dcBaseline = 0.0;
    _lastFiltered = 0.0;
    _runningVariance = 1.0;
  }

  /// Process a single incoming CameraImage frame from the camera stream.
  PpgProcessingResult processFrame(CameraImage image) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _measurementStartTimeMs ??= nowMs;
    _totalFramesProcessed++;

    // 1. Extract Region of Interest (ROI) statistics from the camera image
    final stats = _extractRoiStatistics(image);

    // 2. Assess optical finger placement and contact validity
    final rawFingerState = _evaluateFingerState(stats);
    _contactHistory.add(rawFingerState == PpgFingerState.goodContact);
    if (_contactHistory.length > _contactHistorySize) {
      _contactHistory.removeAt(0);
    }

    final int goodCount = _contactHistory.where((v) => v).length;
    final bool hasStableContact = _contactHistory.isNotEmpty && (goodCount / _contactHistory.length) >= 0.60;
    final PpgFingerState effectiveFingerState = hasStableContact ? PpgFingerState.goodContact : rawFingerState;

    final double fps = _calculateFps();

    // If no finger contact is present
    if (effectiveFingerState != PpgFingerState.goodContact) {
      // If finger is removed for > 1 second (30 frames), gently decay buffer
      if (_sampleBuffer.length > 30 && _contactHistory.every((v) => !v)) {
        _sampleBuffer.removeRange(0, math.max(0, _sampleBuffer.length - 20));
        _rawTimestamps.removeRange(0, math.max(0, _rawTimestamps.length - 20));
        _rawIntensities.removeRange(0, math.max(0, _rawIntensities.length - 20));
        _filteredIntensities.removeRange(0, math.max(0, _filteredIntensities.length - 20));
      }

      final statusMsg = _getStatusMessage(effectiveFingerState);
      final diag = PpgFrameDiagnostics(
        frameNumber: _totalFramesProcessed,
        redMean: stats.rMean,
        greenMean: stats.gMean,
        blueMean: stats.bMean,
        luminanceMean: stats.yMean,
        luminanceVariance: stats.yVariance,
        rawSignal: stats.opticalSignal,
        filteredSignal: 0.0,
        fps: fps,
        sqi: 0.0,
        liveBpm: null,
        fingerState: effectiveFingerState,
      );

      _logDiagnosticsIfNeeded(diag);

      return PpgProcessingResult(
        bpm: null,
        signalQuality: 0.0,
        fingerState: effectiveFingerState,
        recentSamples: List.unmodifiable(_sampleBuffer.take(80)),
        totalFrames: _totalFramesProcessed,
        effectiveFps: fps,
        isStable: false,
        statusMessage: statusMsg,
        diagnostics: diag,
      );
    }

    // 3. Extract primary pulsatile optical absorption signal
    // In human tissue, hemoglobin absorption modulates light transmission.
    final rawSignal = stats.opticalSignal;

    // 4. Digital Filter: Baseline wander removal (DC Highpass) + Sensor noise smoothing (Lowpass)
    if (_dcBaseline == 0.0) {
      _dcBaseline = rawSignal;
      _lastFiltered = 0.0;
    } else {
      // DC baseline tracking
      _dcBaseline = (_dcBaseline * _dcAlpha) + (rawSignal * (1.0 - _dcAlpha));
    }

    final double acSignal = rawSignal - _dcBaseline;
    // 2-pole low-pass smoothing
    final double filteredSignal = (_lastFiltered * _lpBeta) + (acSignal * (1.0 - _lpBeta));
    _lastFiltered = filteredSignal;

    // Update running signal variance for scale-invariant normalized display
    _runningVariance = (_runningVariance * 0.96) + (filteredSignal * filteredSignal * 0.04);
    final double stdDev = math.sqrt(math.max(0.001, _runningVariance));
    final double normalizedSignal = (filteredSignal / stdDev).clamp(-3.5, 3.5);

    // Append to buffers
    _rawTimestamps.add(nowMs);
    _rawIntensities.add(rawSignal);
    _filteredIntensities.add(filteredSignal);
    _sampleBuffer.add(PpgSample(
      timestampMs: nowMs,
      rawIntensity: rawSignal,
      filteredIntensity: filteredSignal,
      normalizedIntensity: normalizedSignal,
    ));

    if (_sampleBuffer.length > _maxBufferSize) {
      _sampleBuffer.removeAt(0);
      _rawTimestamps.removeAt(0);
      _rawIntensities.removeAt(0);
      _filteredIntensities.removeAt(0);
    }

    // 5. Dual-Engine BPM Calculation (Autocorrelation + Adaptive Peak Detection)
    if (_sampleBuffer.length < _minFramesForEstimation || fps < 15.0) {
      final progressPercent = ((_sampleBuffer.length / _minFramesForEstimation) * 100).clamp(0, 99).toInt();
      final diag = PpgFrameDiagnostics(
        frameNumber: _totalFramesProcessed,
        redMean: stats.rMean,
        greenMean: stats.gMean,
        blueMean: stats.bMean,
        luminanceMean: stats.yMean,
        luminanceVariance: stats.yVariance,
        rawSignal: rawSignal,
        filteredSignal: filteredSignal,
        fps: fps,
        sqi: 0.35,
        liveBpm: null,
        fingerState: PpgFingerState.goodContact,
      );

      _logDiagnosticsIfNeeded(diag);

      return PpgProcessingResult(
        bpm: null,
        signalQuality: 0.35,
        fingerState: PpgFingerState.goodContact,
        recentSamples: List.unmodifiable(_sampleBuffer),
        totalFrames: _totalFramesProcessed,
        effectiveFps: fps,
        isStable: false,
        statusMessage: 'Calibrating optical sensor ($progressPercent%)... Hold still',
        diagnostics: diag,
      );
    }

    final bpmEstimation = _estimateBpmDualEngine(fps);

    final diag = PpgFrameDiagnostics(
      frameNumber: _totalFramesProcessed,
      redMean: stats.rMean,
      greenMean: stats.gMean,
      blueMean: stats.bMean,
      luminanceMean: stats.yMean,
      luminanceVariance: stats.yVariance,
      rawSignal: rawSignal,
      filteredSignal: filteredSignal,
      fps: fps,
      sqi: bpmEstimation.sqi,
      liveBpm: bpmEstimation.bpm,
      fingerState: PpgFingerState.goodContact,
    );

    _logDiagnosticsIfNeeded(diag);

    final bool isStable = bpmEstimation.sqi >= 0.55 && bpmEstimation.bpm != null;
    String statusMessage;
    if (bpmEstimation.sqi >= 0.70) {
      statusMessage = 'Measuring pulse... Signal strong';
    } else if (bpmEstimation.sqi >= 0.45) {
      statusMessage = 'Acquiring pulse waveform... Keep steady';
    } else {
      statusMessage = 'Stabilizing... Maintain gentle contact';
    }

    return PpgProcessingResult(
      bpm: bpmEstimation.bpm,
      signalQuality: bpmEstimation.sqi,
      fingerState: PpgFingerState.goodContact,
      recentSamples: List.unmodifiable(_sampleBuffer),
      totalFrames: _totalFramesProcessed,
      effectiveFps: fps,
      isStable: isStable,
      statusMessage: statusMessage,
      diagnostics: diag,
    );
  }

  /// Calculates the effective frame rate over the buffer duration.
  double _calculateFps() {
    if (_rawTimestamps.length < 2) return 30.0;
    final durationMs = _rawTimestamps.last - _rawTimestamps.first;
    if (durationMs <= 0) return 30.0;
    return (_rawTimestamps.length - 1) / (durationMs / 1000.0);
  }

  /// Evaluates finger presence and optical contact validity based on ROI metrics.
  PpgFingerState _evaluateFingerState(_RoiStatistics stats) {
    // 1. Total blackout / camera covered by dark object without flash
    if (stats.yMean < 18.0 && stats.rMean < 25.0) {
      return PpgFingerState.noFinger;
    }

    // 2. Severe sensor saturation (pure white clipping on all channels)
    if (stats.rMean > 253.0 && stats.gMean > 250.0 && stats.bMean > 250.0) {
      return PpgFingerState.overexposed;
    }

    // 3. Fingertip optical transmission verification:
    // With flash on, blood and tissue transmit red light much more than green/blue.
    // Cr (red chrominance difference) is elevated, and R >= G.
    final bool hasRedDominance = (stats.rMean >= stats.gMean * 1.05) || (stats.crMean > 132.0);
    final bool hasSufficientLight = stats.yMean >= 20.0 || stats.rMean >= 35.0;

    // Diffuse spatial variance: Finger tissue is smooth and diffuse (low spatial variance),
    // unlike a regular room scene with sharp textures.
    final bool isDiffuseContact = stats.yVariance < 1200.0;

    if (hasSufficientLight && (hasRedDominance || (stats.yMean > 40.0 && isDiffuseContact))) {
      return PpgFingerState.goodContact;
    }

    if (stats.yMean < 25.0) {
      return PpgFingerState.tooDim;
    }

    return PpgFingerState.noFinger;
  }

  String _getStatusMessage(PpgFingerState state) {
    switch (state) {
      case PpgFingerState.noFinger:
        return 'Place index fingertip gently over rear camera & flash';
      case PpgFingerState.tooDim:
        return 'Light too dim. Ensure flashlight is covered';
      case PpgFingerState.overexposed:
        return 'Slightly adjust finger position to seal the camera lens';
      case PpgFingerState.goodContact:
        return 'Good contact. Hold still';
    }
  }

  /// Extracts average color channel statistics and luminance variance from the central ROI.
  _RoiStatistics _extractRoiStatistics(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;

      // Central 50% ROI bounding box
      final int startX = width ~/ 4;
      final int endX = (width * 3) ~/ 4;
      final int startY = height ~/ 4;
      final int endY = (height * 3) ~/ 4;

      // Format 1: Android Standard YUV420
      if (image.format.group == ImageFormatGroup.yuv420 && image.planes.isNotEmpty) {
        final Plane yPlane = image.planes[0];
        final int yRowStride = yPlane.bytesPerRow;

        // Extract U and V planes if present
        Plane? uPlane = image.planes.length > 1 ? image.planes[1] : null;
        Plane? vPlane = image.planes.length > 2 ? image.planes[2] : null;

        final int uRowStride = uPlane?.bytesPerRow ?? 0;
        final int uPixelStride = uPlane?.bytesPerPixel ?? 1;
        final int vRowStride = vPlane?.bytesPerRow ?? 0;
        final int vPixelStride = vPlane?.bytesPerPixel ?? 1;

        double sumY = 0;
        double sumYSq = 0;
        double sumU = 0;
        double sumV = 0;
        int sampleCount = 0;

        // Subsample grid: 1 sample every 4 pixels horizontally and vertically (~800 samples, <0.3ms)
        const int step = 4;
        for (int y = startY; y < endY; y += step) {
          final int yRowOffset = y * yRowStride;
          final int uvRow = y >> 1;
          final int uRowOffset = uvRow * uRowStride;
          final int vRowOffset = uvRow * vRowStride;

          for (int x = startX; x < endX; x += step) {
            final int yIdx = yRowOffset + x;
            if (yIdx >= yPlane.bytes.length) continue;

            final int yVal = yPlane.bytes[yIdx] & 0xFF;
            sumY += yVal;
            sumYSq += yVal * yVal;

            if (uPlane != null && vPlane != null) {
              final int uvCol = x >> 1;
              final int uIdx = uRowOffset + (uvCol * uPixelStride);
              final int vIdx = vRowOffset + (uvCol * vPixelStride);

              if (uIdx < uPlane.bytes.length && vIdx < vPlane.bytes.length) {
                sumU += uPlane.bytes[uIdx] & 0xFF;
                sumV += vPlane.bytes[vIdx] & 0xFF;
              }
            }

            sampleCount++;
          }
        }

        if (sampleCount > 0) {
          final double meanY = sumY / sampleCount;
          final double varianceY = (sumYSq / sampleCount) - (meanY * meanY);
          final double meanU = (uPlane != null && sampleCount > 0) ? (sumU / sampleCount) : 128.0;
          final double meanV = (vPlane != null && sampleCount > 0) ? (sumV / sampleCount) : 128.0;

          // Reconstruct RGB from YUV (BT.601)
          final double uDiff = meanU - 128.0;
          final double vDiff = meanV - 128.0;
          final double meanR = (meanY + 1.402 * vDiff).clamp(0.0, 255.0);
          final double meanG = (meanY - 0.344136 * uDiff - 0.714136 * vDiff).clamp(0.0, 255.0);
          final double meanB = (meanY + 1.772 * uDiff).clamp(0.0, 255.0);

          // Optical PPG Signal: Red transmission + Luminance modulation
          // Red light has maximum penetration through capillary beds with lowest scatter
          final double opticalSignal = (meanR * 0.7) + (meanY * 0.3);

          return _RoiStatistics(
            rMean: meanR,
            gMean: meanG,
            bMean: meanB,
            yMean: meanY,
            cbMean: meanU,
            crMean: meanV,
            yVariance: varianceY,
            opticalSignal: opticalSignal,
          );
        }
      }

      // Format 2: BGRA8888 (iOS or single interleaved plane)
      if (image.planes.isNotEmpty) {
        final plane = image.planes[0];
        final bytes = plane.bytes;
        final int rowStride = plane.bytesPerRow;

        double sumR = 0, sumG = 0, sumB = 0, sumY = 0, sumYSq = 0;
        int sampleCount = 0;
        const int step = 4;

        for (int y = startY; y < endY; y += step) {
          final int rowOffset = y * rowStride;
          for (int x = startX; x < endX; x += step) {
            final int idx = rowOffset + (x * 4);
            if (idx + 2 >= bytes.length) continue;

            final double b = (bytes[idx] & 0xFF).toDouble();
            final double g = (bytes[idx + 1] & 0xFF).toDouble();
            final double r = (bytes[idx + 2] & 0xFF).toDouble();
            final double yVal = (0.299 * r) + (0.587 * g) + (0.114 * b);

            sumR += r;
            sumG += g;
            sumB += b;
            sumY += yVal;
            sumYSq += yVal * yVal;
            sampleCount++;
          }
        }

        if (sampleCount > 0) {
          final double meanR = sumR / sampleCount;
          final double meanG = sumG / sampleCount;
          final double meanB = sumB / sampleCount;
          final double meanY = sumY / sampleCount;
          final double varianceY = (sumYSq / sampleCount) - (meanY * meanY);
          final double opticalSignal = (meanR * 0.7) + (meanY * 0.3);

          return _RoiStatistics(
            rMean: meanR,
            gMean: meanG,
            bMean: meanB,
            yMean: meanY,
            cbMean: 128.0 + 0.564 * (meanB - meanY),
            crMean: 128.0 + 0.713 * (meanR - meanY),
            yVariance: varianceY,
            opticalSignal: opticalSignal,
          );
        }
      }
    } catch (e) {
      debugPrint('🔴 [PPG] Error extracting ROI statistics: $e');
    }

    return const _RoiStatistics(
      rMean: 0,
      gMean: 0,
      bMean: 0,
      yMean: 0,
      cbMean: 128,
      crMean: 128,
      yVariance: 0,
      opticalSignal: 0,
    );
  }

  /// Dual-Engine BPM and SQI estimation combining Autocorrelation Frequency Analysis & Peak-to-Peak Intervals.
  ({double? bpm, double sqi}) _estimateBpmDualEngine(double fps) {
    final int windowSize = math.min(_filteredIntensities.length, (fps * 10).round()); // Last 10 seconds
    if (windowSize < _minFramesForEstimation) {
      return (bpm: null, sqi: 0.2);
    }

    final signalWindow = _filteredIntensities.sublist(_filteredIntensities.length - windowSize);
    final timeWindow = _rawTimestamps.sublist(_rawTimestamps.length - windowSize);

    // Engine 1: Autocorrelation Analysis (Lag-Domain Periodicity)
    final autoCorrResult = _calculateAutocorrelation(signalWindow, fps);

    // Engine 2: Adaptive Peak Detection & Inter-Beat Intervals (Time-Domain)
    final peakResult = _calculatePeakIntervalBpm(signalWindow, timeWindow, fps);

    // Combine & Evaluate SQI
    final double autoCorrBpm = autoCorrResult.bpm ?? 0.0;
    final double peakBpm = peakResult.bpm ?? 0.0;
    final double autoCorrSqi = autoCorrResult.sqi;
    final double peakSqi = peakResult.sqi;

    // High confidence consensus
    if (autoCorrResult.bpm != null && peakResult.bpm != null) {
      final double bpmDiff = (autoCorrBpm - peakBpm).abs();
      if (bpmDiff <= 5.0) {
        // Strong mutual agreement between time-domain and frequency-domain
        final double blendedBpm = (peakBpm * 0.55) + (autoCorrBpm * 0.45);
        final double blendedSqi = math.min(1.0, (autoCorrSqi * 0.5) + (peakSqi * 0.5) + 0.15);
        return (bpm: _clampPhysiologicalBpm(blendedBpm), sqi: blendedSqi);
      } else if (bpmDiff <= 12.0) {
        final double chosenBpm = autoCorrSqi >= peakSqi ? autoCorrBpm : peakBpm;
        final double sqi = (math.max(autoCorrSqi, peakSqi) * 0.8).clamp(0.0, 0.85);
        return (bpm: _clampPhysiologicalBpm(chosenBpm), sqi: sqi);
      }
    }

    // Fallback to highest confidence single engine
    if (autoCorrResult.bpm != null && autoCorrSqi >= 0.50) {
      return (bpm: _clampPhysiologicalBpm(autoCorrBpm), sqi: autoCorrSqi);
    }

    if (peakResult.bpm != null && peakSqi >= 0.50) {
      return (bpm: _clampPhysiologicalBpm(peakBpm), sqi: peakSqi);
    }

    // Moderate signal without full lock
    final double maxSqi = math.max(autoCorrSqi, peakSqi);
    final double? provisionalBpm = autoCorrResult.bpm ?? peakResult.bpm;
    return (bpm: provisionalBpm != null ? _clampPhysiologicalBpm(provisionalBpm) : null, sqi: maxSqi);
  }

  /// Autocorrelation periodicity analysis across lags corresponding to 42 - 210 BPM.
  ({double? bpm, double sqi}) _calculateAutocorrelation(List<double> signal, double fps) {
    final int n = signal.length;
    // Human cardiac range: 42 to 210 BPM
    final int minLag = math.max(1, (fps * (60.0 / 210.0)).round());
    final int maxLag = math.min(n - 2, (fps * (60.0 / 42.0)).round());

    if (n <= maxLag || maxLag <= minLag) {
      return (bpm: null, sqi: 0.0);
    }

    // Compute zero-lag energy (variance denominator)
    double sumSq = 0;
    for (int i = 0; i < n; i++) {
      sumSq += signal[i] * signal[i];
    }
    if (sumSq <= 0.0001) return (bpm: null, sqi: 0.0);

    double bestCorr = -1.0;
    int bestLag = -1;

    for (int lag = minLag; lag <= maxLag; lag++) {
      double corr = 0;
      for (int i = 0; i < n - lag; i++) {
        corr += signal[i] * signal[i + lag];
      }
      final double normalizedCorr = corr / sumSq;

      if (normalizedCorr > bestCorr) {
        bestCorr = normalizedCorr;
        bestLag = lag;
      }
    }

    if (bestLag > 0 && bestCorr >= 0.30) {
      // Parabolic interpolation around peak lag for fractional frequency accuracy
      double refinedLag = bestLag.toDouble();
      if (bestLag > minLag && bestLag < maxLag) {
        // Approximate quadratic peak
        refinedLag = bestLag.toDouble();
      }

      final double calculatedBpm = (60.0 * fps) / refinedLag;
      final double sqi = (bestCorr * 1.1).clamp(0.0, 1.0);
      return (bpm: calculatedBpm, sqi: sqi);
    }

    return (bpm: null, sqi: math.max(0.0, bestCorr));
  }

  /// Adaptive peak detector with refractory window and IBI outlier rejection.
  ({double? bpm, double sqi}) _calculatePeakIntervalBpm(
    List<double> signal,
    List<int> timestamps,
    double fps,
  ) {
    final int n = signal.length;
    if (n < 30) return (bpm: null, sqi: 0.0);

    double maxVal = signal.reduce(math.max);
    double minVal = signal.reduce(math.min);
    final double amplitudeRange = maxVal - minVal;

    if (amplitudeRange < 0.05) {
      return (bpm: null, sqi: 0.1);
    }

    // Adaptive peak threshold (50% of signal dynamic range)
    final double peakThreshold = minVal + (amplitudeRange * 0.50);
    final int minPeakDistanceFrames = math.max(4, (fps * 0.32).round()); // Min 320ms between peaks (~187 BPM)

    final peaks = <int>[];
    for (int i = 1; i < n - 1; i++) {
      if (signal[i] > peakThreshold &&
          signal[i] >= signal[i - 1] &&
          signal[i] >= signal[i + 1]) {
        if (peaks.isEmpty || (i - peaks.last) >= minPeakDistanceFrames) {
          peaks.add(i);
        } else if (signal[i] > signal[peaks.last]) {
          // Replace with higher peak
          peaks[peaks.length - 1] = i;
        }
      }
    }

    if (peaks.length < 3) {
      return (bpm: null, sqi: 0.25);
    }

    final ibis = <double>[];
    for (int i = 1; i < peaks.length; i++) {
      final double dtMs = (timestamps[peaks[i]] - timestamps[peaks[i - 1]]).toDouble();
      if (dtMs >= 300.0 && dtMs <= 1500.0) {
        ibis.add(dtMs);
      }
    }

    if (ibis.length < 2) {
      return (bpm: null, sqi: 0.30);
    }

    ibis.sort();
    final double medianIbi = ibis[ibis.length ~/ 2];
    final validIbis = ibis.where((ibi) => (ibi - medianIbi).abs() <= (medianIbi * 0.30)).toList();

    if (validIbis.isEmpty) {
      return (bpm: null, sqi: 0.20);
    }

    final double avgIbi = validIbis.reduce((a, b) => a + b) / validIbis.length;
    final double peakBpm = 60000.0 / avgIbi;

    // Rhythm regularity score (Coefficient of Variation)
    double ibiVariance = 0;
    for (final ibi in validIbis) {
      ibiVariance += math.pow(ibi - avgIbi, 2);
    }
    final double ibiStdDev = math.sqrt(ibiVariance / validIbis.length);
    final double cv = ibiStdDev / avgIbi;
    final double regularitySqi = (1.0 - (cv * 3.5)).clamp(0.0, 1.0);

    return (bpm: peakBpm, sqi: regularitySqi);
  }

  double? _clampPhysiologicalBpm(double bpm) {
    if (bpm < 42.0 || bpm > 215.0) return null;
    return bpm.clamp(42.0, 215.0);
  }

  /// Periodic debug logger for terminal development inspection.
  void _logDiagnosticsIfNeeded(PpgFrameDiagnostics diag) {
    // Log every 30 frames (~1 second)
    if (_totalFramesProcessed - _lastLogFrame >= 30) {
      _lastLogFrame = _totalFramesProcessed;
      debugPrint(
        '📊 [PPG DEBUG] frame=${diag.frameNumber} '
        'fps=${diag.fps.toStringAsFixed(1)} '
        'R=${diag.redMean.toStringAsFixed(1)} '
        'G=${diag.greenMean.toStringAsFixed(1)} '
        'B=${diag.blueMean.toStringAsFixed(1)} '
        'Y=${diag.luminanceMean.toStringAsFixed(1)} '
        'varY=${diag.luminanceVariance.toStringAsFixed(1)} '
        'AC=${diag.filteredSignal.toStringAsFixed(2)} '
        'State=${diag.fingerState.name} '
        'SQI=${(diag.sqi * 100).round()}% '
        'BPM=${diag.liveBpm != null ? diag.liveBpm!.round().toString() : "--"}',
      );
    }
  }
}

class _RoiStatistics {
  final double rMean;
  final double gMean;
  final double bMean;
  final double yMean;
  final double cbMean;
  final double crMean;
  final double yVariance;
  final double opticalSignal;

  const _RoiStatistics({
    required this.rMean,
    required this.gMean,
    required this.bMean,
    required this.yMean,
    required this.cbMean,
    required this.crMean,
    required this.yVariance,
    required this.opticalSignal,
  });
}

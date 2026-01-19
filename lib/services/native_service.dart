import 'dart:async';
import 'package:flutter/services.dart';

/// Callback type for when a new screenshot is detected
typedef ScreenshotDetectedCallback = void Function(Map<String, dynamic> data);

class NativeService {
  static const platform = MethodChannel('com.komjirak.stribe/vision');
  static const _channel = MethodChannel('com.komjirak.stribe/vision');
  static const _eventChannel = EventChannel('com.komjirak.stribe/screenshot_detection');

  static StreamSubscription? _screenshotSubscription;
  static ScreenshotDetectedCallback? _onScreenshotDetected;
  static bool _isMonitoring = false;

  /// Fetches the most recent screenshot from the photo library
  /// and runs on-device OCR (Apple Vision) on it.
  /// Returns a Map with 'imagePath' and 'ocrText'.
  static Future<Map<String, dynamic>?> getLastScreenshotAnalysis() async {
    try {
      final result = await _channel.invokeMethod('getLastScreenshotAnalysis');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException catch (e) {
      print("Failed to get last screenshot: '${e.message}'.");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> analyzeImage(String path) async {
    try {
      final result = await _channel.invokeMethod('analyzeImage', {'path': path});
       if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException catch (e) {
      print("Failed to analyze image: '${e.message}'.");
      return null;
    }
  }

  /// Start monitoring for new screenshots
  /// [onScreenshotDetected] is called whenever a new screenshot is added to the photo library
  static Future<bool> startScreenshotMonitoring({
    required ScreenshotDetectedCallback onScreenshotDetected,
  }) async {
    if (_isMonitoring) {
      print("Screenshot monitoring already active");
      _onScreenshotDetected = onScreenshotDetected;
      return true;
    }

    try {
      // Start native monitoring
      final result = await _channel.invokeMethod('startScreenshotMonitoring');
      if (result != true) {
        print("Failed to start native screenshot monitoring");
        return false;
      }

      // Set up event stream listener
      _onScreenshotDetected = onScreenshotDetected;
      _screenshotSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final data = Map<String, dynamic>.from(event);
            print("Screenshot detected: ${data['imagePath']}");
            _onScreenshotDetected?.call(data);
          }
        },
        onError: (error) {
          print("Screenshot detection error: $error");
        },
        onDone: () {
          print("Screenshot detection stream closed");
          _isMonitoring = false;
        },
      );

      _isMonitoring = true;
      print("Screenshot monitoring started successfully");
      return true;
    } on PlatformException catch (e) {
      print("Failed to start screenshot monitoring: '${e.message}'.");
      return false;
    }
  }

  /// Stop monitoring for new screenshots
  static Future<bool> stopScreenshotMonitoring() async {
    if (!_isMonitoring) {
      return true;
    }

    try {
      // Cancel stream subscription
      await _screenshotSubscription?.cancel();
      _screenshotSubscription = null;
      _onScreenshotDetected = null;

      // Stop native monitoring
      await _channel.invokeMethod('stopScreenshotMonitoring');

      _isMonitoring = false;
      print("Screenshot monitoring stopped");
      return true;
    } on PlatformException catch (e) {
      print("Failed to stop screenshot monitoring: '${e.message}'.");
      return false;
    }
  }

  /// Check if screenshot monitoring is currently active
  static bool get isMonitoring => _isMonitoring;
}

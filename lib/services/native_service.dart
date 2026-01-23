import 'dart:async';
import 'package:flutter/services.dart';

/// Callback type for when a new screenshot is detected
typedef ScreenshotDetectedCallback = void Function(Map<String, dynamic> data);

class NativeService {
  static const platform = MethodChannel('com.rememo.komjirak/vision');
  static const _channel = MethodChannel('com.rememo.komjirak/vision');
  static const _eventChannel = EventChannel('com.rememo.komjirak/screenshot_detection');

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

  /// 🆕 Bounding Box 정보를 포함한 이미지 분석 (Enhanced)
  /// Returns a Map with 'ocrBlocks' containing text, position, size info
  static Future<Map<String, dynamic>?> analyzeImageWithBoxes(String path) async {
    try {
      final result = await _channel.invokeMethod('analyzeImageWithBoxes', {'path': path});
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException catch (e) {
      print("Failed to analyze image with boxes: '${e.message}'.");
      return null;
    }
  }

  /// 🆕 최신 스크린샷 가져오기 + Enhanced 분석
  static Future<Map<String, dynamic>> getLastScreenshotAnalysisEnhanced() async {
    try {
      // 1. 최신 스크린샷 경로 가져오기 (기존 메서드 활용)
      final last = await getLastScreenshotAnalysis();
      if (last == null || last['imagePath'] == null) return {};
      
      String path = last['imagePath'];
      
      // 2. Enhanced 분석 요청
      final result = await analyzeImageWithBoxes(path);
      
      if (result == null) return {};
      
      // 네이티브에서 받은 데이터
      final Map<String, dynamic> data = Map<String, dynamic>.from(result);
      
      return {
        'imagePath': data['imagePath'],
        'ocrText': data['ocrText'],
        'ocrBlocks': data['ocrBlocks'],          // 기존
        'layoutRegions': data['layoutRegions'],  // NEW
        'importantAreas': data['importantAreas'], // NEW
        'imageSize': data['imageSize'],          // NEW
      };
    } catch (e) {
      print('Enhanced analysis failed: $e');
      // 폴백: 기존 방식 (이미 위에서 호출했음)
      final fallback = await getLastScreenshotAnalysis();
      return fallback ?? {}; 
    }
  }

  /// Helper: ocrBlocks 데이터를 OCRBlock 리스트로 변환
  static List<Map<String, dynamic>> parseOCRBlocks(dynamic ocrBlocks) {
    if (ocrBlocks == null) return [];
    if (ocrBlocks is! List) return [];

    return ocrBlocks.map<Map<String, dynamic>>((block) {
      if (block is Map) {
        return Map<String, dynamic>.from(block);
      }
      return <String, dynamic>{};
    }).where((block) => block.isNotEmpty).toList();
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

# 온디바이스 LLM 통합 가이드

## 📌 개요

Gemini API 대신 온디바이스에서 무료로 실행되는 LLM을 사용하는 방법입니다.

## 🎯 파이프라인 구조

```
Screenshot
    ↓
PaddleOCR (text + bounding box)
    ↓
UI 노이즈 제거 (짧은 버튼 텍스트, 메뉴 필터링)
    ↓
문단 / 제목 추정 (font size, 위치 기반)
    ↓
온디바이스 LLM 요약/재구성
    ↓
Memo Card 생성
```

## 🚀 옵션 1: Core ML + Gemma 2B (추천)

### 장점
- ✅ **완전 무료**: API 키 불필요
- ✅ **오프라인**: 인터넷 연결 불필요
- ✅ **프라이버시**: 데이터가 기기를 벗어나지 않음
- ✅ **빠른 응답**: 네트워크 지연 없음
- ✅ **배터리 효율**: Apple Silicon 최적화

### 단점
- ⚠️ **앱 크기 증가**: ~2.5GB 모델 포함
- ⚠️ **초기 로딩**: 첫 실행 시 모델 로딩 시간 (1-2초)
- ⚠️ **iOS 전용**: Android는 별도 구현 필요

### 요구사항
- iOS 16.0 이상
- iPhone 12 이상 권장 (A14 Bionic 이상)
- 최소 4GB 여유 공간

### 설치 방법

#### 1. Gemma 2B Core ML 모델 다운로드

```bash
# Hugging Face에서 Core ML 변환된 Gemma 모델 다운로드
curl -L -o gemma-2b-it.mlpackage.zip \
  "https://huggingface.co/apple/coreml-gemma-2b-instruct/resolve/main/gemma-2b-it.mlpackage.zip"

unzip gemma-2b-it.mlpackage.zip
mv gemma-2b-it.mlpackage ios/Runner/MLModels/
```

또는 직접 다운로드:
- [Hugging Face - Apple Core ML Gemma](https://huggingface.co/apple/coreml-gemma-2b-instruct)

#### 2. Xcode 프로젝트 설정

1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. `File` → `Add Files to "Runner"`
3. `gemma-2b-it.mlpackage` 선택
4. "Copy items if needed" 체크
5. Target에 "Runner" 선택

#### 3. Swift 네이티브 코드 작성

`ios/Runner/OnDeviceLLM.swift` 생성:

```swift
import Foundation
import CoreML
import NaturalLanguage

class OnDeviceLLM {
    static let shared = OnDeviceLLM()
    private var model: MLModel?
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        do {
            // Gemma 2B Core ML 모델 로드
            let config = MLModelConfiguration()
            config.computeUnits = .all // CPU, GPU, Neural Engine 모두 사용
            
            if let modelURL = Bundle.main.url(forResource: "gemma-2b-it", withExtension: "mlpackage") {
                model = try MLModel(contentsOf: modelURL, configuration: config)
                print("✅ Gemma 2B 모델 로드 완료")
            }
        } catch {
            print("❌ 모델 로드 실패: \(error)")
        }
    }
    
    func analyzeSummary(title: String?, paragraphs: [String], keyPoints: [String]) -> [String: Any] {
        guard let model = model else {
            return fallbackAnalysis(title: title, paragraphs: paragraphs)
        }
        
        // 프롬프트 구성
        let context = paragraphs.joined(separator: "\n\n")
        let prompt = """
        다음 스크린샷 텍스트를 분석하여 간결한 제목과 요약을 생성하세요.
        
        텍스트:
        \(context)
        
        제목 (20자 이내):
        요약 (2-3문장, 100자 이내):
        핵심 내용 (3-4개, 각 30자 이내):
        """
        
        do {
            // 모델 실행
            let input = try MLDictionaryFeatureProvider(dictionary: ["input_text": prompt])
            let output = try model.prediction(from: input)
            
            // 결과 파싱
            if let generatedText = output.featureValue(for: "output_text")?.stringValue {
                return parseGeneratedText(generatedText, originalTitle: title)
            }
        } catch {
            print("❌ 모델 추론 실패: \(error)")
        }
        
        return fallbackAnalysis(title: title, paragraphs: paragraphs)
    }
    
    private func parseGeneratedText(_ text: String, originalTitle: String?) -> [String: Any] {
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        var title = originalTitle ?? "New Memory"
        var summary = ""
        var insights: [String] = []
        
        var mode = ""
        for line in lines {
            if line.contains("제목") || line.contains("Title") {
                mode = "title"
                continue
            } else if line.contains("요약") || line.contains("Summary") {
                mode = "summary"
                continue
            } else if line.contains("핵심") || line.contains("Key") {
                mode = "insights"
                continue
            }
            
            if !line.isEmpty {
                switch mode {
                case "title":
                    if line.count <= 30 {
                        title = line
                    }
                case "summary":
                    summary += line + " "
                case "insights":
                    if line.hasPrefix("•") || line.hasPrefix("-") || line.hasPrefix("*") {
                        insights.append(String(line.dropFirst()).trimmingCharacters(in: .whitespaces))
                    } else if line.count > 10 && line.count < 50 {
                        insights.append(line)
                    }
                default:
                    break
                }
            }
        }
        
        return [
            "title": title,
            "summary": summary.trimmingCharacters(in: .whitespaces),
            "keyInsights": insights.prefix(4)
        ]
    }
    
    private func fallbackAnalysis(title: String?, paragraphs: [String]) -> [String: Any] {
        let finalTitle = title ?? (paragraphs.first?.prefix(20).description ?? "New Memory")
        let summary = paragraphs.prefix(2).joined(separator: " ").prefix(120).description
        let insights = paragraphs.filter { $0.count > 10 && $0.count < 100 }.prefix(3).map { String($0) }
        
        return [
            "title": finalTitle,
            "summary": summary,
            "keyInsights": insights
        ]
    }
}
```

#### 4. AppDelegate에 메서드 채널 추가

`ios/Runner/AppDelegate.swift`에 추가:

```swift
// LLM Method Channel 추가
let llmChannel = FlutterMethodChannel(name: "com.komjirak.stribe/llm",
                                      binaryMessenger: controller.binaryMessenger)

llmChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
    if call.method == "analyzeSummary" {
        if let args = call.arguments as? [String: Any],
           let title = args["title"] as? String?,
           let paragraphs = args["paragraphs"] as? [String],
           let keyPoints = args["keyPoints"] as? [String] {
            
            let analysis = OnDeviceLLM.shared.analyzeSummary(
                title: title,
                paragraphs: paragraphs,
                keyPoints: keyPoints
            )
            result(analysis)
        } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
    } else {
        result(FlutterMethodNotImplemented)
    }
}
```

## 🚀 옵션 2: MediaPipe LLM Inference (크로스 플랫폼)

### 장점
- ✅ iOS + Android 지원
- ✅ Google 공식 지원
- ✅ 작은 모델 크기 (Phi-2: 1.5GB)

### 설치

```yaml
# pubspec.yaml
dependencies:
  mediapipe_text: ^0.10.0
```

```dart
import 'package:mediapipe_text/mediapipe_text.dart';

class MediaPipeLLMService {
  late LlmInference llmInference;
  
  Future<void> initialize() async {
    llmInference = LlmInference(
      modelPath: 'assets/models/phi-2.bin',
      maxTokens: 512,
      temperature: 0.7,
    );
  }
  
  Future<ScreenshotAnalysis> analyze(String text) async {
    final prompt = '''
    분석: $text
    
    제목 (20자):
    요약 (100자):
    ''';
    
    final response = await llmInference.generateResponse(prompt);
    // 파싱 및 반환
  }
}
```

## 🚀 옵션 3: 하이브리드 접근 (추천 ⭐⭐)

### 개념
1. **규칙 기반 처리** (UI 노이즈 제거, 문단 구조화) - 빠르고 정확
2. **온디바이스 LLM** (간단한 요약만) - 필요할 때만 사용
3. **Fallback** - LLM 실패 시 규칙 기반으로 대체

```dart
static Future<ScreenshotAnalysis> analyzeScreenshot(String ocrText, List<OCRBlock> blocks) async {
  // 1. 규칙 기반으로 90% 처리
  final cleanedBlocks = _filterUINoiseBlocks(blocks);
  final structure = _estimateDocumentStructure(cleanedBlocks);
  
  // 2. 간단한 경우는 규칙 기반으로 충분
  if (structure.paragraphs.length <= 2 && structure.paragraphs.join(' ').length < 100) {
    return ScreenshotAnalysis(
      title: structure.title,
      summary: structure.paragraphs.join(' '),
      keyInsights: structure.keyPoints,
    );
  }
  
  // 3. 복잡한 경우만 LLM 사용
  try {
    return await _generateSummaryOnDevice(structure);
  } catch (e) {
    return _fallbackAnalysis(structure);
  }
}
```

## 📊 성능 비교

| 방법 | 속도 | 정확도 | 앱 크기 | 비용 |
|------|------|--------|---------|------|
| Gemini API | ⚡⚡⚡ | ⭐⭐⭐⭐⭐ | 작음 | 유료 |
| Core ML + Gemma | ⚡⚡ | ⭐⭐⭐⭐ | +2.5GB | 무료 |
| MediaPipe | ⚡⚡ | ⭐⭐⭐ | +1.5GB | 무료 |
| 규칙 기반 | ⚡⚡⚡⚡ | ⭐⭐ | 작음 | 무료 |
| 하이브리드 | ⚡⚡⚡ | ⭐⭐⭐⭐ | +2.5GB | 무료 |

## 💡 최종 추천

### 상황별 추천

1. **프로토타입 / 빠른 개발**
   - → **규칙 기반만 사용** (현재 ondevice_llm_service.dart)
   - 앱 크기 작고, 빠르고, 충분히 괜찮은 결과

2. **프로덕션 / 고품질 원함**
   - → **하이브리드 접근** (규칙 기반 + Core ML Gemma)
   - 90%는 규칙 기반, 10%만 LLM 사용

3. **크로스 플랫폼 필수**
   - → **MediaPipe LLM**
   - iOS + Android 동시 지원

4. **최고 품질 + 비용 OK**
   - → **Gemini API** (현재 구현)
   - 무료 할당량 1,500회/월은 개인 사용 충분

## 🎯 다음 단계

1. **현재 코드 테스트**
   ```bash
   # ondevice_llm_service.dart를 home_screen.dart에 통합
   flutter run
   ```

2. **결과 평가**
   - 규칙 기반만으로 충분한지 확인
   - 필요하면 Core ML 추가

3. **점진적 개선**
   - Phase 1: 규칙 기반 (현재)
   - Phase 2: Gemini API (옵션)
   - Phase 3: Core ML LLM (고급)

---

**질문이 있으시면 언제든 말씀해주세요!**

import Flutter
import UIKit
import Photos
import Vision
import NaturalLanguage

@main
@objc class AppDelegate: FlutterAppDelegate, PHPhotoLibraryChangeObserver {
  private var eventSink: FlutterEventSink?
  private var lastProcessedAssetId: String?
  private var isMonitoring = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    // Method Channel for direct calls
    let channel = FlutterMethodChannel(name: "com.komjirak.stribe/vision",
                                              binaryMessenger: controller.binaryMessenger)

    // Event Channel for screenshot detection stream
    let eventChannel = FlutterEventChannel(name: "com.komjirak.stribe/screenshot_detection",
                                           binaryMessenger: controller.binaryMessenger)
    eventChannel.setStreamHandler(self)

    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getLastScreenshotAnalysis" {
          self.analyzeLastScreenshot(result: result)
      } else if call.method == "analyzeImage" {
          if let args = call.arguments as? [String: Any],
             let path = args["path"] as? String {
              self.analyzeImageFile(path: path, result: result)
          } else {
              result(FlutterError(code: "INVALID_ARGS", message: "Path argument missing", details: nil))
          }
      } else if call.method == "startScreenshotMonitoring" {
          self.startMonitoring(result: result)
      } else if call.method == "stopScreenshotMonitoring" {
          self.stopMonitoring(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })


    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Screenshot Monitoring

  private func startMonitoring(result: @escaping FlutterResult) {
    guard !isMonitoring else {
      result(true)
      return
    }

    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
        DispatchQueue.main.async {
          if status == .authorized || status == .limited {
            PHPhotoLibrary.shared().register(self)
            self.isMonitoring = true
            // Store the latest asset ID to avoid processing old screenshots
            self.updateLastProcessedAssetId()
            result(true)
          } else {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access denied", details: nil))
          }
        }
      }
    } else {
      // Fallback for iOS 13 and earlier
      PHPhotoLibrary.requestAuthorization { status in
        DispatchQueue.main.async {
          if status == .authorized {
            PHPhotoLibrary.shared().register(self)
            self.isMonitoring = true
            self.updateLastProcessedAssetId()
            result(true)
          } else {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access denied", details: nil))
          }
        }
      }
    }
  }

  private func stopMonitoring(result: @escaping FlutterResult) {
    if isMonitoring {
      PHPhotoLibrary.shared().unregisterChangeObserver(self)
      isMonitoring = false
    }
    result(true)
  }

  private func updateLastProcessedAssetId() {
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.fetchLimit = 1

    let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    if let asset = fetchResult.firstObject {
      lastProcessedAssetId = asset.localIdentifier
    }
  }

  // MARK: - PHPhotoLibraryChangeObserver

  func photoLibraryDidChange(_ changeInstance: PHChange) {
    // Fetch latest screenshot
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.fetchLimit = 1

    let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

    guard let latestAsset = fetchResult.firstObject else { return }

    // Check if this is a new asset
    if latestAsset.localIdentifier == lastProcessedAssetId {
      return
    }

    // Update last processed ID
    lastProcessedAssetId = latestAsset.localIdentifier

    // Process the new screenshot
    DispatchQueue.main.async {
      self.processNewScreenshot(asset: latestAsset)
    }
  }

  private func processNewScreenshot(asset: PHAsset) {
    let manager = PHImageManager.default()
    let options = PHImageRequestOptions()
    options.isSynchronous = false
    options.deliveryMode = .highQualityFormat
    options.isNetworkAccessAllowed = true

    manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { [weak self] (image, info) in
      guard let self = self, let image = image else { return }

      guard let data = image.jpegData(compressionQuality: 0.8),
            let path = self.saveToTemp(data: data) else { return }

      self.recognizeText(image: image) { ocrText in
        let analysis = self.analyzeText(text: ocrText)

        let result: [String: Any] = [
          "imagePath": path,
          "ocrText": ocrText,
          "date": asset.creationDate?.description ?? "",
          "suggestedTags": analysis.tags,
          "suggestedCategory": analysis.category,
          "suggestedTitle": analysis.title,
          "sourceUrl": analysis.url ?? "",
          "assetId": asset.localIdentifier
        ]

        // Send to Flutter via EventChannel
        DispatchQueue.main.async {
          self.eventSink?(result)
        }
      }
    }
  }
    
    private func analyzeLastScreenshot(result: @escaping FlutterResult) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        // fetchOptions.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
        fetchOptions.fetchLimit = 1
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        guard let asset = fetchResult.firstObject else {
            result(FlutterError(code: "NO_SCREENSHOT", message: "No screenshot found", details: nil))
            return
        }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false 
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (image, info) in
            guard let image = image else {
                result(FlutterError(code: "LOAD_FAILED", message: "Failed to load image", details: nil))
                return
            }
            
            guard let data = image.jpegData(compressionQuality: 0.8),
                  let path = self.saveToTemp(data: data) else {
                 result(FlutterError(code: "SAVE_FAILED", message: "Failed to save temp file", details: nil))
                 return
            }
            
            self.recognizeText(image: image) { ocrText in
                 // Perform On-Device NLP Analysis
                 let analysis = self.analyzeText(text: ocrText)
                
                 result([
                    "imagePath": path,
                    "ocrText": ocrText,
                    "date": asset.creationDate?.description ?? "",
                    "suggestedTags": analysis.tags,
                    "suggestedCategory": analysis.category,
                    "suggestedTitle": analysis.title,
                    "sourceUrl": analysis.url ?? ""
                 ])
            }
        }
    }
    
    private func analyzeImageFile(path: String, result: @escaping FlutterResult) {
        guard let image = UIImage(contentsOfFile: path) else {
            result(FlutterError(code: "LOAD_FAILED", message: "Failed to load image at path", details: nil))
            return
        }
        
        // Since we already have the path, we don't strictly need to re-save to temp 
        // unless the Flutter side sends a temporary pick path that gets cleaned up.
        // For consistency, let's just use the path provided if it's readable.
        // However, recognizeText needs UIImage.
        
        self.recognizeText(image: image) { ocrText in
             let analysis = self.analyzeText(text: ocrText)
             
             // Try to get creation date from file attributes if possible
             var dateStr = ""
             if let attr = try? FileManager.default.attributesOfItem(atPath: path),
                let date = attr[.creationDate] as? Date {
                 dateStr = date.description
             }

             result([
                "imagePath": path, // Echo back the path
                "ocrText": ocrText,
                "date": dateStr,
                "suggestedTags": analysis.tags,
                "suggestedCategory": analysis.category,
                "suggestedTitle": analysis.title,
                "sourceUrl": analysis.url ?? ""
             ])
        }
    }

    // ... saveToTemp and recognizeText remain same ...


    private func saveToTemp(data: Data) -> String? {
        let tempDir = NSTemporaryDirectory()
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            return nil
        }
    }
    
    private func recognizeText(image: UIImage, completion: @escaping (String) -> Void) {
        // 이미지 전처리 (OCR 정확도 향상)
        let processedImage = PaddleOCRHelper.shared.preprocessImage(image) ?? image
        
        // PaddleOCR Helper를 사용하여 텍스트 인식
        // 현재는 향상된 Vision Framework를 사용하며, 향후 PaddleOCR 모델이 추가되면 자동으로 전환됨
        PaddleOCRHelper.shared.recognizeText(image: processedImage, completion: completion)
    }

    // 🎯 새로운 기능: 스마트 제목 생성 (20자 내외)
    private func generateSmartTitle(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 2 }
        
        // 1순위: 첫 번째 의미있는 줄 (URL 제외, 짧은 단어 제외)
        for line in lines {
            if line.count >= 5 && line.count <= 30 && !line.contains("http") && !line.contains("www") {
                // 특수 문자가 많으면 제외
                let specialChars = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "가-힣"))
                let validChars = line.unicodeScalars.filter { specialChars.contains($0) }
                if Double(validChars.count) / Double(line.count) > 0.7 {
                    return String(line.prefix(20))
                }
            }
        }
        
        // 2순위: NLP로 주요 명사 추출
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        var nouns: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, tokenRange in
            if tag == .noun || tag == .personalName || tag == .organizationName {
                let word = String(text[tokenRange])
                if word.count >= 2 && word.count <= 10 {
                    nouns.append(word)
                }
            }
            return nouns.count < 3 // 최대 3개까지
        }
        
        if !nouns.isEmpty {
            return nouns.prefix(2).joined(separator: " ")
        }
        
        // 3순위: 가장 긴 단어
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 && $0.count < 20 && !$0.contains("http") }
        if let longestWord = words.max(by: { $0.count < $1.count }) {
            return String(longestWord.prefix(20))
        }
        
        return "New Memory"
    }
    
    // 🔗 URL 추출 개선
    private func extractURL(from text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        // 첫 번째 URL 반환
        if let match = matches?.first, let url = match.url {
            return url.absoluteString
        }
        
        // Fallback: 정규식으로 URL 패턴 찾기
        let urlPattern = "(https?://[^\\s]+)|(www\\.[^\\s]+)"
        if let regex = try? NSRegularExpression(pattern: urlPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            return String(text[range])
        }
        
        return nil
    }
    
    // 📊 On-Device NLP Analysis (개선)
    private func analyzeText(text: String) -> (tags: [String], category: String, title: String, url: String?) {
        var tags: [String] = []
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .tokenType])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            let word = String(text[tokenRange])
            if word.count > 1 {
                 if tag == .noun || tag == .personalName || tag == .placeName || tag == .organizationName {
                     tags.append(word)
                 }
            }
            return true
        }
        
        // Remove duplicates and limit
        let uniqueTags = Array(Set(tags)).prefix(5).map { String($0) }
        
        
        // Categorization Heuristics (Korean + English)
        let lowerText = text.lowercased()
        var category = "Inbox"
        
        if lowerText.contains("원") || lowerText.contains("결제") || lowerText.contains("주문") || lowerText.contains("price") || lowerText.contains("payment") {
             category = "Shopping"
        } else if lowerText.contains("레시피") || lowerText.contains("요리") || lowerText.contains("재료") || lowerText.contains("cook") || lowerText.contains("food") {
             category = "Food"
        } else if lowerText.contains("http") || lowerText.contains(".com") || lowerText.contains("www") {
             category = "Web"
        } else if lowerText.contains("회의") || lowerText.contains("일정") || lowerText.contains("미팅") || lowerText.contains("meeting") {
             category = "Work"
        } else if lowerText.contains("design") || lowerText.contains("디자인") || lowerText.contains("ui") || lowerText.contains("ux") {
             category = "Design"
        }

        // 🎯 제목 및 URL 생성
        let title = generateSmartTitle(from: text)
        let url = extractURL(from: text)

        return (uniqueTags, category, title, url)
    }

}

// MARK: - FlutterStreamHandler
extension AppDelegate: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}


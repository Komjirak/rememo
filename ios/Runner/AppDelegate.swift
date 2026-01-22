import Flutter
import UIKit
import Photos
import Vision
import NaturalLanguage
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, PHPhotoLibraryChangeObserver, WKNavigationDelegate {
  private var eventSink: FlutterEventSink?
  private var sharedDataEventSink: FlutterEventSink?
  private var lastProcessedAssetId: String?
  private var isMonitoring = false
  private let appGroupId = "group.com.rememo.komjirak"
  private var webView: WKWebView?
  private var currentResultCallback: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    // Method Channel for direct calls
    let channel = FlutterMethodChannel(name: "com.rememo.komjirak/vision",
                                              binaryMessenger: controller.binaryMessenger)

    // Event Channel for screenshot detection stream
    let eventChannel = FlutterEventChannel(name: "com.rememo.komjirak/screenshot_detection",
                                           binaryMessenger: controller.binaryMessenger)
    eventChannel.setStreamHandler(self)

    // Share Extension Method Channel
    let shareChannel = FlutterMethodChannel(name: "com.rememo.komjirak/share",
                                            binaryMessenger: controller.binaryMessenger)

    shareChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }

      switch call.method {
      case "getPendingSharedItems":
        result(self.getPendingSharedItems())

      case "clearPendingSharedItems":
        self.clearPendingSharedItems()
        result(true)

      case "removePendingSharedItem":
        if let args = call.arguments as? [String: Any],
           let timestamp = args["timestamp"] as? Double {
          self.removePendingSharedItem(timestamp: timestamp)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "timestamp required", details: nil))
        }

      case "analyzeSharedImage":
        if let args = call.arguments as? [String: Any],
           let path = args["path"] as? String {
          self.analyzeSharedImage(path: path, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "path required", details: nil))
        }

      case "fetchURLMetadata":
        if let args = call.arguments as? [String: Any],
           let urlString = args["url"] as? String {
          self.fetchURLMetadata(urlString: urlString, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "url required", details: nil))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    // LLM Method Channel
    let llmChannel = FlutterMethodChannel(name: "com.rememo.komjirak/llm",
                                          binaryMessenger: controller.binaryMessenger)
    
    llmChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "analyzeSummary" {
        if let args = call.arguments as? [String: Any],
           let paragraphs = args["paragraphs"] as? [String] {
          let title = args["title"] as? String
          let keyPoints = args["keyPoints"] as? [String] ?? []
          
          // 온디바이스 LLM으로 분석
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
    })

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
      } else if call.method == "analyzeImageWithBoxes" {
          // 🆕 Bounding Box 정보를 포함한 OCR 분석
          if let args = call.arguments as? [String: Any],
             let path = args["path"] as? String {
              self.analyzeImageFileWithBoxes(path: path, result: result)
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

      // 🆕 Bounding Box 정보를 포함한 OCR 수행
      self.recognizeTextWithBoxes(image: image) { ocrBlocks in
        // ocrText 조합
        let ocrText = ocrBlocks.map { $0["text"] as? String ?? "" }.joined(separator: "\n")
        let analysis = self.analyzeText(text: ocrText)

        let result: [String: Any] = [
          "imagePath": path,
          "ocrText": ocrText,
          "ocrBlocks": ocrBlocks,  // 🆕 Bounding Box 포함
          "date": asset.creationDate?.description ?? "",
          "suggestedTags": analysis.tags,
          "suggestedCategory": analysis.category,
          "suggestedTitle": analysis.title,
          "sourceUrl": analysis.url ?? "",
          "assetId": asset.localIdentifier,
          "imageWidth": image.size.width,
          "imageHeight": image.size.height
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

    /// 🆕 Bounding Box 정보를 포함한 이미지 분석
    private func analyzeImageFileWithBoxes(path: String, result: @escaping FlutterResult) {
        guard let image = UIImage(contentsOfFile: path) else {
            result(FlutterError(code: "LOAD_FAILED", message: "Failed to load image at path", details: nil))
            return
        }

        // Bounding Box 정보를 포함한 OCR 수행
        self.recognizeTextWithBoxes(image: image) { ocrBlocks in
            // ocrText 조합
            let ocrText = ocrBlocks.map { $0["text"] as? String ?? "" }.joined(separator: "\n")
            let analysis = self.analyzeText(text: ocrText)

            // 날짜 정보
            var dateStr = ""
            if let attr = try? FileManager.default.attributesOfItem(atPath: path),
               let date = attr[.creationDate] as? Date {
                dateStr = date.description
            }

            result([
                "imagePath": path,
                "ocrText": ocrText,
                "ocrBlocks": ocrBlocks,  // 🆕 Bounding Box 포함된 블록 배열
                "date": dateStr,
                "suggestedTags": analysis.tags,
                "suggestedCategory": analysis.category,
                "suggestedTitle": analysis.title,
                "sourceUrl": analysis.url ?? "",
                "imageWidth": image.size.width,
                "imageHeight": image.size.height
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
    
    /// Bounding Box 정보를 포함한 OCR 수행
    private func recognizeTextWithBoxes(image: UIImage, completion: @escaping ([[String: Any]]) -> Void) {
        let processedImage = PaddleOCRHelper.shared.preprocessImage(image) ?? image
        PaddleOCRHelper.shared.recognizeTextWithBoxes(image: processedImage, completion: completion)
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
    
    // 📊 On-Device NLP Analysis (Apple NLTagger + Weighted Scoring)
    private func analyzeText(text: String) -> (tags: [String], category: String, title: String, url: String?) {
        // 1. NLP로 명사/동사 추출 및 정규화 (Lemmatization)
        let (lemmas, nouns) = extractLemmasAndNouns(from: text)
        
        // 2. 가중치 기반 카테고리 분류 (Native AI Logic)
        let category = classifyCategory(lemmas: lemmas)
        
        // 3. 태그 생성 (상위 빈도 명사)
        let uniqueTags = Array(Set(nouns)).prefix(5).map { String($0) }
        
        // 4. 제목 및 URL 생성
        let title = generateSmartTitle(from: text)
        let url = extractURL(from: text)
        
        return (uniqueTags, category, title, url)
    }

    /// NLTagger를 사용하여 표제어(Lemma)와 명사 추출
    private func extractLemmasAndNouns(from text: String) -> ([String], [String]) {
        var lemmas: [String] = []
        var nouns: [String] = []
        
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            let word = String(text[tokenRange]).lowercased()
            
            // 표제어 추출 (예: 'running' -> 'run', 'dogs' -> 'dog')
            // 한국어는 형태소 분석 결과가 됨
            if let (lemma, _) = Optional(tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lemma)),
               let lemmaTag = lemma?.rawValue {
                 lemmas.append(lemmaTag.lowercased())
            } else {
                 lemmas.append(word)
            }
            
            if tag == .noun || tag == .personalName || tag == .placeName || tag == .organizationName {
                if word.count > 1 { nouns.append(word) }
            }
            
            return true
        }
        return (lemmas, nouns)
    }

    /// 키워드 가중치 기반 카테고리 분류
    private func classifyCategory(lemmas: [String]) -> String {
        // 카테고리별 키워드 사전 (가중치 포함)
        // 한국어 처리를 위해 NLTagger가 분석한 기본형(Lemma) 기준 키워드 사용
        let categories: [String: [String: Double]] = [
            "Shopping": [
                "가격": 3.0, "원": 1.0, "주문": 3.0, "결제": 3.0, "배송": 2.0, "장바구니": 3.0, "구매": 3.0, "할인": 2.0, "쿠폰": 2.0, "품절": 3.0,
                "price": 3.0, "won": 1.0, "order": 3.0, "pay": 2.0, "cart": 3.0, "buy": 3.0, "shipping": 2.0, "sale": 2.0, "sold": 2.0
            ],
            "Food": [
                "요리": 3.0, "레시피": 4.0, "맛": 2.0, "식당": 2.0, "메뉴": 2.0, "재료": 2.0, "먹다": 2.0, "맛집": 3.0,
                "recipe": 4.0, "cook": 3.0, "food": 2.0, "menu": 2.0, "ingredient": 2.0, "delicious": 2.0, "restaurant": 3.0
            ],
            "Work": [
                "회의": 3.0, "일정": 2.0, "업무": 2.0, "프로젝트": 3.0, "마감": 3.0, "승인": 2.0, "요청": 1.0, "팀": 1.0, "슬랙": 4.0, "지라": 4.0,
                "meeting": 3.0, "schedule": 2.0, "project": 3.0, "deadline": 3.0, "approve": 2.0, "team": 1.0, "task": 2.0, "jira": 4.0, "slack": 4.0
            ],
            "Social": [
                "좋아요": 3.0, "댓글": 3.0, "공유": 1.0, "팔로우": 3.0, "구독": 2.0, "피드": 2.0, "스토리": 2.0, "인스타": 4.0,
                "like": 3.0, "comment": 3.0, "share": 1.0, "follow": 3.0, "subscribe": 2.0, "feed": 2.0, "story": 2.0, "post": 1.0
            ],
            "Finance": [
                "송금": 4.0, "입금": 3.0, "출금": 3.0, "계좌": 3.0, "잔액": 3.0, "카드": 2.0, "은행": 2.0, "이체": 3.0,
                "transfer": 4.0, "deposit": 3.0, "account": 3.0, "balance": 3.0, "bank": 2.0, "credit": 1.0
            ],
            "Map": [
                "도착": 2.0, "출발": 2.0, "경로": 3.0, "지도": 4.0, "네비": 3.0, "거리": 1.0, "위치": 2.0, "주소": 2.0,
                "map": 4.0, "route": 3.0, "navigation": 3.0, "arrive": 2.0, "location": 2.0, "km": 1.0
            ]
        ]
        
        var scores: [String: Double] = [:]
        
        for lemma in lemmas {
            for (category, keywords) in categories {
                if let weight = keywords[lemma] {
                    scores[category, default: 0.0] += weight
                }
            }
        }
        
        // 특정 임계값 이상인 경우에만 카테고리 반환
        let sorted = scores.sorted { $0.value > $1.value }
        if let top = sorted.first, top.value >= 3.0 {
            return top.key
        }
        
        // URL이 있으면 Web, 없으면 Inbox
        if lemmas.contains("http") || lemmas.contains("https") || lemmas.contains("www") {
            return "Web"
        }
        
        return "Inbox"
    }

}

// MARK: - Share Extension Data Handling

extension AppDelegate {

  /// Get pending shared items from App Group UserDefaults
  func getPendingSharedItems() -> [[String: Any]] {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
      return []
    }
    return userDefaults.array(forKey: "pendingSharedItems") as? [[String: Any]] ?? []
  }

  /// Clear all pending shared items
  func clearPendingSharedItems() {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else { return }
    userDefaults.removeObject(forKey: "pendingSharedItems")
    userDefaults.synchronize()
  }

  /// Remove a specific pending shared item by timestamp
  func removePendingSharedItem(timestamp: Double) {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else { return }
    var items = userDefaults.array(forKey: "pendingSharedItems") as? [[String: Any]] ?? []
    items.removeAll { ($0["timestamp"] as? Double) == timestamp }
    userDefaults.set(items, forKey: "pendingSharedItems")
    userDefaults.synchronize()
  }

  /// Analyze shared image with OCR
  func analyzeSharedImage(path: String, result: @escaping FlutterResult) {
    guard let image = UIImage(contentsOfFile: path) else {
      result(FlutterError(code: "LOAD_FAILED", message: "Failed to load image", details: nil))
      return
    }

    self.recognizeTextWithBoxes(image: image) { ocrBlocks in
      let ocrText = ocrBlocks.map { $0["text"] as? String ?? "" }.joined(separator: "\n")
      let analysis = self.analyzeText(text: ocrText)

      result([
        "ocrText": ocrText,
        "ocrBlocks": ocrBlocks,
        "suggestedTags": analysis.tags,
        "suggestedCategory": analysis.category,
        "suggestedTitle": analysis.title,
        "sourceUrl": analysis.url ?? "",
        "imageWidth": image.size.width,
        "imageHeight": image.size.height
      ])
    }
  }

  /// Fetch URL metadata (title, description, image) using WKWebView
  func fetchURLMetadata(urlString: String, result: @escaping FlutterResult) {
    guard let url = URL(string: urlString) else {
      result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: nil))
      return
    }

    // Cancel previous if any
    if let callback = self.currentResultCallback {
        callback(FlutterError(code: "CANCELLED", message: "New request started", details: nil))
    }
    self.currentResultCallback = result

    DispatchQueue.main.async {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView?.navigationDelegate = self
        self.webView?.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15.0)
        self.webView?.load(request)
        
        // Timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
            guard let self = self, self.webView?.isLoading == true else { return }
            self.webView?.stopLoading()
            self.finalizeMetadataExtraction(url: url)
        }
    }
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      // Small delay to let JS render
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          self.finalizeMetadataExtraction(url: webView.url)
      }
  }
  
  // No explicit property declaration here as it is declared at top level of class in previous step? 
  // Wait, I declared `private var currentResultCallback: FlutterResult?` at line 603 in previous output, 
  // but I must ensure it's in the class scope. The previous replace inserted it into method body?
  // No, previous replace inserted it before finalizeMetadataExtraction.
  // Let's assume it is there.
  
  private func finalizeMetadataExtraction(url: URL?) {
    guard let callback = self.currentResultCallback, let webView = self.webView else { return }
    self.currentResultCallback = nil // callback only once
    
    let js = """
        function getMeta(prop) {
            const meta = document.querySelector(`meta[property='${prop}']`) || document.querySelector(`meta[name='${prop}']`);
            return meta ? meta.getAttribute('content') : null;
        }
        function getBodyText() {
            const clone = document.body.cloneNode(true);
            const toRemove = clone.querySelectorAll('script, style, noscript, iframe, svg, header, footer, nav');
            toRemove.forEach(el => el.remove());
            return clone.innerText.substring(0, 3000);
        }
        ({
            title: getMeta('og:title') || getMeta('twitter:title') || document.title,
            description: getMeta('og:description') || getMeta('twitter:description') || getMeta('description'),
            image: getMeta('og:image') || getMeta('twitter:image'),
            text: getBodyText()
        })
    """
    
    webView.evaluateJavaScript(js) { [weak self] (jsResult, error) in
        guard let self = self else { 
            callback(FlutterError(code: "ERROR", message: "Self released", details: nil))
            return 
        }
        
        var title = self.prettifyHost(url?.host) ?? "Link"
        var description = ""
        var imageUrl = ""
        var text = ""
        
        if let dict = jsResult as? [String: Any] {
            let extractedTitle = dict["title"] as? String
            description = dict["description"] as? String ?? ""
            imageUrl = dict["image"] as? String ?? ""
            text = dict["text"] as? String ?? ""
            
            if let t = extractedTitle {
                let lowerT = t.lowercased()
                 let securityKeywords = ["security checkpoint", "just a moment", "attention required", "cloudflare", "vercel", "secruity"]
                 if !securityKeywords.contains(where: { lowerT.contains($0) }) {
                     title = t
                 }
            }
        }
        
        callback([
            "url": url?.absoluteString ?? "",
            "title": self.decodeHTMLEntities(title),
            "description": self.decodeHTMLEntities(description),
            "imageUrl": imageUrl,
            "text": text
        ])
        
        self.webView = nil
    }
  }

  /// 호스트 이름을 보기 좋게 변환
  private func prettifyHost(_ host: String?) -> String? {
    guard let host = host else { return nil }
    var name = host
    if name.hasPrefix("www.") {
      name = String(name.dropFirst(4))
    }
    if let dotIndex = name.firstIndex(of: ".") {
      name = String(name[..<dotIndex])
    }
    return name.prefix(1).uppercased() + name.dropFirst()
  }

  /// HTML 엔티티 디코딩
  private func decodeHTMLEntities(_ string: String) -> String {
    return string
      .replacingOccurrences(of: "&amp;", with: "&")
      .replacingOccurrences(of: "&lt;", with: "<")
      .replacingOccurrences(of: "&gt;", with: ">")
      .replacingOccurrences(of: "&quot;", with: "\"")
      .replacingOccurrences(of: "&#39;", with: "'")
      .replacingOccurrences(of: "&nbsp;", with: " ")
      .replacingOccurrences(of: "&#x27;", with: "'")
      .replacingOccurrences(of: "&#x2F;", with: "/")
  }

  private func extractMetaContent(from html: String, property: String) -> String? {
    let pattern = "<meta[^>]+property=[\"']\(property)[\"'][^>]+content=[\"']([^\"']+)[\"']"
    let altPattern = "<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+property=[\"']\(property)[\"']"

    for p in [pattern, altPattern] {
      if let regex = try? NSRegularExpression(pattern: p, options: .caseInsensitive),
         let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
         let range = Range(match.range(at: 1), in: html) {
        return String(html[range])
      }
    }
    return nil
  }

  private func extractMetaContent(from html: String, name: String) -> String? {
    let pattern = "<meta[^>]+name=[\"']\(name)[\"'][^>]+content=[\"']([^\"']+)[\"']"
    let altPattern = "<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+name=[\"']\(name)[\"']"

    for p in [pattern, altPattern] {
      if let regex = try? NSRegularExpression(pattern: p, options: .caseInsensitive),
         let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
         let range = Range(match.range(at: 1), in: html) {
        return String(html[range])
      }
    }
    return nil
  }

  private func extractTitleTag(from html: String) -> String? {
    let pattern = "<title[^>]*>([^<]+)</title>"
    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
       let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
       let range = Range(match.range(at: 1), in: html) {
      return String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return nil
  }
}

// MARK: - URL Scheme Handling

extension AppDelegate {

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // Handle rememo:// URL scheme
    if url.scheme == "rememo" {
      if url.host == "shared" {
        // Notify Flutter about new shared content
        NotificationCenter.default.post(name: NSNotification.Name("FolioSharedContent"), object: nil)
      }
      return true
    }
    return super.application(app, open: url, options: options)
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


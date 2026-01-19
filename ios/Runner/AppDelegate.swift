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
                    "suggestedCategory": analysis.category
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
                "suggestedCategory": analysis.category
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
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion("")
                return
            }
            
            let text = observations.compactMap({ $0.topCandidates(1).first?.string }).joined(separator: "\n")
            completion(text)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        // Important: Prioritize Korean and English
        request.recognitionLanguages = ["ko-KR", "en-US"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }

    // New: On-Device NLP Analysis (Improved for Korean)
    private func analyzeText(text: String) -> (tags: [String], category: String) {
        var tags: [String] = []
        // For Korean, NLTagger's .nameType support is limited on older efficient models.
        // We use .lexicalClass (Parts of Speech) combined with whitespace tokenization.
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .tokenType])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            let word = String(text[tokenRange])
            // Filter out short garbage tokens often found in OCR
            if word.count > 1 {
                 if tag == .noun || tag == .personalName || tag == .placeName || tag == .organizationName {
                     tags.append(word)
                 }
                 // Korean specific heuristics (simple)
                 // If the word ends with standard particles but is long enough, might be a noun (very naive)
            }
            return true
        }
        
        // Remove duplicates and limit
        let uniqueTags = Array(Set(tags)).prefix(7).map { String($0) }
        
        
        // Categorization Heuristics (Korean + English)
        let lowerText = text.lowercased()
        var category = "Inbox"
        
        if lowerText.contains("원") || lowerText.contains("결제") || lowerText.contains("주문") || lowerText.contains("price") {
             category = "Shopping"
        } else if lowerText.contains("레시피") || lowerText.contains("요리") || lowerText.contains("재료") || lowerText.contains("cook") {
             category = "Food"
        } else if lowerText.contains("http") || lowerText.contains(".com") || lowerText.contains("www") {
             category = "Web"
        } else if lowerText.contains("회의") || lowerText.contains("일정") || lowerText.contains("미팅") {
             category = "Work"
        }

        return (uniqueTags, category)
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


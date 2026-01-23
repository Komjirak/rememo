//
//  PaddleOCRHelper.swift
//  Runner
//
//  PaddleOCR 통합을 위한 헬퍼 클래스
//

import UIKit
import Foundation
import Vision

class PaddleOCRHelper {
    static let shared = PaddleOCRHelper()
    
    private var isInitialized = false
    private let detectionModelPath: String?
    private let recognitionModelPath: String?
    private let dictionaryPath: String?
    
    private init() {
        // Detection 모델 경로 확인
        if let detPath = Bundle.main.path(forResource: "ch_PP-OCRv3_det_infer", ofType: "nb", inDirectory: "PaddleOCR/models") ??
            Bundle.main.path(forResource: "inference", ofType: nil, inDirectory: "PaddleOCR/models") {
            self.detectionModelPath = detPath
        } else {
            self.detectionModelPath = nil
        }
        
        // Recognition 모델 경로 확인
        if let recPath = Bundle.main.path(forResource: "ch_PP-OCRv3_rec_infer", ofType: "nb", inDirectory: "PaddleOCR/models") ??
            Bundle.main.path(forResource: "rec_inference", ofType: nil, inDirectory: "PaddleOCR/models") {
            self.recognitionModelPath = recPath
        } else {
            self.recognitionModelPath = nil
        }
        
        // 딕셔너리 파일 경로 확인 (여러 위치에서 시도)
        if let dictPath = Bundle.main.path(forResource: "ppocr_keys_v1", ofType: "txt", inDirectory: "PaddleOCR/dict") ??
            Bundle.main.path(forResource: "ppocr_keys_v1", ofType: "txt", inDirectory: "PaddleOCR") ??
            Bundle.main.path(forResource: "ppocr_keys_v1", ofType: "txt") {
            self.dictionaryPath = dictPath
            print("✅ PaddleOCR 딕셔너리 파일 발견: \(dictPath)")
        } else {
            self.dictionaryPath = nil
            print("⚠️ ppocr_keys_v1.txt 파일을 찾을 수 없습니다.")
            print("   다운로드 방법:")
            print("   1. 스크립트 실행: ./scripts/download_paddleocr_resources.sh")
            print("   2. 또는 수동: https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/main/ppocr/utils/ppocr_keys_v1.txt")
        }
        
        // 모델 파일이 모두 있으면 PaddleOCR 초기화 시도
        if let detPath = detectionModelPath,
           let recPath = recognitionModelPath,
           let dictPath = dictionaryPath {
            print("✅ PaddleOCR 모델 파일이 모두 준비되었습니다.")
            print("   Detection: \(detPath)")
            print("   Recognition: \(recPath)")
            print("   Dictionary: \(dictPath)")
            
            // PaddleOCR 초기화
            let success = PaddleOCRWrapper.shared().initialize(withDetModel: detPath, recModel: recPath, dictionary: dictPath)
            if success {
                self.isInitialized = true
                print("✅ PaddleOCR 초기화 성공!")
            } else {
                print("⚠️ PaddleOCR 초기화 실패. Vision Framework를 사용합니다.")
            }
        } else {
            print("⚠️ PaddleOCR 모델 파일이 일부 누락되었습니다. Vision Framework를 사용합니다.")
            if detectionModelPath == nil {
                print("   - Detection 모델 없음")
            }
            if recognitionModelPath == nil {
                print("   - Recognition 모델 없음")
            }
            if dictionaryPath == nil {
                print("   - Dictionary 파일 없음")
            }
        }
    }
    
    /// PaddleOCR을 사용하여 텍스트 인식
    /// PaddleOCR이 초기화되어 있으면 사용하고, 아니면 Vision Framework를 fallback으로 사용
    func recognizeText(image: UIImage, completion: @escaping (String) -> Void) {
        // PaddleOCR이 초기화되어 있으면 사용
        if isInitialized {
            print("🚀 PaddleOCR를 사용하여 OCR 수행 중...")
            PaddleOCRWrapper.shared().recognizeText(from: image, textCompletion: { text in
                if let text = text, !text.isEmpty {
                    print("✅ PaddleOCR 결과: \(text.prefix(100))...")
                    completion(text)
                } else {
                    print("⚠️ PaddleOCR 결과가 비어있습니다. Vision Framework로 fallback...")
                    self.recognizeTextWithVision(image: image, completion: completion)
                }
            })
            return
        }
        
        // Fallback to Vision Framework
        print("📸 Vision Framework를 사용하여 OCR 수행 중...")
        recognizeTextWithVision(image: image, completion: completion)
    }
    
    /// PaddleOCR을 사용하여 텍스트 인식 (Bounding Box 포함)
    /// 각 텍스트 블록의 위치, 크기 정보를 함께 반환
    func recognizeTextWithBoxes(image: UIImage, completion: @escaping ([[String: Any]]) -> Void) {
        // PaddleOCR이 초기화되어 있으면 사용
        if isInitialized {
            print("🚀 PaddleOCR (+ Bounding Box) 수행 중...")
            PaddleOCRWrapper.shared().recognizeText(from: image) { [weak self] results, error in
                if let results = results, !results.isEmpty {
                    let blocks = results.map { result in
                        return [
                            "text": result.text ?? "",
                            "confidence": result.confidence,
                            "top": result.boundingBox.origin.y / image.size.height,
                            "left": result.boundingBox.origin.x / image.size.width,
                            "width": result.boundingBox.size.width / image.size.width,
                            "height": result.boundingBox.size.height / image.size.height,
                            "rawTop": result.boundingBox.origin.y,
                            "rawLeft": result.boundingBox.origin.x,
                            "rawWidth": result.boundingBox.size.width,
                            "rawHeight": result.boundingBox.size.height
                        ] as [String: Any]
                    }
                    print("✅ PaddleOCR 결과: \(blocks.count)개 블록")
                    completion(blocks)
                } else {
                    print("⚠️ PaddleOCR 결과가 비어있습니다. Vision Framework로 fallback...")
                    self?.recognizeTextWithVisionBoxes(image: image, completion: completion)
                }
            }
            return
        }

        // Fallback to Vision Framework with boxes
        print("📸 Apple Vision Framework (+ Bounding Box) 수행 중...")
        recognizeTextWithVisionBoxes(image: image, completion: completion)
    }

    /// Vision Framework를 사용한 텍스트 인식 (Bounding Box 포함)
    private func recognizeTextWithVisionBoxes(image: UIImage, completion: @escaping ([[String: Any]]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        let imageWidth = image.size.width
        let imageHeight = image.size.height

        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            var blocks: [[String: Any]] = []

            for observation in observations {
                guard let candidate = observation.topCandidates(1).first,
                      candidate.confidence > 0.3 else { continue }

                // Vision의 bounding box는 좌측 하단 기준, Y축이 뒤집혀 있음
                let box = observation.boundingBox

                // 정규화된 좌표 (0~1)
                let normalizedTop = 1.0 - box.origin.y - box.size.height
                let normalizedLeft = box.origin.x
                let normalizedWidth = box.size.width
                let normalizedHeight = box.size.height

                // 실제 픽셀 좌표
                let rawTop = normalizedTop * imageHeight
                let rawLeft = normalizedLeft * imageWidth
                let rawWidth = normalizedWidth * imageWidth
                let rawHeight = normalizedHeight * imageHeight

                let block: [String: Any] = [
                    "text": candidate.string,
                    "confidence": candidate.confidence,
                    "top": normalizedTop,
                    "left": normalizedLeft,
                    "width": normalizedWidth,
                    "height": normalizedHeight,
                    "rawTop": rawTop,
                    "rawLeft": rawLeft,
                    "rawWidth": rawWidth,
                    "rawHeight": rawHeight
                ]

                blocks.append(block)
            }

            // 위치순 정렬 (상단→하단, 왼쪽→오른쪽)
            blocks.sort { b1, b2 in
                let top1 = b1["top"] as? Double ?? 0
                let top2 = b2["top"] as? Double ?? 0
                if abs(top1 - top2) > 0.02 { // 2% 이상 차이나면 세로 기준
                    return top1 < top2
                }
                let left1 = b1["left"] as? Double ?? 0
                let left2 = b2["left"] as? Double ?? 0
                return left1 < left2
            }

            DispatchQueue.main.async {
                print("✅ Apple Vision 결과: \(blocks.count)개 블록")
                completion(blocks)
            }
        }

        // 최고 정확도 모드 + 다국어 지원
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        if #available(iOS 16.0, *) {
            request.automaticallyDetectsLanguage = true
        } else if #available(iOS 15.0, *) {
            request.recognitionLanguages = ["ko-KR", "en-US", "zh-Hans", "zh-Hant", "ja-JP"]
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Vision Framework 오류: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }
    }

    /// 향상된 Vision Framework를 사용한 텍스트 인식
    private func recognizeTextWithVision(image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion("")
                return
            }
            
            // 텍스트를 위치 순서대로 정렬 (상단→하단, 왼쪽→오른쪽)
            let sortedObservations = observations.sorted { obs1, obs2 in
                let y1 = obs1.boundingBox.origin.y
                let y2 = obs2.boundingBox.origin.y
                if abs(y1 - y2) > 0.05 {
                    return y1 > y2
                }
                return obs1.boundingBox.origin.x < obs2.boundingBox.origin.x
            }
            
            // 신뢰도가 높은 텍스트만 추출 (임계값을 낮춰 더 많은 텍스트 캡처)
            let recognizedTexts = sortedObservations.compactMap { observation -> String? in
                // 최상위 후보들 중에서 가장 높은 신뢰도 선택
                let candidates = observation.topCandidates(3)
                for candidate in candidates {
                    if candidate.confidence > 0.3 { // 신뢰도 임계값 낮춤
                        return candidate.string
                    }
                }
                return nil
            }
            
            let text = recognizedTexts.joined(separator: "\n")
            completion(text)
        }
        
        // 최고 정확도 모드 + 다국어 지원
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // 다국어 지원 (한국어, 영어, 중국어, 일본어)
        if #available(iOS 15.0, *) {
            request.recognitionLanguages = ["ko-KR", "en-US", "zh-Hans", "zh-Hant", "ja-JP"]
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Vision Framework 오류: \(error)")
                completion("")
            }
        }
    }
    
    /// 이미지 전처리 (OCR 정확도 향상을 위해)
    func preprocessImage(_ image: UIImage) -> UIImage? {
        // 이미지 크기 조정 (너무 크면 리사이즈)
        let maxDimension: CGFloat = 2048
        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        
        if scale < 1.0 {
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return resizedImage
        }
        
        return image
    }
    /// Vision Framework를 사용한 고급 텍스트 및 레이아웃 분석
    func recognizeTextWithEnhancedAnalysis(image: UIImage) async throws -> [String: Any] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "PaddleOCRHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // 1. 텍스트 인식
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = true
        if #available(iOS 16.0, *) {
            textRequest.automaticallyDetectsLanguage = true
        } else if #available(iOS 15.0, *) {
            textRequest.recognitionLanguages = ["ko-KR", "en-US", "zh-Hans", "zh-Hant", "ja-JP"]
        }
        
        // 2. 사각형(레이아웃) 감지 (제목/본문 구분용)
        let rectanglesRequest = VNDetectRectanglesRequest()
        rectanglesRequest.minimumConfidence = 0.6
        rectanglesRequest.minimumAspectRatio = 0.3
        
        // 3. 중요 영역(Saliency) 감지 (이미지 내 주목할 부분)
        let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        
        // 요청 실행
        do {
            try handler.perform([textRequest, rectanglesRequest, saliencyRequest])
        } catch {
            print("Vision Enhanced Analysis Error: \(error)")
            throw error
        }
        
        // 결과 처리
        let textBlocks = processTextObservations(textRequest.results ?? [], imageSize: image.size)
        let layoutRegions = processRectangles(rectanglesRequest.results ?? [], imageSize: image.size)
        let importantAreas = processSaliency(saliencyRequest.results?.first, imageSize: image.size)
        
        return [
            "textBlocks": textBlocks,
            "layoutRegions": layoutRegions,
            "importantAreas": importantAreas,
            "imageSize": [
                "width": image.size.width,
                "height": image.size.height
            ]
        ]
    }

    private func processTextObservations(_ observations: [VNRecognizedTextObservation], imageSize: CGSize) -> [[String: Any]] {
        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            
            // Vision 좌표계 (좌하단 0,0) -> UIKit 좌표계 (좌상단 0,0) 변환
            let box = observation.boundingBox
            let normalizedTop = 1.0 - box.origin.y - box.size.height
            
            return [
                "text": candidate.string,
                "confidence": candidate.confidence,
                "top": normalizedTop,
                "left": box.origin.x,
                "width": box.size.width,
                "height": box.size.height,
                // 실제 픽셀 좌표 (디버깅용)
                "rawTop": normalizedTop * imageSize.height,
                "rawLeft": box.origin.x * imageSize.width,
                "rawWidth": box.size.width * imageSize.width,
                "rawHeight": box.size.height * imageSize.height
            ]
        }
    }

    private func processRectangles(_ observations: [VNRectangleObservation], imageSize: CGSize) -> [[String: Any]] {
        return observations.map { obs in
            let box = obs.boundingBox
            let normalizedTop = 1.0 - box.origin.y - box.size.height
            
            return [
                "top": normalizedTop,
                "left": box.origin.x,
                "width": box.size.width,
                "height": box.size.height,
                "confidence": obs.confidence
            ]
        }
    }

    private func processSaliency(_ observation: VNSaliencyImageObservation?, imageSize: CGSize) -> [[String: Any]] {
        guard let saliency = observation, let objects = saliency.salientObjects else { return [] }
        
        return objects.map { obj in
            let box = obj.boundingBox
            let normalizedTop = 1.0 - box.origin.y - box.size.height
            
            return [
                "top": normalizedTop,
                "left": box.origin.x,
                "width": box.size.width,
                "height": box.size.height
            ]
        }
    }
}

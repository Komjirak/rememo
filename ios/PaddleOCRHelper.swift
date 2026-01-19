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
        
        // 모델 파일이 모두 있으면 초기화 가능
        if detectionModelPath != nil && recognitionModelPath != nil && dictionaryPath != nil {
            print("✅ PaddleOCR 모델 파일이 모두 준비되었습니다.")
            print("   Detection: \(detectionModelPath!)")
            print("   Recognition: \(recognitionModelPath!)")
            print("   Dictionary: \(dictionaryPath!)")
            // TODO: Paddle-Lite 초기화 코드 추가 필요
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
    /// 현재는 Vision Framework를 fallback으로 사용
    func recognizeText(image: UIImage, completion: @escaping (String) -> Void) {
        // PaddleOCR 모델이 모두 준비되어 있고 초기화되었는지 확인
        guard let detPath = detectionModelPath,
              let recPath = recognitionModelPath,
              let dictPath = dictionaryPath,
              isInitialized else {
            // Fallback to Vision Framework
            print("📸 Vision Framework를 사용하여 OCR 수행 중...")
            recognizeTextWithVision(image: image, completion: completion)
            return
        }
        
        // TODO: Paddle-Lite를 사용한 실제 OCR 구현
        // 현재는 향상된 Vision Framework 사용
        print("🚀 PaddleOCR 모델이 준비되었지만, 아직 Paddle-Lite 통합이 완료되지 않았습니다.")
        print("   Vision Framework를 사용합니다.")
        recognizeTextWithVision(image: image, completion: completion)
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
}

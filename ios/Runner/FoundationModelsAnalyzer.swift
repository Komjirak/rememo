//
//  FoundationModelsAnalyzer.swift
//  Runner
//
//  Apple Foundation Models 통합 (iOS 26+)
//  WWDC 2025에서 발표된 온디바이스 LLM 기능 활용
//
//  Note: Foundation Models framework는 iOS 26+에서만 사용 가능합니다.
//  현재 SDK에서 FoundationModels를 import할 수 없는 경우,
//  fallback 구현이 사용됩니다.
//

import Foundation
import CoreGraphics

// MARK: - Analysis Result Structure
struct AnalysisResult {
    let title: String
    let summary: String
    let tags: [String]
    let contentType: String
}

// MARK: - Foundation Models Analyzer Protocol
protocol FoundationModelsAnalyzerProtocol {
    static func isAvailable() -> Bool
    func analyze(textBlocks: [[String: Any]], imageSize: [String: CGFloat]) async throws -> AnalysisResult
}

// MARK: - Foundation Models Analyzer Implementation
// Since FoundationModels framework is only available in iOS 26+ SDK,
// we provide a stub implementation that always falls back to the NLP-based analyzer.
// When building with iOS 26+ SDK, replace this with the actual implementation.

@available(iOS 26.0, *)
class FoundationModelsAnalyzer: FoundationModelsAnalyzerProtocol {
    static let shared = FoundationModelsAnalyzer()

    private init() {
        print("[FoundationModelsAnalyzer] Initializing (stub implementation)...")
    }

    // MARK: - Availability Check
    static func isAvailable() -> Bool {
        // Currently returns false since FoundationModels framework
        // is not available in the current SDK.
        // When iOS 26 SDK is available, this will perform actual runtime checks:
        // - Device capability (A17 Pro or newer / M-series)
        // - Framework availability
        // - Session initialization success

        // TODO: Implement actual check when iOS 26 SDK is available:
        // if #available(iOS 26.0, *) {
        //     return LanguageModelSession.isSupported
        // }

        print("[FoundationModelsAnalyzer] isAvailable: false (stub implementation)")
        return false
    }

    // MARK: - Main Analysis API
    func analyze(textBlocks: [[String: Any]], imageSize: [String: CGFloat]) async throws -> AnalysisResult {
        // Stub implementation - throws error to trigger fallback
        // When iOS 26 SDK is available, this will use:
        // 1. LanguageModelSession to create a session
        // 2. Generate structured output using @Generable protocol
        // 3. Parse and return the analysis result

        print("[FoundationModelsAnalyzer] analyze called (stub implementation)")
        throw NSError(
            domain: "FoundationModelsAnalyzer",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "FoundationModels not available in current SDK"]
        )
    }
}

// MARK: - Fallback for older iOS versions
class FoundationModelsAnalyzerFallback {
    static func isAvailable() -> Bool {
        return false
    }
}

// MARK: - Future Implementation Notes
/*
 When iOS 26 SDK becomes available, the actual implementation will look like:

 import FoundationModels

 @available(iOS 26.0, *)
 @Generable
 struct StructuredAnalysisOutput {
     @Guide(description: "A concise title (max 30 chars)")
     let title: String

     @Guide(description: "A brief summary (max 150 chars)")
     let summary: String

     @Guide(description: "3-5 relevant tags")
     let tags: [String]

     @Guide(description: "Content type: shopping, receipt, sns, article, news, tech, or general")
     let contentType: String
 }

 @available(iOS 26.0, *)
 class FoundationModelsAnalyzerReal {
     private var session: LanguageModelSession?

     func analyze(textBlocks: [[String: Any]], imageSize: [String: CGFloat]) async throws -> AnalysisResult {
         let session = try LanguageModelSession()
         let output = try await session.generate(
             StructuredAnalysisOutput.self,
             prompt: buildPrompt(from: textBlocks)
         )
         return AnalysisResult(
             title: output.title,
             summary: output.summary,
             tags: output.tags,
             contentType: output.contentType
         )
     }
 }
 */

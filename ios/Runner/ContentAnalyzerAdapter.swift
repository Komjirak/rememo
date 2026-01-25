//
//  ContentAnalyzerAdapter.swift
//  Runner
//
//  Adapter for content analysis that routes to the appropriate analyzer
//  - iOS 26+: Uses Apple Foundation Models (on-device LLM)
//  - iOS 25 and below: Uses EnhancedContentAnalyzer (NLP-based)
//

import Foundation
import CoreGraphics

class ContentAnalyzerAdapter {
    static let shared = ContentAnalyzerAdapter()

    private init() {
        print("[ContentAnalyzerAdapter] Initializing...")
        logAvailability()
    }

    // MARK: - Availability Logging
    private func logAvailability() {
        if isFoundationModelsAvailable() {
            print("[ContentAnalyzerAdapter] Foundation Models available (iOS 26+)")
        } else {
            print("[ContentAnalyzerAdapter] Using EnhancedContentAnalyzer (fallback)")
        }
    }

    // MARK: - Foundation Models Availability Check
    func isFoundationModelsAvailable() -> Bool {
        if #available(iOS 26.0, *) {
            return FoundationModelsAnalyzer.isAvailable()
        }
        return false
    }

    // MARK: - Main Analysis API
    /// Analyzes content using the best available analyzer
    /// - Parameters:
    ///   - textBlocks: OCR text blocks with position info
    ///   - layoutRegions: Optional layout region info
    ///   - importantAreas: Optional saliency areas
    ///   - imageSize: Image dimensions
    /// - Returns: Analysis result dictionary
    func analyzeSummary(
        textBlocks: [[String: Any]],
        layoutRegions: [[String: Any]]? = nil,
        importantAreas: [[String: Any]]? = nil,
        imageSize: [String: CGFloat]
    ) async -> [String: Any] {

        // Try Foundation Models first (iOS 26+)
        if #available(iOS 26.0, *), isFoundationModelsAvailable() {
            do {
                print("[ContentAnalyzerAdapter] Using Foundation Models (iOS 26+)")

                let result = try await FoundationModelsAnalyzer.shared.analyze(
                    textBlocks: textBlocks,
                    imageSize: imageSize
                )

                return [
                    "title": result.title,
                    "summary": result.summary,
                    "tags": result.tags,
                    "contentType": result.contentType,
                    "analyzerUsed": "FoundationModels"
                ]
            } catch {
                print("[ContentAnalyzerAdapter] Foundation Models failed: \(error)")
                print("[ContentAnalyzerAdapter] Falling back to EnhancedContentAnalyzer")
            }
        }

        // Fallback to EnhancedContentAnalyzer
        print("[ContentAnalyzerAdapter] Using EnhancedContentAnalyzer (fallback)")

        let result = EnhancedContentAnalyzer.shared.analyzeSummary(
            textBlocks: textBlocks,
            layoutRegions: layoutRegions,
            importantAreas: importantAreas,
            imageSize: imageSize
        )

        var mutableResult = result
        mutableResult["analyzerUsed"] = "EnhancedContentAnalyzer"
        return mutableResult
    }

    // MARK: - Synchronous API for compatibility
    /// Synchronous wrapper for analyzeSummary (blocks current thread)
    func analyzeSummarySync(
        textBlocks: [[String: Any]],
        layoutRegions: [[String: Any]]? = nil,
        importantAreas: [[String: Any]]? = nil,
        imageSize: [String: CGFloat]
    ) -> [String: Any] {

        // For iOS 26+, we'd need to use async/await
        // For backward compatibility, use the synchronous EnhancedContentAnalyzer
        print("[ContentAnalyzerAdapter] Using EnhancedContentAnalyzer (sync mode)")

        var result = EnhancedContentAnalyzer.shared.analyzeSummary(
            textBlocks: textBlocks,
            layoutRegions: layoutRegions,
            importantAreas: importantAreas,
            imageSize: imageSize
        )

        result["analyzerUsed"] = "EnhancedContentAnalyzer"
        return result
    }

    // MARK: - Status API
    /// Returns information about the current analyzer being used
    func getAnalyzerInfo() -> [String: Any] {
        let useFoundationModels = isFoundationModelsAvailable()

        return [
            "foundationModelsAvailable": useFoundationModels,
            "currentAnalyzer": useFoundationModels ? "FoundationModels" : "EnhancedContentAnalyzer",
            "iosVersion": ProcessInfo.processInfo.operatingSystemVersionString
        ]
    }
}

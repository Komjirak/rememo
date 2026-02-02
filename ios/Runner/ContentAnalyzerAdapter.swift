//
//  ContentAnalyzerAdapter.swift
//  Runner
//
//  Routes between Enhanced Rules and Foundation Models
//

import Foundation

@available(iOS 13.0, *)
class ContentAnalyzerAdapter {
    static let shared = ContentAnalyzerAdapter()
    
    private let foundationModels: FoundationModelsAnalyzer
    private let enhancedAnalyzer: EnhancedContentAnalyzer
    
    private init() {
        self.foundationModels = FoundationModelsAnalyzer.shared
        self.enhancedAnalyzer = EnhancedContentAnalyzer.shared
        print("[ContentAnalyzerAdapter] Initialized")
    }
    
    // MARK: - Main Analysis Entry Point
    func analyze(
        textBlocks: [[String: Any]], 
        layoutRegions: [[String: Any]]? = nil,
        importantAreas: [[String: Any]]? = nil,
        imageSize: [String: CGFloat]
    ) async -> [String: Any] {
        print("============================================================")
        print("🔍 ContentAnalyzerAdapter: Starting Analysis")
        print("============================================================")
        
        let useFoundationModels = FoundationModelsAnalyzer.isAvailable()
        
        if useFoundationModels {
            print("✨ Using: Apple Intelligence (Foundation Models)")
            print("   - Device supports Apple Intelligence")
            print("   - LLM-based analysis with NLSummarizer + NSDataDetector")
            print("============================================================")
            
            do {
                let result = try await foundationModels.analyze(
                    textBlocks: textBlocks,
                    imageSize: imageSize
                )
                return result.toDict()
            } catch {
                print("⚠️ Foundation Models error: \(error)")
                print("   Falling back to Enhanced Rules...")
                return enhancedAnalyzer.analyzeSummary(
                    textBlocks: textBlocks,
                    layoutRegions: layoutRegions,
                    importantAreas: importantAreas,
                    imageSize: imageSize
                )
            }
        } else {
            print("📊 Using: Enhanced Rules (Pattern-based)")
            print("   - Apple Intelligence not available")
            print("   - Fallback to pattern matching")
            print("============================================================")
            
            return enhancedAnalyzer.analyzeSummary(
                textBlocks: textBlocks,
                layoutRegions: layoutRegions,
                importantAreas: importantAreas,
                imageSize: imageSize
            )
        }
    }
    
    // MARK: - Analyzer Info
    func getAnalyzerInfo() -> [String: Any] {
        let foundationModelsAvailable = FoundationModelsAnalyzer.isAvailable()
        return [
            "foundationModelsAvailable": foundationModelsAvailable,
            "currentAnalyzer": foundationModelsAvailable ? "FoundationModels" : "EnhancedRules",
            "iosVersion": UIDevice.current.systemVersion
        ]
    }
}

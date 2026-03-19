//
//  ContentAnalyzerAdapter.swift
//  Runner
//
//  분석기 라우터: 기기 환경에 따라 최적 분석기 선택
//
//  라우팅 우선순위:
//  1. iOS 26+ + Foundation Models 지원 → RealFoundationModelsAnalyzer (실제 온디바이스 LLM)
//  2. iOS 15+ (지원 기기 한정)       → FoundationModelsAnalyzer (NLP 휴리스틱 v4)
//  3. 그 외                          → EnhancedContentAnalyzer (규칙 기반)
//

import Foundation
import UIKit

@available(iOS 13.0, *)
class ContentAnalyzerAdapter {
    static let shared = ContentAnalyzerAdapter()

    private let heuristicAnalyzer: FoundationModelsAnalyzer
    private let enhancedAnalyzer: EnhancedContentAnalyzer

    private init() {
        self.heuristicAnalyzer = FoundationModelsAnalyzer.shared
        self.enhancedAnalyzer = EnhancedContentAnalyzer.shared
        print("[ContentAnalyzerAdapter] Initialized")
        print("[ContentAnalyzerAdapter] Active analyzer: \(resolveAnalyzerName())")
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
        print("   Active: \(resolveAnalyzerName())")
        print("============================================================")

        // ────────────────────────────────────────────────
        // Tier 1: iOS 26 + 실제 Foundation Models
        // ────────────────────────────────────────────────
        if #available(iOS 26.0, *) {
            if RealFoundationModelsAnalyzer.isAvailable() {
                print("✨ [Tier 1] RealFoundationModels (iOS 26 on-device LLM)")
                do {
                    let result = try await RealFoundationModelsAnalyzer.shared.analyze(
                        textBlocks: textBlocks,
                        imageSize: imageSize
                    )
                    var dict = result.toDict()
                    dict["analyzerUsed"] = "RealFoundationModels (iOS 26)"
                    return dict
                } catch {
                    print("⚠️ [Tier 1] RealFoundationModels 실패: \(error.localizedDescription)")
                    print("   → Tier 2 fallback...")
                }
            } else {
                print("⚠️ [Tier 1] Foundation Models 미지원 기기")
            }
        }

        // ────────────────────────────────────────────────
        // Tier 2: iOS 15+ NLP 휴리스틱 (지원 기기 한정)
        // ────────────────────────────────────────────────
        if FoundationModelsAnalyzer.isAvailable() {
            print("📊 [Tier 2] FoundationModelsAnalyzer (NLP 휴리스틱 v4)")
            do {
                let result = try await heuristicAnalyzer.analyze(
                    textBlocks: textBlocks,
                    imageSize: imageSize
                )
                return result.toDict()
            } catch {
                print("⚠️ [Tier 2] 휴리스틱 분석 실패: \(error.localizedDescription)")
                print("   → Tier 3 fallback...")
            }
        }

        // ────────────────────────────────────────────────
        // Tier 3: 규칙 기반 (항상 사용 가능)
        // ────────────────────────────────────────────────
        print("📋 [Tier 3] EnhancedContentAnalyzer (규칙 기반)")
        return enhancedAnalyzer.analyzeSummary(
            textBlocks: textBlocks,
            layoutRegions: layoutRegions,
            importantAreas: importantAreas,
            imageSize: imageSize
        )
    }

    // MARK: - Analyzer Info (Flutter 쪽에서 현재 분석기 상태 조회용)

    func getAnalyzerInfo() -> [String: Any] {
        var info: [String: Any] = [
            "iosVersion": UIDevice.current.systemVersion,
            "activeAnalyzer": resolveAnalyzerName(),
        ]

        if #available(iOS 26.0, *) {
            info["realFoundationModelsAvailable"] = RealFoundationModelsAnalyzer.isAvailable()
            info["ios26Supported"] = true
        } else {
            info["realFoundationModelsAvailable"] = false
            info["ios26Supported"] = false
        }

        info["heuristicAnalyzerAvailable"] = FoundationModelsAnalyzer.isAvailable()

        // 하위 호환: 기존 Flutter 코드가 'foundationModelsAvailable' 키를 참조할 수 있으므로 유지
        info["foundationModelsAvailable"] = (info["realFoundationModelsAvailable"] as? Bool ?? false)
            || (info["heuristicAnalyzerAvailable"] as? Bool ?? false)

        return info
    }

    // MARK: - Private Helpers

    private func resolveAnalyzerName() -> String {
        if #available(iOS 26.0, *), RealFoundationModelsAnalyzer.isAvailable() {
            return "RealFoundationModels (iOS 26)"
        }
        if FoundationModelsAnalyzer.isAvailable() {
            return "FoundationModelsAnalyzer (NLP v4)"
        }
        return "EnhancedContentAnalyzer (Rules)"
    }
}

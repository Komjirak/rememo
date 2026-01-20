//
//  OnDeviceLLM.swift
//  Runner
//
//  온디바이스 LLM - Apple NaturalLanguage 프레임워크 기반 스마트 분석
//  iOS 12+에서 지원되는 NLTagger, NLLanguageRecognizer 사용
//

import Foundation
import NaturalLanguage

class OnDeviceLLM {
    static let shared = OnDeviceLLM()

    private let languageRecognizer = NLLanguageRecognizer()

    init() {
        print("🤖 OnDeviceLLM 초기화 (Apple NaturalLanguage Framework)")
    }

    // MARK: - 메인 API

    /// 스크린샷 텍스트 분석 (메인 API)
    func analyzeSummary(title: String?, paragraphs: [String], keyPoints: [String]) -> [String: Any] {
        let startTime = Date()
        print("🔄 On-Device NLP 분석 시작...")
        print("   - 입력 제목: \(title ?? "없음")")
        print("   - 문단 수: \(paragraphs.count)")
        print("   - 키포인트 수: \(keyPoints.count)")

        // 언어 감지
        let allText = paragraphs.joined(separator: " ")
        languageRecognizer.reset()
        languageRecognizer.processString(allText)
        let detectedLanguage = languageRecognizer.dominantLanguage
        print("   - 감지된 언어: \(detectedLanguage?.rawValue ?? "알 수 없음")")

        // NLP 기반 스마트 분석
        let result = enhancedNLPAnalysis(
            title: title,
            paragraphs: paragraphs,
            keyPoints: keyPoints,
            language: detectedLanguage
        )

        let elapsed = Date().timeIntervalSince(startTime)
        print("✅ On-Device NLP 분석 완료 (\(String(format: "%.2f", elapsed))초)")
        return result
    }

    // MARK: - 향상된 NLP 분석

    private func enhancedNLPAnalysis(title: String?, paragraphs: [String], keyPoints: [String], language: NLLanguage?) -> [String: Any] {
        // 1. 스마트 제목 생성
        var finalTitle = title ?? "New Memory"
        if finalTitle.isEmpty || finalTitle == "New Memory" {
            finalTitle = generateSmartTitle(from: paragraphs, language: language)
        }

        // 2. 핵심 요약 생성 (문맥 기반)
        let summary = generateContextualSummary(paragraphs: paragraphs, language: language)

        // 3. 핵심 인사이트 추출
        var insights = keyPoints.prefix(4).map { String($0) }
        if insights.isEmpty || insights.count < 2 {
            insights = extractKeyInsights(from: paragraphs, language: language)
        }

        return [
            "title": finalTitle,
            "summary": summary,
            "keyInsights": insights
        ]
    }

    // MARK: - 스마트 제목 생성

    /// NLP 기반 스마트 제목 생성 (언어 지원)
    private func generateSmartTitle(from paragraphs: [String], language: NLLanguage?) -> String {
        guard !paragraphs.isEmpty else { return "New Memory" }

        let firstPara = paragraphs[0]
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = firstPara

        // 중요 단어 추출 (명사, 고유명사, 숫자 등)
        var importantWords: [(String, Int)] = [] // (단어, 중요도)

        tagger.enumerateTags(in: firstPara.startIndex..<firstPara.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, tokenRange in
            let word = String(firstPara[tokenRange])
            guard word.count >= 2 && word.count <= 20 else { return true }

            var importance = 0

            // 명사 계열에 높은 가중치
            switch tag {
            case .noun:
                importance = 3
            case .personalName:
                importance = 5
            case .organizationName:
                importance = 5
            case .placeName:
                importance = 4
            case .number:
                importance = 2
            case .verb:
                importance = 1
            default:
                importance = 0
            }

            if importance > 0 {
                importantWords.append((word, importance))
            }

            return importantWords.count < 10
        }

        // 중요도 순 정렬
        let sortedWords = importantWords.sorted { $0.1 > $1.1 }

        // 상위 3개 단어로 제목 생성
        if sortedWords.count >= 2 {
            let titleWords = sortedWords.prefix(3).map { $0.0 }
            let title = titleWords.joined(separator: " ")
            if title.count <= 25 {
                return title
            }
        }

        // 첫 문장의 첫 부분 사용
        let sentences = firstPara.components(separatedBy: CharacterSet(charactersIn: ".!?。！？\n"))
        if let firstSentence = sentences.first?.trimmingCharacters(in: .whitespacesAndNewlines), !firstSentence.isEmpty {
            if firstSentence.count <= 25 {
                return firstSentence
            }

            // 단어 단위로 자르기
            let words = firstSentence.components(separatedBy: .whitespaces)
            var result = ""
            for word in words {
                if (result + " " + word).count > 25 { break }
                result += result.isEmpty ? word : " " + word
            }

            return result.isEmpty ? String(firstSentence.prefix(25)) : result
        }

        return String(firstPara.prefix(25))
    }

    // MARK: - 문맥 기반 요약 생성

    /// 문맥을 파악하여 핵심 내용을 요약
    private func generateContextualSummary(paragraphs: [String], language: NLLanguage?) -> String {
        guard !paragraphs.isEmpty else { return "스크린샷에서 텍스트가 감지되었습니다." }

        // 모든 문장 추출
        var allSentences: [(String, Double)] = [] // (문장, 점수)

        for para in paragraphs.prefix(10) {
            let sentences = para.components(separatedBy: CharacterSet(charactersIn: ".!?。！？"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { sentence in
                    let count = sentence.count
                    return count >= 10 && count <= 150
                }

            for sentence in sentences {
                let score = scoreSentence(sentence, language: language)
                allSentences.append((sentence, score))
            }
        }

        guard !allSentences.isEmpty else {
            // 문장이 없으면 첫 문단 반환
            let firstPara = paragraphs[0]
            return firstPara.count > 120 ? String(firstPara.prefix(117)) + "..." : firstPara
        }

        // 점수 기준 정렬
        let sortedSentences = allSentences.sorted { $0.1 > $1.1 }

        // 상위 2-3개 문장 선택 (중복 제거)
        var selectedSentences: [String] = []
        for (sentence, _) in sortedSentences {
            let isDuplicate = selectedSentences.contains { existing in
                // 유사도 체크 (앞 15자 비교)
                return existing.prefix(15) == sentence.prefix(15)
            }

            if !isDuplicate {
                selectedSentences.append(sentence)
            }

            if selectedSentences.count >= 2 { break }
        }

        // 요약 조합
        let summary = selectedSentences.joined(separator: " ")

        if summary.count > 150 {
            return String(summary.prefix(147)) + "..."
        }

        return summary.isEmpty ? paragraphs.first ?? "텍스트 내용이 감지되었습니다." : summary
    }

    /// 문장 중요도 점수 계산
    private func scoreSentence(_ sentence: String, language: NLLanguage?) -> Double {
        var score: Double = 0

        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = sentence

        var nounCount = 0
        var verbCount = 0
        var nameCount = 0
        var totalWords = 0

        tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, _ in
            totalWords += 1

            switch tag {
            case .noun:
                nounCount += 1
            case .verb:
                verbCount += 1
            case .personalName, .organizationName, .placeName:
                nameCount += 1
            default:
                break
            }

            return true
        }

        // 명사 비율이 높으면 점수 증가
        if totalWords > 0 {
            score += Double(nounCount) / Double(totalWords) * 30
            score += Double(verbCount) / Double(totalWords) * 10
            score += Double(nameCount) * 5
        }

        // 적절한 길이에 보너스
        let length = sentence.count
        if length >= 30 && length <= 100 {
            score += 10
        } else if length >= 20 && length <= 120 {
            score += 5
        }

        // 숫자/날짜 포함시 보너스
        if sentence.range(of: "\\d+", options: .regularExpression) != nil {
            score += 5
        }

        // URL/링크는 감점
        if sentence.contains("http") || sentence.contains("www") {
            score -= 20
        }

        return score
    }

    // MARK: - 핵심 인사이트 추출

    /// NLP 기반 핵심 인사이트 추출
    private func extractKeyInsights(from paragraphs: [String], language: NLLanguage?) -> [String] {
        var insights: [String] = []

        // 모든 문장 수집 및 점수화
        var allSentences: [(String, Double)] = []

        for para in paragraphs {
            let sentences = para.components(separatedBy: CharacterSet(charactersIn: ".!?。！？"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { sentence in
                    let count = sentence.count
                    return count >= 10 && count <= 100 && !sentence.contains("http")
                }

            for sentence in sentences {
                let score = scoreSentence(sentence, language: language)
                allSentences.append((sentence, score))
            }
        }

        // 점수 기준 정렬
        let sortedSentences = allSentences.sorted { $0.1 > $1.1 }

        // 상위 4개 선택 (중복 제거)
        for (sentence, _) in sortedSentences {
            let isDuplicate = insights.contains { existing in
                return existing.prefix(12) == sentence.prefix(12)
            }

            if !isDuplicate {
                insights.append(sentence)
            }

            if insights.count >= 4 { break }
        }

        // 인사이트가 부족하면 문단에서 추가
        if insights.count < 2 {
            for para in paragraphs {
                let trimmed = para.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count >= 10 && trimmed.count <= 100 && !insights.contains(trimmed) {
                    insights.append(trimmed)
                }
                if insights.count >= 4 { break }
            }
        }

        return Array(insights.prefix(4))
    }
}

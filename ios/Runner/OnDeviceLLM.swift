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

    // MARK: - 스마트 제목 생성 (강화)

    /// NLP 기반 스마트 제목 생성 - 핵심 내용 중심
    private func generateSmartTitle(from paragraphs: [String], language: NLLanguage?) -> String {
        guard !paragraphs.isEmpty else { return "New Memory" }

        // 전략 1: 가장 의미있는 문장 찾기
        let bestSentence = findBestTitleSentence(from: paragraphs)
        if let sentence = bestSentence, sentence.count >= 5 {
            return truncateToTitle(sentence, maxLength: 35)
        }

        // 전략 2: 핵심 명사구 추출
        let keyPhrase = extractKeyPhrase(from: paragraphs, language: language)
        if !keyPhrase.isEmpty && keyPhrase.count >= 3 {
            return truncateToTitle(keyPhrase, maxLength: 35)
        }

        // 전략 3: 첫 번째 의미있는 문단 사용
        for para in paragraphs {
            let cleaned = para.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.count >= 5 && !isUINoiseText(cleaned) {
                return truncateToTitle(cleaned, maxLength: 35)
            }
        }

        return "New Memory"
    }

    /// 제목으로 가장 적합한 문장 찾기
    private func findBestTitleSentence(from paragraphs: [String]) -> String? {
        var candidates: [(String, Double)] = []

        for para in paragraphs.prefix(5) {
            // 문장 분리
            let sentences = para.components(separatedBy: CharacterSet(charactersIn: ".!?。！？\n"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { s in
                    let len = s.count
                    return len >= 8 && len <= 80 && !isUINoiseText(s)
                }

            for sentence in sentences {
                let score = scoreTitleCandidate(sentence)
                candidates.append((sentence, score))
            }
        }

        // 점수 기준 정렬
        candidates.sort { $0.1 > $1.1 }
        return candidates.first?.0
    }

    /// 제목 후보 점수 계산
    private func scoreTitleCandidate(_ text: String) -> Double {
        var score: Double = 0

        // 길이 점수 (15-40자가 이상적)
        let length = text.count
        if length >= 15 && length <= 40 {
            score += 20
        } else if length >= 10 && length <= 60 {
            score += 10
        }

        // 명사/고유명사 포함 시 가산점
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = text

        var nounCount = 0
        var nameCount = 0

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, _ in
            switch tag {
            case .noun:
                nounCount += 1
            case .personalName, .organizationName, .placeName:
                nameCount += 1
            default:
                break
            }
            return true
        }

        score += Double(nounCount) * 3
        score += Double(nameCount) * 5

        // 숫자 포함 시 (가격, 날짜 등 구체적 정보)
        if text.range(of: "\\d+", options: .regularExpression) != nil {
            score += 5
        }

        // 감점 요소
        // URL 포함
        if text.contains("http") || text.contains("www") {
            score -= 30
        }
        // 시간 패턴으로 시작
        if text.range(of: "^\\d{1,2}:\\d{2}", options: .regularExpression) != nil {
            score -= 20
        }
        // 특수문자가 많은 경우
        let specialChars = text.filter { "!@#$%^&*()_+=[]{}|\\;:'\",.<>?/`~".contains($0) }
        if Double(specialChars.count) / Double(text.count) > 0.2 {
            score -= 15
        }

        return score
    }

    /// 핵심 명사구 추출
    private func extractKeyPhrase(from paragraphs: [String], language: NLLanguage?) -> String {
        let allText = paragraphs.prefix(3).joined(separator: " ")
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = allText

        var importantPhrases: [(String, Int)] = []
        var currentPhrase: [String] = []
        var lastWasNoun = false

        tagger.enumerateTags(in: allText.startIndex..<allText.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, tokenRange in
            let word = String(allText[tokenRange])
            guard word.count >= 2 && word.count <= 15 else {
                if !currentPhrase.isEmpty {
                    let phrase = currentPhrase.joined(separator: " ")
                    if phrase.count >= 3 {
                        importantPhrases.append((phrase, currentPhrase.count))
                    }
                    currentPhrase = []
                }
                lastWasNoun = false
                return true
            }

            let isNounLike = tag == .noun || tag == .personalName || tag == .organizationName || tag == .placeName

            if isNounLike {
                currentPhrase.append(word)
                lastWasNoun = true
            } else if tag == .adjective && currentPhrase.isEmpty {
                // 형용사로 시작하는 경우 포함
                currentPhrase.append(word)
            } else {
                if !currentPhrase.isEmpty {
                    let phrase = currentPhrase.joined(separator: " ")
                    if phrase.count >= 3 {
                        importantPhrases.append((phrase, currentPhrase.count))
                    }
                    currentPhrase = []
                }
                lastWasNoun = false
            }

            return importantPhrases.count < 15
        }

        // 마지막 구문 처리
        if !currentPhrase.isEmpty {
            let phrase = currentPhrase.joined(separator: " ")
            if phrase.count >= 3 {
                importantPhrases.append((phrase, currentPhrase.count))
            }
        }

        // 길이 기준 정렬 (2-4 단어가 이상적)
        importantPhrases.sort { (a, b) in
            let aScore = a.1 >= 2 && a.1 <= 4 ? a.1 + 5 : a.1
            let bScore = b.1 >= 2 && b.1 <= 4 ? b.1 + 5 : b.1
            return aScore > bScore
        }

        return importantPhrases.first?.0 ?? ""
    }

    /// UI 노이즈 텍스트인지 확인
    private func isUINoiseText(_ text: String) -> Bool {
        let lower = text.lowercased()

        // 시간 패턴
        if text.range(of: "^\\d{1,2}:\\d{2}", options: .regularExpression) != nil { return true }
        // 퍼센트
        if text.range(of: "^\\d{1,3}%$", options: .regularExpression) != nil { return true }
        // UI 키워드
        let uiKeywords = ["뒤로", "다음", "완료", "취소", "확인", "설정", "닫기", "검색", "메뉴", "홈",
                         "back", "next", "done", "cancel", "ok", "settings", "close", "search", "menu", "home",
                         "팔로우", "좋아요", "댓글", "공유", "더보기", "follow", "like", "comment", "share", "more"]
        if uiKeywords.contains(lower) || uiKeywords.contains(text) { return true }

        return false
    }

    /// 제목 길이로 자르기 (단어 단위)
    private func truncateToTitle(_ text: String, maxLength: Int) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= maxLength { return cleaned }

        // 단어 단위로 자르기
        let words = cleaned.components(separatedBy: .whitespaces)
        var result = ""
        for word in words {
            let next = result.isEmpty ? word : result + " " + word
            if next.count > maxLength - 3 { break }
            result = next
        }

        if result.isEmpty {
            return String(cleaned.prefix(maxLength - 3)) + "..."
        }

        return result.count < cleaned.count ? result + "..." : result
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

import Foundation

enum QuizEngine {
    static func evaluateMeaning(answer: String, expected: String?) -> MeaningResult {
        let answerTokens = tokenizeChinese(answer)
        let expectedTokens = tokenizeChinese(expected ?? "")

        guard !answerTokens.isEmpty else {
            return MeaningResult(grade: .incorrect, explanation: "还没有输入中文意思。")
        }
        guard !expectedTokens.isEmpty else {
            return MeaningResult(grade: .close, explanation: "这个单词没有同步到标准释义，请人工确认。")
        }

        let exactHit = answerTokens.contains { answer in
            expectedTokens.contains { expected in
                expected.contains(answer) || answer.contains(expected)
            }
        }
        if exactHit {
            return MeaningResult(grade: .correct, explanation: "你的中文意思和欧路释义匹配。")
        }

        let answerCharacters = Set(answerTokens.joined())
        let expectedCharacters = Set(expectedTokens.joined())
        let overlap = answerCharacters.intersection(expectedCharacters).count
        let denominator = max(1, min(answerCharacters.count, expectedCharacters.count))
        let ratio = Double(overlap) / Double(denominator)

        if ratio >= 0.45 {
            return MeaningResult(grade: .close, explanation: "意思有重叠，但建议再看一下标准释义。")
        }
        return MeaningResult(grade: .incorrect, explanation: "没有明显匹配到标准释义。")
    }

    static func evaluatePronunciation(target: String, transcript: String) -> PronunciationResult {
        let normalizedTarget = normalizeEnglish(target)
        let normalizedTranscript = normalizeEnglish(transcript)

        guard !normalizedTranscript.isEmpty else {
            return PronunciationResult(grade: .incorrect, transcript: transcript, explanation: "没有识别到有效发音。")
        }

        if normalizedTranscript == normalizedTarget ||
            normalizedTranscript.split(separator: " ").contains(Substring(normalizedTarget)) {
            return PronunciationResult(grade: .correct, transcript: transcript, explanation: "系统识别到了目标单词。")
        }

        let distance = levenshtein(normalizedTarget, normalizedTranscript)
        let limit = max(1, normalizedTarget.count / 4)
        if distance <= limit {
            return PronunciationResult(grade: .close, transcript: transcript, explanation: "识别结果接近目标单词。")
        }

        return PronunciationResult(grade: .incorrect, transcript: transcript, explanation: "识别结果和目标单词差距较大。")
    }

    private static func tokenizeChinese(_ text: String) -> [String] {
        text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .components(separatedBy: CharacterSet(charactersIn: "；;，,、/｜|（）()[]{}：:.\n\r\t "))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func normalizeEnglish(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "[^a-z\\s-]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .joined(separator: " ")
    }

    private static func levenshtein(_ lhs: String, _ rhs: String) -> Int {
        let lhs = Array(lhs)
        let rhs = Array(rhs)
        var previous = Array(0...rhs.count)

        for (i, left) in lhs.enumerated() {
            var current = [i + 1]
            for (j, right) in rhs.enumerated() {
                current.append(left == right ? previous[j] : min(previous[j], previous[j + 1], current[j]) + 1)
            }
            previous = current
        }
        return previous.last ?? 0
    }
}

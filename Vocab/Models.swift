import Foundation

/// One vocabulary entry: the English word and its meaning in the learner's language.
nonisolated struct Word: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    var english: String
    var translation: String
    /// The list the word belongs to, e.g. "Unit 3" or the scan it came from.
    var deck: String
    var created = Date.now
    /// Leitner box 0…5: 0 = new or often wrong, 5 = known well. Low boxes come up more often.
    var box = 0
    var correct = 0
    var wrong = 0
    var lastAsked: Date?

    /// 0…3 stars for the word list.
    var stars: Int { min(3, (box + 1) / 2) }
}

/// A brainrot picture the parent added from the photo library.
nonisolated struct CustomBrainrot: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    var name: String
}

nonisolated struct Progress: Codable, Sendable {
    /// Correct answers since the last brainrot.
    var sinceReward = 0
    var totalCorrect = 0
    var totalAnswers = 0
    /// How often each brainrot was shown, by id.
    var seen: [String: Int] = [:]
}

/// Everything the app keeps, as one JSON file.
nonisolated struct SaveData: Codable, Sendable {
    var words: [Word] = []
    var progress = Progress()
    var custom: [CustomBrainrot] = []
}

/// Which words a practice round uses.
nonisolated enum DeckFilter: Hashable, Sendable {
    case all
    case tricky
    case deck(String)
}

/// User settings, stored in UserDefaults (and read with @AppStorage in the views).
nonisolated enum Settings {
    static let language = "nativeLanguage"
    static let accent = "englishAccent"
    static let rewardEvery = "rewardEvery"

    /// Languages Apple's on-device translation can translate English into.
    static let languages = ["de", "fr", "es", "it", "pt", "nl", "pl", "tr", "uk", "ru", "ar", "zh-Hans", "ja", "ko",
                            "hi", "id", "th", "vi"]

    static var defaultLanguage: String {
        let code = Locale.current.language.languageCode?.identifier ?? "de"
        return languages.contains(code) ? code : "de"
    }

    static var currentLanguage: String { UserDefaults.standard.string(forKey: language) ?? defaultLanguage }
    static var englishVoice: String { UserDefaults.standard.string(forKey: accent) ?? "en-GB" }

    static var currentRewardEvery: Int {
        let value = UserDefaults.standard.integer(forKey: rewardEvery)
        return value > 0 ? value : 10
    }

    /// "German", "Französisch", … in the language of the device.
    static func name(of code: String) -> String {
        Locale.current.localizedString(forIdentifier: code) ?? code
    }
}

/// Compares typed answers with the stored English word.
nonisolated enum Check {
    private static let separators: Set<Character> = [",", ";", "/"]

    /// Lowercased, without brackets, "to"/articles in front, punctuation at the ends and double spaces.
    static func normalize(_ text: String) -> String {
        var t = text.lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: #"\([^)]*\)|\[[^\]]*\]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        for prefix in ["to ", "a ", "an ", "the "] where t.hasPrefix(prefix) && t.count > prefix.count {
            t.removeFirst(prefix.count)
            break
        }
        return t
    }

    /// "go, went, gone" or "big / large" count as several right answers.
    static func variants(_ english: String) -> [String] {
        let parts = english.split(whereSeparator: { separators.contains($0) }).map { normalize(String($0)) }
        return ([normalize(english)] + parts).filter { !$0.isEmpty }
    }

    static func isRight(_ input: String, for english: String) -> Bool {
        let n = normalize(input)
        return !n.isEmpty && variants(english).contains(n)
    }

    /// One wrong letter (two in long words): worth a second try.
    static func isAlmost(_ input: String, for english: String) -> Bool {
        let n = normalize(input)
        guard n.count >= 3 else { return false }
        return variants(english).contains { distance(n, $0) <= ($0.count >= 8 ? 2 : 1) }
    }

    /// The form used for spelling: the first variant, without brackets.
    static func main(_ english: String) -> String {
        let first = english.split(whereSeparator: { separators.contains($0) }).first.map(String.init) ?? english
        return first
            .replacingOccurrences(of: #"\([^)]*\)|\[[^\]]*\]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The bare word for spelling games: `main` without "to" or an article in front ("to feed" → "feed").
    static func core(_ english: String) -> String {
        let word = main(english)
        for prefix in ["to ", "a ", "an ", "the "] where word.lowercased().hasPrefix(prefix) && word.count > prefix.count {
            return String(word.dropFirst(prefix.count))
        }
        return word
    }

    /// Levenshtein distance.
    static func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }
        var previous = Array(0...b.count)
        for i in 1...a.count {
            var current = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            previous = current
        }
        return previous[b.count]
    }
}

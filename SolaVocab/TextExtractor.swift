import NaturalLanguage
import UIKit
import Vision

/// What was found on the photos.
nonisolated struct ScanResult: Sendable {
    /// English word and translation side by side, as in the vocabulary lists of school books.
    var pairs: [Pair] = []
    /// English words that could be new, in reading order.
    var words: [String] = []
    /// Very common words, hidden unless asked for.
    var easy: [String] = []
    /// All recognized text, line by line.
    var text = ""

    struct Pair: Sendable, Hashable {
        var english: String
        var translation: String
    }
}

/// Reads text from photos with Vision and picks vocabulary from it. Everything runs on the device.
nonisolated enum TextExtractor {
    /// One recognized piece of text, in normalized coordinates (origin bottom left).
    private struct Segment {
        var text: String
        var x: CGFloat
        var y: CGFloat
        var height: CGFloat
        /// Rise of the text's baseline; photos are rarely held perfectly straight.
        var slope: CGFloat
    }

    @concurrent static func read(_ images: [UIImage], language: String) async -> ScanResult {
        var rows: [[String]] = []
        for image in images {
            guard let cgImage = upright(image) else { continue }
            rows += await lines(in: cgImage, language: language)
        }
        return analyze(rows, language: language)
    }

    // MARK: Text recognition

    /// The recognized text, grouped into rows; each row lists its pieces from left to right.
    private static func lines(in image: CGImage, language: String) async -> [[String]] {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = false
        let wanted = [Locale.Language(identifier: "en-US")] + request.supportedRecognitionLanguages
            .filter { $0.languageCode?.identifier == Locale.Language(identifier: language).languageCode?.identifier }
            .prefix(1)
        request.recognitionLanguages = Array(wanted)

        guard let observations = try? await request.perform(on: image) else { return [] }
        let segments = observations.compactMap { observation -> Segment? in
            guard let text = observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespaces),
                  !text.isEmpty else { return nil }
            let left = observation.bottomLeft, right = observation.bottomRight
            let width = right.x - left.x
            return Segment(text: text,
                           x: (left.x + right.x) / 2,
                           y: (observation.topLeft.y + observation.topRight.y + left.y + right.y) / 4,
                           height: abs(observation.topLeft.y - left.y),
                           slope: width > 0.15 ? (right.y - left.y) / width : .nan)
        }

        // Undo the tilt, then pieces whose heights line up form a row. Vision reports a usable slope only for
        // long lines, so that is just the starting point: nearby slopes are tried and the one giving the
        // fewest rows wins (ties go to the closest one, so rows never shift by a whole line).
        let slopes = segments.filter { !$0.slope.isNaN && $0.height > 0 }.map(\.slope).sorted()
        let hint = slopes.isEmpty ? 0 : slopes[slopes.count / 2]
        var best: [[Segment]] = []
        var bestDistance = CGFloat.infinity
        for step in -12...12 {
            let slope = hint + CGFloat(step) * 0.005
            let rows = group(segments, slope: slope)
            let distance = abs(slope - hint)
            if best.isEmpty || rows.count < best.count || (rows.count == best.count && distance < bestDistance) {
                best = rows
                bestDistance = distance
            }
        }
        return best.map { $0.sorted { $0.x < $1.x }.map(\.text) }
    }

    private static func group(_ segments: [Segment], slope: CGFloat) -> [[Segment]] {
        let level = { (segment: Segment) in segment.y - slope * segment.x }
        var rows: [[Segment]] = []
        for segment in segments.sorted(by: { level($0) > level($1) }) {
            if let first = rows.last?.first,
               abs(level(first) - level(segment)) < max(first.height, segment.height) * 0.5 {
                rows[rows.count - 1].append(segment)
            } else {
                rows.append([segment])
            }
        }
        return rows
    }

    /// Turned upright (camera photos carry their rotation separately) and at most 3000 px.
    private static func upright(_ image: UIImage) -> CGImage? {
        let scale = min(1, 3000 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format)
            .image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
            .cgImage
    }

    // MARK: Vocabulary

    private static func analyze(_ rows: [[String]], language: String) -> ScanResult {
        var result = ScanResult()
        result.text = rows.map { $0.joined(separator: "   ") }.joined(separator: "\n")

        // A page is a vocabulary list when several rows have an English word on the left and its
        // translation on the right. Phonetics in between ([ˈæpl]) and example sentences are skipped.
        var pairs: [ScanResult.Pair] = []
        var pairRows = Set<Int>()
        for (index, row) in rows.enumerated() {
            let parts = row.filter { !looksPhonetic($0) }
            guard parts.count >= 2, let left = parts.first.map(clean), let right = parts.last.map(clean),
                  !left.isEmpty, !right.isEmpty,
                  wordCount(left) <= 4, wordCount(right) <= 6,
                  left.contains(where: \.isLetter), right.contains(where: \.isLetter),
                  !isLanguage(right, .english, versus: language) else { continue }
            pairs.append(.init(english: left, translation: right))
            pairRows.insert(index)
        }
        if pairs.count >= 3 {
            var seen = Set<String>()
            result.pairs = pairs.filter { seen.insert($0.english.lowercased()).inserted }
        } else {
            pairRows = []
        }

        // Single words come from the English text outside the list; the list itself is offered as pairs.
        var english: [String] = []
        for (index, row) in rows.enumerated() where !pairRows.contains(index) {
            english += row.filter { !isLanguage($0, NLLanguage(rawValue: language), versus: language) }
        }
        (result.words, result.easy) = vocabulary(in: english)
        return result
    }

    /// Nouns, verbs, adjectives and adverbs in their base form ("children" → "child"), no names.
    private static func vocabulary(in lines: [String]) -> ([String], [String]) {
        let text = lines.joined(separator: "\n").replacingOccurrences(of: "-\n", with: "")
        let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass, .lemma])
        tagger.string = text
        let all = text.startIndex..<text.endIndex
        tagger.setLanguage(.english, range: all)
        let wanted: Set<NLTag> = [.noun, .verb, .adjective, .adverb]
        var seen = Set<String>()
        var new: [String] = []
        var easy: [String] = []
        tagger.enumerateTags(in: all, unit: .word, scheme: .nameTypeOrLexicalClass,
                             options: [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]) { tag, range in
            guard let tag, wanted.contains(tag) else { return true }
            let token = String(text[range])
            let lemma = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lemma).0?.rawValue ?? ""
            let word = (lemma.isEmpty ? token : lemma).lowercased()
            guard word.count >= 3, word.allSatisfy({ $0.isLetter || $0 == "-" }),
                  seen.insert(word).inserted else { return true }
            if CommonWords.all.contains(word) { easy.append(word) } else { new.append(word) }
            return true
        }
        return (new, easy)
    }

    /// True when the text is clearly in `target`. Short pieces are too uncertain and count as not.
    private static func isLanguage(_ text: String, _ target: NLLanguage, versus native: String) -> Bool {
        guard text.count >= 4 else { return false }
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = [.english, NLLanguage(rawValue: native)]
        recognizer.processString(text)
        return (recognizer.languageHypotheses(withMaximum: 2)[target] ?? 0) > 0.8
    }

    private static func looksPhonetic(_ text: String) -> Bool {
        text.hasPrefix("[") || text.hasPrefix("/") || text.contains(where: { "əʃʒθðŋæɪʊˈˌːɒʌɜɑɔ".contains($0) })
    }

    /// Without list numbers, bullets and trailing punctuation.
    private static func clean(_ text: String) -> String {
        text.replacingOccurrences(of: #"^[\d•·\-–.)\s]+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: ".,;:")))
    }

    private static func wordCount(_ text: String) -> Int {
        text.split(separator: " ").count
    }
}

/// The most frequent English words. They are hidden on the review screen unless asked for.
nonisolated enum CommonWords {
    static let all: Set<String> = Set("""
    the be to of and a in that have i it for not on with he as you do at this but his by from they we say her she or \
    an will my one all would there their what so up out if about who get which go me when make can like time no just \
    him know take people into year your good some could them see other than then now look only come its over think \
    also back after use two how our work first well way even new want because any these give day most us is are was \
    were been has had did does said says made went got gone came seen took done very much more many really here where \
    why yes thing things man men woman women child children boy girl mum mom dad family friend friends school home \
    house room door window car bus street town city book books page word words name love like likes liked play \
    plays played playing eat eats ate drink water food big small little old young long short high low great right \
    left next last same different own few lot lots every never always often sometimes today tomorrow yesterday \
    morning evening night week month hello please thank thanks sorry okay nice happy sad bad best better put let \
    help tell ask find found need feel try call keep start stop run walk sit stand open close read write hear listen \
    speak talk learn live leave turn show bring begin seem mean move pay meet include set hold happen carry stay \
    fall cut kill remain buy sell send build grow lose win spend die pass sing dance swim sleep wake cook clean wash \
    red blue green yellow black white brown pink orange purple grey gray colour color number one two three four five \
    six seven eight nine ten hundred thousand first second third cat dog fish bird animal tree flower sun moon \
    star sky rain snow hot cold warm cool head hand hands eye eyes face hair arm leg foot feet mouth nose ear body \
    yes no not mister miss teacher class lesson question answer example exercise unit picture down
    """.split(whereSeparator: \.isWhitespace).map(String.init))
}

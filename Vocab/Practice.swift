import SwiftUI

/// The kinds of exercises. Every one is checked by the app, so each correct answer is earned.
nonisolated enum Exercise: String, CaseIterable, Identifiable, Sendable {
    case meaning, word, typing, listening, letters, matching

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .meaning: "What does it mean?"
        case .word: "Which word is it?"
        case .typing: "Type it"
        case .listening: "Listen and write"
        case .letters: "Letter puzzle"
        case .matching: "Find the pairs"
        }
    }

    var emoji: String {
        switch self {
        case .meaning: "🤔"
        case .word: "🎯"
        case .typing: "⌨️"
        case .listening: "🎧"
        case .letters: "🧩"
        case .matching: "🃏"
        }
    }

    /// Choices and pairs need other words to mix in.
    var minWords: Int {
        switch self {
        case .meaning, .word, .matching: 4
        case .typing, .listening, .letters: 1
        }
    }

    func fits(_ word: Word) -> Bool {
        switch self {
        case .letters:
            let letters = Check.core(word.english).filter { !$0.isWhitespace }.count
            return (2...14).contains(letters)
        default: return true
        }
    }
}

nonisolated struct Question: Identifiable, Sendable {
    let id = UUID()
    let exercise: Exercise
    let word: Word
    /// Answer choices (including `word`) or the words of a pairs board.
    var options: [Word] = []
    /// For typing: other English words with the same meaning also count.
    var accepted: [String] = []
}

/// Result of one question: right or wrong overall, and per word for the Leitner boxes.
nonisolated struct Answer: Sendable {
    var correct: Bool
    var results: [UUID: Bool]
}

nonisolated enum Quiz {
    /// How likely a word comes up, by Leitner box.
    private static let weights = [12.0, 8, 5, 3, 2, 1]

    static func next(from words: [Word], mode: Exercise?, recent: [UUID]) -> Question? {
        let usable = words.filter { !$0.english.trimmed.isEmpty && !$0.translation.trimmed.isEmpty }
        guard !usable.isEmpty else { return nil }
        let kinds = (mode.map { [$0] } ?? Exercise.allCases).filter { usable.count >= $0.minWords }
        let kind = kinds.randomElement() ?? .typing

        let pool = usable.filter(kind.fits)
        guard !pool.isEmpty else { return next(from: usable, mode: .typing, recent: recent) }
        let fresh = pool.filter { !recent.contains($0.id) }
        let word = pick(from: fresh.isEmpty ? pool : fresh)

        switch kind {
        case .meaning, .word:
            let shown: (Word) -> String = { Check.normalize(kind == .meaning ? $0.translation : $0.english) }
            var used: Set<String> = [shown(word)]
            let others = usable.shuffled().filter { $0.id != word.id && used.insert(shown($0)).inserted }.prefix(3)
            guard others.count == 3 else { return next(from: usable, mode: .typing, recent: recent) }
            return Question(exercise: kind, word: word, options: ([word] + others).shuffled())
        case .matching:
            var english: Set<String> = [Check.normalize(word.english)]
            var meaning: Set<String> = [Check.normalize(word.translation)]
            let others = usable.shuffled().filter {
                $0.id != word.id && english.insert(Check.normalize($0.english)).inserted
                    && meaning.insert(Check.normalize($0.translation)).inserted
            }.prefix(3)
            guard others.count == 3 else { return next(from: usable, mode: .typing, recent: recent) }
            return Question(exercise: kind, word: word, options: ([word] + others).shuffled())
        case .typing:
            let meaning = Check.normalize(word.translation)
            let same = usable.filter { $0.id != word.id && Check.normalize($0.translation) == meaning }.map(\.english)
            return Question(exercise: kind, word: word, accepted: same)
        case .listening, .letters:
            return Question(exercise: kind, word: word)
        }
    }

    private static func pick(from words: [Word]) -> Word {
        let total = words.reduce(0) { $0 + weights[min($1.box, 5)] }
        var roll = Double.random(in: 0..<total)
        for word in words {
            roll -= weights[min(word.box, 5)]
            if roll < 0 { return word }
        }
        return words[words.count - 1]
    }
}

/// One practice round, until closed. Questions keep coming; every few correct answers a brainrot appears.
struct PracticeView: View {
    @Bindable var store: Store
    let filter: DeckFilter
    let mode: Exercise?
    @Environment(\.dismiss) private var dismiss
    @State private var question: Question?
    @State private var answer: Answer?
    @State private var praise = ""
    @State private var recent: [UUID] = []
    @State private var sessionCorrect = 0
    @State private var sessionTotal = 0
    @State private var successes = 0
    @State private var mistakes = 0
    @State private var advance: Task<Void, Never>?

    private static let praises = ["Great!", "Awesome!", "Super!", "Well done!", "Nice one!", "Brilliant!",
                                  "Fantastic!", "You rock!", "Perfect!", "Yes!"]

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if let question {
                ScrollView {
                    ExerciseView(question: question, locked: answer != nil, finish: finish)
                        .id(question.id)
                        .padding(20)
                }
                .scrollDismissesKeyboard(.never)
            } else {
                Spacer()
                Text("No words to practise yet.")
                    .foregroundStyle(Color.muted)
                Spacer()
            }
        }
        .background(Color.bg)
        .safeAreaInset(edge: .bottom) {
            if let answer { feedback(answer) }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: answer != nil)
        .sensoryFeedback(.success, trigger: successes)
        .sensoryFeedback(.error, trigger: mistakes)
        .fullScreenCover(item: $store.reward, onDismiss: next) { reward in
            BrainrotReveal(item: reward.item, isNew: reward.isNew)
        }
        .onAppear { if question == nil { next() } }
        .onDisappear {
            advance?.cancel()
            Speech.shared.stop()
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            CircleIconButton(systemImage: "xmark", label: "Close") { dismiss() }
            RewardMeter(store: store, compact: true)
            Text("✓ \(sessionCorrect)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.good)
                .monospacedDigit()
                .accessibilityLabel("\(sessionCorrect) correct")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func feedback(_ answer: Answer) -> some View {
        let shown = question.map { q in
            q.exercise == .matching ? q.options.filter { answer.results[$0.id] == false } : [q.word]
        } ?? []
        return VStack(alignment: .leading, spacing: 10) {
            Text(answer.correct ? "🎉 \(praise)" : String(localized: "Not quite…"))
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(answer.correct ? Color.good : Color.danger)
            ForEach(shown) { word in
                HStack(spacing: 10) {
                    Text("\(word.english) = \(word.translation)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Spacer(minLength: 0)
                    SpeakButton(text: word.english, size: 34)
                }
            }
            if !answer.correct {
                Button("Next", action: next)
                    .buttonStyle(BigButtonStyle(primary: true))
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(answer.correct ? Color.goodSoft : Color.dangerSoft)
        .contentShape(.rect)
        .onTapGesture { if answer.correct { next() } }
        .transition(.move(edge: .bottom))
    }

    private func finish(_ result: Answer) {
        guard answer == nil, let question else { return }
        answer = result
        sessionTotal += 1
        if result.correct {
            sessionCorrect += 1
            successes += 1
            praise = Self.praises.randomElement() ?? "Great!"
            if question.exercise != .matching { Speech.shared.english(question.word.english) }
        } else {
            mistakes += 1
        }
        store.record(result)
        // Right answers move on by themselves, unless a brainrot is about to show.
        if result.correct, store.reward == nil {
            advance = Task {
                try? await Task.sleep(for: .seconds(1.4))
                if !Task.isCancelled { next() }
            }
        }
    }

    private func next() {
        advance?.cancel()
        guard store.reward == nil else { return }
        let words = store.words(for: filter)
        question = Quiz.next(from: words.isEmpty ? store.words : words, mode: mode, recent: recent)
        answer = nil
        if let id = question?.word.id {
            recent = Array((recent + [id]).suffix(min(3, max(0, words.count - 1))))
        }
    }
}

/// Progress towards the next brainrot: "🧠 7 / 10" with a bar.
struct RewardMeter: View {
    let store: Store
    var compact = false
    @AppStorage(Settings.rewardEvery) private var rewardEvery = 10

    var body: some View {
        let done = min(store.progress.sinceReward, rewardEvery)
        HStack(spacing: 10) {
            Text("🧠")
                .font(.system(size: compact ? 22 : 34))
            VStack(alignment: .leading, spacing: 6) {
                if !compact {
                    Text("Next brainrot")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.ink)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.line)
                        Capsule()
                            .fill(LinearGradient(colors: [Color.brand, Color(hex: 0xFF5FA2)],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, geo.size.width * CGFloat(done) / CGFloat(max(rewardEvery, 1))))
                    }
                }
                .frame(height: compact ? 10 : 14)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: done)
                if !compact {
                    Text("\(rewardEvery - done) more correct answers")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.muted)
                }
            }
            Text("\(done)/\(rewardEvery)")
                .font(.system(size: compact ? 14 : 17, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.brand)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Next brainrot: \(done) of \(rewardEvery)")
    }
}

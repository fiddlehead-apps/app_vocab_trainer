import SwiftUI

/// Shows the right exercise for a question. `finish` is called once, with the result.
struct ExerciseView: View {
    let question: Question
    let locked: Bool
    let finish: (Answer) -> Void

    var body: some View {
        switch question.exercise {
        case .meaning: ChoiceExercise(question: question, reverse: false, locked: locked, finish: finish)
        case .word: ChoiceExercise(question: question, reverse: true, locked: locked, finish: finish)
        case .typing: TypingExercise(question: question, listening: false, locked: locked, finish: finish)
        case .listening: TypingExercise(question: question, listening: true, locked: locked, finish: finish)
        case .letters: LettersExercise(question: question, locked: locked, finish: finish)
        case .matching: MatchingExercise(question: question, locked: locked, finish: finish)
        }
    }
}

/// The word that is asked for, big, on a card.
struct PromptCard: View {
    let label: LocalizedStringResource
    let text: String
    var speak: String?

    var body: some View {
        VStack(spacing: 14) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.muted)
            Text(text)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
            if let speak { SpeakButton(text: speak) }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 16)
        .background(Color.surface, in: .rect(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.line, lineWidth: 1.5))
    }
}

enum OptionState {
    case idle, right, wrong, faded
}

/// Answer button that turns green or red.
struct OptionStyle: ButtonStyle {
    let state: OptionState

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .semibold, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundStyle(state == .right || state == .wrong ? Color.white : Color.ink)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.horizontal, 16)
            .background(background, in: .rect(cornerRadius: 16))
            .overlay {
                if state == .idle || state == .faded {
                    RoundedRectangle(cornerRadius: 16).strokeBorder(Color.line, lineWidth: 1.5)
                }
            }
            .opacity(state == .faded ? 0.5 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: state)
    }

    private var background: Color {
        switch state {
        case .right: .good
        case .wrong: .danger
        case .idle, .faded: .surface
        }
    }
}

// MARK: - Multiple choice

/// English → meaning (or the other way round), four choices.
struct ChoiceExercise: View {
    let question: Question
    let reverse: Bool
    let locked: Bool
    let finish: (Answer) -> Void
    @State private var chosen: UUID?

    var body: some View {
        VStack(spacing: 20) {
            PromptCard(label: reverse ? "Which English word is it?" : "What does it mean?",
                       text: reverse ? question.word.translation : question.word.english,
                       speak: reverse ? nil : question.word.english)
            VStack(spacing: 12) {
                ForEach(question.options) { option in
                    Button { pick(option) } label: {
                        Text(reverse ? option.english : option.translation)
                    }
                    .buttonStyle(OptionStyle(state: state(of: option)))
                    .disabled(locked || chosen != nil)
                }
            }
        }
        .onAppear { if !reverse { Speech.shared.english(question.word.english) } }
    }

    private func state(of option: Word) -> OptionState {
        guard let chosen else { return .idle }
        if option.id == question.word.id { return .right }
        return option.id == chosen ? .wrong : .faded
    }

    private func pick(_ option: Word) {
        guard chosen == nil else { return }
        chosen = option.id
        let right = option.id == question.word.id
        finish(Answer(correct: right, results: [question.word.id: right]))
    }
}

// MARK: - Typing and listening

/// Type the English word for a meaning, or for what the voice says.
struct TypingExercise: View {
    let question: Question
    let listening: Bool
    let locked: Bool
    let finish: (Answer) -> Void
    @State private var input = ""
    @State private var hints = 0
    @State private var almost = false
    @State private var result: Bool?
    @FocusState private var focused: Bool

    private var target: String { Check.core(question.word.english) }
    private var maxHints: Int { max(1, target.count / 2) }

    var body: some View {
        VStack(spacing: 18) {
            if listening {
                listenCard
            } else {
                PromptCard(label: "Type the English word", text: question.word.translation)
            }

            TextField("", text: $input, prompt: Text(hintText).foregroundStyle(Color.muted.opacity(0.6)))
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.done)
                .focused($focused)
                .onSubmit(check)
                .disabled(locked)
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .background(Color.surface, in: .rect(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(border, lineWidth: 2))

            if almost && result == nil {
                Text("Almost! Check the spelling.")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.orange)
            }

            if result == nil {
                HStack(spacing: 12) {
                    Button {
                        hints = min(maxHints, hints + 1)
                    } label: {
                        Label("Hint", systemImage: "lightbulb")
                    }
                    .buttonStyle(BigButtonStyle(primary: false))
                    .disabled(hints >= maxHints)
                    Button("Check", action: check)
                        .buttonStyle(BigButtonStyle(primary: true))
                        .disabled(input.trimmed.isEmpty)
                }
            }
        }
        .onAppear {
            focused = true
            if listening {
                Task {
                    try? await Task.sleep(for: .seconds(0.3))
                    Speech.shared.english(target)
                }
            }
        }
    }

    private var listenCard: some View {
        VStack(spacing: 16) {
            Text("Listen and write the word")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.muted)
            HStack(spacing: 18) {
                Button { Speech.shared.english(target) } label: {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(Color.brandInk)
                        .frame(width: 104, height: 104)
                        .background(Color.brand, in: .circle)
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("Listen")
                Button { Speech.shared.english(target, slow: true) } label: {
                    Text("🐢")
                        .font(.system(size: 30))
                        .frame(width: 64, height: 64)
                        .background(Color.brandSoft, in: .circle)
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("Listen slowly")
            }
            if result != nil {
                Text(question.word.translation)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(Color.surface, in: .rect(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.line, lineWidth: 1.5))
    }

    /// "ap___" after two hints.
    private var hintText: String {
        guard hints > 0 else { return "…" }
        return String(target.prefix(hints)) + String(repeating: "_", count: max(0, target.count - hints))
    }

    private var border: Color {
        switch result {
        case true?: .good
        case false?: .danger
        case nil: almost ? .orange : .line
        }
    }

    private func check() {
        guard result == nil, !locked, !input.trimmed.isEmpty else { return }
        let english = [question.word.english] + question.accepted
        if english.contains(where: { Check.isRight(input, for: $0) }) {
            result = true
        } else if !almost, english.contains(where: { Check.isAlmost(input, for: $0) }) {
            almost = true
            return
        } else {
            result = false
        }
        focused = false
        finish(Answer(correct: result == true, results: [question.word.id: result == true]))
    }
}

// MARK: - Letter puzzle

/// Build the English word from shuffled letter tiles.
struct LettersExercise: View {
    let question: Question
    let locked: Bool
    let finish: (Answer) -> Void
    @State private var tiles: [Tile] = []
    @State private var placed: [Int] = []
    @State private var result: Bool?

    struct Tile: Identifiable {
        let id: Int
        let letter: Character
    }

    private var letters: [Character] { Array(Check.core(question.word.english).filter { !$0.isWhitespace }) }

    var body: some View {
        VStack(spacing: 22) {
            PromptCard(label: "Build the English word", text: question.word.translation)

            FlowLayout(spacing: 6, lineSpacing: 8) {
                ForEach(letters.indices, id: \.self) { slot in
                    let tile = slot < placed.count ? tiles.first { $0.id == placed[slot] } : nil
                    Button {
                        if let tile { remove(tile.id) }
                    } label: {
                        Text(tile.map { String($0.letter) } ?? " ")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(slotColor == .line ? Color.ink : Color.white)
                            .frame(width: letters.count > 8 ? 32 : 40, height: 50)
                            .background(tile == nil ? Color.clear : slotColor == .line ? Color.surface : slotColor,
                                        in: .rect(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(slotColor, lineWidth: 2))
                    }
                    .buttonStyle(PressStyle())
                    .disabled(tile == nil || locked)
                }
            }
            .frame(maxWidth: .infinity)

            FlowLayout(spacing: 10, lineSpacing: 10) {
                ForEach(tiles) { tile in
                    let used = placed.contains(tile.id)
                    Button { place(tile.id) } label: {
                        Text(String(tile.letter))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.brandInk)
                            .frame(width: 52, height: 56)
                            .background(Color.brand, in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(PressStyle())
                    .opacity(used ? 0.15 : 1)
                    .disabled(used || locked)
                }
            }
            .frame(maxWidth: .infinity)

            if result == nil, !placed.isEmpty {
                Button {
                    placed.removeAll()
                } label: {
                    Label("Start again", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(BigButtonStyle(primary: false))
            }
        }
        .onAppear(perform: shuffle)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: placed)
    }

    private var slotColor: Color {
        switch result {
        case true?: .good
        case false?: .danger
        case nil: .line
        }
    }

    private func shuffle() {
        guard tiles.isEmpty else { return }
        let ordered = letters.enumerated().map { Tile(id: $0.offset, letter: $0.element) }
        var mixed = ordered.shuffled()
        // Never hand out the solution already in order.
        for _ in 0..<5 where ordered.count > 1 && mixed.map(\.letter) == ordered.map(\.letter) {
            mixed.shuffle()
        }
        tiles = mixed
    }

    private func place(_ id: Int) {
        guard result == nil, !placed.contains(id) else { return }
        placed.append(id)
        guard placed.count == letters.count else { return }
        let built = placed.compactMap { id in tiles.first { $0.id == id }?.letter }
        let right = String(built).lowercased() == String(letters).lowercased()
        result = right
        finish(Answer(correct: right, results: [question.word.id: right]))
    }

    private func remove(_ id: Int) {
        guard result == nil else { return }
        placed.removeAll { $0 == id }
    }
}

// MARK: - Pairs

/// Match four English words with their meanings. Counts as right when no pair went wrong.
struct MatchingExercise: View {
    let question: Question
    let locked: Bool
    let finish: (Answer) -> Void
    @State private var meanings: [Word] = []
    @State private var selected: Pick?
    @State private var matched: Set<UUID> = []
    @State private var missed: Set<UUID> = []
    @State private var flashing: Set<Pick> = []

    struct Pick: Hashable {
        let english: Bool
        let id: UUID
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("Find the pairs")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.muted)
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 12) {
                    ForEach(question.options) { word in
                        tile(word.english, pick: Pick(english: true, id: word.id))
                    }
                }
                VStack(spacing: 12) {
                    ForEach(meanings) { word in
                        tile(word.translation, pick: Pick(english: false, id: word.id))
                    }
                }
            }
        }
        .onAppear {
            if meanings.isEmpty { meanings = question.options.shuffled() }
        }
    }

    private func tile(_ text: String, pick: Pick) -> some View {
        let done = matched.contains(pick.id)
        let isSelected = selected == pick
        let isFlashing = flashing.contains(pick)
        return Button { tap(pick) } label: {
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .foregroundStyle(done || isFlashing || isSelected ? Color.white : Color.ink)
                .frame(maxWidth: .infinity, minHeight: 64)
                .padding(.horizontal, 8)
                .background(isFlashing ? Color.danger : done ? Color.good : isSelected ? Color.brand : Color.surface,
                            in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.line, lineWidth: done || isSelected ? 0 : 1.5))
        }
        .buttonStyle(PressStyle())
        .disabled(done || locked)
        .opacity(done ? 0.6 : 1)
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .animation(.easeOut(duration: 0.15), value: isFlashing)
    }

    private func tap(_ pick: Pick) {
        guard !matched.contains(pick.id) else { return }
        guard let first = selected, first.english != pick.english else {
            selected = selected == pick ? nil : pick
            if pick.english, let word = question.options.first(where: { $0.id == pick.id }) {
                Speech.shared.english(word.english)
            }
            return
        }
        selected = nil
        let englishID = pick.english ? pick.id : first.id
        if first.id == pick.id {
            matched.insert(pick.id)
        } else {
            missed.insert(englishID)
            let wrong: Set<Pick> = [first, pick]
            flashing = wrong
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                flashing.subtract(wrong)
            }
        }
        if matched.count == question.options.count {
            finish(Answer(correct: missed.isEmpty,
                          results: Dictionary(uniqueKeysWithValues: question.options.map { ($0.id, !missed.contains($0.id)) })))
        }
    }
}

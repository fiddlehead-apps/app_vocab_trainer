import SwiftUI
@preconcurrency import Translation

/// All words, grouped by list. Edit, delete, add by hand, or look at them as flash cards.
struct WordsView: View {
    let store: Store
    @State private var search = ""
    @State private var editing: Word?
    @State private var adding = false
    @State private var cards: CardDeck?
    @State private var deckToDelete: String?

    struct CardDeck: Identifiable {
        let id = UUID()
        let words: [Word]
    }

    private func words(in deck: String) -> [Word] {
        let all = store.words.filter { $0.deck == deck }.sorted { $0.english.localizedCaseInsensitiveCompare($1.english) == .orderedAscending }
        guard !search.trimmed.isEmpty else { return all }
        return all.filter { $0.english.localizedCaseInsensitiveContains(search) || $0.translation.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List {
            if store.words.isEmpty {
                Text("No words yet. Scan a page or add a word with +.")
                    .foregroundStyle(Color.muted)
            }
            ForEach(store.decks, id: \.self) { deck in
                let list = words(in: deck)
                if !list.isEmpty {
                    Section {
                        ForEach(list) { word in
                            Button { editing = word } label: { row(word) }
                                .swipeActions {
                                    Button("Delete", systemImage: "trash", role: .destructive) { store.delete([word.id]) }
                                }
                        }
                    } header: {
                        HStack {
                            Text(deck)
                            Spacer()
                            Menu {
                                Button("Flash cards", systemImage: "rectangle.on.rectangle.angled") {
                                    cards = CardDeck(words: store.words.filter { $0.deck == deck }.shuffled())
                                }
                                Button("Delete list", systemImage: "trash", role: .destructive) { deckToDelete = deck }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 17))
                            }
                            .accessibilityLabel("List options")
                        }
                    }
                }
            }
        }
        .searchable(text: $search)
        .navigationTitle("My words")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add word", systemImage: "plus") { adding = true }
            }
        }
        .sheet(item: $editing) { word in
            WordEditor(store: store, word: word)
        }
        .sheet(isPresented: $adding) {
            WordEditor(store: store, word: Word(english: "", translation: "", deck: store.decks.first ?? String(localized: "My words")),
                       isNew: true)
        }
        .fullScreenCover(item: $cards) { deck in
            FlashcardsView(words: deck.words)
        }
        .confirmationDialog("Delete this list and all its words?", isPresented: .init(
            get: { deckToDelete != nil }, set: { if !$0 { deckToDelete = nil } }), titleVisibility: .visible) {
            Button("Delete list", role: .destructive) {
                if let deckToDelete { store.deleteDeck(deckToDelete) }
            }
        }
    }

    private func row(_ word: Word) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(word.english)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Text(word.translation)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.muted)
            }
            Spacer()
            Text(String(repeating: "★", count: word.stars) + String(repeating: "☆", count: 3 - word.stars))
                .font(.system(size: 14))
                .foregroundStyle(Color.sun)
                .accessibilityLabel("\(word.stars) of 3 stars")
        }
    }
}

/// Edit one word, or add one by hand (with on-device translation if wanted).
struct WordEditor: View {
    let store: Store
    @State var word: Word
    var isNew = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Settings.language) private var language = Settings.defaultLanguage
    @State private var config: TranslationSession.Configuration?
    @State private var failed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("English") {
                    TextField("English", text: $word.english)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section(Settings.name(of: language)) {
                    TextField(Settings.name(of: language), text: $word.translation)
                    if !word.english.trimmed.isEmpty {
                        Button("Translate", systemImage: "translate") {
                            failed = false
                            if config == nil {
                                config = .init(source: Locale.Language(identifier: "en"), target: Locale.Language(identifier: language))
                            } else {
                                config?.invalidate()
                            }
                        }
                    }
                    if failed {
                        Text("Translation isn't available right now. Type the meaning yourself.")
                            .font(.footnote)
                            .foregroundStyle(Color.danger)
                    }
                }
                Section("List") {
                    TextField("List name", text: $word.deck)
                    if !store.decks.isEmpty {
                        Picker("Existing list", selection: $word.deck) {
                            ForEach(store.decks, id: \.self) { Text($0).tag($0) }
                            if !store.decks.contains(word.deck) { Text(word.deck).tag(word.deck) }
                        }
                    }
                }
                if !isNew {
                    Section {
                        LabeledContent("Right", value: "\(word.correct)")
                        LabeledContent("Wrong", value: "\(word.wrong)")
                    }
                    Section {
                        Button("Delete word", role: .destructive) {
                            store.delete([word.id])
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New word" : "Edit word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(word.english.trimmed.isEmpty || word.translation.trimmed.isEmpty)
                }
            }
            .translationTask(config) { session in
                do {
                    let response = try await session.translate(word.english.trimmed)
                    word.translation = response.targetText
                } catch {
                    failed = true
                }
            }
        }
    }

    private func save() {
        word.english = word.english.trimmed
        word.translation = word.translation.trimmed
        word.deck = word.deck.trimmed.isEmpty ? String(localized: "My words") : word.deck.trimmed
        if isNew { store.add([word]) } else { store.update(word) }
        dismiss()
    }
}

/// Look at the words before practising: tap to turn the card. Nothing is counted here.
struct FlashcardsView: View {
    let words: [Word]
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var flipped = false

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                CircleIconButton(systemImage: "xmark", label: "Close") { dismiss() }
                Spacer()
                Text("\(index + 1) / \(words.count)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.muted)
                    .monospacedDigit()
            }
            Spacer()
            if words.indices.contains(index) {
                let word = words[index]
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { flipped.toggle() }
                } label: {
                    ZStack {
                        face(word.english, hint: String(localized: "Tap to turn"), color: .surface)
                            .opacity(flipped ? 0 : 1)
                        face(word.translation, hint: word.english, color: .brandSoft)
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            .opacity(flipped ? 1 : 0)
                    }
                    .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                }
                .buttonStyle(PressStyle())
                SpeakButton(text: word.english, size: 56)
            }
            Spacer()
            HStack(spacing: 12) {
                Button { move(-1) } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(BigButtonStyle(primary: false))
                    .disabled(index == 0)
                Button { move(1) } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(BigButtonStyle(primary: true))
                    .disabled(index >= words.count - 1)
            }
        }
        .padding(20)
        .background(Color.bg)
        .onAppear { speakCurrent() }
    }

    private func face(_ text: String, hint: String, color: Color) -> some View {
        VStack(spacing: 14) {
            Text(text)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
            Text(hint)
                .font(.system(size: 15))
                .foregroundStyle(Color.muted)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 280)
        .background(color, in: .rect(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.line, lineWidth: 1.5))
    }

    private func move(_ step: Int) {
        index = min(max(0, index + step), words.count - 1)
        flipped = false
        speakCurrent()
    }

    private func speakCurrent() {
        if words.indices.contains(index) { Speech.shared.english(words[index].english) }
    }
}

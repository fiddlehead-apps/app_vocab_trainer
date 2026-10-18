import SwiftUI
@preconcurrency import Translation

/// Shows what the scan found: word pairs to keep, words to pick, translations to check.
struct ReviewView: View {
    let store: Store
    let result: ScanResult
    let retry: () -> Void
    let done: () -> Void
    @AppStorage(Settings.language) private var language = Settings.defaultLanguage
    @State private var rows: [Row] = []
    @State private var deck = ""
    @State private var skipped = 0
    @State private var showEasy = false
    @State private var config: TranslationSession.Configuration?
    @State private var translating = false
    @State private var translationFailed = false
    @State private var started = false

    struct Row: Identifiable {
        let id = UUID()
        var english: String
        var translation: String
        var tried = false
    }

    private var chips: [String] {
        let taken = Set(rows.map { Check.normalize($0.english) })
        return (result.words + (showEasy ? result.easy : [])).filter { !taken.contains($0) && !store.contains($0) }
    }

    private var ready: [Row] {
        rows.filter { !$0.english.trimmed.isEmpty && !$0.translation.trimmed.isEmpty }
    }

    var body: some View {
        Group {
            if result.text.trimmed.isEmpty {
                nothingFound
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        deckField
                        newWords
                        if !result.words.isEmpty || !result.easy.isEmpty { pickWords }
                        DisclosureGroup("Recognized text") {
                            Text(result.text)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(Color.muted)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .tint(Color.muted)
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save \(ready.count)") { save() }
                    .fontWeight(.semibold)
                    .disabled(ready.isEmpty)
            }
        }
        .translationTask(config) { session in
            await translate(with: session)
        }
        .onAppear(perform: setUp)
    }

    private var nothingFound: some View {
        VStack(spacing: 14) {
            Text("🔍").font(.system(size: 64))
            Text("No text found")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ink)
            Text("Try again with more light and a little closer to the page.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.muted)
            Button("Try again", action: retry)
                .buttonStyle(BigButtonStyle(primary: true))
                .padding(.top, 8)
        }
        .padding(24)
    }

    private var deckField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("List").sectionTitle()
            HStack {
                TextField("List name", text: $deck)
                    .font(.system(size: 17, weight: .semibold))
                if !store.decks.isEmpty {
                    Menu {
                        ForEach(store.decks, id: \.self) { name in
                            Button(name) { deck = name }
                        }
                    } label: {
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundStyle(Color.muted)
                    }
                    .accessibilityLabel("Choose a list")
                }
            }
            .card(padding: 14)
        }
    }

    private var newWords: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your new words").sectionTitle()
            if rows.isEmpty {
                Text(result.words.isEmpty && result.easy.isEmpty
                     ? "No new words found on the photo."
                     : "Tap the words below that you want to learn.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
            }
            ForEach($rows) { $row in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("English", text: $row.english)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.ink)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField(translating && row.translation.isEmpty ? String(localized: "Translating…")
                                  : Settings.name(of: language), text: $row.translation)
                            .font(.system(size: 16))
                            .foregroundStyle(Color.muted)
                            .autocorrectionDisabled()
                    }
                    SpeakButton(text: row.english, size: 36)
                    Button {
                        rows.removeAll { $0.id == row.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.line)
                    }
                    .accessibilityLabel("Remove")
                }
                .card(padding: 12)
            }
            HStack {
                Button {
                    rows.append(Row(english: "", translation: ""))
                } label: {
                    Label("Add a word", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                }
                Spacer()
                if rows.contains(where: { $0.translation.trimmed.isEmpty && !$0.english.trimmed.isEmpty }) {
                    Button {
                        for i in rows.indices { rows[i].tried = false }
                        requestTranslation()
                    } label: {
                        Label("Translate", systemImage: "translate")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            .padding(.horizontal, 4)
            if translationFailed {
                Text("Translation isn't available right now. Type the meaning yourself.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.danger)
            }
            if skipped > 0 {
                Text("\(skipped) words from the photo are already in your list.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.muted)
            }
        }
    }

    private var pickWords: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Words on the photo").sectionTitle()
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(chips, id: \.self) { word in
                    Button {
                        rows.append(Row(english: word, translation: ""))
                        requestTranslation()
                    } label: {
                        Text(word)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.surface, in: .capsule)
                            .overlay(Capsule().strokeBorder(Color.line, lineWidth: 1.5))
                    }
                    .buttonStyle(PressStyle())
                }
            }
            if !result.easy.isEmpty {
                Toggle("Show easy words too (\(result.easy.count))", isOn: $showEasy)
                    .font(.system(size: 15))
                    .tint(Color.brand)
                    .padding(.top, 6)
            }
        }
    }

    private func setUp() {
        guard !started else { return }
        started = true
        deck = String(localized: "Scan \(Date.now.formatted(.dateTime.day().month(.abbreviated)))")
        let fresh = result.pairs.filter { !store.contains($0.english) }
        skipped = result.pairs.count - fresh.count
        rows = fresh.map { Row(english: $0.english, translation: $0.translation, tried: true) }
    }

    /// Starts (or restarts) the on-device translation for rows without a meaning.
    private func requestTranslation() {
        translationFailed = false
        if config == nil {
            config = .init(source: Locale.Language(identifier: "en"), target: Locale.Language(identifier: language))
        } else {
            config?.invalidate()
        }
    }

    private func translate(with session: TranslationSession) async {
        let pending = rows.filter { $0.translation.trimmed.isEmpty && !$0.english.trimmed.isEmpty && !$0.tried }
        guard !pending.isEmpty else { return }
        for row in pending {
            if let i = rows.firstIndex(where: { $0.id == row.id }) { rows[i].tried = true }
        }
        translating = true
        defer { translating = false }
        do {
            let texts = pending.map { (id: $0.id.uuidString, text: $0.english.trimmed) }
            for (id, translation) in try await Self.translations(of: texts, with: session) {
                guard let i = rows.firstIndex(where: { $0.id.uuidString == id }),
                      rows[i].translation.trimmed.isEmpty else { continue }
                rows[i].translation = translation
            }
        } catch {
            translationFailed = true
        }
    }

    /// Translates in one batch; returns (id, translation) pairs.
    private nonisolated static func translations(of texts: [(id: String, text: String)],
                                                 with session: TranslationSession) async throws -> [(String, String)] {
        let requests = texts.map { TranslationSession.Request(sourceText: $0.text, clientIdentifier: $0.id) }
        return try await session.translations(from: requests).compactMap { response in
            response.clientIdentifier.map { ($0, response.targetText) }
        }
    }

    private func save() {
        let name = deck.trimmed.isEmpty ? String(localized: "My words") : deck.trimmed
        store.add(ready.map { Word(english: $0.english.trimmed, translation: $0.translation.trimmed, deck: name) })
        done()
    }
}

nonisolated extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

import SwiftUI

/// What a practice round was started with.
struct Session: Identifiable {
    let id = UUID()
    let filter: DeckFilter
    let mode: Exercise?
}

struct HomeView: View {
    let store: Store
    @State private var filter = DeckFilter.all
    @State private var session: Session?
    @State private var showScan = false
    @State private var showSettings = false

    private var count: Int { store.words(for: filter).count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    RewardMeter(store: store).card()
                    Button { showScan = true } label: {
                        Label("Scan new words", systemImage: "camera.viewfinder")
                    }
                    .buttonStyle(BigButtonStyle(primary: store.words.isEmpty))
                    HStack(spacing: 12) {
                        NavigationLink { WordsView(store: store) } label: {
                            shortcut("📚", "My words", "\(store.words.count)")
                        }
                        NavigationLink { CollectionView(store: store) } label: {
                            shortcut("🦈", "Collection",
                                     "\(store.allBrainrots.filter { store.timesSeen($0) > 0 }.count)/\(store.allBrainrots.count)")
                        }
                    }
                    .buttonStyle(PressStyle())

                    if store.words.isEmpty {
                        emptyState
                    } else {
                        practice
                    }
                }
                .padding(20)
            }
            .background(Color.bg)
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showScan) { ScanView(store: store) }
        .sheet(isPresented: $showSettings) { SettingsView(store: store) }
        .fullScreenCover(item: $session) { session in
            PracticeView(store: store, filter: session.filter, mode: session.mode)
        }
        .onChange(of: store.decks) { _, decks in
            if case .deck(let name) = filter, !decks.contains(name) { filter = .all }
        }
        #if DEBUG
        .fullScreenCover(item: $debugReveal) { BrainrotReveal(item: $0, isNew: true) }
        .task { openDebugScreen() }
        #endif
    }

    #if DEBUG
    @State private var debugReveal: BrainrotItem?

    /// For screenshots in the simulator: `-debugScreen practice-letters`, `scan`, `settings` or `reveal-tralalero`.
    private func openDebugScreen() {
        guard let screen = UserDefaults.standard.string(forKey: "debugScreen") else { return }
        if screen == "scan" { showScan = true }
        if screen == "settings" { showSettings = true }
        if screen.hasPrefix("practice-") {
            session = Session(filter: .all, mode: Exercise(rawValue: String(screen.dropFirst(9))))
        }
        if screen.hasPrefix("reveal-"), let rot = Brainrot.all.first(where: { $0.id == screen.dropFirst(7) }) {
            debugReveal = .builtIn(rot)
        }
    }
    #endif

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hi! 👋")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.muted)
                Text("English words")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.ink)
            }
            Spacer()
            CircleIconButton(systemImage: "gearshape", label: "Settings") { showSettings = true }
        }
    }

    private func shortcut(_ emoji: String, _ title: LocalizedStringKey, _ value: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.muted)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ink)
            }
            Spacer(minLength: 0)
        }
        .card(padding: 14)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            BookIllustration(width: 96)
                .padding(.bottom, 6)
            Text("No words yet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ink)
            Text("Take a photo of a page from your English book. The app finds the new words for you.")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.muted)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 24)
    }

    private var practice: some View {
        VStack(spacing: 12) {
            Text("Practise").sectionTitle()
                .padding(.top, 6)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(String(localized: "All words"), .all)
                    if !store.tricky.isEmpty { chip("😬 " + String(localized: "Tricky words"), .tricky) }
                    ForEach(store.decks, id: \.self) { chip($0, .deck($0)) }
                }
            }
            .scrollClipDisabled()

            Button { session = Session(filter: filter, mode: nil) } label: {
                HStack(spacing: 14) {
                    Text("🎲").font(.system(size: 40))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Mixed")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                        Text("All exercises, randomly · \(count) words")
                            .font(.system(size: 14))
                            .opacity(0.85)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "play.fill").font(.system(size: 22))
                }
                .foregroundStyle(Color.brandInk)
                .padding(18)
                .background(Color.brand, in: .rect(cornerRadius: 18))
            }
            .buttonStyle(PressStyle())

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Exercise.allCases) { exercise in
                    let possible = count >= exercise.minWords
                    Button { session = Session(filter: filter, mode: exercise) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.emoji).font(.system(size: 30))
                            Text(exercise.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.ink)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2, reservesSpace: true)
                            if !possible {
                                Text("Needs \(exercise.minWords) words")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.muted)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card(padding: 14)
                    }
                    .buttonStyle(PressStyle())
                    .disabled(!possible)
                    .opacity(possible ? 1 : 0.5)
                }
            }
        }
    }

    private func chip(_ title: String, _ value: DeckFilter) -> some View {
        let active = filter == value
        return Button { filter = value } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(active ? Color.brandInk : Color.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(active ? Color.brand : Color.surface, in: .capsule)
                .overlay(Capsule().strokeBorder(active ? Color.clear : Color.line, lineWidth: 1.5))
        }
        .buttonStyle(PressStyle())
    }
}

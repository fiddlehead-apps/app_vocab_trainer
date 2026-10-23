import SwiftUI

/// An Italian brainrot character, drawn from emoji. The name is spoken by the Italian voice.
nonisolated struct Brainrot: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let main: String
    /// Placed around the main emoji: bottom left, bottom right, top right, top left, bottom.
    let extras: [String]
    let colors: [UInt32]
    let motion: Motion
    let english: String
    let german: String

    enum Motion: Sendable {
        case bounce, wiggle, spin, float, shake
    }

    static let all: [Brainrot] = [
        .init(id: "tralalero", name: "Tralalero Tralala", main: "🦈", extras: ["👟", "👟", "🌊", "", "👟"],
              colors: [0x2E8BFF, 0x7FE3FF], motion: .bounce,
              english: "A shark with three legs in blue sneakers. He runs on the beach faster than anyone.",
              german: "Ein Hai mit drei Beinen in blauen Turnschuhen. Er rennt am Strand schneller als alle anderen."),
        .init(id: "bombardiro", name: "Bombardiro Crocodilo", main: "🐊", extras: ["☁️", "☁️", "✈️"],
              colors: [0x3B7A3B, 0xA6E36B], motion: .float,
              english: "Half crocodile, half airplane. He flies over the sea and drops… water balloons!",
              german: "Halb Krokodil, halb Flugzeug. Er fliegt übers Meer und wirft … Wasserbomben!"),
        .init(id: "tungtung", name: "Tung Tung Tung Sahur", main: "🪵", extras: ["", "🏏", "🌙"],
              colors: [0x8B5A2B, 0xE0B07A], motion: .shake,
              english: "A wooden log with a bat. Tung tung tung! He knocks on every door at night.",
              german: "Ein Holzklotz mit einem Schläger. Tung tung tung! Er klopft nachts an jede Tür."),
        .init(id: "patapim", name: "Brr Brr Patapim", main: "🐒", extras: ["🦶", "🦶", "🌳", "🍃"],
              colors: [0x2F6B2F, 0x9BD770], motion: .wiggle,
              english: "A monkey who is also a tree. His feet are huge and he loves to say brr brr.",
              german: "Ein Affe, der gleichzeitig ein Baum ist. Seine Füße sind riesig und er sagt gern brr brr."),
        .init(id: "lirili", name: "Lirilì Larilà", main: "🐘", extras: ["🩴", "🩴", "⏰", "🌵"],
              colors: [0xC9A227, 0xFFE08A], motion: .float,
              english: "An elephant made of cactus, wearing sandals. He can stop time with his clock.",
              german: "Ein Elefant aus Kaktus, in Sandalen. Mit seiner Uhr kann er die Zeit anhalten."),
        .init(id: "ballerina", name: "Ballerina Cappuccina", main: "☕️", extras: ["🩰", "🩰", "✨", "🎀"],
              colors: [0xB5651D, 0xFFC1D6], motion: .spin,
              english: "A ballerina with a cup of cappuccino as her head. She dances all day long.",
              german: "Eine Ballerina mit einer Tasse Cappuccino als Kopf. Sie tanzt den ganzen Tag."),
        .init(id: "assassino", name: "Cappuccino Assassino", main: "☕️", extras: ["", "", "⚡️", "🥷"],
              colors: [0x3A2A20, 0xA8744F], motion: .shake,
              english: "A tiny coffee cup ninja. You never see him coming – you only smell him.",
              german: "Ein winziger Kaffeetassen-Ninja. Man sieht ihn nie kommen – man riecht ihn nur."),
        .init(id: "chimpanzini", name: "Chimpanzini Bananini", main: "🍌", extras: ["", "", "🐒", "💛"],
              colors: [0xF2C200, 0xFFF29A], motion: .bounce,
              english: "A chimpanzee who lives inside a banana. Peel him carefully!",
              german: "Ein Schimpanse, der in einer Banane wohnt. Vorsichtig schälen!"),
        .init(id: "bombombini", name: "Bombombini Gusini", main: "🪿", extras: ["💨", "", "✈️"],
              colors: [0x5A6B7A, 0xC9D6E3], motion: .float,
              english: "A goose who is also a jet plane. Honk honk, here she comes!",
              german: "Eine Gans, die auch ein Düsenjet ist. Tröt tröt, da kommt sie!"),
        .init(id: "trippi", name: "Trippi Troppi", main: "🦐", extras: ["🌊", "", "🐱"],
              colors: [0xFF6F61, 0xFFC3A0], motion: .wiggle,
              english: "A shrimp with the face of a cat. Meow from the bottom of the sea.",
              german: "Eine Garnele mit Katzengesicht. Miau vom Meeresgrund."),
        .init(id: "frigo", name: "Frigo Camelo", main: "🐪", extras: ["👢", "👢", "❄️", "🧊"],
              colors: [0x6FC3DF, 0xE6F7FF], motion: .shake,
              english: "A camel who lives in a fridge and wears boots. He is always very, very cold.",
              german: "Ein Kamel, das in einem Kühlschrank wohnt und Stiefel trägt. Ihm ist immer sehr, sehr kalt."),
        .init(id: "saturno", name: "La Vaca Saturno Saturnita", main: "🐄", extras: ["⭐️", "✨", "🪐"],
              colors: [0x2B1B5A, 0x9B7BFF], motion: .float,
              english: "A cow from planet Saturn. She walks through space on tiny feet.",
              german: "Eine Kuh vom Planeten Saturn. Sie spaziert auf winzigen Füßen durchs All."),
        .init(id: "boneca", name: "Boneca Ambalabu", main: "🐸", extras: ["🦵", "🦵", "🛞"],
              colors: [0x2E7D32, 0x81C784], motion: .bounce,
              english: "A frog with a car tyre for a body and human legs. Ambalabu!",
              german: "Ein Frosch mit einem Autoreifen als Körper und Menschenbeinen. Ambalabu!"),
        .init(id: "glorbo", name: "Glorbo Fruttodrillo", main: "🍉", extras: ["", "", "🐊"],
              colors: [0xD9344A, 0x6BCB77], motion: .wiggle,
              english: "A crocodile inside a watermelon. Juicy and dangerous at the same time.",
              german: "Ein Krokodil in einer Wassermelone. Saftig und gefährlich zugleich."),
        .init(id: "burbaloni", name: "Burbaloni Luliloli", main: "🥥", extras: ["🌊", "🏝️", "🦫"],
              colors: [0x7B4F2C, 0xD9B38C], motion: .float,
              english: "A capybara hiding inside a coconut. He floats around the island all day.",
              german: "Ein Wasserschwein, das sich in einer Kokosnuss versteckt. Es treibt den ganzen Tag um die Insel."),
        .init(id: "trulimero", name: "Trulimero Trulicina", main: "🐟", extras: ["🦵", "🦵", "🐱", "", "🦵"],
              colors: [0x1E88E5, 0x80DEEA], motion: .bounce,
              english: "A fish with a cat's head and human legs. Nobody knows why.",
              german: "Ein Fisch mit Katzenkopf und Menschenbeinen. Keiner weiß, warum."),
        .init(id: "giraffa", name: "Giraffa Celeste", main: "🦒", extras: ["🍉", "", "🚀", "⭐️"],
              colors: [0x0D1B4C, 0x4FC3F7], motion: .float,
              english: "A giraffe made of watermelon who flies through space.",
              german: "Eine Giraffe aus Wassermelone, die durchs Weltall fliegt."),
        .init(id: "orangutini", name: "Orangutini Ananasini", main: "🦧", extras: ["", "🍍", "", "🍍"],
              colors: [0xE09F1F, 0xFFE066], motion: .wiggle,
              english: "An orangutan with a pineapple body. Sweet, but a bit prickly.",
              german: "Ein Orang-Utan mit Ananaskörper. Süß, aber ein bisschen stachelig."),
        .init(id: "cocofanto", name: "Cocofanto Elefanto", main: "🥥", extras: ["", "", "🐘", "🌴"],
              colors: [0x6D4C41, 0xBCAAA4], motion: .bounce,
              english: "A coconut with an elephant's head. Watch out when he falls from a palm tree!",
              german: "Eine Kokosnuss mit Elefantenkopf. Vorsicht, wenn er von der Palme fällt!"),
        .init(id: "tigrrullini", name: "Tigrrullini Watermellini", main: "🐯", extras: ["🍉", "🍉"],
              colors: [0xFF8F00, 0xEF5350], motion: .shake,
              english: "A tiger with a watermelon head. Grrr – and very refreshing.",
              german: "Ein Tiger mit Wassermelonenkopf. Grrr – und sehr erfrischend."),
        .init(id: "hotspot", name: "Pot Hotspot", main: "💀", extras: ["📱", "", "📶"],
              colors: [0x263238, 0x00E5FF], motion: .shake,
              english: "A skeleton who is always looking for free Wi-Fi. Hotspot, bro?",
              german: "Ein Skelett, das immer nach kostenlosem WLAN sucht. Hotspot, Bro?"),
        .init(id: "svinino", name: "Svinino Bombondino", main: "🐷", extras: ["", "🎊", "💣"],
              colors: [0xF48FB1, 0xFFCDD2], motion: .bounce,
              english: "A pig who is also a bomb. Don't worry – he only explodes into confetti.",
              german: "Ein Schwein, das auch eine Bombe ist. Keine Sorge – es explodiert nur zu Konfetti."),
        .init(id: "cacto", name: "Il Cacto Hipopotamo", main: "🦛", extras: ["🌵", "🌵", "", "🌵"],
              colors: [0x558B2F, 0xC5E1A5], motion: .wiggle,
              english: "A hippo who is also a cactus. Please don't hug him.",
              german: "Ein Nilpferd, das auch ein Kaktus ist. Bitte nicht umarmen."),
        .init(id: "toasterino", name: "Rhino Toasterino", main: "🦏", extras: ["🍞", "", "🔥"],
              colors: [0x8D6E63, 0xFFB74D], motion: .shake,
              english: "A rhino who is also a toaster. Breakfast is ready!",
              german: "Ein Nashorn, das auch ein Toaster ist. Frühstück ist fertig!"),
        .init(id: "spaghetti", name: "Spaghetti Tualetti", main: "🚽", extras: ["🧻", "", "🍝", "🍝"],
              colors: [0xE53935, 0xFFF59D], motion: .wiggle,
              english: "A toilet full of spaghetti. The strangest restaurant in Italy.",
              german: "Eine Toilette voller Spaghetti. Das seltsamste Restaurant Italiens."),
        .init(id: "bananita", name: "Bananita Dolfinita", main: "🐬", extras: ["🌊", "🌊", "🍌"],
              colors: [0x00ACC1, 0xFFEE58], motion: .float,
              english: "A dolphin in a banana costume. She jumps out of the water to say hello.",
              german: "Ein Delfin im Bananenkostüm. Er springt aus dem Wasser und sagt Hallo."),
        .init(id: "crabracadabra", name: "Chef Crabracadabra", main: "🦀", extras: ["🍕", "", "✨", "👨‍🍳"],
              colors: [0xD84315, 0xFFAB91], motion: .wiggle,
              english: "A crab chef who cooks with magic. Abracadabra – pizza!",
              german: "Ein Krabben-Koch, der mit Magie kocht. Abrakadabra – Pizza!"),
        .init(id: "gorillo", name: "Gorillo Watermellondrillo", main: "🦍", extras: ["🍉", "🍉", "", "", "🍉"],
              colors: [0x2E7D32, 0xE57373], motion: .shake,
              english: "A gorilla with a watermelon body. Super strong and super juicy.",
              german: "Ein Gorilla mit Wassermelonenkörper. Superstark und supersaftig."),
    ]
}

// MARK: - Pictures

/// A brainrot drawn from emoji, or an own picture, moving the way the character moves.
struct BrainrotPicture: View {
    let item: BrainrotItem
    var size: CGFloat = 260
    var animated = true

    private static let slots: [CGPoint] = [.init(x: -0.42, y: 0.5), .init(x: 0.42, y: 0.5), .init(x: 0.5, y: -0.45),
                                           .init(x: -0.5, y: -0.45), .init(x: 0, y: 0.62)]

    var body: some View {
        TimelineView(.animation(paused: !animated)) { context in
            let t = animated ? context.date.timeIntervalSinceReferenceDate : 0
            switch item {
            case .builtIn(let rot): drawing(rot, t: t)
            case .custom(let own): photo(own, t: t)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(item.name)
    }

    private func drawing(_ rot: Brainrot, t: Double) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: rot.colors.map { Color(hex: $0) }.reversed(),
                                     center: .center, startRadius: 0, endRadius: size * 0.55))
                .frame(width: size * 0.92, height: size * 0.92)
            Text(rot.main)
                .font(.system(size: size * 0.5))
                .modifier(Moving(motion: rot.motion, t: t, size: size))
            ForEach(Array(rot.extras.enumerated()), id: \.offset) { index, emoji in
                let slot = Self.slots[index % Self.slots.count]
                Text(emoji)
                    .font(.system(size: size * 0.2))
                    .rotationEffect(.degrees(sin(t * 2 + Double(index)) * 10))
                    .offset(x: slot.x * size * 0.5,
                            y: slot.y * size * 0.5 + sin(t * 3 + Double(index) * 1.7) * size * 0.025)
            }
        }
    }

    private func photo(_ own: CustomBrainrot, t: Double) -> some View {
        Group {
            if let image = Store.picture(own.id) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.brandSoft
            }
        }
        .frame(width: size * 0.9, height: size * 0.9)
        .clipShape(.rect(cornerRadius: size * 0.16))
        .overlay(RoundedRectangle(cornerRadius: size * 0.16).strokeBorder(.white, lineWidth: max(2, size * 0.02)))
        .modifier(Moving(motion: .wiggle, t: t, size: size * 0.4))
    }
}

/// Moves a view as a function of time, so the motion keeps going without state.
private struct Moving: ViewModifier {
    let motion: Brainrot.Motion
    let t: Double
    let size: CGFloat

    func body(content: Content) -> some View {
        switch motion {
        case .bounce:
            content
                .scaleEffect(x: 1 + abs(cos(t * 4)) * 0.04, y: 1 - abs(cos(t * 4)) * 0.04, anchor: .bottom)
                .offset(y: -abs(sin(t * 4)) * size * 0.08)
        case .wiggle:
            content.rotationEffect(.degrees(sin(t * 5) * 10))
        case .spin:
            content.rotation3DEffect(.degrees(t * 140), axis: (x: 0, y: 1, z: 0))
        case .float:
            content.offset(x: cos(t * 1.3) * size * 0.03, y: sin(t * 2) * size * 0.05)
        case .shake:
            let burst = sin(t * 2.2) > 0.4 ? 1.0 : 0.15
            content
                .offset(x: sin(t * 28) * size * 0.015 * burst)
                .rotationEffect(.degrees(sin(t * 28) * 4 * burst))
        }
    }
}

/// Falling emoji confetti.
struct Confetti: View {
    private struct Piece {
        let x = Double.random(in: 0...1)
        let speed = Double.random(in: 0.1...0.25)
        let phase = Double.random(in: 0...1)
        let size = Double.random(in: 20...36)
        let symbol = ["🎉", "⭐️", "✨", "🍕", "💥", "🎊", "🍝"].randomElement() ?? "🎉"
    }

    @State private var pieces = (0..<26).map { _ in Piece() }

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { canvas, size in
                let t = context.date.timeIntervalSinceReferenceDate
                for piece in pieces {
                    let progress = (t * piece.speed + piece.phase).truncatingRemainder(dividingBy: 1)
                    let point = CGPoint(x: piece.x * size.width + sin(t * 2 + piece.phase * 6) * 18,
                                        y: progress * (size.height + 80) - 40)
                    canvas.draw(Text(piece.symbol).font(.system(size: piece.size)), at: point)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Reveal

/// The big moment: the brainrot pops up and the Italian voice says its name.
struct BrainrotReveal: View {
    let item: BrainrotItem
    var isNew = false
    var replay = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Settings.language) private var language = Settings.defaultLanguage
    @State private var appeared = false
    @State private var showTranslation = false

    private var colors: [Color] {
        switch item {
        case .builtIn(let rot): rot.colors.map { Color(hex: $0) }
        case .custom: [Color(hex: 0x6C47FF), Color(hex: 0xFF5FA2)]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [colors[0], .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if !replay { Confetti().ignoresSafeArea() }

            VStack(spacing: 18) {
                Text(isNew ? "NEW BRAINROT!" : "BRAINROT!")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.sun, in: .capsule)
                    .opacity(replay ? 0 : 1)

                Spacer(minLength: 0)

                BrainrotPicture(item: item, size: 270)
                    .scaleEffect(appeared ? 1 : 0.1)
                    .rotationEffect(.degrees(appeared ? 0 : -40))

                Text(item.name)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                    .opacity(appeared ? 1 : 0)

                if case .builtIn(let rot) = item {
                    description(rot)
                }

                Spacer(minLength: 0)

                HStack(spacing: 12) {
                    Button { sayName() } label: {
                        Label("Say it again", systemImage: "speaker.wave.2.fill")
                    }
                    if case .builtIn(let rot) = item {
                        Button { Speech.shared.english(rot.english) } label: {
                            Label("Read to me", systemImage: "book")
                        }
                    }
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .buttonStyle(.bordered)
                .tint(.white)

                Button(replay ? "Close" : "Keep going!") { dismiss() }
                    .buttonStyle(BigButtonStyle(primary: true))
            }
            .padding(24)
        }
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) { appeared = true }
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                sayName()
            }
        }
        .onDisappear { Speech.shared.stop() }
    }

    /// The English text is a little reading exercise; tap it to see the German.
    private func description(_ rot: Brainrot) -> some View {
        Button {
            withAnimation { showTranslation.toggle() }
        } label: {
            VStack(spacing: 8) {
                Text(rot.english)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                if language == "de" {
                    if showTranslation {
                        Text(rot.german)
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.75))
                    } else {
                        Text("Tap for German")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
            .multilineTextAlignment(.center)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.12), in: .rect(cornerRadius: 16))
        }
        .buttonStyle(PressStyle())
        .disabled(language != "de")
        .opacity(appeared ? 1 : 0)
    }

    private func sayName() {
        Speech.shared.say(item.name, language: "it-IT", rate: 0.42, pitch: 0.9)
    }
}

// MARK: - Collection

/// All brainrots; the ones not found yet are hidden behind a question mark.
struct CollectionView: View {
    let store: Store
    @State private var shown: BrainrotItem?

    var body: some View {
        let items = store.allBrainrots
        let found = items.filter { store.timesSeen($0) > 0 }.count
        ScrollView {
            VStack(spacing: 18) {
                Text("You found \(found) of \(items.count)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.muted)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 12)], spacing: 12) {
                    ForEach(items) { item in cell(item) }
                }
            }
            .padding(20)
        }
        .background(Color.bg)
        .navigationTitle("Brainrot collection")
        .fullScreenCover(item: $shown) { item in
            BrainrotReveal(item: item, replay: true)
        }
    }

    private func cell(_ item: BrainrotItem) -> some View {
        let seen = store.timesSeen(item)
        return Button { if seen > 0 { shown = item } } label: {
            VStack(spacing: 6) {
                if seen > 0 {
                    BrainrotPicture(item: item, size: 88, animated: false)
                } else {
                    Text("?")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(Color.muted)
                        .frame(width: 80, height: 80)
                        .background(Color.line, in: .circle)
                        .frame(width: 88, height: 88)
                }
                Text(seen > 0 ? item.name : "???")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                if seen > 1 {
                    Text("×\(seen)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.brand)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .background(Color.surface, in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.line, lineWidth: 1.5))
        }
        .buttonStyle(PressStyle())
        .disabled(seen == 0)
    }
}

import Observation
import UIKit

/// Words, learning progress and the brainrot collection. Saved as JSON in the app's documents.
@Observable
final class Store {
    private(set) var words: [Word] = []
    private(set) var progress = Progress()
    private(set) var custom: [CustomBrainrot] = []
    /// Set when enough correct answers came together; the practice screen shows it.
    var reward: Reward?

    private static var file: URL { URL.documentsDirectory.appending(path: "vocab.json") }
    private static var pictures: URL { URL.documentsDirectory.appending(path: "Brainrots", directoryHint: .isDirectory) }

    init() {
        guard let data = try? Data(contentsOf: Self.file) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let saved = try? decoder.decode(SaveData.self, from: data) else { return }
        words = saved.words
        progress = saved.progress
        custom = saved.custom
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(SaveData(words: words, progress: progress, custom: custom)) else { return }
        try? data.write(to: Self.file, options: [.atomic, .completeFileProtection])
    }

    // MARK: Words

    /// List names, newest first.
    var decks: [String] {
        var seen = Set<String>()
        return words.sorted { $0.created > $1.created }.map(\.deck).filter { seen.insert($0).inserted }
    }

    func words(for filter: DeckFilter) -> [Word] {
        switch filter {
        case .all: words
        case .tricky: tricky
        case .deck(let name): words.filter { $0.deck == name }
        }
    }

    /// Words that went wrong and are not learned yet.
    var tricky: [Word] { words.filter { $0.wrong > 0 && $0.box <= 1 } }

    func contains(_ english: String) -> Bool {
        let key = Check.normalize(english)
        return words.contains { Check.normalize($0.english) == key }
    }

    /// Adds new words, skipping ones that are already in the list.
    func add(_ new: [Word]) {
        for word in new where !contains(word.english) {
            words.append(word)
        }
        save()
    }

    func update(_ word: Word) {
        guard let i = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[i] = word
        save()
    }

    func delete(_ ids: Set<UUID>) {
        words.removeAll { ids.contains($0.id) }
        save()
    }

    func deleteDeck(_ deck: String) {
        words.removeAll { $0.deck == deck }
        save()
    }

    // MARK: Practice

    /// Moves the words between the Leitner boxes and counts towards the next brainrot.
    func record(_ answer: Answer) {
        for (id, right) in answer.results {
            guard let i = words.firstIndex(where: { $0.id == id }) else { continue }
            if right {
                words[i].box = min(5, words[i].box + 1)
                words[i].correct += 1
            } else {
                words[i].box = max(0, words[i].box - 2)
                words[i].wrong += 1
            }
            words[i].lastAsked = .now
        }
        progress.totalAnswers += 1
        if answer.correct {
            progress.totalCorrect += 1
            progress.sinceReward += 1
            if progress.sinceReward >= Settings.currentRewardEvery {
                progress.sinceReward = 0
                reward = pickReward()
            }
        }
        save()
    }

    /// A random brainrot; ones not found yet are more likely, so the collection grows.
    private func pickReward() -> Reward {
        let all = allBrainrots
        let unseen = all.filter { progress.seen[$0.id] == nil }
        let item = (!unseen.isEmpty && Double.random(in: 0..<1) < 0.75 ? unseen : all).randomElement() ?? .builtIn(Brainrot.all[0])
        let isNew = progress.seen[item.id] == nil
        progress.seen[item.id, default: 0] += 1
        return Reward(item: item, isNew: isNew)
    }

    /// Back to box 0 for every word and no answers counted. Words and the collection stay.
    func resetProgress() {
        for i in words.indices {
            words[i].box = 0
            words[i].correct = 0
            words[i].wrong = 0
            words[i].lastAsked = nil
        }
        progress.sinceReward = 0
        progress.totalCorrect = 0
        progress.totalAnswers = 0
        save()
    }

    // MARK: Brainrots

    var allBrainrots: [BrainrotItem] { Brainrot.all.map(BrainrotItem.builtIn) + custom.map(BrainrotItem.custom) }

    func timesSeen(_ item: BrainrotItem) -> Int { progress.seen[item.id] ?? 0 }

    func addCustom(name: String, image: UIImage) {
        let entry = CustomBrainrot(name: name)
        try? FileManager.default.createDirectory(at: Self.pictures, withIntermediateDirectories: true)
        guard let data = Self.shrink(image, to: 900).jpegData(compressionQuality: 0.85),
              (try? data.write(to: Self.pictureFile(entry.id))) != nil else { return }
        custom.append(entry)
        save()
    }

    func deleteCustom(_ id: UUID) {
        custom.removeAll { $0.id == id }
        progress.seen["custom-\(id.uuidString)"] = nil
        try? FileManager.default.removeItem(at: Self.pictureFile(id))
        save()
    }

    static func picture(_ id: UUID) -> UIImage? { UIImage(contentsOfFile: pictureFile(id).path) }

    private static func pictureFile(_ id: UUID) -> URL { pictures.appending(path: "\(id.uuidString).jpg") }

    private static func shrink(_ image: UIImage, to side: CGFloat) -> UIImage {
        let scale = min(1, side / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
}

/// The brainrot shown after enough correct answers.
struct Reward: Identifiable {
    let item: BrainrotItem
    let isNew: Bool
    var id: String { item.id }
}

/// A built-in brainrot or one of the own pictures.
nonisolated enum BrainrotItem: Identifiable, Hashable, Sendable {
    case builtIn(Brainrot)
    case custom(CustomBrainrot)

    var id: String {
        switch self {
        case .builtIn(let rot): rot.id
        case .custom(let own): "custom-\(own.id.uuidString)"
        }
    }

    var name: String {
        switch self {
        case .builtIn(let rot): rot.name
        case .custom(let own): own.name
        }
    }
}

import AVFoundation
import SwiftUI

@main
struct SolaVocabApp: App {
    @State private var store = Store()

    init() {
        // Speak even when the iPhone is switched to silent.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    var body: some Scene {
        WindowGroup {
            HomeView(store: store)
                .tint(Color.brand)
        }
    }
}

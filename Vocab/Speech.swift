import AVFoundation

/// Reads words aloud with the built-in voices. Works offline.
final class Speech {
    static let shared = Speech()
    private let synth = AVSpeechSynthesizer()

    func english(_ text: String, slow: Bool = false) {
        say(text, language: Settings.englishVoice, rate: slow ? 0.22 : 0.42)
    }

    func say(_ text: String, language: String, rate: Float = 0.45, pitch: Float = 1) {
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        synth.speak(utterance)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }
}

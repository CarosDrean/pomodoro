import AVFoundation
import AppKit

final class SoundManager {
    static let shared = SoundManager()

    private var player: AVAudioPlayer?
    private var synthesizer: NSSpeechSynthesizer?

    private init() {}

    func playCompletionSound() {
        let soundName = Defaults.alertSound
        if soundName == "default" {
            NSSound.beep()
        } else {
            NSSound(named: soundName)?.play()
        }
    }

    func playPreview(named soundName: String) {
        if soundName == "default" {
            NSSound.beep()
        } else {
            NSSound(named: soundName)?.play()
        }
    }

    func speak(_ text: String) {
        guard Defaults.readPhrases else { return }
        synthesizer?.stopSpeaking()
        synthesizer = NSSpeechSynthesizer()
        synthesizer?.startSpeaking(text)
    }

    func stopSpeaking() {
        synthesizer?.stopSpeaking()
    }
}

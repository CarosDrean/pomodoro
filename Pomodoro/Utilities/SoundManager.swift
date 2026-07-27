import AVFoundation
import AppKit

final class SoundManager {
    static let shared = SoundManager()

    private var player: AVAudioPlayer?

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
}

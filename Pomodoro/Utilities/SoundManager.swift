import AVFoundation
import AppKit

final class SoundManager {
    static let shared = SoundManager()

    private init() {}

    func playCompletionSound() {
        NSSound.beep()
    }
}

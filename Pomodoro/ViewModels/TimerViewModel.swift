import Foundation
import SwiftUI

@MainActor
final class TimerViewModel: ObservableObject {
    @Published var phase: TimerPhase = .idle
    @Published var timeRemaining: Int = 0
    @Published var totalTime: Int = 0
    @Published var isRunning: Bool = false
    @Published var pomodoroCount: Int = 0

    private var timer: Timer?

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(timeRemaining) / Double(totalTime)
    }

    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var phaseColor: Color {
        switch phase {
        case .work: .red
        case .shortBreak: .green
        case .longBreak: .blue
        case .idle: .gray
        }
    }

    var menuBarIcon: String {
        if isRunning {
            return phase == .work ? "brain.head.profile.fill" : "cup.and.saucer.fill"
        }
        return "timer"
    }

    init() {
        pomodoroCount = 0
    }

    func startWork() {
        startPhase(.work, duration: Defaults.workDuration * 60)
    }

    func startShortBreak() {
        startPhase(.shortBreak, duration: Defaults.shortBreakDuration * 60)
    }

    func startLongBreak() {
        startPhase(.longBreak, duration: Defaults.longBreakDuration * 60)
    }

    func toggle() {
        if isRunning {
            pause()
        } else if phase == .idle {
            startWork()
        } else {
            resume()
        }
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func resume() {
        guard timeRemaining > 0 else { return }
        isRunning = true
        startTimer()
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        phase = .idle
        timeRemaining = 0
        totalTime = 0
        isRunning = false
        pomodoroCount = 0
    }

    func skip() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        advanceToNextPhase()
    }

    private func startPhase(_ newPhase: TimerPhase, duration: Int) {
        timer?.invalidate()
        phase = newPhase
        timeRemaining = duration
        totalTime = duration
        isRunning = true
        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard timeRemaining > 0 else {
            completePhase()
            return
        }
        timeRemaining -= 1
    }

    private func completePhase() {
        timer?.invalidate()
        timer = nil
        isRunning = false

        let record = SessionRecord(phase: phase, duration: totalTime)
        Defaults.addSession(record)

        if phase == .work {
            pomodoroCount += 1
            NotificationManager.shared.sendWorkComplete()
        } else {
            NotificationManager.shared.sendBreakComplete()
        }

        SoundManager.shared.playCompletionSound()
        advanceToNextPhase()
    }

    private func advanceToNextPhase() {
        if phase == .work {
            if pomodoroCount % Defaults.pomodorosBeforeLongBreak == 0 && pomodoroCount > 0 {
                startLongBreak()
            } else {
                startShortBreak()
            }
        } else {
            if Defaults.autoStart {
                startWork()
            } else {
                phase = .idle
                timeRemaining = 0
                totalTime = 0
            }
        }
    }
}

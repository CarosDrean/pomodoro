import Foundation
import SwiftUI

struct AlertInfo {
    let title: String
    let message: String
    let buttonText: String
    let color: Color
    let isBreak: Bool
}

@MainActor
final class TimerViewModel: ObservableObject {
    @Published var phase: TimerPhase = .idle
    @Published var timeRemaining: Int = 0
    @Published var totalTime: Int = 0
    @Published var isRunning: Bool = false
    @Published var pomodoroCount: Int = 0
    @Published var alertInfo: AlertInfo?

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
        alertInfo = nil
    }

    func skip() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        alertInfo = nil
        advanceToNextPhase()
    }

    func acknowledgeAlert() {
        alertInfo = nil
        advanceToNextPhase()
    }

    private func startPhase(_ newPhase: TimerPhase, duration: Int) {
        timer?.invalidate()
        phase = newPhase
        timeRemaining = duration
        totalTime = duration
        isRunning = true

        if newPhase == .shortBreak || newPhase == .longBreak {
            if Defaults.intrusiveBreaks {
                alertInfo = AlertInfo(
                    title: "Break time",
                    message: Self.breakMessages.randomElement() ?? "Relájate un momento.",
                    buttonText: "Pause",
                    color: .green,
                    isBreak: true
                )
            }
        }

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
        }

        SoundManager.shared.playCompletionSound()
        showAlertForCompletedPhase()
    }

    private func showAlertForCompletedPhase() {
        switch phase {
        case .work:
            alertInfo = AlertInfo(
                title: "Great work!",
                message: Self.breakMessages.randomElement() ?? "Time for a break.",
                buttonText: "Start Break",
                color: .green,
                isBreak: false
            )
        case .shortBreak, .longBreak:
            alertInfo = AlertInfo(
                title: "Break is over!",
                message: Self.focusMessages.randomElement() ?? "Ready to focus again?",
                buttonText: "Start Focus",
                color: .red,
                isBreak: false
            )
        case .idle:
            break
        }
    }

    static let breakMessages = [
        "Toma un descanso, te lo mereces.",
        "Bebe agua y estira el cuerpo.",
        "Camina un poco y descansa la vista.",
        "Respira profundo y relaja los hombros.",
        "Mira por la ventana unos segundos.",
        "Saluda a un compañero o amigo.",
        "Come algo saludable para recargar.",
        "Haz algunos estiramientos suaves.",
        "Escucha una canción que te guste.",
        "Cierra los ojos y descansa la mente.",
        "Muévete un poco, tu cuerpo lo agradecerá.",
        "Toma 10 respiraciones profundas."
    ]

    private static let focusMessages = [
        "¡Listo para concentrarte? ¡Vamos!",
        "Hora de entrar en zona. Tú puedes.",
        "Un pomodoro a la vez. ¡Enfócate!",
        "Apaga distracciones y a trabajar.",
        "Tu mejor trabajo empieza ahora.",
        "Concentración total por unos minutos."
    ]

    static func fetchCatImage(completion: @escaping (Data?) -> Void) {
        let cacheBuster = Int(Date().timeIntervalSince1970)
        let url = URL(string: "https://cataas.com/cat?\(cacheBuster)")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(data) }
        }
        task.resume()
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

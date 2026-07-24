import SwiftUI

@main
struct PomodoroApp: App {
    @StateObject private var timerVM = TimerViewModel()
    @State private var activeView: ActiveView = .timer

    init() {
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        MenuBarExtra {
            Group {
                switch activeView {
                case .timer:
                    TimerView(viewModel: timerVM, activeView: $activeView)
                case .settings:
                    SettingsView(activeView: $activeView)
                case .history:
                    SessionHistoryView(activeView: $activeView)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: activeView)
        } label: {
            Label {
                Text("Pomodoro")
            } icon: {
                Image(systemName: timerVM.menuBarIcon)
            }
        }
        .menuBarExtraStyle(.window)
    }
}

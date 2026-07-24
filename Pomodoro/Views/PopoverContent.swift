import SwiftUI

struct PopoverContent: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var activeView: ActiveView = .timer

    var body: some View {
        Group {
            switch activeView {
            case .timer:
                TimerView(viewModel: viewModel, activeView: $activeView)
            case .settings:
                SettingsView(activeView: $activeView)
            case .history:
                SessionHistoryView(activeView: $activeView)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: activeView)
    }
}

import SwiftUI

enum ActiveView {
    case timer
    case settings
    case history
}

struct TimerView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Binding var activeView: ActiveView

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 12)

            timerCircle
                .padding(.bottom, 8)

            phaseLabel
                .padding(.bottom, 14)

            controls
                .padding(.bottom, 10)

            pomodoroDots
                .padding(.bottom, 16)

            Spacer(minLength: 0)

            bottomBar
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
        }
        .frame(width: 280, height: 350)
    }

    private var header: some View {
        HStack {
            Text("Pomodoro")
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            Button {
                activeView = .settings
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .pointingHand()
        }
    }

    private var timerCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)

            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    viewModel.phaseColor,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.progress)

            VStack(spacing: 4) {
                Text(viewModel.formattedTime)
                    .font(.system(size: 40, weight: .light, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: 160, height: 160)
        .contentShape(Circle())
        .onTapGesture {
            viewModel.toggle()
        }
        .pointingHand()
    }

    private var phaseLabel: some View {
        Text(viewModel.phase.displayName)
            .font(.subheadline)
            .foregroundStyle(viewModel.phaseColor)
            .fontWeight(.medium)
    }

    private var controls: some View {
        HStack(spacing: 20) {
            Button {
                viewModel.reset()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.phase == .idle)
            .foregroundStyle(viewModel.phase == .idle ? .gray : .primary)
            .pointingHand()

            Button {
                viewModel.toggle()
            } label: {
                Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
            }
            .buttonStyle(.plain)
            .foregroundStyle(viewModel.phaseColor)
            .pointingHand()

            Button {
                viewModel.skip()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.phase == .idle)
            .foregroundStyle(viewModel.phase == .idle ? .gray : .primary)
            .pointingHand()
        }
    }

    private var pomodoroDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<Defaults.pomodorosBeforeLongBreak, id: \.self) { index in
                Circle()
                    .fill(index < (viewModel.pomodoroCount % Defaults.pomodorosBeforeLongBreak)
                          ? viewModel.phaseColor
                          : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.top, 4)
    }

    private var bottomBar: some View {
        HStack {
            Button {
                activeView = .history
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 11))
                    Text("\(Defaults.completedPomodorosToday) today")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .pointingHand()

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .pointingHand()
        }
    }
}

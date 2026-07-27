import SwiftUI

struct SettingsView: View {
    @AppStorage("workDuration") private var workDuration = 25
    @AppStorage("shortBreakDuration") private var shortBreakDuration = 5
    @AppStorage("longBreakDuration") private var longBreakDuration = 15
    @AppStorage("pomodorosBeforeLongBreak") private var pomodorosBeforeLongBreak = 4
    @AppStorage("autoStart") private var autoStart = true

    @Binding var activeView: ActiveView

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 14) {
                durationRow(label: "Focus", value: $workDuration, color: .red)
                durationRow(label: "Short Break", value: $shortBreakDuration, color: .green)
                durationRow(label: "Long Break", value: $longBreakDuration, color: .blue)
            }
            .padding(.horizontal, 20)

            Divider()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 10) {
                Stepper(
                    "Sessions before long break: \(pomodorosBeforeLongBreak)",
                    value: $pomodorosBeforeLongBreak,
                    in: 2...8
                )
                .font(.subheadline)

                Toggle("Auto-start next session", isOn: $autoStart)
                    .font(.subheadline)
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .frame(width: 280, height: 350)
    }

    private var header: some View {
        HStack {
            Button {
                activeView = .timer
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .pointingHand()

            Text("Settings")
                .font(.headline)

            Spacer()
        }
    }

    private func durationRow(label: String, value: Binding<Int>, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
            Spacer()
            Stepper(
                value: value,
                in: 1...60
            ) {
                Text("\(value.wrappedValue) min")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }
}

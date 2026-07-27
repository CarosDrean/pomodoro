import SwiftUI
import AVFoundation

struct SettingsView: View {
    @AppStorage("workDuration") private var workDuration = 25
    @AppStorage("shortBreakDuration") private var shortBreakDuration = 5
    @AppStorage("longBreakDuration") private var longBreakDuration = 15
    @AppStorage("pomodorosBeforeLongBreak") private var pomodorosBeforeLongBreak = 4
    @AppStorage("autoStart") private var autoStart = true
    @AppStorage("alertSound") private var alertSound = "default"
    @AppStorage("intrusiveBreaks") private var intrusiveBreaks = true

    @Binding var activeView: ActiveView
    @State private var showResetConfirm = false

    private let soundOptions = [
        ("default", "Default (Beep)"),
        ("Glass", "Glass"),
        ("Ping", "Ping"),
        ("Pop", "Pop"),
        ("Purr", "Purr"),
        ("Sosumi", "Sosumi"),
        ("Submarine", "Submarine")
    ]

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

                Toggle("Intrusive break mode", isOn: $intrusiveBreaks)
                    .font(.subheadline)
                    .onChange(of: intrusiveBreaks) { _, newValue in
                        Defaults.intrusiveBreaks = newValue
                    }

                HStack {
                    Text("Alert sound")
                        .font(.subheadline)
                    Spacer()
                    Picker("", selection: $alertSound) {
                        ForEach(soundOptions, id: \.0) { key, label in
                            Text(label).tag(key)
                        }
                    }
                    .frame(width: 130)
                    .labelsHidden()
                    .onChange(of: alertSound) { _, newValue in
                        Defaults.alertSound = newValue
                        SoundManager.shared.playPreview(named: newValue)
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button {
                    showResetConfirm = true
                } label: {
                    Text("Reset to Defaults")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .pointingHand()
                .alert("Reset all settings?", isPresented: $showResetConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) {
                        workDuration = 25
                        shortBreakDuration = 5
                        longBreakDuration = 15
                        pomodorosBeforeLongBreak = 4
                        autoStart = true
                        alertSound = "default"
                        Defaults.alertSound = "default"
                        intrusiveBreaks = true
                        Defaults.intrusiveBreaks = true
                    }
                } message: {
                    Text("This will restore all durations and options to their original values.")
                }
                .padding(.trailing, 20)
                .padding(.bottom, 14)
            }
        }
        .frame(width: 280, height: 350)
    }

    private var header: some View {
        HStack {
            Button {
                activeView = .timer
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Timer")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
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

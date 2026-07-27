import SwiftUI

struct SessionHistoryView: View {
    @Binding var activeView: ActiveView

    private var todayRecords: [SessionRecord] {
        Defaults.sessionRecords.filter {
            Calendar.current.isDateInToday($0.date)
        }
    }

    private var workSessions: [SessionRecord] {
        todayRecords.filter { $0.phase == .work }
    }

    private var completedPomodoros: Int { workSessions.count }
    private var targetPerCycle: Int { Defaults.pomodorosBeforeLongBreak }
    private var completedCycles: Int { completedPomodoros / targetPerCycle }
    private var pomodorosInCurrentCycle: Int { completedPomodoros % targetPerCycle }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

            HStack(spacing: 16) {
                statCard(
                    title: "Pomodoros",
                    value: "\(workSessions.count)",
                    icon: "brain.head.profile.fill",
                    color: .red
                )
                statCard(
                    title: "Focus Time",
                    value: totalFocusTime,
                    icon: "clock.fill",
                    color: .orange
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            if completedPomodoros > 0 {
                progressCycles
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }

            Divider()
                .padding(.horizontal, 20)

            if todayRecords.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No sessions yet today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(todayRecords.reversed()) { record in
                            sessionRow(record)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(width: 280, height: 350)
    }

    private var progressCycles: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Progress")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(0..<targetPerCycle, id: \.self) { index in
                    Circle()
                        .fill(index < pomodorosInCurrentCycle ? Color.red : Color.gray.opacity(0.2))
                        .frame(width: 14, height: 14)
                        .overlay {
                            if index < pomodorosInCurrentCycle {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .animation(.easeInOut(duration: 0.4), value: pomodorosInCurrentCycle)
                }

                if completedCycles > 0 {
                    Text("×\(completedCycles)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                        .padding(.leading, 2)
                }
            }
        }
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

            Text("Today's Sessions")
                .font(.headline)

            Spacer()
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func sessionRow(_ record: SessionRecord) -> some View {
        HStack {
            Circle()
                .fill(record.phase == .work ? .red : .green)
                .frame(width: 6, height: 6)
            Text(record.phase.displayName)
                .font(.caption)
            Spacer()
            Text(timeString(record.duration))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Text(record.date, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var totalFocusTime: String {
        let total = workSessions.reduce(0) { $0 + $1.duration }
        return timeString(total)
    }

    private func timeString(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }
}

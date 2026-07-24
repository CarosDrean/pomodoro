import Foundation

enum TimerPhase: String, Codable, CaseIterable {
    case work
    case shortBreak
    case longBreak
    case idle

    var displayName: String {
        switch self {
        case .work: "Focus"
        case .shortBreak: "Short Break"
        case .longBreak: "Long Break"
        case .idle: "Ready"
        }
    }

    var systemImage: String {
        switch self {
        case .work: "brain.head.profile"
        case .shortBreak: "cup.and.saucer.fill"
        case .longBreak: "moon.zzz.fill"
        case .idle: "timer"
        }
    }
}

struct SessionRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let phase: TimerPhase
    let duration: Int

    init(date: Date = Date(), phase: TimerPhase, duration: Int) {
        self.id = UUID()
        self.date = date
        self.phase = phase
        self.duration = duration
    }
}

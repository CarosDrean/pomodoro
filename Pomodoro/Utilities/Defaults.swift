import Foundation

enum Defaults {
    private enum Key {
        static let workDuration = "workDuration"
        static let shortBreakDuration = "shortBreakDuration"
        static let longBreakDuration = "longBreakDuration"
        static let pomodorosBeforeLongBreak = "pomodorosBeforeLongBreak"
        static let autoStart = "autoStart"
        static let completedToday = "completedPomodorosToday"
        static let lastSessionDate = "lastSessionDate"
        static let sessionRecords = "sessionRecords"
    }

    static var workDuration: Int {
        get { storedInt(Key.workDuration, fallback: 25) }
        set { UserDefaults.standard.set(newValue, forKey: Key.workDuration) }
    }

    static var shortBreakDuration: Int {
        get { storedInt(Key.shortBreakDuration, fallback: 5) }
        set { UserDefaults.standard.set(newValue, forKey: Key.shortBreakDuration) }
    }

    static var longBreakDuration: Int {
        get { storedInt(Key.longBreakDuration, fallback: 15) }
        set { UserDefaults.standard.set(newValue, forKey: Key.longBreakDuration) }
    }

    static var pomodorosBeforeLongBreak: Int {
        get { storedInt(Key.pomodorosBeforeLongBreak, fallback: 4) }
        set { UserDefaults.standard.set(newValue, forKey: Key.pomodorosBeforeLongBreak) }
    }

    static var autoStart: Bool {
        get {
            guard UserDefaults.standard.object(forKey: Key.autoStart) != nil else { return true }
            return UserDefaults.standard.bool(forKey: Key.autoStart)
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.autoStart) }
    }

    static var completedPomodorosToday: Int {
        get {
            resetIfNewDay()
            return UserDefaults.standard.integer(forKey: Key.completedToday)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.completedToday)
            UserDefaults.standard.set(Date(), forKey: Key.lastSessionDate)
        }
    }

    static var sessionRecords: [SessionRecord] {
        get {
            guard let data = UserDefaults.standard.data(forKey: Key.sessionRecords),
                  let records = try? JSONDecoder().decode([SessionRecord].self, from: data) else {
                return []
            }
            return records
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Key.sessionRecords)
            }
        }
    }

    static func addSession(_ record: SessionRecord) {
        var records = sessionRecords
        records.append(record)
        sessionRecords = records

        if record.phase == .work {
            completedPomodorosToday += 1
        }
    }

    private static func storedInt(_ key: String, fallback: Int) -> Int {
        let val = UserDefaults.standard.integer(forKey: key)
        return val == 0 ? fallback : val
    }

    private static func resetIfNewDay() {
        guard let lastDate = UserDefaults.standard.object(forKey: Key.lastSessionDate) as? Date else { return }
        if !Calendar.current.isDateInToday(lastDate) {
            UserDefaults.standard.set(0, forKey: Key.completedToday)
        }
    }
}

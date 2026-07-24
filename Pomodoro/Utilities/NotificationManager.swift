import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func sendWorkComplete() {
        send(title: "Time to take a break!", body: "Great work! Your pomodoro session is complete.")
    }

    func sendBreakComplete() {
        send(title: "Break is over!", body: "Ready to focus again? Starting next work session.")
    }
}

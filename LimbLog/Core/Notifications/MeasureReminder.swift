import Foundation
import UserNotifications

/// One local notification on the morning the next measurement is due. Rescheduled after every measurement.
enum MeasureReminder {
    static let enabledKey = "reminder.measure.enabled"
    static let identifier = "measure.due"

    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }

    static func ensurePermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied: return false
        default: return true
        }
    }

    static func reschedule(profile: LimbProfile?, measurements: [LimbMeasurement]) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard isEnabled, let profile, await ensurePermission() else { return }
        let calendar = Calendar.current
        var due = VolumeMath.nextDue(profile: profile, measurements: measurements)
        if due <= calendar.startOfDay(for: .now) { due = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? due }
        var components = calendar.dateComponents([.year, .month, .day], from: due)
        components.hour = 9
        let content = UNMutableNotificationContent()
        content.title = AppConfig.appName
        content.body = "Time to measure your \(profile.affectedLabel.lowercased()) (and the other side)."
        content.sound = .default
        try? await center.add(UNNotificationRequest(identifier: identifier, content: content,
                                                     trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

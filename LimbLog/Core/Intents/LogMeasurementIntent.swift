import AppIntents
import Foundation

/// "Log a measurement in Limb Log" opens the app on the measurement form.
struct LogMeasurementIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a Measurement"
    static var description = IntentDescription("Opens Limb Log ready to enter today's circumferences.")
    static var openAppWhenRun = true

    static let pendingKey = "intent.openMeasure"

    func perform() async throws -> some IntentResult {
        WidgetSnapshot.defaults.set(true, forKey: Self.pendingKey)
        return .result()
    }
}

struct LimbLogShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: LogMeasurementIntent(), phrases: ["Log a measurement in \(.applicationName)", "Measure in \(.applicationName)"],
                    shortTitle: "Log Measurement", systemImageName: "ruler")
    }
}

import Foundation

/// Summary the app writes to the App Group for the widget.
struct WidgetSnapshot: Codable {
    var hasProfile: Bool = false
    var limbLabel: String = ""
    var latestVolumeML: Double? = nil
    var latestDate: Date? = nil
    var changeSinceBaselineML: Double? = nil
    var percentVsOtherSide: Double? = nil
    var nextDue: Date? = nil
    var updatedAt: Date = .now

    static let storageKey = "widget.snapshot"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: AppConfig.appGroupID) ?? .standard
    }

    static func load() -> WidgetSnapshot {
        guard let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return WidgetSnapshot()
        }
        return snapshot
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.defaults.set(data, forKey: Self.storageKey)
    }

    static let placeholder = WidgetSnapshot(hasProfile: true, limbLabel: "Right arm", latestVolumeML: 2340, latestDate: .now,
                                            changeSinceBaselineML: -160, percentVsOtherSide: 11.2,
                                            nextDue: Calendar.current.date(byAdding: .day, value: 5, to: .now))
}

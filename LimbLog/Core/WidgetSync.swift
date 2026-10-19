import Foundation
import WidgetKit

enum WidgetSync {
    static func update(profile: LimbProfile?, measurements: [LimbMeasurement]) {
        var snapshot = WidgetSnapshot()
        if let profile {
            snapshot.hasProfile = true
            snapshot.limbLabel = profile.affectedLabel
            let summary = VolumeMath.summary(profile: profile, measurements: measurements, from: .distantPast)
            snapshot.latestVolumeML = summary.latestML
            snapshot.latestDate = summary.latestDate
            snapshot.changeSinceBaselineML = summary.changeML
            snapshot.percentVsOtherSide = summary.latestPercentVsOther
            snapshot.nextDue = VolumeMath.nextDue(profile: profile, measurements: measurements)
        }
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

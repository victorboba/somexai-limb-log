import Foundation

/// Circumference arithmetic used across the app. Pure, unit-tested.
enum VolumeMath {
    /// Truncated-cone (frustum) volume between consecutive tape points, summed. Circumferences in cm,
    /// distances in cm, result in mL. V = h (C1² + C1·C2 + C2²) / (12π) per segment.
    static func frustumVolume(_ series: [(distanceCm: Double, circumferenceCm: Double)]) -> Double {
        let sorted = series.sorted { $0.distanceCm < $1.distanceCm }
        guard sorted.count >= 2 else { return 0 }
        var total = 0.0
        for i in 1..<sorted.count {
            let h = sorted[i].distanceCm - sorted[i - 1].distanceCm
            let c1 = sorted[i - 1].circumferenceCm, c2 = sorted[i].circumferenceCm
            total += h * (c1 * c1 + c1 * c2 + c2 * c2) / (12 * Double.pi)
        }
        return total
    }

    /// (affected − other) / other × 100
    static func percentDifference(affected: Double, other: Double) -> Double? {
        guard other > 0 else { return nil }
        return (affected - other) / other * 100
    }

    /// For an affected-side measurement, the other-side measurement closest in time within the pair window.
    static func partner(for measurement: LimbMeasurement, in all: [LimbMeasurement], otherSide: Side, windowDays: Int = AppConfig.pairWindowDays) -> LimbMeasurement? {
        let limit = TimeInterval(windowDays * 86_400)
        return all.filter { $0.side == otherSide && $0.profileID == measurement.profileID && abs($0.date.timeIntervalSince(measurement.date)) <= limit }
            .min { abs($0.date.timeIntervalSince(measurement.date)) < abs($1.date.timeIntervalSince(measurement.date)) }
    }

    struct Summary: Equatable {
        var affectedCount = 0
        var baselineML: Double?
        var baselineDate: Date?
        var latestML: Double?
        var latestDate: Date?
        var changeML: Double?
        var changePercent: Double?
        var latestOtherML: Double?
        var latestPercentVsOther: Double?
        var baselinePercentVsOther: Double?
    }

    static func summary(profile: LimbProfile, measurements: [LimbMeasurement], from start: Date, to end: Date = .now) -> Summary {
        var s = Summary()
        let mine = measurements.filter { $0.profileID == profile.id && $0.date >= start && $0.date <= end }
        let affected = mine.filter { $0.side == profile.affectedSide }.sorted { $0.date < $1.date }
        s.affectedCount = affected.count
        guard let first = affected.first, let last = affected.last else { return s }
        s.baselineML = first.volumeML
        s.baselineDate = first.date
        s.latestML = last.volumeML
        s.latestDate = last.date
        s.changeML = last.volumeML - first.volumeML
        s.changePercent = first.volumeML > 0 ? (last.volumeML - first.volumeML) / first.volumeML * 100 : nil
        if let other = partner(for: last, in: measurements, otherSide: profile.otherSide) {
            s.latestOtherML = other.volumeML
            s.latestPercentVsOther = percentDifference(affected: last.volumeML, other: other.volumeML)
        }
        if let other = partner(for: first, in: measurements, otherSide: profile.otherSide) {
            s.baselinePercentVsOther = percentDifference(affected: first.volumeML, other: other.volumeML)
        }
        return s
    }

    /// Next measurement due: last affected-side measurement + interval, or now when none.
    static func nextDue(profile: LimbProfile, measurements: [LimbMeasurement], calendar: Calendar = .current) -> Date {
        let last = measurements.filter { $0.profileID == profile.id }.map(\.date).max()
        guard let last else { return calendar.startOfDay(for: .now) }
        return calendar.startOfDay(for: calendar.date(byAdding: .day, value: profile.measureEveryDays, to: last) ?? last)
    }
}

import Foundation
import SwiftData

#if DEBUG
/// Debug-only sample data: ten weekly measurement pairs of an affected right arm that is slowly
/// responding to therapy (from about +18% to +11% versus the left), plus symptom notes. Fictional.
enum SampleData {
    static func insert(into context: ModelContext) {
        let calendar = Calendar.current
        let existing = (try? context.fetch(FetchDescriptor<LimbProfile>()))?.first
        let profile = existing ?? LimbProfile(name: "Marta", limbType: .arm, affectedSide: .right)
        if existing == nil {
            profile.therapistName = "Riverside Lymphedema Clinic"
            profile.nextAppointment = calendar.date(byAdding: .day, value: 12, to: .now)
            context.insert(profile)
        }
        let hasData = !((try? context.fetch(FetchDescriptor<LimbMeasurement>()))?.isEmpty ?? true)
        guard !hasData else { return }

        // Left (unaffected) baseline circumferences at 0, 10, 20, 30, 40 cm.
        let left: [Double: Double] = [0: 16.0, 10: 21.5, 20: 25.0, 30: 27.0, 40: 29.0]
        for week in stride(from: 9, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -7 * week, to: calendar.startOfDay(for: .now)),
                  let time = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: day) else { continue }
            let progress = Double(9 - week) / 9.0                      // 0 at the start, 1 now
            let excess = 0.18 - 0.07 * progress                          // +18% -> +11% circumference-ish
            let l = LimbMeasurement(profile: profile, side: .left, date: time)
            l.values = left.mapValues { $0 + Double.random(in: -0.2...0.2) }
            context.insert(l)
            let r = LimbMeasurement(profile: profile, side: .right, date: time.addingTimeInterval(240))
            r.values = left.mapValues { $0 * (1 + excess * 0.55) + Double.random(in: -0.2...0.2) }
            if week == 9 { r.notes = "Baseline before starting therapy." }
            if week == 3 { r.notes = "Measured after a long flight; puffier than usual." }
            context.insert(r)

            if week % 2 == 0 {
                let s = SymptomEntry(profile: profile, date: time.addingTimeInterval(3600 * 12))
                s.heaviness = max(0, 3 - Int(progress * 3))
                s.tightness = week == 3 ? 2 : 1
                s.skinSigns = week == 3 ? [.pitting] : []
                s.therapies = [.mld, .exercise]
                s.garmentHours = 12 + Double(week % 3)
                if week == 3 { s.notes = "Sleeve felt tight after the trip; elevated in the evening." }
                context.insert(s)
            }
        }
        try? context.save()
    }
}
#endif

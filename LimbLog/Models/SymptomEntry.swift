import Foundation
import SwiftData

/// How the limb felt and what was done about it. Goes on the report next to the numbers.
@Model
final class SymptomEntry {
    var id: UUID = UUID()
    var profileID: UUID = UUID()
    var date: Date = Date()
    var heaviness: Int = 0
    var tightness: Int = 0
    var pain: Int = 0
    var skinRaw: String = ""
    var therapyRaw: String = ""
    var garmentHours: Double = 0
    var notes: String = ""
    var createdAt: Date = Date()

    init(profile: LimbProfile, date: Date = .now) {
        self.profileID = profile.id
        self.date = date
    }

    var skinSigns: [SkinSign] {
        get { skinRaw.split(separator: "|").compactMap { SkinSign(rawValue: String($0)) } }
        set { skinRaw = newValue.map(\.rawValue).joined(separator: "|") }
    }

    var therapies: [Therapy] {
        get { therapyRaw.split(separator: "|").compactMap { Therapy(rawValue: String($0)) } }
        set { therapyRaw = newValue.map(\.rawValue).joined(separator: "|") }
    }

    var summary: String {
        var parts: [String] = []
        if heaviness > 0 { parts.append("heaviness \(heaviness)/3") }
        if tightness > 0 { parts.append("tightness \(tightness)/3") }
        if pain > 0 { parts.append("pain \(pain)/3") }
        parts += skinSigns.map { $0.rawValue.lowercased() }
        return parts.isEmpty ? "No symptoms" : parts.joined(separator: ", ")
    }

    var therapySummary: String {
        var parts = therapies.map(\.rawValue)
        if garmentHours > 0 { parts.append("garment \(Formatters.hours(garmentHours))") }
        return parts.joined(separator: ", ")
    }
}

enum SkinSign: String, CaseIterable, Identifiable {
    case redness = "Redness", warmth = "Warmth", hardness = "Hardness", pitting = "Pitting", dryness = "Dryness", rash = "Rash", blister = "Blister or break"
    var id: String { rawValue }
}

enum Therapy: String, CaseIterable, Identifiable {
    case mld = "Manual drainage", bandaging = "Bandaging", pump = "Pump session", exercise = "Exercise", elevation = "Elevation", skinCare = "Skin care"
    var id: String { rawValue }
}

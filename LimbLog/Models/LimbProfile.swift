import Foundation
import SwiftData

/// Which limb is measured, which side is affected, and the tape points (distance from a landmark).
@Model
final class LimbProfile {
    var id: UUID = UUID()
    var name: String = ""
    var limbTypeRaw: String = LimbType.arm.rawValue
    var affectedSideRaw: String = Side.right.rawValue
    /// "Wrist:0|10 cm above wrist:10|…" — label:distanceCm, sorted by distance.
    var pointsRaw: String = ""
    var unitRaw: String = LengthUnit.cm.rawValue
    var therapistName: String = ""
    var nextAppointment: Date? = nil
    var measureEveryDays: Int = AppConfig.defaultMeasureEveryDays
    var notes: String = ""
    var createdAt: Date = Date()

    init(name: String = "", limbType: LimbType = .arm, affectedSide: Side = .right) {
        self.name = name
        self.limbTypeRaw = limbType.rawValue
        self.affectedSideRaw = affectedSide.rawValue
        self.points = limbType.defaultPoints
    }

    var limbType: LimbType {
        get { LimbType(rawValue: limbTypeRaw) ?? .arm }
        set { limbTypeRaw = newValue.rawValue }
    }

    var affectedSide: Side {
        get { Side(rawValue: affectedSideRaw) ?? .right }
        set { affectedSideRaw = newValue.rawValue }
    }

    var unit: LengthUnit {
        get { LengthUnit(rawValue: unitRaw) ?? .cm }
        set { unitRaw = newValue.rawValue }
    }

    var points: [MeasurePoint] {
        get {
            pointsRaw.split(separator: "|").compactMap { part in
                let bits = part.split(separator: ":", maxSplits: 1).map(String.init)
                guard bits.count == 2, let d = Double(bits[1]) else { return nil }
                return MeasurePoint(label: bits[0], distanceCm: d)
            }
            .sorted { $0.distanceCm < $1.distanceCm }
        }
        set { pointsRaw = newValue.sorted { $0.distanceCm < $1.distanceCm }.map { "\($0.label):\($0.distanceCm)" }.joined(separator: "|") }
    }

    var otherSide: Side { affectedSide == .left ? .right : .left }

    /// "Right arm"
    var affectedLabel: String { "\(affectedSide.rawValue.capitalized) \(limbType.rawValue)" }
    var title: String { name.isEmpty ? affectedLabel : "\(name) · \(affectedLabel)" }
}

struct MeasurePoint: Identifiable, Hashable, Codable {
    var id: Double { distanceCm }
    var label: String
    var distanceCm: Double
}

enum LimbType: String, CaseIterable, Identifiable {
    case arm, leg
    var id: String { rawValue }
    var name: String { rawValue.capitalized }
    var landmark: String { self == .arm ? "wrist (ulnar styloid)" : "ankle (medial malleolus)" }
    var defaultPoints: [MeasurePoint] {
        switch self {
        case .arm: [MeasurePoint(label: "Wrist", distanceCm: 0), MeasurePoint(label: "10 cm above wrist", distanceCm: 10),
                    MeasurePoint(label: "20 cm above wrist", distanceCm: 20), MeasurePoint(label: "30 cm above wrist", distanceCm: 30),
                    MeasurePoint(label: "40 cm above wrist", distanceCm: 40)]
        case .leg: [MeasurePoint(label: "Ankle", distanceCm: 0), MeasurePoint(label: "10 cm above ankle", distanceCm: 10),
                    MeasurePoint(label: "20 cm above ankle", distanceCm: 20), MeasurePoint(label: "30 cm above ankle", distanceCm: 30),
                    MeasurePoint(label: "40 cm above ankle", distanceCm: 40), MeasurePoint(label: "50 cm above ankle", distanceCm: 50)]
        }
    }
}

enum Side: String, CaseIterable, Identifiable {
    case left, right
    var id: String { rawValue }
    var name: String { rawValue.capitalized }
}

enum LengthUnit: String, CaseIterable, Identifiable {
    case cm, inch = "in"
    var id: String { rawValue }
    var name: String { self == .cm ? "Centimeters" : "Inches" }
    func display(cm: Double) -> Double { self == .cm ? cm : cm / 2.54 }
    func toCm(_ value: Double) -> Double { self == .cm ? value : value * 2.54 }
}

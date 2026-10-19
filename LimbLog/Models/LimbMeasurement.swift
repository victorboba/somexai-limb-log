import Foundation
import SwiftData

/// One tape session on one side: a circumference (cm) for each point of the profile.
@Model
final class LimbMeasurement {
    var id: UUID = UUID()
    var profileID: UUID = UUID()
    var date: Date = Date()
    var sideRaw: String = Side.right.rawValue
    /// "0:16.5|10:22.0|…" — distanceCm:circumferenceCm
    var valuesRaw: String = ""
    var notes: String = ""
    @Attribute(.externalStorage) var photo: Data? = nil
    var createdAt: Date = Date()

    init(profile: LimbProfile, side: Side, date: Date = .now) {
        self.profileID = profile.id
        self.sideRaw = side.rawValue
        self.date = date
    }

    var side: Side {
        get { Side(rawValue: sideRaw) ?? .right }
        set { sideRaw = newValue.rawValue }
    }

    /// distanceCm -> circumferenceCm
    var values: [Double: Double] {
        get {
            var dict: [Double: Double] = [:]
            for part in valuesRaw.split(separator: "|") {
                let bits = part.split(separator: ":").map(String.init)
                if bits.count == 2, let d = Double(bits[0]), let c = Double(bits[1]) { dict[d] = c }
            }
            return dict
        }
        set { valuesRaw = newValue.keys.sorted().map { "\($0):\(newValue[$0]!)" }.joined(separator: "|") }
    }

    /// Ordered (distance, circumference) pairs for the points that have a value.
    var series: [(distanceCm: Double, circumferenceCm: Double)] {
        values.keys.sorted().map { ($0, values[$0]!) }
    }

    var volumeML: Double { VolumeMath.frustumVolume(series) }
}

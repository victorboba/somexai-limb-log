import Foundation

enum Formatters {
    static let fileStamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmm"
        return f
    }()

    static let dateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static let date: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let short: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    /// "2,340 mL"
    static func volume(_ ml: Double) -> String {
        let n = NumberFormatter()
        n.numberStyle = .decimal
        n.maximumFractionDigits = 0
        return "\(n.string(from: NSNumber(value: ml.rounded())) ?? "\(Int(ml))") mL"
    }

    /// "+160 mL" / "−90 mL"
    static func volumeDelta(_ ml: Double) -> String {
        let sign = ml > 0 ? "+" : ml < 0 ? "−" : ""
        return sign + volume(abs(ml))
    }

    /// "+12.4%"
    static func percent(_ p: Double) -> String {
        let sign = p > 0 ? "+" : p < 0 ? "−" : ""
        return String(format: "%@%.1f%%", sign, abs(p))
    }

    /// "24.5 cm" / "9.6 in"
    static func length(_ cm: Double, unit: LengthUnit) -> String {
        String(format: "%.1f %@", unit.display(cm: cm), unit.rawValue)
    }

    static func hours(_ hours: Double) -> String {
        hours == hours.rounded() ? "\(Int(hours)) hr" : String(format: "%.1f hr", hours)
    }
}

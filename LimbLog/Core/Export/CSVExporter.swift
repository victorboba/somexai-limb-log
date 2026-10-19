import Foundation

enum CSVExporter {
    static func measurementsCSV(_ measurements: [LimbMeasurement], profile: LimbProfile) -> String {
        let iso = ISO8601DateFormatter()
        let points = profile.points
        var lines = [(["date", "side"] + points.map { "\($0.label) (cm)" } + ["volume_ml", "notes"]).map(quote).joined(separator: ",")]
        for m in measurements.filter({ $0.profileID == profile.id }).sorted(by: { $0.date < $1.date }) {
            let values = m.values
            let row = [iso.string(from: m.date), m.side.rawValue]
                + points.map { values[$0.distanceCm].map { String(format: "%.1f", $0) } ?? "" }
                + [String(Int(m.volumeML.rounded())), m.notes]
            lines.append(row.map(quote).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func symptomsCSV(_ entries: [SymptomEntry]) -> String {
        let iso = ISO8601DateFormatter()
        var lines = ["date,heaviness,tightness,pain,skin,therapy,garment_hours,notes"]
        for e in entries.sorted(by: { $0.date < $1.date }) {
            lines.append([iso.string(from: e.date), "\(e.heaviness)", "\(e.tightness)", "\(e.pain)",
                          e.skinSigns.map(\.rawValue).joined(separator: "; "), e.therapies.map(\.rawValue).joined(separator: "; "),
                          String(format: "%.1f", e.garmentHours), e.notes].map(quote).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func write(_ csv: String, suffix: String) throws -> URL {
        let url = ExportFile.temporaryURL(suffix: suffix, extension: "csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func quote(_ field: String) -> String {
        "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

struct ExportFile: Identifiable {
    let url: URL
    var id: String { url.path }

    static func temporaryURL(suffix: String, extension ext: String) -> URL {
        let stamp = Formatters.fileStamp.string(from: .now)
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("\(AppConfig.exportFileStem)-\(suffix)-\(stamp)")
            .appendingPathExtension(ext)
    }
}

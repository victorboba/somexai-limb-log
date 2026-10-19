import SwiftUI
import UIKit

/// The therapist report: prescription-free facts. Baseline, latest, change, side-to-side, the chart, every tape reading, symptoms.
@MainActor
enum ReportExporter {
    static func export(profile: LimbProfile, measurements: [LimbMeasurement], symptoms: [SymptomEntry], from start: Date, to end: Date = .now) throws -> URL {
        let mine = measurements.filter { $0.profileID == profile.id && $0.date >= start && $0.date <= end }.sorted { $0.date < $1.date }
        let summary = VolumeMath.summary(profile: profile, measurements: measurements, from: start, to: end)
        let entries = symptoms.filter { $0.profileID == profile.id && $0.date >= start && $0.date <= end }.sorted { $0.date < $1.date }
        let points = profile.points
        let unit = profile.unit

        let renderer = ImageRenderer(content: VolumeChart(measurements: mine, profile: profile).frame(width: 720, height: 260).padding(8).background(Color.white))
        renderer.scale = 2
        let chartImage = renderer.uiImage

        let footer = "\(AppConfig.appName) · patient-entered measurements · truncated-cone volume estimate · not a diagnosis"
        return try PDFCanvas.render(footer: footer) { pdf in
            pdf.title("Limb measurement report")
            pdf.subtitle("\(profile.title) · \(Formatters.date.string(from: start)) to \(Formatters.date.string(from: end)) · generated \(Formatters.dateTime.string(from: .now))")

            pdf.heading("Setup")
            var pairs: [(String, String)] = [
                ("Patient", profile.name.isEmpty ? "—" : profile.name),
                ("Limb", "\(profile.limbType.name), affected side \(profile.affectedSide.name.lowercased())"),
                ("Landmark", profile.limbType.landmark),
                ("Tape points", points.map { "\($0.label) (\(Int($0.distanceCm)) cm)" }.joined(separator: ", ")),
                ("Units", unit.name),
            ]
            if !profile.therapistName.isEmpty { pairs.append(("Therapist / clinic", profile.therapistName)) }
            if let next = profile.nextAppointment { pairs.append(("Next appointment", Formatters.date.string(from: next))) }
            pdf.keyValues(pairs)

            pdf.heading("Summary (\(profile.affectedLabel.lowercased()))")
            var rows: [(String, String)] = [("Measurements in period", "\(summary.affectedCount)")]
            if let b = summary.baselineML, let bd = summary.baselineDate { rows.append(("Baseline volume", "\(Formatters.volume(b)) on \(Formatters.date.string(from: bd))")) }
            if let l = summary.latestML, let ld = summary.latestDate { rows.append(("Latest volume", "\(Formatters.volume(l)) on \(Formatters.date.string(from: ld))")) }
            if let c = summary.changeML, let p = summary.changePercent { rows.append(("Change over period", "\(Formatters.volumeDelta(c)) (\(Formatters.percent(p)))")) }
            if let p = summary.latestPercentVsOther { rows.append(("Latest vs other side", Formatters.percent(p))) }
            if let p = summary.baselinePercentVsOther { rows.append(("Baseline vs other side", Formatters.percent(p))) }
            pdf.keyValues(rows)

            if let chartImage {
                pdf.spacer(6)
                pdf.image(chartImage, caption: "Estimated volume per measurement, both sides.", maxHeight: 190)
            }

            pdf.heading("Measurements")
            let pointWidth = 0.55 / Double(max(points.count, 1))
            pdf.table(
                headers: ["Date", "Side"] + points.map { "\(Int($0.distanceCm)) cm" } + ["Volume"],
                widths: [0.18, 0.09] + points.map { _ in CGFloat(pointWidth) } + [0.18],
                rows: mine.map { m in
                    let v = m.values
                    return [Formatters.date.string(from: m.date), m.side.name] + points.map { v[$0.distanceCm].map { String(format: "%.1f", unit.display(cm: $0)) } ?? "—" } + [Formatters.volume(m.volumeML)]
                }
            )
            let noted = mine.filter { !$0.notes.isEmpty }
            if !noted.isEmpty {
                pdf.spacer(4)
                pdf.paragraph("Notes: " + noted.map { "\(Formatters.date.string(from: $0.date)) (\($0.side.name.lowercased())): \($0.notes)" }.joined(separator: " · "), color: .darkGray)
            }

            pdf.heading("Symptoms and therapy")
            pdf.table(headers: ["Date", "Symptoms", "Therapy", "Notes"], widths: [0.16, 0.34, 0.26, 0.24],
                      rows: entries.map { [Formatters.date.string(from: $0.date), $0.summary, $0.therapySummary, $0.notes] })

            for m in mine where m.photo != nil {
                if let data = m.photo, let image = UIImage(data: data) {
                    pdf.image(image, caption: "\(Formatters.date.string(from: m.date)) · \(m.side.name)")
                }
            }

            pdf.spacer(10)
            pdf.paragraph(AppConfig.disclaimer, color: .darkGray)
        }
    }
}

import SwiftUI
import SwiftData

struct ReportView: View {
    @Query(sort: \LimbProfile.createdAt) private var profiles: [LimbProfile]
    @Query(sort: \LimbMeasurement.date, order: .reverse) private var measurements: [LimbMeasurement]
    @Query(sort: \SymptomEntry.date, order: .reverse) private var symptoms: [SymptomEntry]

    @State private var period: Period = .days90
    @State private var exportFile: ExportFile?
    @State private var exportError: String?

    enum Period: String, CaseIterable, Identifiable {
        case days30 = "30 days", days90 = "90 days", year = "12 months", all = "All"
        var id: String { rawValue }
        var start: Date {
            let today = Calendar.current.startOfDay(for: .now)
            switch self {
            case .days30: return Calendar.current.date(byAdding: .day, value: -29, to: today) ?? today
            case .days90: return Calendar.current.date(byAdding: .day, value: -89, to: today) ?? today
            case .year: return Calendar.current.date(byAdding: .day, value: -364, to: today) ?? today
            case .all: return .distantPast
            }
        }
    }

    private var profile: LimbProfile? { profiles.first }
    private var summary: VolumeMath.Summary? { profile.map { VolumeMath.summary(profile: $0, measurements: measurements, from: period.start) } }

    var body: some View {
        NavigationStack {
            Group {
                if let profile, let summary {
                    List {
                        Section {
                            Picker("Period", selection: $period) { ForEach(Period.allCases) { Text($0.rawValue).tag($0) } }
                                .pickerStyle(.segmented).listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                        }
                        Section("\(profile.affectedLabel) · \(summary.affectedCount) measurement\(summary.affectedCount == 1 ? "" : "s")") {
                            if let b = summary.baselineML, let bd = summary.baselineDate { LabeledContent("Baseline", value: "\(Formatters.volume(b)) · \(Formatters.short.string(from: bd))") }
                            if let l = summary.latestML, let ld = summary.latestDate { LabeledContent("Latest", value: "\(Formatters.volume(l)) · \(Formatters.short.string(from: ld))") }
                            if let c = summary.changeML, let p = summary.changePercent { LabeledContent("Change", value: "\(Formatters.volumeDelta(c)) (\(Formatters.percent(p)))").foregroundStyle(c > 0 ? .orange : .primary) }
                            if let p = summary.latestPercentVsOther { LabeledContent("Latest vs other side", value: Formatters.percent(p)).foregroundStyle(p > 10 ? .orange : .primary) }
                            if let p = summary.baselinePercentVsOther { LabeledContent("Baseline vs other side", value: Formatters.percent(p)) }
                            if summary.affectedCount == 0 { Text("No measurements in this period.").foregroundStyle(.secondary) }
                        }
                        Section("Export") {
                            Button { export { try ReportExporter.export(profile: profile, measurements: measurements, symptoms: symptoms, from: period.start) } } label: {
                                Label("PDF report for the therapist", systemImage: "doc.richtext")
                            }
                            Button { export { try CSVExporter.write(CSVExporter.measurementsCSV(measurements.filter { $0.date >= period.start }, profile: profile), suffix: "measurements") } } label: {
                                Label("Measurements CSV", systemImage: "tablecells")
                            }
                            Button { export { try CSVExporter.write(CSVExporter.symptomsCSV(symptoms.filter { $0.profileID == profile.id && $0.date >= period.start }), suffix: "symptoms") } } label: {
                                Label("Symptoms CSV", systemImage: "tablecells")
                            }
                        }
                        Section { Text(AppConfig.disclaimer).font(.footnote).foregroundStyle(.secondary) }
                    }
                } else {
                    ContentUnavailableView("No limb set up yet", systemImage: "doc.text", description: Text("Set it up on Home to start a report."))
                }
            }
            .navigationTitle("Report")
            .sheet(item: $exportFile) { ShareSheet(url: $0.url) }
            .alert("Export failed", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
                Button("OK") { exportError = nil }
            } message: { Text(exportError ?? "") }
        }
    }

    private func export(_ make: () throws -> URL) {
        do { exportFile = ExportFile(url: try make()) } catch { exportError = error.localizedDescription }
    }
}

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LimbProfile.createdAt) private var profiles: [LimbProfile]
    @Query(sort: \LimbMeasurement.date, order: .reverse) private var measurements: [LimbMeasurement]
    @Query(sort: \SymptomEntry.date, order: .reverse) private var symptoms: [SymptomEntry]

    @State private var editingMeasurement: LimbMeasurement?
    @State private var editingSymptom: SymptomEntry?
    @State private var section: Section = .measurements

    enum Section: String, CaseIterable, Identifiable {
        case measurements = "Measurements", symptoms = "Symptoms"
        var id: String { rawValue }
    }

    private var profile: LimbProfile? { profiles.first }
    private var mine: [LimbMeasurement] { measurements.filter { $0.profileID == profile?.id } }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    List {
                        SwiftUI.Section("Estimated volume") {
                            if mine.count >= 2 {
                                VolumeChart(measurements: mine, profile: profile)
                                    .frame(height: 220)
                                    .listRowInsets(EdgeInsets(top: 12, leading: 8, bottom: 8, trailing: 16))
                            } else {
                                Text("The chart appears after two measurements.").foregroundStyle(.secondary)
                            }
                        }
                        SwiftUI.Section {
                            Picker("Section", selection: $section) { ForEach(Section.allCases) { Text($0.rawValue).tag($0) } }
                                .pickerStyle(.segmented).listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                        }
                        if section == .measurements {
                            SwiftUI.Section {
                                ForEach(mine) { m in
                                    Button { editingMeasurement = m } label: { MeasurementRow(measurement: m, profile: profile, partner: VolumeMath.partner(for: m, in: measurements, otherSide: m.side == profile.affectedSide ? profile.otherSide : profile.affectedSide)) }
                                        .buttonStyle(.plain)
                                }
                                .onDelete { offsets in offsets.map { mine[$0] }.forEach(context.delete) }
                            }
                        } else {
                            SwiftUI.Section {
                                let entries = symptoms.filter { $0.profileID == profile.id }
                                ForEach(entries) { e in
                                    Button { editingSymptom = e } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(Formatters.date.string(from: e.date)).font(.subheadline.weight(.semibold))
                                            Text(e.summary).font(.subheadline)
                                            if !e.therapySummary.isEmpty { Text(e.therapySummary).font(.caption).foregroundStyle(.secondary) }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { offsets in offsets.map { entries[$0] }.forEach(context.delete) }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("No limb set up yet", systemImage: "chart.xyaxis.line", description: Text("Set it up on Home to start the history."))
                }
            }
            .navigationTitle("History")
            .sheet(item: $editingMeasurement) { m in if let profile { MeasurementEditorView(profile: profile, side: m.side, existing: m) } }
            .sheet(item: $editingSymptom) { e in if let profile { SymptomEditorView(profile: profile, existing: e) } }
        }
    }
}

struct MeasurementRow: View {
    let measurement: LimbMeasurement
    let profile: LimbProfile
    let partner: LimbMeasurement?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: measurement.side == profile.affectedSide ? "circle.fill" : "circle")
                .foregroundStyle(measurement.side == profile.affectedSide ? Color.accentColor : Color.secondary).font(.caption)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Formatters.date.string(from: measurement.date)) · \(measurement.side.name)\(measurement.side == profile.affectedSide ? " (affected)" : "")")
                    .font(.subheadline.weight(.semibold))
                Text(measurement.series.map { String(format: "%.1f", profile.unit.display(cm: $0.circumferenceCm)) }.joined(separator: " · ") + " \(profile.unit.rawValue)")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                if !measurement.notes.isEmpty { Text(measurement.notes).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.volume(measurement.volumeML)).monospacedDigit()
                if measurement.side == profile.affectedSide, let partner, let p = VolumeMath.percentDifference(affected: measurement.volumeML, other: partner.volumeML) {
                    Text(Formatters.percent(p)).font(.caption).foregroundStyle(p > 10 ? .orange : .secondary).monospacedDigit()
                }
            }
        }
        .contentShape(Rectangle())
    }
}

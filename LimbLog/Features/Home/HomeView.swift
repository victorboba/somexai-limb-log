import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \LimbProfile.createdAt) private var profiles: [LimbProfile]
    @Query(sort: \LimbMeasurement.date, order: .reverse) private var measurements: [LimbMeasurement]
    @Query(sort: \SymptomEntry.date, order: .reverse) private var symptoms: [SymptomEntry]

    @State private var measuring: Side?
    @State private var showingSymptoms = false
    @State private var showingProfile = false
    @State private var showingSettings = false

    private var profile: LimbProfile? { profiles.first }
    private var summary: VolumeMath.Summary? { profile.map { VolumeMath.summary(profile: $0, measurements: measurements, from: .distantPast) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile, let summary {
                    VStack(spacing: 16) {
                        latestCard(profile, summary)
                        HStack(spacing: 12) {
                            Button { measuring = profile.affectedSide } label: { Label("Measure now", systemImage: "ruler").frame(maxWidth: .infinity).padding(.vertical, 6) }
                                .buttonStyle(.borderedProminent).controlSize(.large)
                            Button { showingSymptoms = true } label: { Label("Log symptoms", systemImage: "bandage").frame(maxWidth: .infinity).padding(.vertical, 6) }
                                .buttonStyle(.bordered).controlSize(.large)
                        }
                        dueCard(profile)
                        if let last = symptoms.first(where: { $0.profileID == profile.id }) {
                            card("Last symptoms · \(Formatters.date.string(from: last.date))") {
                                Text(last.summary).font(.subheadline)
                                if !last.therapySummary.isEmpty { Text(last.therapySummary).font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                        Text(AppConfig.disclaimer).font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                } else {
                    ContentUnavailableView {
                        Label("Set up the limb", systemImage: "ruler")
                    } description: {
                        Text("Choose arm or leg, the affected side, and the tape points your therapist uses.")
                    } actions: {
                        Button("Set Up") { showingProfile = true }.buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 60)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button { showingSettings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings")
                    NavigationLink { HowToView() } label: { Image(systemName: "questionmark.circle") }.accessibilityLabel("How do I use this app")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let profile {
                        Menu {
                            Button("Measure \(profile.affectedSide.name.lowercased()) (affected)", systemImage: "ruler") { measuring = profile.affectedSide }
                            Button("Measure \(profile.otherSide.name.lowercased())", systemImage: "ruler") { measuring = profile.otherSide }
                            Button("Log symptoms", systemImage: "bandage") { showingSymptoms = true }
                            Button("Edit limb setup", systemImage: "pencil") { showingProfile = true }
                        } label: { Image(systemName: "plus") }
                        .accessibilityLabel("More")
                    }
                }
            }
            .sheet(item: $measuring) { side in if let profile { MeasurementEditorView(profile: profile, side: side, existing: nil) } }
            .sheet(isPresented: $showingSymptoms) { if let profile { SymptomEditorView(profile: profile, existing: nil) } }
            .sheet(isPresented: $showingProfile) { ProfileEditorView(profile: profile) }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-sampleData"), profiles.isEmpty { SampleData.insert(into: context) }
            #endif
        }
        .onChange(of: measurements.count, initial: true) { sync() }
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active, let profile else { return }
            if WidgetSnapshot.defaults.bool(forKey: LogMeasurementIntent.pendingKey) {
                WidgetSnapshot.defaults.removeObject(forKey: LogMeasurementIntent.pendingKey)
                measuring = profile.affectedSide
            }
        }
    }

    private func sync() {
        WidgetSync.update(profile: profile, measurements: measurements)
        let p = profile, m = measurements
        Task { await MeasureReminder.reschedule(profile: p, measurements: m) }
    }

    private func latestCard(_ profile: LimbProfile, _ summary: VolumeMath.Summary) -> some View {
        card(profile.title) {
            if let latest = summary.latestML, let date = summary.latestDate {
                HStack(alignment: .firstTextBaseline) {
                    Text(Formatters.volume(latest)).font(.system(size: 36, weight: .bold, design: .rounded)).monospacedDigit()
                    Text("estimated volume").font(.caption).foregroundStyle(.secondary)
                }
                Text("Measured \(Formatters.date.string(from: date))").font(.caption).foregroundStyle(.secondary)
                Divider()
                HStack(spacing: 20) {
                    stat("vs other side", summary.latestPercentVsOther.map(Formatters.percent) ?? "—", warn: (summary.latestPercentVsOther ?? 0) > 10)
                    stat("since baseline", summary.changeML.map(Formatters.volumeDelta) ?? "—", warn: (summary.changeML ?? 0) > 0)
                    if let bp = summary.baselinePercentVsOther { stat("baseline vs other", Formatters.percent(bp), warn: false) }
                }
            } else {
                Text("No measurements yet. Tap Measure now and enter each circumference.").font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private func dueCard(_ profile: LimbProfile) -> some View {
        let due = VolumeMath.nextDue(profile: profile, measurements: measurements)
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: due).day ?? 0
        return card("Schedule") {
            LabeledContent("Next measurement", value: days <= 0 ? "Due now" : days == 1 ? "Tomorrow" : "In \(days) days")
            LabeledContent("Every", value: "\(profile.measureEveryDays) days")
            if let next = profile.nextAppointment {
                let d = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: next)).day ?? 0
                LabeledContent("Appointment", value: d < 0 ? "Was \(Formatters.date.string(from: next))" : d == 0 ? "Today" : "In \(d) days")
            }
        }
    }

    private func stat(_ label: String, _ value: String, warn: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.headline).monospacedDigit().foregroundStyle(warn ? Color.orange : Color.primary)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}


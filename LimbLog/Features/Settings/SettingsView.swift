import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Query(sort: \LimbProfile.createdAt) private var profiles: [LimbProfile]
    @Query private var measurements: [LimbMeasurement]

    @AppStorage(MeasureReminder.enabledKey) private var reminderEnabled = false
    @State private var confirmingDeleteAll = false
    @State private var editingProfile = false
    #if DEBUG
    @State private var sampleDataImported = false
    @AppStorage(DebugFlags.unlockKey) private var debugUnlock = false
    @AppStorage("onboarding.completed") private var onboardingCompleted = true
    #endif

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Limb setup") {
                    if let profile = profiles.first {
                        Button { editingProfile = true } label: {
                            VStack(alignment: .leading) {
                                Text(profile.title).foregroundStyle(.primary)
                                Text("\(profile.points.count) tape points · \(profile.unit.name.lowercased()) · every \(profile.measureEveryDays) days").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("Not set up yet. Start on Home.").foregroundStyle(.secondary)
                    }
                }

                Section {
                    Toggle("Remind me when a measurement is due", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) {
                            let p = profiles.first, m = measurements
                            Task { await MeasureReminder.reschedule(profile: p, measurements: m) }
                        }
                } header: { Text("Reminders") } footer: { Text("One notification at 9 am on the due day, based on your measuring interval.") }

                Section("Help") {
                    NavigationLink { HowToView() } label: { Label("How do I use \(AppConfig.appName)?", systemImage: "questionmark.circle") }
                }

                Section("Your plan") {
                    LabeledContent("Status", value: planDescription)
                    if store.isEntitled && !store.isLifetime {
                        Button("Manage Subscription") { openURL(URL(string: "https://apps.apple.com/account/subscriptions")!) }
                    }
                    Button("Restore Purchases") { Task { await store.restore() } }
                    if let error = store.lastError { Text(error).font(.footnote).foregroundStyle(.red) }
                }

                Section("Your data") {
                    Text("Everything you record stays on this device\(AppConfig.iCloudSyncEnabled ? " and in your private iCloud" : ""). Nothing is sent to us.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Delete All Data", role: .destructive) { confirmingDeleteAll = true }
                }

                Section("About") {
                    Text(AppConfig.disclaimer).font(.footnote).foregroundStyle(.secondary)
                    if !AppConfig.appStoreID.isEmpty {
                        Button("Rate \(AppConfig.appName)") { openURL(URL(string: "https://apps.apple.com/app/id\(AppConfig.appStoreID)?action=write-review")!) }
                    }
                    Button("Contact Support") {
                        let subject = "\(AppConfig.appName) \(version)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        openURL(URL(string: "mailto:\(AppConfig.supportEmail)?subject=\(subject)")!)
                    }
                    NavigationLink("Privacy Policy") { PrivacyPolicyView() }
                    Link("Terms of Use", destination: AppConfig.termsURL)
                    LabeledContent("Version", value: version)
                }

                #if DEBUG
                Section("Debug (not in release builds)") {
                    Toggle("Unlock without purchase", isOn: $debugUnlock)
                        .onChange(of: debugUnlock) { Task { await store.refreshEntitlements() } }
                    Button("Show onboarding again") { onboardingCompleted = false; dismiss() }
                    Button(sampleDataImported ? "Imported ✓" : "Insert sample data (10 weeks)") {
                        SampleData.insert(into: context)
                        sampleDataImported = true
                        Task { try? await Task.sleep(for: .seconds(2)); sampleDataImported = false }
                    }
                    .disabled(sampleDataImported)
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $editingProfile) { ProfileEditorView(profile: profiles.first) }
            .confirmationDialog("Delete the limb setup, every measurement and every symptom entry on this device?", isPresented: $confirmingDeleteAll, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    try? context.delete(model: LimbMeasurement.self)
                    try? context.delete(model: SymptomEntry.self)
                    try? context.delete(model: LimbProfile.self)
                    MeasureReminder.cancel()
                    WidgetSync.update(profile: nil, measurements: [])
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This cannot be undone. Export a report first if you want a copy.") }
        }
    }

    private var planDescription: String {
        guard store.isEntitled else { return "Not active" }
        if store.isLifetime { return "Lifetime" }
        if let expiry = store.expiresAt { return "Annual, renews \(expiry.formatted(date: .abbreviated, time: .omitted))" }
        return "Active"
    }
}

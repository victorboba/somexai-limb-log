import SwiftUI
import SwiftData

@main
struct LimbLog: App {
    @State private var entitlements = EntitlementStore()
    private let container: ModelContainer

    init() {
        let schema = Schema([LimbProfile.self, LimbMeasurement.self, SymptomEntry.self])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: AppConfig.iCloudSyncEnabled ? .automatic : .none)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetData") {
            let context = container.mainContext
            try? context.delete(model: LimbMeasurement.self)
            try? context.delete(model: SymptomEntry.self)
            try? context.delete(model: LimbProfile.self)
            try? context.save()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(entitlements)
        }
        .modelContainer(container)
    }
}

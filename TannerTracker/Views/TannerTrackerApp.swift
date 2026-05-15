//
//  TannerTrackerApp.swift
//  TannerTracker
//

import SwiftUI
import SwiftData

@main
struct TannerTrackerApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Exercise.self, WorkoutEntry.self])
        container = Self.makeContainer(schema: schema)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(AppSettings.shared)
                .preferredColorScheme(.dark)
        }
    }

    private static func makeContainer(schema: Schema) -> ModelContainer {
        let cloudConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
            return container
        }
        // Schema mismatch or corrupt store — wipe and retry with CloudKit.
        wipeDefaultStore()
        if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
            return container
        }
        // CloudKit unavailable (simulator, no iCloud account, etc.) — fall back to local store.
        let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private static func wipeDefaultStore() {
        let base = URL.applicationSupportDirectory
        for name in ["default.store", "default.store-shm", "default.store-wal"] {
            try? FileManager.default.removeItem(at: base.appending(path: name))
        }
    }
}

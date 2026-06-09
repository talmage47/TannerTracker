//
//  PratosApp.swift
//  Pratos
//

import SwiftUI
import SwiftData

@main
struct PratosApp: App {
    let container: ModelContainer
    let iCloudAvailable: Bool
    @State private var showCloudKitAlert: Bool

    init() {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let (c, available) = Self.makeContainer(schema: schema)
        container = c
        iCloudAvailable = available
        _showCloudKitAlert = State(initialValue: !available)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(AppSettings.shared)
                .preferredColorScheme(.dark)
                .alert("iCloud Unavailable", isPresented: $showCloudKitAlert) {
                    Button("OK") {}
                } message: {
                    Text("Your workouts are being saved locally only. Sign in to iCloud in Settings to sync your data and prevent data loss if the app is reinstalled.")
                }
        }
    }

    // Returns (container, iCloudAvailable). CloudKit and local stores use separate files
    // so they can never conflict. Local data is preserved across kill/restart regardless
    // of CloudKit availability.
    private static func makeContainer(schema: Schema) -> (ModelContainer, Bool) {
        let base = URL.applicationSupportDirectory
        // CloudKit uses the default store path — specifying a custom URL breaks it on some
        // SwiftData versions. Local fallback uses a different path to avoid conflicts.
        let cloudConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.undonecone.pratos"))
        let localConfig = ModelConfiguration(
            schema: schema,
            url: base.appending(path: "local.store"),
            cloudKitDatabase: .none
        )

        // 1. Happy path — CloudKit available.
        if let container = try? ModelContainer(for: schema, migrationPlan: PratosMigrationPlan.self, configurations: [cloudConfig]) {
            return (container, true)
        }

        // 2. CloudKit unavailable — fall back to the separate local store file.
        //    No conflict possible since they're different paths.
        if let container = try? ModelContainer(for: schema, migrationPlan: PratosMigrationPlan.self, configurations: [localConfig]) {
            return (container, false)
        }

        // 3. Local store corrupt/incompatible — wipe only the local store and retry.
        wipeStore(at: base.appending(path: "local.store"))
        do {
            return (try ModelContainer(for: schema, migrationPlan: PratosMigrationPlan.self, configurations: [localConfig]), false)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private static func wipeStore(at url: URL) {
        let path = url.path
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(atPath: path + suffix)
        }
    }
}

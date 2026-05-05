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
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(AppSettings.shared)
                .preferredColorScheme(.dark)
        }
    }
}

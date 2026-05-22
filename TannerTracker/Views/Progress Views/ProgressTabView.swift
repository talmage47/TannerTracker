//
//  ProgressTabView.swift
//  TannerTracker
//

import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Environment(AppSettings.self) var settings

    @State private var showSettings = false
    @State private var navExercise: Exercise? = nil

    var body: some View {
        NavigationStack {
            ExerciseList(onRowTap: { navExercise = $0 }, showChevron: true)
                .navigationTitle("Progress")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(item: $navExercise) {
                    ExerciseProgressView(exercise: $0)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(settings.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    ProgressTabView()
        .environment(AppSettings.shared)
}

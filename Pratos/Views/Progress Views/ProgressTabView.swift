//
//  ProgressTabView.swift
//  Pratos
//

import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Environment(AppSettings.self) var settings

    @State private var showSettings = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ExerciseList(onRowTap: { path.append($0) }, showChevron: true)
                .navigationTitle("Progress")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(for: Exercise.self) { exercise in
                    ExerciseProgressView(exercise: exercise)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(settings.accentColor)
                                .padding(6)
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

//
//  ExerciseSelectorView.swift
//  TannerTracker
//

import SwiftUI
import SwiftData

struct ExerciseSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) var settings

    @Binding var selectedExercise: Exercise?

    var body: some View {
        NavigationStack {
            ExerciseList(selectedExercise: $selectedExercise, onRowTap: { _ in dismiss() })
                .navigationTitle("Select Exercise")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") { dismiss() }
                            .tint(.gray)
                    }
                }
        }
        .presentationDragIndicator(.visible)
    }
}

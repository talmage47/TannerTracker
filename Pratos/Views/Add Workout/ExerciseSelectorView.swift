//
//  ExerciseSelectorView.swift
//  Pratos
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
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Select Exercise")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
        }
        .presentationDragIndicator(.visible)
    }
}

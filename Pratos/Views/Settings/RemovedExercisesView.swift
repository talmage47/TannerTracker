//
//  RemovedExercisesView.swift
//  Pratos
//

import SwiftUI
import SwiftData

struct RemovedExercisesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) var settings
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<Exercise> { $0.isRemoved == true }, sort: \Exercise.name)
    private var removedExercises: [Exercise]

    @State private var editingExercise: Exercise? = nil
    @State private var showActionAlert = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1A1A1A").ignoresSafeArea()

                if removedExercises.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trash.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray.opacity(0.3))
                        Text("No removed exercises")
                            .foregroundStyle(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 1)

                            ForEach(removedExercises) { exercise in
                                HStack {
                                    Text(exercise.name)
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white)
                                    Spacer()
                                }
                                .padding(.leading, 20)
                                .padding(.trailing, 16)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                                .exerciseRowGestures(
                                    onTap: {
                                        editingExercise = exercise
                                        showActionAlert = true
                                    },
                                    onLongPress: {
                                        editingExercise = exercise
                                        showActionAlert = true
                                    }
                                )

                                Rectangle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 1)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Removed Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(settings.accentColor)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .alert(editingExercise?.name ?? "", isPresented: $showActionAlert) {
            Button("Recover Exercise") {
                editingExercise?.isRemoved = false
                editingExercise = nil
            }
            Button("Delete Exercise", role: .destructive) {
                showDeleteConfirmation = true
            }
            Button("Cancel", role: .cancel) {
                editingExercise = nil
            }
        }
        .alert("Delete Exercise", isPresented: $showDeleteConfirmation) {
            Button("Delete Permanently", role: .destructive) {
                if let exercise = editingExercise {
                    modelContext.delete(exercise)
                }
                editingExercise = nil
            }
            Button("Cancel", role: .cancel) {
                editingExercise = nil
            }
        } message: {
            Text("Deleting \"\(editingExercise?.name ?? "")\" will permanently remove it and all of its workout history. This cannot be undone.")
        }
    }
}

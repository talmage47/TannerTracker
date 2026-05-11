//
//  ExerciseSelectorView.swift
//  TannerTracker
//

import SwiftUI
import SwiftData

struct ExerciseSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) var settings

    let exercises: [Exercise]
    @Binding var selectedName: String

    @State private var searchText = ""
    @State private var showNewExercisePopup = false
    @State private var newExerciseName = ""
    @FocusState private var nameFieldFocused: Bool

    private var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var hasExactMatch: Bool {
        exercises.contains { $0.name.localizedCaseInsensitiveCompare(searchText) == .orderedSame }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1A1A1A").ignoresSafeArea()

                List {
                    ForEach(filteredExercises) { exercise in
                        Button {
                            selectedName = exercise.name
                            dismiss()
                        } label: {
                            HStack {
                                Text(exercise.name)
                                    .foregroundStyle(.white)
                                Spacer()
                                if selectedName == exercise.name {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(settings.accentColor)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .listRowBackground(Color(hex: "#242424"))
                        .listRowSeparatorTint(Color.white.opacity(0.08))
                    }

                    if !searchText.isEmpty && !hasExactMatch {
                        Button {
                            addExercise(name: searchText)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(settings.accentColor)
                                Text("Add \"\(searchText)\"")
                                    .foregroundStyle(settings.accentColor)
                            }
                        }
                        .listRowBackground(Color(hex: "#242424"))
                        .listRowSeparatorTint(Color.white.opacity(0.08))
                    } else if searchText.isEmpty {
                        Button {
                            showNewExercisePopup = true
                            nameFieldFocused = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(settings.accentColor)
                                Text("Create New Exercise")
                                    .foregroundStyle(settings.accentColor)
                            }
                        }
                        .listRowBackground(Color(hex: "#242424"))
                        .listRowSeparatorTint(Color.white.opacity(0.08))
                    }
                }
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")

                if showNewExercisePopup {
                    newExerciseOverlay
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.gray)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var newExerciseOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { dismissPopup() }

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .font(.title2)
                        .foregroundStyle(settings.accentColor)

                    Text("New Exercise")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }

                TextField("Exercise name", text: $newExerciseName)
                    .textFieldStyle(.plain)
                    .focused($nameFieldFocused)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                    .submitLabel(.done)
                    .onSubmit {
                        if !newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty {
                            createExercise()
                        }
                    }

                HStack(spacing: 12) {
                    Button("Cancel") { dismissPopup() }
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button("Create") { createExercise() }
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.gray.opacity(0.3) : settings.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .disabled(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(24)
            .glassEffect(in: RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 28)
        }
    }

    private func addExercise(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let exercise = Exercise(name: trimmed)
        modelContext.insert(exercise)
        selectedName = trimmed
        dismiss()
    }

    private func dismissPopup() {
        nameFieldFocused = false
        showNewExercisePopup = false
        newExerciseName = ""
    }

    private func createExercise() {
        let trimmed = newExerciseName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let exercise = Exercise(name: trimmed)
        modelContext.insert(exercise)
        selectedName = trimmed
        dismissPopup()
        dismiss()
    }
}

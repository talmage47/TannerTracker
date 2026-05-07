//
//  AddWorkoutView.swift
//  TannerTracker
//

import SwiftUI
import SwiftData

struct AddWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) var settings
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    var editingEntry: WorkoutEntry?
    var date: Date

    @State private var selectedExerciseName: String
    @State private var weight: Int
    @State private var reps: Int
    @State private var sets: Int
    @State private var showExerciseSelector = false

    init(editingEntry: WorkoutEntry? = nil, date: Date = Date()) {
        self.editingEntry = editingEntry
        self.date = date
        _selectedExerciseName = State(initialValue: editingEntry?.exerciseName ?? "")
        _weight = State(initialValue: editingEntry?.weight ?? 0)
        _reps = State(initialValue: editingEntry?.reps ?? 10)
        _sets = State(initialValue: editingEntry?.sets ?? 3)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1A1A1A").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        exerciseSelector
                        weightPicker
                        repsSetsPicker
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle(editingEntry == nil ? "Add Workout" : "Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showExerciseSelector) {
            ExerciseSelectorView(exercises: exercises, selectedName: $selectedExerciseName)
        }
    }

    private var exerciseSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Exercise")

            Button {
                showExerciseSelector = true
            } label: {
                HStack {
                    Text(selectedExerciseName.isEmpty ? "Select Exercise" : selectedExerciseName)
                        .foregroundStyle(selectedExerciseName.isEmpty ? Color.gray : Color.white)
                        .font(.body)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(hex: "#242424"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(settings.accentColor.opacity(0.4), lineWidth: 1)
                )
            }
        }
    }

    private var weightPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Weight (\(settings.unitLabel))")

            HStack(spacing: 0) {
                Spacer()

                Picker("Weight", selection: $weight) {
                    ForEach(0...999, id: \.self) { val in
                        Text("\(val)").tag(val)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 120, height: 160)

                Text(settings.unitLabel)
                    .font(.body)
                    .foregroundStyle(.gray)
                    .frame(width: 44, alignment: .leading)

                Spacer()
            }
            .background(Color(hex: "#242424"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(settings.accentColor.opacity(0.4), lineWidth: 1)
            )
        }
    }

    private var repsSetsPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Reps & Sets")

            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text("Reps:")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                        .frame(minWidth: 44, alignment: .trailing)

                    Picker("Reps", selection: $reps) {
                        ForEach(1...50, id: \.self) { val in
                            Text("\(val)").tag(val)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 72, height: 130)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, 16)

                HStack(spacing: 8) {
                    Text("Sets:")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                        .frame(minWidth: 44, alignment: .trailing)

                    Picker("Sets", selection: $sets) {
                        ForEach(1...20, id: \.self) { val in
                            Text("\(val)").tag(val)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 72, height: 130)
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color(hex: "#242424"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(settings.accentColor.opacity(0.4), lineWidth: 1)
            )
        }
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text(editingEntry == nil ? "Save Workout" : "Update Workout")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedExerciseName.isEmpty ? Color.gray.opacity(0.3) : settings.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(selectedExerciseName.isEmpty)
    }

    private func save() {
        if let entry = editingEntry {
            entry.exerciseName = selectedExerciseName
            entry.weight = weight
            entry.reps = reps
            entry.sets = sets
        } else {
            let entry = WorkoutEntry(
                exerciseName: selectedExerciseName,
                weight: weight,
                reps: reps,
                sets: sets,
                date: date
            )
            modelContext.insert(entry)
        }
        dismiss()
    }
}

#Preview {
    AddWorkoutView()
        .environment(AppSettings.shared)
}

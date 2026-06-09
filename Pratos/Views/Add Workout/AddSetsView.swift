//
//  AddSetsView.swift
//  Pratos
//

import SwiftUI
import SwiftData

struct AddSetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) var settings
    var editingEntry: ExerciseSet?
    var date: Date

    @Query(sort: \ExerciseSet.performedAt, order: .reverse) private var allEntries: [ExerciseSet]

    @State private var selectedExercise: Exercise?
    @State private var weight: Double
    @State private var reps: Int
    @State private var sets: Int
    @State private var showExerciseSelector = false
    @State private var defaultsApplied = false

    private var lastEntryForDate: ExerciseSet? {
        allEntries.first { Calendar.current.isDate($0.performedAt, inSameDayAs: date) }
    }

    private static let weightValuesLbs: [Double] = {
        var values: [Double] = [0]
        values += stride(from: 2.5, through: 20, by: 2.5).map { $0 }
        values += stride(from: 25, through: 1000, by: 5).map { $0 }
        return values
    }()

    private static let weightValuesKg: [Double] = {
        var values: [Double] = [0]
        values += stride(from: 1, through: 20, by: 1).map { $0 }
        values += stride(from: 22.5, through: 500, by: 2.5).map { $0 }
        return values
    }()

    private var pickerWeightValues: [Double] {
        settings.isMetric ? Self.weightValuesKg : Self.weightValuesLbs
    }

    private static func nearestPickerValue(_ value: Double, isMetric: Bool) -> Double {
        let values = isMetric ? weightValuesKg : weightValuesLbs
        return values.min(by: { abs($0 - value) < abs($1 - value) }) ?? value
    }

    init(editingEntry: ExerciseSet? = nil, date: Date = Date()) {
        self.editingEntry = editingEntry
        self.date = date
        _selectedExercise = State(initialValue: editingEntry.flatMap { $0.exercise })
        let s = AppSettings.shared
        let displayVal = s.displayWeight(editingEntry?.weight ?? 0)
        _weight = State(initialValue: Self.nearestPickerValue(displayVal, isMetric: s.isMetric))
        _reps = State(initialValue: editingEntry?.reps ?? 10)
        _sets = State(initialValue: 3)
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(editingEntry == nil ? "Add Sets" : "Edit Sets")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            guard !defaultsApplied, editingEntry == nil else {
                defaultsApplied = true
                return
            }
            defaultsApplied = true
            if let last = lastEntryForDate {
                selectedExercise = last.exercise
                let displayVal = settings.displayWeight(last.weight)
                weight = Self.nearestPickerValue(displayVal, isMetric: settings.isMetric)
                reps = last.reps
            }
        }
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showExerciseSelector) {
            ExerciseSelectorView(selectedExercise: $selectedExercise)
        }
    }

    private var exerciseSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Exercise")

            Button {
                showExerciseSelector = true
            } label: {
                HStack {
                    Text(selectedExercise?.name ?? "Select Exercise")
                        .foregroundStyle(selectedExercise == nil ? Color.gray : Color.white)
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
                    ForEach(pickerWeightValues, id: \.self) { val in
                        Text(formatWeight(val)).tag(val)
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
        HStack(spacing: 16) {
            if editingEntry != nil {
                Button {
                    deleteEntry()
                } label: {
                    Text("Delete")
                        .font(.headline)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                }
                .glassEffect(in: Capsule())
                .buttonStyle(.plain)
            }

            Button {
                save()
            } label: {
                Text("Save")
                    .font(.headline)
                    .foregroundStyle(selectedExercise == nil ? .gray : settings.accentColor)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
            }
            .glassEffect(in: Capsule())
            .buttonStyle(.plain)
            .disabled(selectedExercise == nil)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func deleteEntry() {
        if let entry = editingEntry {
            modelContext.delete(entry)
        }
        dismiss()
    }

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }

    private func save() {
        let storageWeight = settings.toStorageLbs(weight)
        if let entry = editingEntry {
            // Editing one specific set — the sets picker is ignored in edit mode.
            entry.exercise = selectedExercise
            entry.weight = storageWeight
            entry.reps = reps
            entry.updatedAt = Date()
        } else {
            // Insert one ExerciseSet per set the user dialed in.
            for _ in 0..<sets {
                let entry = ExerciseSet(
                    exercise: selectedExercise,
                    weight: storageWeight,
                    reps: reps,
                    performedAt: date
                )
                modelContext.insert(entry)
            }
        }
        dismiss()
    }
}

#Preview {
    AddSetsView()
        .environment(AppSettings.shared)
}

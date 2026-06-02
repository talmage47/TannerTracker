//
//  SettingsView.swift
//  TannerTracker
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) var settings

    @State private var accentColor: Color = AppSettings.shared.accentColor
    @State private var showExerciseList = false
    @State private var showRemovedExercises = false


    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            ZStack {
                Color(hex: "#1A1A1A").ignoresSafeArea()

                List {
                    // Units
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Unit System")
                                .font(.subheadline)
                                .foregroundStyle(.gray)

                            Picker("Unit System", selection: $settings.unitSystem) {
                                Text("Imperial (lbs)").tag("imperial")
                                Text("Metric (kg)").tag("metric")
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color(hex: "#242424"))
                    } header: {
                        Text("Units")
                            .foregroundStyle(.gray)
                    }

                    // Accent Color
                    Section {
                        HStack {
                            Text("Accent Color")
                                .foregroundStyle(.white)
                            Spacer()
                            ColorPicker("", selection: $accentColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: accentColor) { _, newColor in
                                    settings.accentColor = newColor
                                }
                        }
                        .listRowBackground(Color(hex: "#242424"))

                        HStack {
                            Text("Preview")
                                .foregroundStyle(.gray)
                            Spacer()
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(settings.accentColor)
                                    .frame(width: 22, height: 22)

                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(settings.accentColor, lineWidth: 1.5)
                                    .frame(width: 60, height: 22)
                            }
                        }
                        .listRowBackground(Color(hex: "#242424"))
                    } header: {
                        Text("Appearance")
                            .foregroundStyle(.gray)
                    }

                    // Exercises
                    Section {
                        Button {
                            showExerciseList = true
                        } label: {
                            HStack {
                                Text("Exercise List")
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.gray)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ListRowButtonStyle())
                        .listRowBackground(Color(hex: "#242424"))

                        Button {
                            showRemovedExercises = true
                        } label: {
                            HStack {
                                Text("Removed Exercises")
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.gray)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ListRowButtonStyle())
                        .listRowBackground(Color(hex: "#242424"))
                    } header: {
                        Text("Exercises")
                            .foregroundStyle(.gray)
                    }

                    #if DEBUG
                    Section {
                        Button {
                            loadSampleData()
                        } label: {
                            HStack {
                                Text("Load Sample Data")
                                    .foregroundStyle(.orange)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ListRowButtonStyle())
                        .listRowBackground(Color(hex: "#242424"))

                        Button {
                            wipeAllData()
                        } label: {
                            HStack {
                                Text("Wipe All Data")
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ListRowButtonStyle())
                        .listRowBackground(Color(hex: "#242424"))
                    } header: {
                        Text("Developer")
                            .foregroundStyle(.gray)
                    }
                    #endif
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(settings.accentColor)
                }
            }
            .onAppear {
                accentColor = settings.accentColor
            }
        }
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showExerciseList) {
            ExerciseSettingsList()
        }
        .sheet(isPresented: $showRemovedExercises) {
            RemovedExercisesView()
        }
    }

    #if DEBUG
    private func loadSampleData() {
        let existing = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        let existingNames = Set(existing.map { $0.name })

        let calendar = Calendar.current
        let today = Date()

        // Disable autosave so all inserts land in a single transaction,
        // triggering one UI refresh instead of one per exercise.
        modelContext.autosaveEnabled = false
        defer {
            try? modelContext.save()
            modelContext.autosaveEnabled = true
        }

        // name, starting weight, lbs gained per week, rep rotation, sets
        typealias ExSpec = (name: String, start: Double, gain: Double, repCycle: [Int], sets: Int)
        let specs: [ExSpec] = [
            ("Bench Press",    95,  1.00, [5, 8, 10, 12],  3),
            ("Squat",          135, 1.50, [5, 6, 8, 10],   3),
            ("Deadlift",       185, 2.00, [3, 5, 6, 8],    3),
            ("Overhead Press", 65,  0.75, [6, 8, 10, 12],  3),
            ("Barbell Row",    95,  1.00, [6, 8, 10, 12],  3),
            ("Incline Bench",  75,  0.75, [8, 10, 12, 15], 3),
            ("Romanian DL",    135, 1.25, [6, 8, 10, 12],  3),
            ("Leg Press",      225, 2.50, [8, 10, 12, 15], 4),
        ]

        // Small repeating variation so the line isn't perfectly straight
        let wave: [Double] = [0, 2.5, 5, 2.5, 0, -2.5, 0, 2.5, 5, 0]
        let totalWeeks = 104  // ~2 years

        // Weight multipliers keyed by rep count — heavier weight for lower reps
        func weightForReps(_ base: Double, reps: Int) -> Double {
            let multipliers: [Int: Double] = [3: 1.20, 5: 1.10, 6: 1.05, 8: 1.00,
                                               10: 0.92, 12: 0.85, 15: 0.78]
            return base * (multipliers[reps] ?? 1.0)
        }

        for spec in specs {
            guard !existingNames.contains(spec.name) else { continue }
            let exercise = Exercise(name: spec.name)
            modelContext.insert(exercise)

            // 0...totalWeeks so week == totalWeeks produces weeksAgo == 0 (today)
            for week in 0...totalWeeks {
                // Skip one week in every five to simulate missed workouts
                guard week % 5 != 2 else { continue }

                let weeksAgo = totalWeeks - week
                guard let date = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: today) else { continue }

                let reps = spec.repCycle[week % spec.repCycle.count]
                let base = spec.start + Double(week) * spec.gain + wave[week % wave.count]
                let weight = weightForReps(base, reps: reps)
                modelContext.insert(WorkoutEntry(
                    exercise: exercise,
                    weight: max(weight, 0),
                    reps: reps,
                    sets: spec.sets,
                    date: date
                ))
            }
        }
    }

    private func wipeAllData() {
        try? modelContext.delete(model: WorkoutEntry.self)
        try? modelContext.delete(model: Exercise.self)
    }
    #endif
}


#Preview {
    SettingsView()
        .environment(AppSettings.shared)
}

//
//  SettingsView.swift
//  Pratos
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) var settings

    @State private var accentColor: Color = AppSettings.shared.accentColor
    @State private var showExerciseList = false
    @State private var showRemovedExercises = false
    @State private var showExportOptions = false
    @State private var showExporter = false
    @State private var exportFormat: ExportFormat? = nil
    @State private var exportDocument: ExportDocument? = nil
    @State private var showImporter = false
    @State private var importedCount = 0
    @State private var importError: String? = nil
    @State private var showImportResult = false


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
                        .listRowPressHighlight()

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
                        .listRowPressHighlight()
                    } header: {
                        Text("Exercises")
                            .foregroundStyle(.gray)
                    }

                    // Data
                    Section {
                        Button {
                            showExportOptions = true
                        } label: {
                            HStack {
                                Text("Export Data")
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.gray)
                            }
                            .contentShape(Rectangle())
                        }
                        .listRowPressHighlight()

                        Button {
                            showImporter = true
                        } label: {
                            HStack {
                                Text("Import Data")
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "square.and.arrow.down")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.gray)
                            }
                            .contentShape(Rectangle())
                        }
                        .listRowPressHighlight()
                    } header: {
                        Text("Data")
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
                        .listRowPressHighlight()

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
                        .listRowPressHighlight()
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
        .confirmationDialog("Export Format", isPresented: $showExportOptions) {
            Button("JSON") {
                exportFormat = .json
                exportDocument = ExportDocument(generateJSON())
                showExporter = true
            }
            Button("CSV") {
                exportFormat = .csv
                exportDocument = ExportDocument(generateCSV())
                showExporter = true
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: exportFormat?.contentType ?? .json,
            defaultFilename: exportFilename(extension: exportFormat?.fileExtension ?? "json")
        ) { _ in
            exportDocument = nil
            exportFormat = nil
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert(
            importError != nil ? "Import Failed" : "Import Complete",
            isPresented: $showImportResult
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = importError {
                Text(error)
            } else {
                Text("Successfully imported \(importedCount) \(importedCount == 1 ? "entry" : "entries").")
            }
        }
    }

    // MARK: - Export

    private func exportFilename(extension ext: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "Pratos-\(formatter.string(from: Date())).\(ext)"
    }

    private func fetchSortedEntries() -> [ExerciseSet] {
        let descriptor = FetchDescriptor<ExerciseSet>(sortBy: [SortDescriptor(\ExerciseSet.performedAt)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func generateJSON() -> String {
        let entries = fetchSortedEntries()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dicts: [[String: Any]] = entries.map { entry in
            [
                "date": dateFormatter.string(from: entry.performedAt),
                "exercise": entry.exercise?.name ?? "",
                "weight_\(settings.unitLabel)": settings.displayWeight(entry.weight),
                "reps": entry.reps
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dicts, options: .prettyPrinted) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private func generateCSV() -> String {
        let entries = fetchSortedEntries()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var lines = ["Date,Exercise,Weight (\(settings.unitLabel)),Reps"]
        for entry in entries {
            let date = dateFormatter.string(from: entry.performedAt)
            let exercise = (entry.exercise?.name ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let weight = settings.displayWeight(entry.weight)
            let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(weight))" : String(format: "%.1f", weight)
            lines.append("\(date),\"\(exercise)\",\(weightStr),\(entry.reps)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Import

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importError = error.localizedDescription
            showImportResult = true
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Permission denied for the selected file."
                showImportResult = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                let ext = url.pathExtension.lowercased()
                importedCount = ext == "csv" ? try importCSV(data) : try importJSON(data)
                importError = nil
            } catch {
                importError = error.localizedDescription
            }
            showImportResult = true
        }
    }

    // Import/export logic will be rewritten in Commit B with legacy-format detection
    // and proper per-set semantics. The current implementations below are minimal
    // stubs that compile against the new schema. Real legacy import support comes next.

    private func entryKey(name: String, dateStr: String, weightLbs: Double, reps: Int) -> String {
        "\(name)|\(dateStr)|\(String(format: "%.1f", weightLbs))|\(reps)"
    }

    private func buildExistingKeys(dateFormatter: DateFormatter) -> Set<String> {
        let entries = (try? modelContext.fetch(FetchDescriptor<ExerciseSet>())) ?? []
        return Set(entries.compactMap { entry -> String? in
            guard let name = entry.exercise?.name else { return nil }
            return entryKey(name: name, dateStr: dateFormatter.string(from: entry.performedAt), weightLbs: entry.weight, reps: entry.reps)
        })
    }

    private func importJSON(_ data: Data) throws -> Int {
        guard let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw ImportError.invalidFormat
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let existing = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        var exerciseMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.name, $0) })
        var seenKeys = buildExistingKeys(dateFormatter: dateFormatter)
        var count = 0
        for dict in array {
            guard let dateStr = dict["date"] as? String,
                  let date = dateFormatter.date(from: dateStr),
                  let exerciseName = dict["exercise"] as? String,
                  let reps = dict["reps"] as? Int else { continue }
            let weightLbs: Double
            if let w = dict["weight_lbs"] as? Double {
                weightLbs = w
            } else if let w = dict["weight_kg"] as? Double {
                weightLbs = w * 2.20462
            } else { continue }
            let key = entryKey(name: exerciseName, dateStr: dateStr, weightLbs: weightLbs, reps: reps)
            guard !seenKeys.contains(key) else { continue }
            seenKeys.insert(key)
            let exercise = exerciseMap[exerciseName] ?? {
                let ex = Exercise(name: exerciseName)
                modelContext.insert(ex)
                exerciseMap[exerciseName] = ex
                return ex
            }()
            modelContext.insert(ExerciseSet(exercise: exercise, weight: weightLbs, reps: reps, performedAt: date))
            count += 1
        }
        return count
    }

    private func importCSV(_ data: Data) throws -> Int {
        guard let content = String(data: data, encoding: .utf8) else { throw ImportError.invalidFormat }
        var lines = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return 0 }
        let header = lines.removeFirst()
        let isMetric = header.contains("(kg)")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let existing = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        var exerciseMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.name, $0) })
        var seenKeys = buildExistingKeys(dateFormatter: dateFormatter)
        var count = 0
        for line in lines {
            let fields = parseCSVLine(line)
            guard fields.count >= 4,
                  let date = dateFormatter.date(from: fields[0]),
                  let weightVal = Double(fields[2]),
                  let reps = Int(fields[3]) else { continue }
            let exerciseName = fields[1]
            let weightLbs = isMetric ? weightVal * 2.20462 : weightVal
            let key = entryKey(name: exerciseName, dateStr: fields[0], weightLbs: weightLbs, reps: reps)
            guard !seenKeys.contains(key) else { continue }
            seenKeys.insert(key)
            let exercise = exerciseMap[exerciseName] ?? {
                let ex = Exercise(name: exerciseName)
                modelContext.insert(ex)
                exerciseMap[exerciseName] = ex
                return ex
            }()
            modelContext.insert(ExerciseSet(exercise: exercise, weight: weightLbs, reps: reps, performedAt: date))
            count += 1
        }
        return count
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex
        while i < line.endIndex {
            let c = line[i]
            let next = line.index(after: i)
            if c == "\"" {
                if inQuotes && next < line.endIndex && line[next] == "\"" {
                    current.append("\"")
                    i = line.index(after: next)
                    continue
                }
                inQuotes.toggle()
            } else if c == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(c)
            }
            i = next
        }
        fields.append(current)
        return fields
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
                // Insert one ExerciseSet per set in the workout.
                for _ in 0..<spec.sets {
                    modelContext.insert(ExerciseSet(
                        exercise: exercise,
                        weight: max(weight, 0),
                        reps: reps,
                        performedAt: date
                    ))
                }
            }
        }
    }

    private func wipeAllData() {
        try? modelContext.delete(model: ExerciseSet.self)
        try? modelContext.delete(model: Exercise.self)
    }
    #endif
}


enum ImportError: LocalizedError {
    case invalidFormat
    var errorDescription: String? { "The file could not be parsed. Make sure it was exported from Pratos." }
}

enum ExportFormat {
    case json, csv
    var contentType: UTType { self == .json ? .json : .commaSeparatedText }
    var fileExtension: String { self == .json ? "json" : "csv" }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [] }
    static var writableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    let content: String

    init(_ content: String) { self.content = content }
    init(configuration: ReadConfiguration) throws { content = "" }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(content.utf8))
    }
}

#Preview {
    SettingsView()
        .environment(AppSettings.shared)
}

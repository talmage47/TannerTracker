//  ExerciseList.swift
//  TannerTracker
//

import SwiftUI
import SwiftData

struct ExerciseList: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) var settings

    @Query(filter: #Predicate<Exercise> { $0.isRemoved == false }, sort: \Exercise.name)
    private var exercises: [Exercise]

    var selectedExercise: Binding<Exercise?>? = nil
    var onRowTap: ((Exercise) -> Void)? = nil
    var showChevron: Bool = false

    @State private var searchText = ""
    @State private var showNewExercisePopup = false
    @State private var newExerciseName = ""
    @FocusState private var nameFieldFocused: Bool
    @FocusState private var searchFocused: Bool

    @State private var editingExercise: Exercise? = nil
    @State private var editingName = ""
    @State private var showEditAlert = false
    @State private var showRemoveWarning = false

    private var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var hasExactMatch: Bool { nameAlreadyExists(searchText) }

    private var canSaveEdit: Bool {
        let trimmed = editingName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != editingExercise?.name else { return false }
        return !nameAlreadyExists(trimmed)
    }

    private func nameAlreadyExists(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return exercises.contains { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
    }

    private var canCreate: Bool {
        let trimmed = newExerciseName.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !nameAlreadyExists(trimmed)
    }

    var body: some View {
        ZStack {
            Color(hex: "#1A1A1A").ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 1)

                    ForEach(filteredExercises) { exercise in
                        HStack {
                            Text(exercise.name)
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                            Spacer()
                            if showChevron {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.gray)
                                    .font(.caption.weight(.semibold))
                            } else if selectedExercise?.wrappedValue?.persistentModelID == exercise.persistentModelID {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(settings.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.leading, 20)
                        .padding(.trailing, 16)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .exerciseRowGestures(
                            onTap: {
                                guard let onRowTap else { return }
                                selectedExercise?.wrappedValue = exercise
                                onRowTap(exercise)
                            },
                            onLongPress: {
                                searchFocused = false
                                editingExercise = exercise
                                editingName = exercise.name
                                showEditAlert = true
                            }
                        )

                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)
                    }

                    if !searchText.isEmpty && !hasExactMatch {
                        Button { addExercise(name: searchText) } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(settings.accentColor)
                                Text("Add \"\(searchText)\"")
                                    .foregroundStyle(settings.accentColor)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ListRowButtonStyle())
                    } else if searchText.isEmpty {
                        Button {
                            searchFocused = false
                            showNewExercisePopup = true
                            nameFieldFocused = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(settings.accentColor)
                                Text("Create New Exercise")
                                    .foregroundStyle(settings.accentColor)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ListRowButtonStyle())
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)

            if showNewExercisePopup { newExerciseOverlay }
        }
        .safeAreaInset(edge: .bottom) { searchBar }
        .alert("Edit Exercise", isPresented: $showEditAlert) {
            TextField("Exercise name", text: $editingName)
            Button("Save") { saveEdit() }
            Button("Remove Exercise", role: .destructive) {
                dismissEditPopup()
                showRemoveWarning = true
            }
        }
        .alert("Remove Exercise", isPresented: $showRemoveWarning) {
            Button("Remove", role: .destructive) {
                editingExercise?.isRemoved = true
                dismissEditPopup()
            }
        } message: {
            Text("This exercise will be removed from the list but can be recovered in Settings.")
        }
        .tint(.blue)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 16, weight: .medium))

            TextField("Search exercises", text: $searchText)
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .glassEffect(in: Capsule())
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - New Exercise Overlay

    private var newExerciseOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { dismissNewPopup() }

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .font(.title2)
                        .foregroundStyle(settings.accentColor)

                    Text("New Exercise")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }

                VStack(spacing: 6) {
                    TextField("Exercise name", text: $newExerciseName)
                        .textFieldStyle(.plain)
                        .focused($nameFieldFocused)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                        .submitLabel(.done)
                        .onSubmit { if canCreate { createExercise() } }

                    if nameAlreadyExists(newExerciseName) {
                        Text("An exercise with this name already exists")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }

                HStack(spacing: 12) {
                    Button("Cancel") { dismissNewPopup() }
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
                        .background(canCreate ? settings.accentColor : Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .disabled(!canCreate)
                }
            }
            .padding(24)
            .glassEffect(in: RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Actions

    private func addExercise(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !nameAlreadyExists(trimmed) else { return }
        let exercise = Exercise(name: trimmed)
        modelContext.insert(exercise)
        selectedExercise?.wrappedValue = exercise
        onRowTap?(exercise)
    }

    private func dismissNewPopup() {
        nameFieldFocused = false
        showNewExercisePopup = false
        newExerciseName = ""
    }

    private func createExercise() {
        let trimmed = newExerciseName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !nameAlreadyExists(trimmed) else { return }
        let exercise = Exercise(name: trimmed)
        modelContext.insert(exercise)
        selectedExercise?.wrappedValue = exercise
        dismissNewPopup()
        onRowTap?(exercise)
    }

    private func saveEdit() {
        if canSaveEdit, let exercise = editingExercise {
            exercise.name = editingName.trimmingCharacters(in: .whitespaces)
        }
        dismissEditPopup()
    }

    private func dismissEditPopup() {
        editingExercise = nil
        editingName = ""
        showEditAlert = false
        showRemoveWarning = false
    }
}

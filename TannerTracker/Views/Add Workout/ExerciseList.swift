//
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

    @State private var editingExercise: Exercise? = nil
    @State private var editingName = ""
    @State private var showRemoveWarning = false
    @FocusState private var editFieldFocused: Bool
    @FocusState private var searchFocused: Bool

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
                    ForEach(Array(filteredExercises.enumerated()), id: \.element.id) { index, exercise in
                        if index > 0 {
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                        }

                        HStack {
                            Text(exercise.name)
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#242424"))
                        .pressHighlight()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard let onRowTap else { return }
                            selectedExercise?.wrappedValue = exercise
                            onRowTap(exercise)
                        }
                        .longPressWithScaleAndHaptic {
                            editingExercise = exercise
                            editingName = exercise.name
                        }
                    }

                    if !searchText.isEmpty && !hasExactMatch {
                        if !filteredExercises.isEmpty {
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                        }
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
                        }
                        .background(Color(hex: "#242424"))
                    } else if searchText.isEmpty {
                        if !filteredExercises.isEmpty {
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                        }
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
                        }
                        .background(Color(hex: "#242424"))
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)

            if showNewExercisePopup { newExerciseOverlay }
            if editingExercise != nil { editExerciseOverlay }
        }
        .safeAreaInset(edge: .bottom) { searchBar }
        .onChange(of: editingExercise) { _, new in
            if new != nil {
                searchFocused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    editFieldFocused = true
                }
            }
        }
        .alert("Remove Exercise", isPresented: $showRemoveWarning) {
            Button("Remove", role: .destructive) {
                editingExercise?.isRemoved = true
                dismissEditPopup()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This exercise will be removed from the list but can be recovered in Settings.")
        }
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

    // MARK: - Edit Exercise Overlay

    private var editExerciseOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { dismissEditPopup() }

            VStack(spacing: 20) {
                Text("Edit Exercise")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                TextField("Exercise name", text: $editingName)
                    .textFieldStyle(.plain)
                    .focused($editFieldFocused)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                    .submitLabel(.done)
                    .onSubmit { if canSaveEdit { saveEdit() } }

                HStack(spacing: 12) {
                    Button("Cancel") { dismissEditPopup() }
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button("Save") { saveEdit() }
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(canSaveEdit ? settings.accentColor : Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .disabled(!canSaveEdit)
                }

                Button("Remove Exercise") { showRemoveWarning = true }
                    .foregroundStyle(.red)
                    .font(.subheadline.weight(.medium))
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
        let trimmed = editingName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let exercise = editingExercise else { return }
        exercise.name = trimmed
        dismissEditPopup()
    }

    private func dismissEditPopup() {
        editFieldFocused = false
        editingExercise = nil
        editingName = ""
        showRemoveWarning = false
    }
}

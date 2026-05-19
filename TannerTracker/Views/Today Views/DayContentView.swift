//
//  DayContentView.swift
//  TannerTracker
//

import SwiftUI
import SwiftData

struct DayContentView: View {
    @Binding var selectedDate: Date
    @Binding var isEditing: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) var settings
    @Query(sort: \WorkoutEntry.date) private var allEntries: [WorkoutEntry]

    @State private var displayDate: Date
    @State private var dragOffset: CGFloat = 0
    @State private var transitionOffset: CGFloat = 0
    @State private var dragDirection: DragDirection = .undecided
    @State private var isTransitioning = false
    @State private var editingEntry: WorkoutEntry?
    @State private var expandedEntryID: WorkoutEntry.ID?

    private enum DragDirection { case undecided, horizontal, vertical }
    @State private var showAddWorkoutForDate = false

    private let screenWidth = UIScreen.main.bounds.width

    init(selectedDate: Binding<Date>, isEditing: Binding<Bool>) {
        _selectedDate = selectedDate
        _isEditing = isEditing
        _displayDate = State(initialValue: selectedDate.wrappedValue)
    }

    private var dayBefore: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: displayDate)!
    }
    private var dayAfter: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: displayDate)!
    }

    private var displayDateEntries: [WorkoutEntry] {
        entries(for: displayDate)
    }

    private func entries(for date: Date) -> [WorkoutEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private struct ExerciseGroup: Identifiable {
        let id: String
        let exercise: Exercise?
        let entries: [WorkoutEntry]
    }

    private func groupedEntries(_ entries: [WorkoutEntry]) -> [ExerciseGroup] {
        var orderKeys: [String] = []
        var groups: [String: [WorkoutEntry]] = [:]
        for entry in entries {
            let key = entry.exercise.map { String(describing: $0.persistentModelID) } ?? "__nil__"
            if groups[key] == nil {
                orderKeys.append(key)
                groups[key] = []
            }
            groups[key]!.append(entry)
        }
        return orderKeys.map { key in
            ExerciseGroup(id: key, exercise: groups[key]!.first?.exercise, entries: groups[key]!)
        }
    }

    private func completeDrag(translation: CGFloat) {
        isTransitioning = true
        let goingRight = translation > 0
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            dragOffset = goingRight ? screenWidth : -screenWidth
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let newDate = goingRight ? dayBefore : dayAfter
            isEditing = false
            displayDate = newDate
            selectedDate = newDate
            dragOffset = 0
            isTransitioning = false
        }
    }

    private func cancelDrag() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            dragOffset = 0
        }
    }

    private func animateToDate(_ target: Date) {
        let calendar = Calendar.current
        guard !calendar.isDate(target, inSameDayAs: displayDate) else { return }

        isTransitioning = true
        let goingRight = target < displayDate
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            transitionOffset = goingRight ? screenWidth : -screenWidth
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isEditing = false
            displayDate = target
            transitionOffset = goingRight ? -screenWidth : screenWidth
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    transitionOffset = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isTransitioning = false
            }
        }
    }

    private func dateLabelView(for date: Date) -> some View {
        VStack(spacing: 0) {
            Divider()
            Text(date.formatted(Date.FormatStyle().weekday(.wide)) + " - " + date.formatted(.dateTime.month(.wide).day().year()))
                .font(.subheadline)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            Divider()
        }
    }

    @ViewBuilder
    private func readOnlyPanel(for date: Date) -> some View {
        let dayEntries = entries(for: date)
        VStack(spacing: 0) {
            dateLabelView(for: date)
            if dayEntries.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(groupedEntries(dayEntries)) { group in
                            ExerciseEntryCard(
                                exercise: group.exercise,
                                entries: group.entries,
                                unitLabel: settings.unitLabel,
                                accentColor: settings.accentColor,
                                isMetric: settings.isMetric,
                                isEditing: false,
                                onTap: { _ in },
                                onDelete: { _ in },
                                expandedEntryID: .constant(nil)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                .ignoresSafeArea(.container, edges: .bottom)
                .scrollDisabled(dragDirection == .horizontal || isTransitioning)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    var body: some View {
        ZStack {
            Color(hex: "#1A1A1A").ignoresSafeArea()

            ZStack {
                readOnlyPanel(for: dayBefore)
                    .offset(x: dragOffset - screenWidth)

                VStack(spacing: 0) {
                    dateLabelView(for: displayDate)
                    if displayDateEntries.isEmpty && !isEditing {
                        emptyStateView
                    } else {
                        workoutList
                            .id(displayDate)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .offset(x: dragOffset + transitionOffset)

                readOnlyPanel(for: dayAfter)
                    .offset(x: dragOffset + screenWidth)
            }
            .clipped()
            .ignoresSafeArea(.container, edges: .bottom)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        // Let the row's swipe-right gesture handle dismissing the delete button
                        if expandedEntryID != nil && value.translation.width > 0 { return }
                        if dragDirection == .undecided {
                            dragDirection = abs(value.translation.width) > abs(value.translation.height)
                                ? .horizontal : .vertical
                        }
                        guard dragDirection == .horizontal else { return }
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        defer { dragDirection = .undecided }
                        if expandedEntryID != nil && value.translation.width > 0 { return }
                        guard dragDirection == .horizontal else { return }
                        let h = value.translation.width
                        let v = value.translation.height
                        if abs(h) > 60 && abs(h) > abs(v) {
                            completeDrag(translation: h)
                        } else {
                            cancelDrag()
                        }
                    }
            )
        }
        .onChange(of: selectedDate) { _, newDate in
            animateToDate(newDate)
        }
        .sheet(item: $editingEntry) { entry in
            AddWorkoutView(editingEntry: entry)
        }
        .sheet(isPresented: $showAddWorkoutForDate) {
            AddWorkoutView(date: displayDate)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.gray.opacity(0.25))
            Text("No workouts yet today")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var workoutList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(groupedEntries(displayDateEntries)) { group in
                    ExerciseEntryCard(
                        exercise: group.exercise,
                        entries: group.entries,
                        unitLabel: settings.unitLabel,
                        accentColor: settings.accentColor,
                        isMetric: settings.isMetric,
                        isEditing: isEditing,
                        onTap: { entry in editingEntry = entry },
                        onDelete: { entry in modelContext.delete(entry) },
                        expandedEntryID: $expandedEntryID
                    )
                }

                if isEditing {
                    Button {
                        showAddWorkoutForDate = true
                    } label: {
                        Text("add workout")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(settings.accentColor)
                    }
                    .padding(.top, 4)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 120)
            .animation(.easeInOut(duration: 0.25), value: isEditing)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .scrollDisabled(dragDirection == .horizontal || isTransitioning)
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .interacting, expandedEntryID != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    expandedEntryID = nil
                }
            }
        }
    }
}

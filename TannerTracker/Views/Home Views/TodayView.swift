//
//  TodayView.swift
//  TannerTracker
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) var settings
    @Query(sort: \WorkoutEntry.date) private var allEntries: [WorkoutEntry]

    @State private var showMonthView = false
    @State private var showSettings = false
    @State private var editingEntry: WorkoutEntry?
    @State private var selectedDate: Date = Date()
    @State private var isEditing = false
    @State private var entryToDelete: WorkoutEntry?
    @State private var showDeleteAlert = false
    @State private var showAddWorkoutForDate = false

    private var currentMonthName: String {
        Date().formatted(.dateTime.month(.wide))
    }

    private var currentWeekDates: [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate) - 1
        let sunday = calendar.date(byAdding: .day, value: -weekday, to: selectedDate)!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: sunday) }
    }

    private var weekHeader: some View {
        let calendar = Calendar.current
        let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(currentWeekDates.enumerated()), id: \.offset) { index, date in
                    let isToday = calendar.isDateInToday(date)
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let dayNum = calendar.component(.day, from: date)

                    Button {
                        selectedDate = date
                    } label: {
                        VStack(spacing: 7) {
                            Text(dayLetters[index])
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(isToday ? settings.accentColor : .gray)

                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(isToday ? settings.accentColor : .white)
                                        .frame(width: 30, height: 30)
                                }
                                Text("\(dayNum)")
                                    .font(.system(size: 15, weight: isToday ? .bold : .regular))
                                    .foregroundStyle(
                                        isSelected
                                            ? (isToday ? .white : .black)
                                            : (isToday ? settings.accentColor : .white)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(Color.gray.opacity(0.3))

            Text(selectedDate.formatted(Date.FormatStyle().weekday(.wide)) + " - " + selectedDate.formatted(.dateTime.month(.wide).day().year()))
                .font(.subheadline)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
    }

    private var selectedDateEntries: [WorkoutEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1A1A1A").ignoresSafeArea()

                if selectedDateEntries.isEmpty && !isEditing {
                    emptyStateView
                } else {
                    workoutList
                }
            }
            .safeAreaInset(edge: .top) {
                weekHeader
                    .background(Color(hex: "#1A1A1A"))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showMonthView = true
                    } label: {
                        Label(currentMonthName, systemImage: "chevron.left")
                            .foregroundStyle(settings.accentColor)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isEditing.toggle()
                        }
                    } label: {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(settings.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(settings.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showMonthView) {
            MonthView { date in
                selectedDate = date
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(item: $editingEntry) { entry in
            AddWorkoutView(editingEntry: entry)
        }
        .sheet(isPresented: $showAddWorkoutForDate) {
            AddWorkoutView(date: selectedDate)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.gray.opacity(0.25))
            Text("No workouts yet today")
                .font(.title2.bold())
                .foregroundStyle(.white)
        }
    }

    private var workoutList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(selectedDateEntries) { entry in
                    HStack(spacing: 12) {
                        if isEditing {
                            Button {
                                entryToDelete = entry
                                showDeleteAlert = true
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }

                        WorkoutEntryRow(
                            entry: entry,
                            unitLabel: settings.unitLabel,
                            accentColor: settings.accentColor
                        )
                        .onTapGesture {
                            if !isEditing { editingEntry = entry }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
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
        .alert("Delete Workout", isPresented: $showDeleteAlert, presenting: entryToDelete) { entry in
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
                entryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        } message: { entry in
            Text("Delete \(entry.exerciseName)?")
        }
    }
}

#Preview {
    TodayView()
        .environment(AppSettings.shared)
}

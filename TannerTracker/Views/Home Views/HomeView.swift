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

    private var currentMonthName: String {
        Date().formatted(.dateTime.month(.wide))
    }

    private var todayEntries: [WorkoutEntry] {
        allEntries.filter { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1A1A1A").ignoresSafeArea()

                if todayEntries.isEmpty {
                    emptyStateView
                } else {
                    workoutList
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
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
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(settings.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showMonthView) {
            MonthView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(item: $editingEntry) { entry in
            AddWorkoutView(editingEntry: entry)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.gray.opacity(0.25))
            Text("No workouts today")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Tap the + button below to log an exercise")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var workoutList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(todayEntries) { entry in
                    WorkoutEntryRow(
                        entry: entry,
                        unitLabel: settings.unitLabel,
                        accentColor: settings.accentColor
                    )
                    .onTapGesture {
                        editingEntry = entry
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
    }
}

struct WorkoutEntryRow: View {
    let entry: WorkoutEntry
    let unitLabel: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.exerciseName)
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 14) {
                    WorkoutStatBadge(value: "\(entry.weight) \(unitLabel)", icon: "scalemass.fill")
                    WorkoutStatBadge(value: "\(entry.reps) reps", icon: "repeat")
                    WorkoutStatBadge(value: "\(entry.sets) sets", icon: "square.stack.fill")
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.gray.opacity(0.5))
        }
        .padding(16)
        .background(Color(hex: "#242424"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accentColor.opacity(0.35), lineWidth: 1)
        )
    }
}

struct WorkoutStatBadge: View {
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.gray)
            Text(value)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    TodayView()
        .environment(AppSettings.shared)
}

//
//  WorkoutCalendarView.swift
//  TannerTracker
//

import SwiftUI
import SwiftData
import UIKit

struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}

struct MonthView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) var settings
    @Query(sort: \WorkoutEntry.date) private var allEntries: [WorkoutEntry]

    @State private var selectedDay: IdentifiableDate?

    private var datesWithWorkouts: Set<DateComponents> {
        Set(allEntries.map {
            Calendar.current.dateComponents([.year, .month, .day], from: $0.date)
        })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1A1A1A").ignoresSafeArea()

                UICalendarViewRepresentable(
                    datesWithWorkouts: datesWithWorkouts,
                    accentColor: settings.accentColor
                ) { date in
                    selectedDay = IdentifiableDate(date: date)
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(settings.accentColor)
                }
            }
        }
        .sheet(item: $selectedDay) { identDate in
            DayWorkoutsView(date: identDate.date)
        }
    }
}

// MARK: - UICalendarView Wrapper

struct UICalendarViewRepresentable: UIViewRepresentable {
    let datesWithWorkouts: Set<DateComponents>
    let accentColor: Color
    let onDateSelected: (Date) -> Void

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = Calendar.current
        calendarView.locale = Locale.current
        calendarView.backgroundColor = .clear
        calendarView.delegate = context.coordinator

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = selection

        return calendarView
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        context.coordinator.datesWithWorkouts = datesWithWorkouts
        context.coordinator.onDateSelected = onDateSelected
        uiView.reloadDecorations(forDateComponents: Array(datesWithWorkouts), animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(datesWithWorkouts: datesWithWorkouts, accentColor: accentColor, onDateSelected: onDateSelected)
    }

    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var datesWithWorkouts: Set<DateComponents>
        let accentColor: UIColor
        var onDateSelected: (Date) -> Void

        init(datesWithWorkouts: Set<DateComponents>, accentColor: Color, onDateSelected: @escaping (Date) -> Void) {
            self.datesWithWorkouts = datesWithWorkouts
            self.accentColor = UIColor(accentColor)
            self.onDateSelected = onDateSelected
        }

        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard hasWorkout(on: dateComponents) else { return nil }
            return .default(color: accentColor, size: .small)
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
            guard let dateComponents else { return false }
            return hasWorkout(on: dateComponents)
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents,
                  hasWorkout(on: dateComponents),
                  let date = Calendar.current.date(from: dateComponents) else { return }
            onDateSelected(date)
        }

        private func hasWorkout(on components: DateComponents) -> Bool {
            datesWithWorkouts.contains(where: {
                $0.year == components.year &&
                $0.month == components.month &&
                $0.day == components.day
            })
        }
    }
}

// MARK: - Day Workouts Sheet

struct DayWorkoutsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) var settings
    @Query(sort: \WorkoutEntry.date) private var allEntries: [WorkoutEntry]

    let date: Date

    @State private var editingEntry: WorkoutEntry?

    private var dayEntries: [WorkoutEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1A1A1A").ignoresSafeArea()

                if dayEntries.isEmpty {
                    Text("No workouts on this day")
                        .foregroundStyle(.gray)
                } else {
                    List {
                        ForEach(dayEntries) { entry in
                            WorkoutEntryRow(
                                entry: entry,
                                unitLabel: settings.unitLabel,
                                accentColor: settings.accentColor
                            )
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(settings.accentColor)
                }
            }
        }
        .sheet(item: $editingEntry) { entry in
            AddWorkoutView(editingEntry: entry)
        }
    }
}

#Preview {
    MonthView()
        .environment(AppSettings.shared)
}

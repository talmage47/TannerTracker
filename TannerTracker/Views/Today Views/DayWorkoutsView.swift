//
//  DayWorkoutsView.swift
//  TannerTracker
//

import SwiftUI
import SwiftData

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

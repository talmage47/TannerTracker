//
//  MonthView.swift
//  Pratos
//

import SwiftUI
import SwiftData

struct MonthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) var settings
    @Query(sort: \WorkoutEntry.date) private var allEntries: [WorkoutEntry]

    var initialDate: Date = Date()
    var onDateSelected: (Date) -> Void = { _ in }

    @State private var tappedDate: Date?

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
                    accentColor: settings.accentColor,
                    initialDate: initialDate
                ) { date in
                    tappedDate = date
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(settings.accentColor)
                }
            }
        }
        .onChange(of: tappedDate) { _, date in
            guard let date else { return }
            onDateSelected(date)
            dismiss()
        }
    }
}

#Preview {
    MonthView()
        .environment(AppSettings.shared)
}

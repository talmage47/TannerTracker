//
//  UICalendarViewRepresentable.swift
//  Pratos
//

import SwiftUI
import UIKit

struct UICalendarViewRepresentable: UIViewRepresentable {
    let datesWithWorkouts: Set<DateComponents>
    let accentColor: Color
    let initialDate: Date
    let onDateSelected: (Date) -> Void

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = Calendar.current
        calendarView.locale = Locale.current
        calendarView.backgroundColor = .clear
        calendarView.overrideUserInterfaceStyle = .dark
        calendarView.delegate = context.coordinator

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = selection

        calendarView.visibleDateComponents = Calendar.current.dateComponents([.year, .month], from: initialDate)

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
            return .default(color: accentColor, size: .large)
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
            return dateComponents != nil
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents,
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

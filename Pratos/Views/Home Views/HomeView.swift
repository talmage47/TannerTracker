//
//  HomeView.swift
//  Pratos
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppSettings.self) var settings

    @State private var showMonthView = false
    @State private var showSettings = false
    @State private var selectedDate: Date = Date()
    @State private var isEditing = false
    @State private var weekOffset: CGFloat = 0
    @State private var weekDragOccurred = false

    private let screenWidth = UIScreen.main.bounds.width

    private var currentMonthName: String {
        selectedDate.formatted(.dateTime.month(.wide))
    }

    private func weekDates(centeredOn date: Date) -> [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 1
        let sunday = calendar.date(byAdding: .day, value: -weekday, to: date)!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: sunday) }
    }

    private var prevWeekDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate)!
    }
    private var nextWeekDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate)!
    }

    private func completeWeekDrag(translation: CGFloat) {
        let goingRight = translation > 0
        let calendar = Calendar.current
        let newDate = calendar.date(byAdding: .weekOfYear, value: goingRight ? -1 : 1, to: selectedDate) ?? selectedDate
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            weekOffset = goingRight ? screenWidth : -screenWidth
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            selectedDate = newDate
            weekOffset = 0
        }
    }

    private func cancelWeekDrag() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            weekOffset = 0
        }
    }

    @ViewBuilder
    private func weekHeaderPanel(for baseDate: Date) -> some View {
        let calendar = Calendar.current
        let dates = weekDates(centeredOn: baseDate)
        let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]

        HStack(spacing: 0) {
            ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                let isToday = calendar.isDateInToday(date)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let dayNum = calendar.component(.day, from: date)

                Button {
                    guard !weekDragOccurred else { return }
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
        .frame(width: screenWidth)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var weekHeader: some View {
        ZStack {
            weekHeaderPanel(for: prevWeekDate)
                .offset(x: weekOffset - screenWidth)
            weekHeaderPanel(for: selectedDate)
                .offset(x: weekOffset)
            weekHeaderPanel(for: nextWeekDate)
                .offset(x: weekOffset + screenWidth)
        }
        .frame(width: screenWidth)
        .clipped()
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    weekDragOccurred = true
                    weekOffset = value.translation.width
                }
                .onEnded { value in
                    let h = value.translation.width
                    let v = value.translation.height
                    if abs(h) > 60 && abs(h) > abs(v) {
                        completeWeekDrag(translation: h)
                    } else {
                        cancelWeekDrag()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        weekDragOccurred = false
                    }
                }
        )
    }

    var body: some View {
        NavigationStack {
            DayContentView(selectedDate: $selectedDate, isEditing: $isEditing)
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
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text(currentMonthName)
                            }
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
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(settings.accentColor)
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(settings.accentColor)
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
        }
        .sheet(isPresented: $showMonthView) {
            MonthView(initialDate: selectedDate) { date in
                selectedDate = date
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    HomeView()
        .environment(AppSettings.shared)
}

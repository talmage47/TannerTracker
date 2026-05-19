//
//  ExerciseProgressView.swift
//  TannerTracker
//

import SwiftUI
import SwiftData
import Charts
import UIKit

private enum TimeRange: String, CaseIterable {
    case oneMonth    = "1M"
    case threeMonths = "3M"
    case sixMonths   = "6M"
    case ytd         = "YTD"
    case oneYear     = "1Y"
    case twoYears    = "2Y"
    case all         = "All"

    func startDate() -> Date? {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .oneMonth:    return cal.date(byAdding: .month, value: -1, to: now)
        case .threeMonths: return cal.date(byAdding: .month, value: -3, to: now)
        case .sixMonths:   return cal.date(byAdding: .month, value: -6, to: now)
        case .ytd:         return cal.date(from: cal.dateComponents([.year], from: now))
        case .oneYear:     return cal.date(byAdding: .year, value: -1, to: now)
        case .twoYears:    return cal.date(byAdding: .year, value: -2, to: now)
        case .all:         return nil
        }
    }
}

private enum ChartMode: Equatable {
    case estimatedOneRM
    case repMax(Int)

    var label: String {
        switch self {
        case .estimatedOneRM: return "Estimated 1 Rep Max"
        case .repMax(let r):  return r == 1 ? "1 Rep Max" : "\(r) Rep Max"
        }
    }
}

struct ExerciseProgressView: View {
    let exercise: Exercise
    @Environment(AppSettings.self) var settings
    @Query private var allEntries: [WorkoutEntry]

    @State private var selectedRange: TimeRange = .all
    @State private var selectedPoint: DayEpley? = nil
    @State private var isDragging = false
    @State private var chartMode: ChartMode = .estimatedOneRM

    private var exerciseEntries: [WorkoutEntry] {
        allEntries.filter { $0.exercise?.persistentModelID == exercise.persistentModelID }
    }

    private func dw(_ lbs: Double) -> Double {
        settings.isMetric ? lbs / 2.20462 : lbs
    }

    private func epleyValue(weight: Double, reps: Int) -> Double {
        weight * (1 + Double(reps) / 30.0)
    }

    struct DayEpley: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let weight: Double
        let reps: Int
    }

    private var epleyData: [DayEpley] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: exerciseEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return grouped.compactMap { day, entries in
            guard let best = entries.max(by: {
                epleyValue(weight: $0.weight, reps: $0.reps) <
                epleyValue(weight: $1.weight, reps: $1.reps)
            }) else { return nil }
            return DayEpley(
                date: day,
                value: dw(epleyValue(weight: best.weight, reps: best.reps)),
                weight: dw(best.weight),
                reps: best.reps
            )
        }
        .sorted { $0.date < $1.date }
    }

    private struct RepMax: Identifiable {
        let id = UUID()
        let reps: Int
        let maxWeight: Double
        var label: String { reps == 1 ? "1 rep" : "\(reps) reps" }
    }

    private var maxWeightByReps: [RepMax] {
        let grouped = Dictionary(grouping: exerciseEntries) { $0.reps }
        return grouped.map { reps, entries in
            RepMax(reps: reps, maxWeight: dw(entries.map(\.weight).max() ?? 0))
        }
        .sorted { $0.reps < $1.reps }
    }

    private var uniqueReps: [Int] {
        Array(Set(exerciseEntries.map(\.reps))).sorted()
    }

    private func repMaxData(for reps: Int) -> [DayEpley] {
        let calendar = Calendar.current
        let filtered = exerciseEntries.filter { $0.reps == reps }
        let grouped = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.date) }
        return grouped.compactMap { day, entries in
            guard let best = entries.max(by: { $0.weight < $1.weight }) else { return nil }
            return DayEpley(date: day, value: dw(best.weight), weight: dw(best.weight), reps: best.reps)
        }
        .sorted { $0.date < $1.date }
    }

    private var currentChartData: [DayEpley] {
        switch chartMode {
        case .estimatedOneRM:   return epleyData
        case .repMax(let reps): return repMaxData(for: reps)
        }
    }

    private var filteredCurrentChartData: [DayEpley] {
        guard let start = selectedRange.startDate() else { return currentChartData }
        return currentChartData.filter { $0.date >= start }
    }

    private var currentAllTimeHigh: Double { currentChartData.map(\.value).max() ?? 0 }
    private var currentMostRecent: Double  { currentChartData.last?.value ?? 0 }

    private func formatValue(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }

    // Rotates accent color 180° on the hue wheel
    private var complementaryColor: Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(settings.accentColor).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(fmod(h + 0.5, 1.0)), saturation: Double(s), brightness: Double(b))
    }

    private var activeColor: Color { isDragging ? complementaryColor : settings.accentColor }

    var body: some View {
        ZStack {
            Color(hex: "#1A1A1A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    epleyCard
                    maxWeightByRepsCard
                }
                .padding(16)
                .padding(.bottom, 100)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var epleyCard: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Title dropdown
            VStack(alignment: .leading, spacing: 4) {
                Menu {
                    Button("Estimated 1 Rep Max") {
                        chartMode = .estimatedOneRM
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isDragging = false
                            selectedPoint = nil
                        }
                    }
                    ForEach(uniqueReps, id: \.self) { reps in
                        Button(reps == 1 ? "1 Rep Max" : "\(reps) Rep Max") {
                            chartMode = .repMax(reps)
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isDragging = false
                                selectedPoint = nil
                            }
                        }
                    }
                } label: {
                    ZStack(alignment: .leading) {
                        // Invisible placeholder sized to the longest possible label,
                        // so the container never resizes and never clips during animation.
                        HStack(spacing: 4) {
                            Text("Estimated 1 Rep Max")
                                .font(.title3.bold())
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                        }
                        .hidden()

                        HStack(spacing: 4) {
                            Text(chartMode.label)
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.gray)
                        }
                    }
                }

                Text("(weight × (1 + reps/30))")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.gray)
                    .opacity(chartMode == .estimatedOneRM ? 1 : 0)
            }
            .padding(.bottom, 14)

            if currentChartData.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 36))
                        .foregroundStyle(.gray.opacity(0.3))
                    Text("No data yet")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {

                // Stats
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ALL-TIME HIGH")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        Text("\(formatValue(currentAllTimeHigh)) \(settings.unitLabel)")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MOST RECENT")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        Text("\(formatValue(currentMostRecent)) \(settings.unitLabel)")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 14)

                // Top divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)

                // Selector or scrub info — fixed height so the chart never shifts
                let chartData = filteredCurrentChartData.isEmpty ? currentChartData : filteredCurrentChartData
                ZStack {
                    if isDragging, let point = selectedPoint {
                        VStack(spacing: 1) {
                            Text(point.date.formatted(.dateTime.month(.wide).day().year()))
                                .font(.caption)
                                .foregroundStyle(.gray)
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(formatValue(point.value)) \(settings.unitLabel)")
                                    .font(.callout.bold())
                                    .foregroundStyle(complementaryColor)
                                if case .estimatedOneRM = chartMode {
                                    Text("(\(point.reps) reps at \(formatValue(point.weight)) \(settings.unitLabel))")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                    } else {
                        HStack(spacing: 0) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedRange = range
                                    }
                                } label: {
                                    Text(range.rawValue)
                                        .font(.subheadline.weight(selectedRange == range ? .semibold : .regular))
                                        .foregroundStyle(selectedRange == range ? .white : .gray)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background {
                                            if selectedRange == range {
                                                Capsule()
                                                    .fill(Color.white.opacity(0.15))
                                                    .padding(.horizontal, 2)
                                                    .padding(.vertical, 7)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .frame(height: 44)
                .animation(.easeInOut(duration: 0.15), value: isDragging)

                // Chart
                Chart {
                    ForEach(chartData) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Est. 1RM", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [activeColor.opacity(0.4), activeColor.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Est. 1RM", point.value)
                        )
                        .foregroundStyle(activeColor)

                        if !isDragging && (selectedRange == .oneMonth || selectedRange == .threeMonths) {
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Est. 1RM", point.value)
                            )
                            .foregroundStyle(activeColor)
                            .symbolSize(25)
                        }
                    }

                    if let point = selectedPoint {
                        RuleMark(x: .value("Selected", point.date))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1.5))

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Est. 1RM", point.value)
                        )
                        .foregroundStyle(complementaryColor)
                        .symbolSize(70)
                    }
                }
                .frame(height: 200)
                .animation(.easeInOut(duration: 0.2), value: isDragging)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let origin = geometry[proxy.plotAreaFrame].origin
                                        let x = value.location.x - origin.x
                                        guard x >= 0 else { return }
                                        if let date: Date = proxy.value(atX: x) {
                                            let nearest = chartData.min(by: {
                                                abs($0.date.timeIntervalSince(date)) <
                                                abs($1.date.timeIntervalSince(date))
                                            })
                                            if nearest?.id != selectedPoint?.id {
                                                selectedPoint = nearest
                                            }
                                            if !isDragging {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    isDragging = true
                                                }
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isDragging = false
                                            selectedPoint = nil
                                        }
                                    }
                            )
                    }
                }
                .padding(.bottom, 2)
            }
        }
        .padding(16)
        .background(Color(hex: "#242424"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var maxWeightByRepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Max Weight By Reps")
                .font(.headline)
                .foregroundStyle(.white)

            if maxWeightByReps.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 36))
                        .foregroundStyle(.gray.opacity(0.3))
                    Text("No data yet")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else {
                // Domain ordered high→low so lowest reps lands at top of the y-axis
                let yDomain = maxWeightByReps.sorted { $0.reps < $1.reps }.map(\.label)
                let xMax = (maxWeightByReps.map(\.maxWeight).max() ?? 100) * 1.25

                Chart(maxWeightByReps) { data in
                    BarMark(
                        x: .value("Max Weight", data.maxWeight),
                        y: .value("Reps", data.label)
                    )
                    .foregroundStyle(settings.accentColor)
                    .annotation(position: .trailing, alignment: .leading, spacing: 6) {
                        Text("\(formatValue(data.maxWeight)) \(settings.unitLabel)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                .chartYScale(domain: yDomain)
                .chartXScale(domain: 0...xMax)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(maxWeightByReps.count) * 44)
            }
        }
        .padding(16)
        .background(Color(hex: "#242424"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

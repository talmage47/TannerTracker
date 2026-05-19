//
//  WorkoutEntryRow.swift
//  TannerTracker
//

import SwiftUI

struct WorkoutEntryRow: View {
    let entry: WorkoutEntry
    let unitLabel: String
    let accentColor: Color
    let isMetric: Bool

    private func displayedWeight(_ lbs: Double) -> Double {
        isMetric ? lbs / 2.20462 : lbs
    }

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.exercise?.name ?? "Unknown")
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 14) {
                    WorkoutStatBadge(value: "\(formatWeight(displayedWeight(entry.weight))) \(unitLabel)", icon: "scalemass.fill")
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

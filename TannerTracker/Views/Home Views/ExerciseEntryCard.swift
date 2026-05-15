//
//  ExerciseEntryCard.swift
//  TannerTracker
//

import SwiftUI

struct ExerciseEntryCard: View {
    let exercise: Exercise?
    let entries: [WorkoutEntry]
    let unitLabel: String
    let accentColor: Color
    var isEditing: Bool
    var onTap: (WorkoutEntry) -> Void
    var onDelete: (WorkoutEntry) -> Void

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(exercise?.name ?? "Unknown")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ForEach(entries) { entry in
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.leading, 16)

                HStack(spacing: 12) {
                    if isEditing {
                        Button {
                            onDelete(entry)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    HStack(spacing: 14) {
                        WorkoutStatBadge(value: "\(formatWeight(entry.weight)) \(unitLabel)", icon: "scalemass.fill")
                        WorkoutStatBadge(value: "\(entry.reps) reps", icon: "repeat")
                        WorkoutStatBadge(value: "\(entry.sets) sets", icon: "square.stack.fill")
                    }

                    Spacer()

                    if !isEditing {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.gray.opacity(0.5))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !isEditing { onTap(entry) }
                }
            }
        }
        .background(Color(hex: "#242424"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accentColor.opacity(0.35), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.25), value: isEditing)
    }
}

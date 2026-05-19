//
//  ExerciseEntryCard.swift
//  TannerTracker
//

import SwiftUI
import SwiftData

struct ExerciseEntryCard: View {
    let exercise: Exercise?
    let entries: [WorkoutEntry]
    let unitLabel: String
    let accentColor: Color
    let isMetric: Bool
    var isEditing: Bool
    var onTap: (WorkoutEntry) -> Void
    var onDelete: (WorkoutEntry) -> Void
    @Binding var expandedEntryID: WorkoutEntry.ID?

    private func displayedWeight(_ lbs: Double) -> Double {
        isMetric ? lbs / 2.20462 : lbs
    }

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }

    private func closeExpanded() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            expandedEntryID = nil
        }
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
            .contentShape(Rectangle())
            .onTapGesture {
                if expandedEntryID != nil { closeExpanded() }
            }

            ForEach(entries) { entry in
                let isExpanded = isEditing && expandedEntryID == entry.id

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.leading, 16)

                ZStack(alignment: .trailing) {
                    if isEditing {
                        Button {
                            closeExpanded()
                            onDelete(entry)
                        } label: {
                            Text("Delete")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 80)
                                .frame(maxHeight: .infinity)
                                .background(Color.red)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        if expandedEntryID != nil {
                            closeExpanded()
                        } else if !isEditing {
                            onTap(entry)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if isEditing {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        expandedEntryID = isExpanded ? nil : entry.id
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                            }

                            HStack(spacing: 14) {
                                WorkoutStatBadge(value: "\(formatWeight(displayedWeight(entry.weight))) \(unitLabel)", icon: "scalemass.fill")
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
                        .background(Color(hex: "#242424"))
                        .contentShape(Rectangle())
                    }
                    .offset(x: isExpanded ? -80 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                guard isExpanded,
                                      value.translation.width > 20,
                                      abs(value.translation.width) > abs(value.translation.height)
                                else { return }
                                closeExpanded()
                            }
                    )
                    .buttonStyle(ListRowButtonStyle(highlighted: !isEditing))
                }
                .clipped()
            }
        }
        .background(Color(hex: "#242424"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accentColor.opacity(0.35), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.25), value: isEditing)
        .onChange(of: isEditing) { _, editing in
            if !editing { closeExpanded() }
        }
    }
}

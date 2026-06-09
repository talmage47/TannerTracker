//
//  ExerciseEntryCard.swift
//  Pratos
//

import SwiftUI
import SwiftData

// One display row in the card — a run of consecutive identical (weight, reps) sets.
// Built lazily from a flat [ExerciseSet] in the parent; not persisted.
struct SetGroup: Identifiable, Hashable {
    let id: UUID
    let exercise: Exercise?
    let weight: Double
    let reps: Int
    let sets: [ExerciseSet]
    var count: Int { sets.count }

    static func == (lhs: SetGroup, rhs: SetGroup) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// Group consecutive identical (weight, reps) ExerciseSets into SetGroups.
// Non-consecutive identical sets stay in separate groups (each "logging session" is its own row).
func groupedSets(_ entries: [ExerciseSet]) -> [SetGroup] {
    var runs: [[ExerciseSet]] = []
    for entry in entries {
        if let last = runs.last?.last,
           last.weight == entry.weight,
           last.reps == entry.reps {
            runs[runs.count - 1].append(entry)
        } else {
            runs.append([entry])
        }
    }
    return runs.compactMap { sets in
        guard let first = sets.first else { return nil }
        return SetGroup(
            id: first.id,
            exercise: first.exercise,
            weight: first.weight,
            reps: first.reps,
            sets: sets
        )
    }
}

struct ExerciseEntryCard: View {
    let exercise: Exercise?
    let entries: [ExerciseSet]
    let unitLabel: String
    let accentColor: Color
    let isMetric: Bool
    var isEditing: Bool
    var onTap: (SetGroup) -> Void
    var onDelete: (SetGroup) -> Void
    @Binding var expandedGroupID: SetGroup.ID?

    private var groups: [SetGroup] { groupedSets(entries) }

    private func displayedWeight(_ lbs: Double) -> Double {
        isMetric ? lbs / 2.20462 : lbs
    }

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }

    private func closeExpanded() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            expandedGroupID = nil
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
                if expandedGroupID != nil { closeExpanded() }
            }

            ForEach(groups) { group in
                let isExpanded = isEditing && expandedGroupID == group.id

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.leading, 16)

                ZStack(alignment: .trailing) {
                    if isEditing {
                        Button {
                            closeExpanded()
                            onDelete(group)
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
                        if expandedGroupID != nil {
                            closeExpanded()
                        } else if !isEditing {
                            onTap(group)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if isEditing {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        expandedGroupID = isExpanded ? nil : group.id
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
                                WorkoutStatBadge(value: "\(formatWeight(displayedWeight(group.weight))) \(unitLabel)", icon: "scalemass.fill")
                                WorkoutStatBadge(value: "\(group.reps) reps", icon: "repeat")
                                WorkoutStatBadge(value: "\(group.count) \(group.count == 1 ? "set" : "sets")", icon: "square.stack.fill")
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

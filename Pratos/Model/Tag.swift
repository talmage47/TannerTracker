//
//  Tag.swift
//  Pratos
//

import Foundation
import SwiftData

enum TagKind: String, CaseIterable {
    case split
    case muscleGroup
    case equipment
    case movement
}

@Model
class Tag {
    var id: UUID = UUID()
    var name: String = ""
    var kind: String? = nil
    var color: String? = nil
    var sortOrder: Int? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(inverse: \Exercise.tags)
    var exercises: [Exercise]? = nil

    @Relationship(inverse: \Workout.tags)
    var workouts: [Workout]? = nil

    var tagKind: TagKind? {
        get { kind.flatMap(TagKind.init(rawValue:)) }
        set { kind = newValue?.rawValue }
    }

    init(name: String = "", kind: TagKind? = nil, color: String? = nil, sortOrder: Int? = nil) {
        self.id = UUID()
        self.name = name
        self.kind = kind?.rawValue
        self.color = color
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Seeded once on first launch (when the Tag table is empty) so the picker isn't blank.
    // User can rename, delete, recolor, or add their own afterwards.
    static let defaults: [(name: String, kind: TagKind)] = [
        ("Push", .split), ("Pull", .split), ("Legs", .split),
        ("Upper", .split), ("Lower", .split), ("Full Body", .split),
        ("Chest", .muscleGroup), ("Back", .muscleGroup), ("Shoulders", .muscleGroup),
        ("Quads", .muscleGroup), ("Hamstrings", .muscleGroup), ("Glutes", .muscleGroup),
        ("Biceps", .muscleGroup), ("Triceps", .muscleGroup), ("Calves", .muscleGroup),
        ("Core", .muscleGroup),
        ("Barbell", .equipment), ("Dumbbell", .equipment), ("Cable", .equipment),
        ("Machine", .equipment), ("Smith Machine", .equipment), ("Bodyweight", .equipment),
        ("Kettlebell", .equipment), ("Bands", .equipment),
        ("Compound", .movement), ("Isolation", .movement),
    ]

    static func seedDefaultsIfNeeded(in context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Tag>())) ?? 0
        guard count == 0 else { return }
        for (index, entry) in defaults.enumerated() {
            context.insert(Tag(name: entry.name, kind: entry.kind, sortOrder: index))
        }
        try? context.save()
    }
}

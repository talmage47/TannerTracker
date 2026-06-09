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
}

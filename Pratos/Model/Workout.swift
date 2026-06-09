//
//  Workout.swift
//  Pratos
//

import Foundation
import SwiftData

@Model
class Workout {
    var id: UUID = UUID()
    var name: String? = nil
    var notes: String? = nil
    var startedAt: Date = Date()
    var finishedAt: Date? = nil
    var templateID: UUID? = nil
    var sortOrder: Int? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isRemoved: Bool = false

    var tags: [Tag]? = nil

    @Relationship(deleteRule: .nullify, inverse: \ExerciseSet.workout)
    var sets: [ExerciseSet]? = nil

    init(name: String? = nil, startedAt: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.startedAt = startedAt
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

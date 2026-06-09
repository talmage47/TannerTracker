//
//  ExerciseSet.swift
//  Pratos
//

import Foundation
import SwiftData

@Model
class ExerciseSet {
    var id: UUID = UUID()
    var exercise: Exercise? = nil
    var workout: Workout? = nil
    var weight: Double = 0
    var reps: Int = 0
    var performedAt: Date = Date()
    var setNumber: Int? = nil
    var notes: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        exercise: Exercise?,
        weight: Double,
        reps: Int,
        performedAt: Date = Date(),
        setNumber: Int? = nil,
        workout: Workout? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.exercise = exercise
        self.workout = workout
        self.weight = weight
        self.reps = reps
        self.performedAt = performedAt
        self.setNumber = setNumber
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

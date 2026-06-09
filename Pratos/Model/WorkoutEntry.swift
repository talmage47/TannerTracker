//
//  WorkoutEntry.swift
//  Pratos
//

import Foundation
import SwiftData

@Model
class WorkoutEntry {
    var exercise: Exercise?
    var weight: Double = 0
    var reps: Int = 0
    var sets: Int = 0
    var date: Date = Date()
    var time: Date = Date()

    init(exercise: Exercise?, weight: Double, reps: Int, sets: Int, date: Date = Date(), time: Date = Date()) {
        self.exercise = exercise
        self.weight = weight
        self.reps = reps
        self.sets = sets
        self.date = date
        self.time = time
    }
}

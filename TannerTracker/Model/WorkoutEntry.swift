//
//  WorkoutEntry.swift
//  TannerTracker
//

import Foundation
import SwiftData

@Model
class WorkoutEntry {
    var exerciseName: String = ""
    var weight: Int = 0
    var reps: Int = 0
    var sets: Int = 0
    var date: Date = Date()
    var time: Date = Date()

    init(exerciseName: String, weight: Int, reps: Int, sets: Int, date: Date = Date(), time: Date = Date()) {
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.sets = sets
        self.date = date
        self.time = time
    }
}

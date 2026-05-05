//
//  WorkoutEntry.swift
//  TannerTracker
//

import Foundation
import SwiftData

@Model
class WorkoutEntry {
    var exerciseName: String
    var weight: Int
    var reps: Int
    var sets: Int
    var date: Date
    var time: Date

    init(exerciseName: String, weight: Int, reps: Int, sets: Int, date: Date = Date(), time: Date = Date()) {
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.sets = sets
        self.date = date
        self.time = time
    }
}

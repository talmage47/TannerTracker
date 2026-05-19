//
//  Exercise.swift
//  TannerTracker
//

import Foundation
import SwiftData

@Model
class Exercise {
    var name: String = ""
    var createdAt: Date = Date()
    var isRemoved: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \WorkoutEntry.exercise)
    var entries: [WorkoutEntry]?

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}

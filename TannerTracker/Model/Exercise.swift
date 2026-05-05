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

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}

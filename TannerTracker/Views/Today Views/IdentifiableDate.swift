//
//  IdentifiableDate.swift
//  TannerTracker
//

import Foundation

struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}

//
//  IdentifiableDate.swift
//  Pratos
//

import Foundation

struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}

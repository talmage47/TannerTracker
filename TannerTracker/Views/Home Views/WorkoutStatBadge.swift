//
//  WorkoutStatBadge.swift
//  TannerTracker
//

import SwiftUI

struct WorkoutStatBadge: View {
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.gray)
            Text(value)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}

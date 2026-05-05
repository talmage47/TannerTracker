//
//  TabBarItem.swift
//  TannerTracker
//

import SwiftUI

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? accentColor : Color.gray)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? accentColor : Color.gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

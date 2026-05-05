//
//  FloatingBottomBar.swift
//  TannerTracker
//

import SwiftUI

struct FloatingBottomBar: View {
    @Binding var selectedTab: AppTab
    @Binding var showAddWorkout: Bool
    var accentColor: Color

    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: 4) {
                TabBarItem(icon: "calendar", label: "Today", isSelected: selectedTab == .today, accentColor: accentColor) {
                    selectedTab = .today
                }
                .padding(.horizontal, 10)
                TabBarItem(icon: "figure.strengthtraining.traditional", label: "Progress", isSelected: selectedTab == .progress, accentColor: accentColor) {
                    selectedTab = .progress
                }
                .padding(.horizontal, 10)
            }
            .fixedSize()
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .glassEffect()

            Spacer()
            Spacer()

            Button {
                showAddWorkout = true
            } label: {
                ZStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 56, height: 56)
                        .shadow(color: accentColor.opacity(0.55), radius: 14, y: 4)
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 0)
    }
}

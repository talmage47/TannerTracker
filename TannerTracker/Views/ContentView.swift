//
//  ContentView.swift
//  TannerTracker
//

import SwiftUI

enum AppTab {
    case today, photos, progress, threshold
}

struct ContentView: View {
    @Environment(AppSettings.self) var settings
    @State private var selectedTab: AppTab = .today
    @State private var showAddWorkout = false

    var body: some View {
        ZStack {
            Color(hex: "#1A1A1A").ignoresSafeArea()

            Group {
                switch selectedTab {
                case .today:
                    TodayView()
                case .photos:
                    PhotosView()
                case .progress:
                    WorkoutProgressView()
                case .threshold:
                    ThresholdView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            FloatingBottomBar(
                selectedTab: $selectedTab,
                showAddWorkout: $showAddWorkout,
                accentColor: settings.accentColor
            )
        }
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutView()
        }
        .tint(settings.accentColor)
    }
}

struct FloatingBottomBar: View {
    @Binding var selectedTab: AppTab
    @Binding var showAddWorkout: Bool
    var accentColor: Color

    var body: some View {
        HStack(alignment: .center) {
            // Liquid glass tab selector
            HStack(spacing: 4) {
                TabBarItem(icon: "calendar", label: "Today", isSelected: selectedTab == .today, accentColor: accentColor) {
                    selectedTab = .today
                }
                TabBarItem(icon: "camera", label: "Photos", isSelected: selectedTab == .photos, accentColor: accentColor) {
                    selectedTab = .photos
                }
                TabBarItem(icon: "dumbbell", label: "Progress", isSelected: selectedTab == .progress, accentColor: accentColor) {
                    selectedTab = .progress
                }
                TabBarItem(icon: "figure.strengthtraining.traditional", label: "Lifts", isSelected: selectedTab == .threshold, accentColor: accentColor) {
                    selectedTab = .threshold
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(in: Capsule())

            Spacer()

            // Floating accent plus button
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
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

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

#Preview {
    ContentView()
        .environment(AppSettings.shared)
}

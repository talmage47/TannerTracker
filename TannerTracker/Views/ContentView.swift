//
//  ContentView.swift
//  TannerTracker
//

import SwiftUI

enum AppTab {
    case today, progress
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
                case .progress:
                    WorkoutProgressView()
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

#Preview {
    ContentView()
        .environment(AppSettings.shared)
}

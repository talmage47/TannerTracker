//
//  ContentView.swift
//  TannerTracker
//

import SwiftUI

enum AppTab {
    case today, progress, add
}

struct ContentView: View {
    @Environment(AppSettings.self) var settings
    @State private var selectedTab: AppTab = .today
    @State private var showAddWorkout = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "calendar", value: AppTab.today) {
                TodayView()
            }
            Tab("Progress", systemImage: "figure.strengthtraining.traditional", value: AppTab.progress) {
                WorkoutProgressView()
            }
            Tab("Add", systemImage: "plus", value: AppTab.add, role: .search) {
                Color.clear
            }
        }
        .tint(settings.accentColor)
        .tabBarMinimizeBehavior(.onScrollDown)
        .onChange(of: selectedTab) { old, new in
            if new == .add {
                selectedTab = old
                showAddWorkout = true
            }
        }
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppSettings.shared)
}

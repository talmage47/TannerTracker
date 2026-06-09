//
//  ContentView.swift
//  Pratos
//

import SwiftUI

enum AppTab {
    case today, progress, add
}

struct ContentView: View {
    @Environment(AppSettings.self) var settings
    @State private var selectedTab: AppTab = .today
    @State private var tabBeforeAdd: AppTab = .today
    @State private var showAddWorkout = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Workout", systemImage: "figure.strengthtraining.traditional", value: AppTab.today) {
                HomeView()
            }
            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.progress) {
                ProgressTabView()
            }
            Tab("Add", systemImage: "plus", value: AppTab.add, role: .search) {
                Color(hex: "#1A1A1A").ignoresSafeArea()
            }
        }
        .tint(settings.accentColor)
        .tabBarMinimizeBehavior(.onScrollDown)
        .onChange(of: selectedTab) { old, new in
            if new == .add {
                tabBeforeAdd = old
                showAddWorkout = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if selectedTab == .add {
                        selectedTab = tabBeforeAdd
                    }
                }
            }
        }
        .sheet(isPresented: $showAddWorkout, onDismiss: {
            if selectedTab == .add {
                selectedTab = tabBeforeAdd
            }
        }) {
            AddEntryView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppSettings.shared)
}

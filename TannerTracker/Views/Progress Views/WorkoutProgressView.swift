//
//  WorkoutProgressView.swift
//  TannerTracker
//

import SwiftUI

struct WorkoutProgressView: View {
    @Environment(AppSettings.self) var settings

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1A1A1A").ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.gray.opacity(0.25))
                    Text("Progress")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Coming soon")
                        .foregroundStyle(.gray)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    WorkoutProgressView()
        .environment(AppSettings.shared)
}

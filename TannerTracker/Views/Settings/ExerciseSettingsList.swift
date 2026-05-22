//
//  ExerciseSettingsList.swift
//  TannerTracker
//

import SwiftUI

struct ExerciseSettingsList: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) var settings

    var body: some View {
        NavigationStack {
            ExerciseList()
                .navigationTitle("Exercise List")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundStyle(settings.accentColor)
                    }
                }
        }
        .presentationDragIndicator(.visible)
    }
}

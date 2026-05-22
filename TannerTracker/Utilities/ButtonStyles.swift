//
//  ButtonStyles.swift
//  TannerTracker
//

import SwiftUI

// For non-List rows (ProgressTabView, ExerciseEntryCard) where the button
// label already fills the full row — ButtonStyle background covers it correctly.
struct ListRowButtonStyle: ButtonStyle {
    var highlighted: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed && highlighted ? Color.white.opacity(0.08) : Color.clear)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// For native List rows — uses listRowBackground so the highlight covers the
// full cell height (including UIKit's minimum row height), not just the label frame.
private struct PressHighlightListRow: ViewModifier {
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .listRowBackground(
                Color(hex: "#242424")
                    .overlay(isPressed ? Color.white.opacity(0.08) : Color.clear)
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: .infinity)
                    .updating($isPressed) { value, state, _ in state = value }
            )
    }
}

extension View {
    func listRowPressHighlight() -> some View {
        modifier(PressHighlightListRow())
    }
}

// Scale up + haptic on long press completion. Apply only to views that support long press editing.
private struct LongPressScaleModifier: ViewModifier {
    @GestureState private var isPressing = false
    @State private var hapticTrigger = false
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressing ? 1.04 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isPressing)
            .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .updating($isPressing) { value, state, _ in state = value }
                    .onEnded { _ in
                        hapticTrigger.toggle()
                        action()
                    }
            )
    }
}

extension View {
    func longPressWithScaleAndHaptic(action: @escaping () -> Void) -> some View {
        modifier(LongPressScaleModifier(action: action))
    }
}

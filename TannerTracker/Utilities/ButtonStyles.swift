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

// Handles tap + long press for ScrollView/LazyVStack rows without blocking scroll.
// Uses Button (which has native scroll-deferral in UIKit) for tap recognition.
// Long press is detected via ButtonStyle.isPressed + a Timer — no extra gesture
// recognizers that would interfere with ScrollView's pan gesture.
// The longPressActivated flag in ExerciseRowModifier prevents the Button's tap
// action from firing after a long press completes.
private struct ExerciseRowButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let onLongPress: () -> Void

    @State private var longPressTimer: Timer? = nil
    @State private var scaleTimer: Timer? = nil
    @State private var hapticTimer: Timer? = nil
    @State private var isScaled = false
    @State private var hapticTrigger = false

    var body: some View {
        configuration.label
            .scaleEffect(isScaled ? 1.02 : 1.0)
            .background(configuration.isPressed ? Color.white.opacity(0.08) : Color.clear)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isScaled)
            .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    scaleTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
                        isScaled = true
                    }
                    hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { _ in
                        hapticTrigger.toggle()
                    }
                    longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                        onLongPress()
                    }
                } else {
                    scaleTimer?.invalidate(); scaleTimer = nil
                    hapticTimer?.invalidate(); hapticTimer = nil
                    longPressTimer?.invalidate(); longPressTimer = nil
                    isScaled = false
                }
            }
    }
}

private struct ExerciseRowButtonStyle: ButtonStyle {
    let onLongPress: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        ExerciseRowButtonBody(configuration: configuration, onLongPress: onLongPress)
    }
}

private struct ExerciseRowModifier: ViewModifier {
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var longPressActivated = false

    func body(content: Content) -> some View {
        Button {
            if !longPressActivated {
                onTap()
            }
            longPressActivated = false
        } label: {
            content
        }
        .buttonStyle(ExerciseRowButtonStyle(
            onLongPress: {
                longPressActivated = true
                onLongPress()
            }
        ))
    }
}

extension View {
    func exerciseRowGestures(onTap: @escaping () -> Void, onLongPress: @escaping () -> Void) -> some View {
        modifier(ExerciseRowModifier(onTap: onTap, onLongPress: onLongPress))
    }
}

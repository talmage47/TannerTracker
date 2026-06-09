//
//  AppSettings.swift
//  Pratos
//

import SwiftUI

@Observable
class AppSettings {
    static let shared = AppSettings()

    private let store = NSUbiquitousKeyValueStore.default

    var unitSystem: String {
        didSet {
            store.set(unitSystem, forKey: "unitSystem")
            store.synchronize()
        }
    }

    var accentColorHex: String {
        didSet {
            store.set(accentColorHex, forKey: "accentColorHex")
            store.synchronize()
        }
    }

    var accentColor: Color {
        get { Color(hex: accentColorHex) }
        set { accentColorHex = newValue.toHex() }
    }

    var isMetric: Bool { unitSystem == "metric" }

    var unitLabel: String { isMetric ? "kg" : "lbs" }

    func displayWeight(_ lbs: Double) -> Double {
        isMetric ? lbs / 2.20462 : lbs
    }

    func toStorageLbs(_ value: Double) -> Double {
        isMetric ? value * 2.20462 : value
    }

    private init() {
        self.unitSystem = store.string(forKey: "unitSystem") ?? "imperial"
        self.accentColorHex = store.string(forKey: "accentColorHex") ?? "#007AFF"

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.unitSystem = self.store.string(forKey: "unitSystem") ?? self.unitSystem
            self.accentColorHex = self.store.string(forKey: "accentColorHex") ?? self.accentColorHex
        }
    }
}

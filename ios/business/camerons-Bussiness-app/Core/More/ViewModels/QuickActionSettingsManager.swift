//
//  QuickActionSettingsManager.swift
//  knockbites-Bussiness-app
//
//  Extracted from QuickActionSettings.swift during Phase 3 cleanup
//

import Foundation
import SwiftUI
import Combine

class QuickActionSettingsManager: ObservableObject {
    static let shared = QuickActionSettingsManager()

    @Published var enabledActions: Set<QuickActionType> {
        didSet {
            saveSettings()
        }
    }

    private let userDefaultsKey = "quick_actions_enabled"

    private init() {
        // Load saved settings or use defaults
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(Set<QuickActionType>.self, from: savedData) {
            self.enabledActions = decoded
        } else {
            // Default: all actions enabled
            self.enabledActions = Set(QuickActionType.allCases)
        }
    }

    func isEnabled(_ action: QuickActionType) -> Bool {
        enabledActions.contains(action)
    }

    func toggle(_ action: QuickActionType) {
        if enabledActions.contains(action) {
            enabledActions.remove(action)
        } else {
            enabledActions.insert(action)
        }
    }

    func enable(_ action: QuickActionType) {
        enabledActions.insert(action)
    }

    func disable(_ action: QuickActionType) {
        enabledActions.remove(action)
    }

    func resetToDefaults() {
        enabledActions = Set(QuickActionType.allCases)
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(enabledActions) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func getEnabledActions() -> [QuickActionType] {
        QuickActionType.allCases.filter { enabledActions.contains($0) }
    }
}

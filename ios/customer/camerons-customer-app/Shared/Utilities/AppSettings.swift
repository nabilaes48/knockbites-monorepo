//
//  AppSettings.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import Combine

@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }

    @Published var isCompactView: Bool {
        didSet {
            UserDefaults.standard.set(isCompactView, forKey: "isCompactView")
        }
    }

    @Published var shareUsageData: Bool {
        didSet {
            UserDefaults.standard.set(shareUsageData, forKey: "shareUsageData")
        }
    }

    @Published var personalizedAds: Bool {
        didSet {
            UserDefaults.standard.set(personalizedAds, forKey: "personalizedAds")
        }
    }

    private init() {
        // Load saved settings
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.isCompactView = UserDefaults.standard.bool(forKey: "isCompactView")
        self.shareUsageData = UserDefaults.standard.bool(forKey: "shareUsageData")
        self.personalizedAds = UserDefaults.standard.bool(forKey: "personalizedAds")
    }

    var colorScheme: ColorScheme? {
        isDarkMode ? .dark : .light
    }
}

// MARK: - Environment Key
private struct AppSettingsKey: EnvironmentKey {
    static let defaultValue = AppSettings.shared
}

extension EnvironmentValues {
    var appSettings: AppSettings {
        get { self[AppSettingsKey.self] }
        set { self[AppSettingsKey.self] = newValue }
    }
}

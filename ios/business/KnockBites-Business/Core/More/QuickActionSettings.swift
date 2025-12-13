//
//  QuickActionSettings.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import Foundation
import SwiftUI
import Combine

// MARK: - Quick Action Model

enum QuickActionType: String, CaseIterable, Codable {
    case team = "team"
    case storeInfo = "store_info"
    case notifications = "notifications"
    case reports = "reports"
    case analytics = "analytics"

    var title: String {
        switch self {
        case .team: return "Team"
        case .storeInfo: return "Store Info"
        case .notifications: return "Notifications"
        case .reports: return "Reports"
        case .analytics: return "Analytics"
        }
    }

    var icon: String {
        switch self {
        case .team: return "person.3.fill"
        case .storeInfo: return "building.2.fill"
        case .notifications: return "bell.fill"
        case .reports: return "chart.bar.fill"
        case .analytics: return "chart.line.uptrend.xyaxis"
        }
    }

    var color: Color {
        switch self {
        case .team: return .blue
        case .storeInfo: return .green
        case .notifications: return .orange
        case .reports: return .purple
        case .analytics: return .blue
        }
    }

    var description: String {
        switch self {
        case .team: return "Manage team members and roles"
        case .storeInfo: return "View and edit store information"
        case .notifications: return "Push notification settings"
        case .reports: return "Generate business reports"
        case .analytics: return "View analytics dashboard"
        }
    }

    var requiresPermission: Bool {
        switch self {
        case .team: return true
        case .storeInfo: return true
        case .notifications: return false
        case .reports: return false
        case .analytics: return false
        }
    }
}

// MARK: - Quick Action Settings Manager (extracted to Core/More/ViewModels/QuickActionSettingsManager.swift)

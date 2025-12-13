//
//  QuickActionsSettingsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct QuickActionsSettingsView: View {
    @StateObject private var settingsManager = QuickActionSettingsManager.shared
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Customize which quick actions appear on your Profile page. Toggle actions on or off based on your preferences.")
                        .font(AppFonts.subheadline)
                        .foregroundColor(.textSecondary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: Spacing.md, trailing: 0))
                }

                Section(header: Text("Available Quick Actions")) {
                    ForEach(QuickActionType.allCases, id: \.self) { action in
                        QuickActionToggleRow(
                            action: action,
                            isEnabled: settingsManager.isEnabled(action),
                            hasPermission: hasPermission(for: action)
                        ) {
                            settingsManager.toggle(action)
                        }
                    }
                }

                Section {
                    Button(action: {
                        settingsManager.resetToDefaults()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Defaults")
                        }
                        .foregroundColor(.brandPrimary)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Enabled: \(settingsManager.enabledActions.count) of \(QuickActionType.allCases.count)")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)

                        Text("Quick actions provide fast access to frequently used features.")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func hasPermission(for action: QuickActionType) -> Bool {
        switch action {
        case .team:
            return authManager.hasPermission(.staff)
        case .storeInfo:
            return authManager.hasPermission(.settings)
        default:
            return true
        }
    }
}

// MARK: - Quick Action Toggle Row

struct QuickActionToggleRow: View {
    let action: QuickActionType
    let isEnabled: Bool
    let hasPermission: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(action.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: action.icon)
                    .font(.system(size: 20))
                    .foregroundColor(action.color)
            }

            // Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(action.title)
                        .font(AppFonts.body)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)

                    if action.requiresPermission && !hasPermission {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }

                Text(action.description)
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { isEnabled && hasPermission },
                set: { _ in
                    if hasPermission {
                        onToggle()
                    }
                }
            ))
            .labelsHidden()
            .disabled(!hasPermission)
        }
        .padding(.vertical, Spacing.xs)
        .opacity(hasPermission ? 1.0 : 0.5)
    }
}

// MARK: - Preview

#Preview {
    QuickActionsSettingsView()
        .environmentObject(AuthManager.shared)
}

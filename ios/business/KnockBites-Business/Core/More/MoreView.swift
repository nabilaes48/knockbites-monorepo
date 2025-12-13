//
//  MoreView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI
import Supabase

struct MoreView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // User Profile Card
                    UserProfileCard()
                        .padding(.horizontal)
                        .padding(.top, Spacing.lg)

                    // Quick Actions
                    MoreQuickActionsSection()
                        .padding(.horizontal)

                    // App Settings
                    AppSettingsSection(showSettings: $showSettings)
                        .padding(.horizontal)

                    // Support & Info
                    SupportSection()
                        .padding(.horizontal)

                    // Sign Out
                    SignOutSection()
                        .padding(.horizontal)
                        .padding(.bottom, Spacing.xl)
                }
            }
            .background(Color.surface.ignoresSafeArea())
            .navigationTitle("Profile")
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - User Profile Card

struct UserProfileCard: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Profile Image
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.brandPrimary, Color.brandSecondary]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                )

            // User Info
            VStack(spacing: Spacing.sm) {
                Text(authManager.userProfile?.fullName ?? "User")
                    .font(AppFonts.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                if let phone = authManager.userProfile?.phone {
                    Text(phone)
                        .font(AppFonts.subheadline)
                        .foregroundColor(.textSecondary)
                }

                // Role Badge
                if let role = authManager.userProfile?.role {
                    Text(role.displayName)
                        .font(AppFonts.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(role.badgeColor)
                        .cornerRadius(CornerRadius.lg)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .background(Color.surfaceSecondary)
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - More Quick Actions Section

struct MoreQuickActionsSection: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var settingsManager = QuickActionSettingsManager.shared

    var enabledActions: [QuickActionType] {
        settingsManager.getEnabledActions().filter { action in
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

    var body: some View {
        if !enabledActions.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Quick Actions")
                    .font(AppFonts.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, Spacing.xs)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.md) {
                    ForEach(enabledActions, id: \.self) { action in
                        MoreQuickActionCard(
                            action: action
                        )
                    }
                }
            }
        }
    }
}

struct MoreQuickActionCard: View {
    let action: QuickActionType

    var body: some View {
        NavigationLink(destination: destinationView) {
            VStack(spacing: Spacing.md) {
                Image(systemName: action.icon)
                    .font(.system(size: 32))
                    .foregroundColor(action.color)

                Text(action.title)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(Color.surfaceSecondary)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var destinationView: some View {
        switch action {
        case .team:
            // TODO: Implement TeamView and replace this placeholder
            VStack(spacing: Spacing.lg) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.textSecondary)
                Text("Team Management")
                    .font(AppFonts.title2)
                    .fontWeight(.bold)
                Text("Coming Soon")
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Team")
        case .storeInfo:
            StoreAnalyticsView()
        case .notifications:
            NotificationsAnalyticsView()
        case .reports:
            BusinessReportsView()
        case .analytics:
            AnalyticsView()
        }
    }
}

// MARK: - App Settings Section

struct AppSettingsSection: View {
    @Binding var showSettings: Bool
    @State private var showQuickActionsSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Settings")
                .font(AppFonts.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, Spacing.xs)

            VStack(spacing: 0) {
                MoreMenuItem(
                    icon: "gearshape.fill",
                    title: "App Settings",
                    iconColor: .gray,
                    showChevron: true
                ) {
                    showSettings = true
                }

                Divider()
                    .padding(.leading, 56)

                MoreMenuItem(
                    icon: "square.grid.2x2.fill",
                    title: "Quick Actions",
                    iconColor: .brandPrimary,
                    showChevron: true
                ) {
                    showQuickActionsSettings = true
                }

                Divider()
                    .padding(.leading, 56)

                MoreMenuItem(
                    icon: "bell.badge.fill",
                    title: "Notifications",
                    iconColor: .orange,
                    showChevron: true,
                    action: {}
                )

                Divider()
                    .padding(.leading, 56)

                MoreMenuItem(
                    icon: "lock.fill",
                    title: "Privacy & Security",
                    iconColor: .blue,
                    showChevron: true,
                    action: {}
                )
            }
            .background(Color.surfaceSecondary)
            .cornerRadius(CornerRadius.md)
        }
        .sheet(isPresented: $showQuickActionsSettings) {
            QuickActionsSettingsView()
        }
    }
}

// MARK: - Support Section

struct SupportSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Support & Info")
                .font(AppFonts.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, Spacing.xs)

            VStack(spacing: 0) {
                MoreMenuItem(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    iconColor: .green,
                    showChevron: true,
                    action: {}
                )

                Divider()
                    .padding(.leading, 56)

                MoreMenuItem(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    iconColor: .blue,
                    showChevron: true,
                    action: {}
                )

                Divider()
                    .padding(.leading, 56)

                MoreMenuItem(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    iconColor: .purple,
                    showChevron: true,
                    action: {}
                )

                Divider()
                    .padding(.leading, 56)

                MoreMenuItem(
                    icon: "info.circle.fill",
                    title: "About",
                    subtitle: "Version 1.0.0",
                    iconColor: .gray,
                    showChevron: false
                )
            }
            .background(Color.surfaceSecondary)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Sign Out Section

struct SignOutSection: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Button(action: {
            Task {
                await authManager.signOut()
            }
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 20))

                Text("Sign Out")
                    .font(AppFonts.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(Color.error)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - More Menu Item

struct MoreMenuItem: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let iconColor: Color
    var showChevron: Bool = true
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.body)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    MoreView()
        .environmentObject(AuthManager.shared)
}

//
//  KnockBitesBusinessApp.swift
//  KnockBites Business
//
//  Created by Nabil Imran on 11/12/25.
//

import SwiftUI

@main
struct KnockBitesBusinessApp: App {
    @ObservedObject private var authManager = AuthManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Test Supabase connection on app launch
        Task {
            await SupabaseManager.shared.testConnection()
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    // Loading screen while checking auth status
                    LoadingScreen()
                } else if authManager.isAuthenticated {
                    // Show main dashboard when authenticated
                    MainTabView()
                        .environmentObject(authManager)
                } else {
                    // Show login screen when not authenticated
                    StaffLoginView()
                        .environmentObject(authManager)
                }
            }
            .task {
                // Check auth status on app launch
                await authManager.checkAuthStatus()
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
        }
    }

    // MARK: - App Lifecycle Handling

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App became active - refresh data
            DebugLogger.info("App became active - refreshing data")
            NotificationCenter.default.post(name: .appBecameActive, object: nil)

        case .inactive:
            DebugLogger.info("App became inactive")

        case .background:
            DebugLogger.info("App entered background")

        @unknown default:
            break
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let appBecameActive = Notification.Name("appBecameActive")
    static let orderReceived = Notification.Name("orderReceived")
    static let orderStatusChanged = Notification.Name("orderStatusChanged")
}

// MARK: - Loading Screen

struct LoadingScreen: View {
    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.brandPrimary)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))

                Text("Loading...")
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

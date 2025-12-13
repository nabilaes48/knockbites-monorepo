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
        }
    }
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

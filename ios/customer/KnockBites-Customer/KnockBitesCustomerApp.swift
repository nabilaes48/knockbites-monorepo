//
//  KnockBitesCustomerApp.swift
//  KnockBites Customer
//
//  Created by Nabil Imran on 11/12/25.
//

import SwiftUI

@main
struct KnockBitesCustomerApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var cartViewModel = CartViewModel()
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var paymentMethodViewModel = PaymentMethodViewModel()
    @StateObject private var appSettings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    StoreSelectionWrapper()
                        .environmentObject(cartViewModel)
                        .environmentObject(favoritesViewModel)
                        .environmentObject(profileViewModel)
                        .environmentObject(paymentMethodViewModel)
                        .environment(\.appSettings, appSettings)
                        .preferredColorScheme(appSettings.colorScheme)
                        .withToast()
                } else {
                    LoginView()
                        .environment(\.appSettings, appSettings)
                        .preferredColorScheme(appSettings.colorScheme)
                        .withToast()
                }
            }
            .environmentObject(authManager)
        }
    }

    init() {
        // Test Supabase connection on app launch
        Task {
            await SupabaseManager.shared.testConnection()
        }
    }
}

// MARK: - Store Selection Wrapper
struct StoreSelectionWrapper: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var showStoreSelector = false
    @State private var hasCheckedStore = false

    var body: some View {
        Group {
            if cartViewModel.selectedStore != nil || hasCheckedStore {
                MainTabView()
            } else {
                Color.background.ignoresSafeArea()
                    .onAppear {
                        // Check if we have a saved store
                        Task {
                            await loadSavedStore()
                        }
                    }
            }
        }
        .sheet(isPresented: $showStoreSelector) {
            StoreSelectorView(selectedStore: $cartViewModel.selectedStore, autoSelectIfOne: true)
        }
    }

    private func loadSavedStore() async {
        // Try to load previously selected store
        // TODO: Move store fetching into StoreViewModel for MVVM compliance
        if let savedStoreId = UserDefaults.standard.string(forKey: "selectedStoreId") {
            print("📍 Attempting to load saved store: \(savedStoreId)")

            do {
                let stores = try await SupabaseManager.shared.fetchStores()
                if let savedStore = stores.first(where: { $0.id == savedStoreId }) {
                    await MainActor.run {
                        cartViewModel.selectedStore = savedStore
                        hasCheckedStore = true
                        print("✅ Restored saved store: \(savedStore.name)")
                    }
                    return
                }
            } catch {
                print("❌ Failed to load saved store: \(error)")
            }
        }

        // No saved store or failed to load - show selector
        await MainActor.run {
            hasCheckedStore = true
            showStoreSelector = true
        }
    }
}

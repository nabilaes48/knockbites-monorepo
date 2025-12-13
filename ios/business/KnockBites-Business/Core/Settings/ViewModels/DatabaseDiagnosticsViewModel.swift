//
//  DatabaseDiagnosticsViewModel.swift
//  knockbites-Bussiness-app
//
//  Extracted from DatabaseDiagnosticsView.swift during Phase 3 cleanup
//  Updated in Phase 4 to use DatabaseDiagnosticsService instead of direct Supabase access
//

import SwiftUI
import Combine

@MainActor
class DatabaseDiagnosticsViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var isTesting = false
    @Published var isLoadingOrders = false
    @Published var totalOrders = 0
    @Published var pendingOrders = 0
    @Published var completedOrders = 0
    @Published var recentOrders: [Order] = []
    @Published var errorMessage: String?

    private let diagnosticsService = DatabaseDiagnosticsService.shared

    func testConnection() {
        Task {
            isTesting = true
            errorMessage = nil

            let result = await diagnosticsService.testConnection()

            isConnected = result.isConnected
            errorMessage = result.errorMessage

            if result.isConnected {
                print("✅ Connection successful! Found \(result.storeCount) stores")
            } else {
                print("❌ Connection failed: \(result.errorMessage ?? "Unknown error")")
            }

            isTesting = false
        }
    }

    func fetchOrders() {
        Task {
            isLoadingOrders = true
            errorMessage = nil

            let result = await diagnosticsService.fetchOrderDiagnostics(storeId: SupabaseConfig.storeId)

            recentOrders = result.recentOrders
            totalOrders = result.totalOrders
            pendingOrders = result.pendingOrders
            completedOrders = result.completedOrders
            errorMessage = result.errorMessage

            if result.errorMessage == nil {
                print("✅ Fetched \(result.totalOrders) orders for store \(SupabaseConfig.storeId)")
            } else {
                print("⚠️ \(result.errorMessage ?? "")")
            }

            isLoadingOrders = false
        }
    }

    func fetchAllStoreOrders() {
        Task {
            isLoadingOrders = true
            errorMessage = nil

            let result = await diagnosticsService.fetchAllStoreOrders(currentStoreId: SupabaseConfig.storeId)

            totalOrders = result.totalOrders
            errorMessage = result.message

            print("📊 \(result.message)")

            isLoadingOrders = false
        }
    }
}

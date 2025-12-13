//
//  MenuManagementViewModel.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//  Extracted from MenuManagementView.swift
//

import SwiftUI
import Combine

@MainActor
class MenuManagementViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var menuItems: [MenuItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadMenu() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                // Fetch categories and menu items from Supabase
                async let categoriesTask = SupabaseManager.shared.fetchCategories()
                async let menuItemsTask = SupabaseManager.shared.fetchMenuItems()

                categories = try await categoriesTask
                menuItems = try await menuItemsTask

                print("✅ Loaded \(categories.count) categories and \(menuItems.count) menu items from Supabase")
            } catch {
                print("❌ Failed to load menu: \(error)")
                errorMessage = "Failed to load menu: \(error.localizedDescription)"

                // Fallback to mock data for testing
                print("⚠️ Using mock data as fallback")
                categories = MockDataService.shared.mockCategories
                menuItems = MockDataService.shared.getMockMenuItems()
            }

            isLoading = false
        }
    }

    func toggleAvailability(for itemId: String, available: Bool) {
        Task {
            do {
                // Update in Supabase
                try await SupabaseManager.shared.updateMenuItemAvailability(
                    itemId: itemId,
                    isAvailable: available
                )

                // Update local state
                if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                    menuItems[index].isAvailable = available
                }

                print("✅ Toggled availability for item \(itemId) to \(available)")
            } catch {
                print("❌ Failed to toggle availability: \(error)")
                errorMessage = "Failed to update: \(error.localizedDescription)"

                // Revert local change on error
                if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                    menuItems[index].isAvailable = !available
                }
            }
        }
    }

    func updateItemPrice(for itemId: String, newPrice: Double) {
        Task {
            do {
                // Update in Supabase
                try await SupabaseManager.shared.updateMenuItemPrice(
                    itemId: itemId,
                    price: newPrice
                )

                // Update local state
                if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                    menuItems[index].price = newPrice
                }

                print("✅ Updated price for item \(itemId) to $\(String(format: "%.2f", newPrice))")
            } catch {
                print("❌ Failed to update price: \(error)")
                errorMessage = "Failed to update price: \(error.localizedDescription)"
            }
        }
    }

    func updateMenuItem(_ item: MenuItem) {
        if let index = menuItems.firstIndex(where: { $0.id == item.id }) {
            menuItems[index] = item
            print("✅ Updated menu item: \(item.name)")
            // TODO: Update in Supabase
        }
    }

    func addMenuItem(_ item: MenuItem) {
        menuItems.append(item)
        print("✅ Added new menu item: \(item.name)")
        // TODO: Save to Supabase
    }
}

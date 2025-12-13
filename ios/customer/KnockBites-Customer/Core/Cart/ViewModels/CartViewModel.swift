//
//  CartViewModel.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import Combine

@MainActor
class CartViewModel: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var selectedStore: Store?
    @Published var orderType: OrderType = .pickup
    @Published var scheduledFor: Date? = nil // For scheduled orders

    // MARK: - Computed Properties
    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }

    var tax: Double {
        subtotal * 0.08 // 8% tax
    }

    var total: Double {
        subtotal + tax
    }

    var formattedSubtotal: String {
        String(format: "$%.2f", subtotal)
    }

    var formattedTax: String {
        String(format: "$%.2f", tax)
    }

    var formattedTotal: String {
        String(format: "$%.2f", total)
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    // MARK: - Add Item
    func addItem(
        menuItem: MenuItem,
        quantity: Int = 1,
        selectedOptions: [String: [String]] = [:],
        portionSelections: [Int: PortionLevel]? = nil,
        specialInstructions: String? = nil
    ) {
        let newItem = CartItem(
            id: UUID().uuidString,
            menuItem: menuItem,
            quantity: quantity,
            selectedOptions: selectedOptions,
            portionSelections: portionSelections,
            specialInstructions: specialInstructions
        )

        // Check if same item with same customizations exists
        if let existingIndex = items.firstIndex(where: {
            $0.menuItem.id == newItem.menuItem.id &&
            $0.selectedOptions == newItem.selectedOptions &&
            $0.portionSelections == newItem.portionSelections &&
            $0.specialInstructions == newItem.specialInstructions
        }) {
            items[existingIndex].quantity += quantity
        } else {
            items.append(newItem)
        }

        saveCart()
    }

    // MARK: - Update Quantity
    func updateQuantity(for item: CartItem, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        if quantity <= 0 {
            items.remove(at: index)
        } else {
            items[index].quantity = quantity
        }

        saveCart()
    }

    // MARK: - Remove Item
    func removeItem(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
        saveCart()
    }

    // MARK: - Clear Cart
    func clearCart() {
        items.removeAll()
        saveCart()
    }

    // MARK: - Persistence
    private func saveCart() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "cartItems")
        }
    }

    func loadCart() {
        if let data = UserDefaults.standard.data(forKey: "cartItems"),
           let decoded = try? JSONDecoder().decode([CartItem].self, from: data) {
            items = decoded
        }
    }
}

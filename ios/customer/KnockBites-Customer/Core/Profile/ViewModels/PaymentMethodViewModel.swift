//
//  PaymentMethodViewModel.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//
//  SECURITY FIX: Migrated from UserDefaults to Keychain for secure storage
//  CVE-2025-KB003: Payment card data must be stored in encrypted Keychain
//

import SwiftUI
import Combine

@MainActor
class PaymentMethodViewModel: ObservableObject {
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var isLoading = false

    // SECURITY: Using Keychain key instead of UserDefaults key
    private let keychainKey = "secure.paymentMethods.v2"
    private let keychain = KeychainHelper.shared

    init() {
        loadPaymentMethods()

        // Add some mock payment methods if none exist (for demo purposes)
        if paymentMethods.isEmpty {
            addMockPaymentMethods()
        }
    }

    // MARK: - Load/Save (SECURE: Using Keychain)

    private func loadPaymentMethods() {
        // SECURITY: Load from Keychain instead of UserDefaults
        if let methods: [PaymentMethod] = keychain.read(forKey: keychainKey, as: [PaymentMethod].self) {
            paymentMethods = methods
        }
    }

    private func savePaymentMethods() {
        // SECURITY: Save to Keychain instead of UserDefaults
        do {
            try keychain.save(paymentMethods, forKey: keychainKey)
        } catch {
            DebugLogger.error("Failed to save payment methods to Keychain", error)
        }
    }

    // MARK: - Add Mock Payment Methods

    private func addMockPaymentMethods() {
        let mockMethods = [
            PaymentMethod(
                id: UUID().uuidString,
                type: .card,
                displayName: "Visa •••• 4242",
                lastFourDigits: "4242",
                expiryMonth: 12,
                expiryYear: 2025,
                isDefault: true,
                cardBrand: .visa
            ),
            PaymentMethod(
                id: UUID().uuidString,
                type: .card,
                displayName: "Mastercard •••• 8888",
                lastFourDigits: "8888",
                expiryMonth: 6,
                expiryYear: 2026,
                isDefault: false,
                cardBrand: .mastercard
            ),
            PaymentMethod(
                id: UUID().uuidString,
                type: .applePay,
                displayName: "Apple Pay",
                lastFourDigits: nil,
                expiryMonth: nil,
                expiryYear: nil,
                isDefault: false,
                cardBrand: nil
            )
        ]

        paymentMethods = mockMethods
        savePaymentMethods()
    }

    // MARK: - Payment Method Management

    func addPaymentMethod(_ method: PaymentMethod) {
        // If this is set as default, remove default from others
        if method.isDefault {
            paymentMethods = paymentMethods.map { existing in
                PaymentMethod(
                    id: existing.id,
                    type: existing.type,
                    displayName: existing.displayName,
                    lastFourDigits: existing.lastFourDigits,
                    expiryMonth: existing.expiryMonth,
                    expiryYear: existing.expiryYear,
                    isDefault: false,
                    cardBrand: existing.cardBrand
                )
            }
        }

        paymentMethods.append(method)
        savePaymentMethods()

        ToastManager.shared.show(
            "Payment method added",
            icon: "checkmark.circle.fill",
            type: .success
        )
    }

    func deletePaymentMethod(_ method: PaymentMethod) {
        paymentMethods.removeAll { $0.id == method.id }
        savePaymentMethods()

        ToastManager.shared.show(
            "Payment method removed",
            icon: "checkmark.circle.fill",
            type: .success
        )
    }

    func setDefaultPaymentMethod(_ method: PaymentMethod) {
        paymentMethods = paymentMethods.map { existing in
            PaymentMethod(
                id: existing.id,
                type: existing.type,
                displayName: existing.displayName,
                lastFourDigits: existing.lastFourDigits,
                expiryMonth: existing.expiryMonth,
                expiryYear: existing.expiryYear,
                isDefault: existing.id == method.id,
                cardBrand: existing.cardBrand
            )
        }
        savePaymentMethods()

        ToastManager.shared.show(
            "Default payment method updated",
            icon: "checkmark.circle.fill",
            type: .success
        )
    }

    var defaultPaymentMethod: PaymentMethod? {
        paymentMethods.first { $0.isDefault }
    }

    var hasExpiredCards: Bool {
        paymentMethods.contains { $0.isExpired }
    }

    // MARK: - Clear All (for testing)

    func clearAll() {
        paymentMethods.removeAll()
        // SECURITY: Clear from Keychain instead of UserDefaults
        keychain.delete(forKey: keychainKey)
    }
}

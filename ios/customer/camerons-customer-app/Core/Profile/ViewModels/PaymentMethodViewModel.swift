//
//  PaymentMethodViewModel.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import Combine

@MainActor
class PaymentMethodViewModel: ObservableObject {
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var isLoading = false

    private let paymentMethodsKey = "savedPaymentMethods"

    init() {
        loadPaymentMethods()

        // Add some mock payment methods if none exist
        if paymentMethods.isEmpty {
            addMockPaymentMethods()
        }
    }

    // MARK: - Load/Save

    private func loadPaymentMethods() {
        if let data = UserDefaults.standard.data(forKey: paymentMethodsKey),
           let methods = try? JSONDecoder().decode([PaymentMethod].self, from: data) {
            paymentMethods = methods
        }
    }

    private func savePaymentMethods() {
        if let encoded = try? JSONEncoder().encode(paymentMethods) {
            UserDefaults.standard.set(encoded, forKey: paymentMethodsKey)
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
        UserDefaults.standard.removeObject(forKey: paymentMethodsKey)
    }
}

//
//  AddressViewModel.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/19/25.
//

import SwiftUI
import Combine

@MainActor
class AddressViewModel: ObservableObject {
    @Published var addresses: [Address] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let addressesKey = "userAddresses"

    init() {
        loadAddressesFromCache()
    }

    // MARK: - Fetch Addresses from Supabase

    func fetchAddresses() async {
        isLoading = true
        errorMessage = nil

        print("📥 Fetching addresses from Supabase...")

        do {
            let fetchedAddresses = try await SupabaseManager.shared.getUserAddresses()
            addresses = fetchedAddresses

            // Cache addresses for offline access
            saveAddressesToCache()

            print("✅ Loaded \(fetchedAddresses.count) addresses from Supabase")
        } catch {
            print("❌ Failed to fetch addresses: \(error.localizedDescription)")
            errorMessage = "Failed to load addresses"

            // Fallback to cached addresses
            loadAddressesFromCache()
        }

        isLoading = false
    }

    // MARK: - Add Address

    func addAddress(_ address: Address) async {
        isLoading = true
        errorMessage = nil

        print("🔄 Adding new address: \(address.label)")

        do {
            try await SupabaseManager.shared.addAddress(address)

            // Refresh addresses list
            await fetchAddresses()

            ToastManager.shared.show(
                "Address added successfully",
                icon: "checkmark.circle.fill",
                type: .success
            )
        } catch {
            print("❌ Failed to add address: \(error.localizedDescription)")
            errorMessage = "Failed to add address"

            ToastManager.shared.show(
                "Failed to add address",
                icon: "exclamationmark.triangle",
                type: .error
            )
        }

        isLoading = false
    }

    // MARK: - Update Address

    func updateAddress(_ address: Address) async {
        isLoading = true
        errorMessage = nil

        print("🔄 Updating address: \(address.label)")

        do {
            try await SupabaseManager.shared.updateAddress(address)

            // Refresh addresses list
            await fetchAddresses()

            ToastManager.shared.show(
                "Address updated successfully",
                icon: "checkmark.circle.fill",
                type: .success
            )
        } catch {
            print("❌ Failed to update address: \(error.localizedDescription)")
            errorMessage = "Failed to update address"

            ToastManager.shared.show(
                "Failed to update address",
                icon: "exclamationmark.triangle",
                type: .error
            )
        }

        isLoading = false
    }

    // MARK: - Delete Address

    func deleteAddress(_ address: Address) async {
        isLoading = true
        errorMessage = nil

        print("🔄 Deleting address: \(address.label)")

        do {
            try await SupabaseManager.shared.deleteAddress(address.id)

            // Refresh addresses list
            await fetchAddresses()

            ToastManager.shared.show(
                "Address deleted",
                icon: "trash.fill",
                type: .info
            )
        } catch {
            print("❌ Failed to delete address: \(error.localizedDescription)")
            errorMessage = "Failed to delete address"

            ToastManager.shared.show(
                "Failed to delete address",
                icon: "exclamationmark.triangle",
                type: .error
            )
        }

        isLoading = false
    }

    // MARK: - Set Default Address

    func setDefaultAddress(_ address: Address) async {
        isLoading = true
        errorMessage = nil

        print("🔄 Setting default address: \(address.label)")

        do {
            try await SupabaseManager.shared.setDefaultAddress(address.id)

            // Refresh addresses list
            await fetchAddresses()

            ToastManager.shared.show(
                "Default address updated",
                icon: "checkmark.circle.fill",
                type: .success
            )
        } catch {
            print("❌ Failed to set default address: \(error.localizedDescription)")
            errorMessage = "Failed to set default address"

            ToastManager.shared.show(
                "Failed to set default address",
                icon: "exclamationmark.triangle",
                type: .error
            )
        }

        isLoading = false
    }

    // MARK: - Helper Methods

    var defaultAddress: Address? {
        addresses.first { $0.isDefault }
    }

    // MARK: - Cache Management

    private func saveAddressesToCache() {
        if let encoded = try? JSONEncoder().encode(addresses) {
            UserDefaults.standard.set(encoded, forKey: addressesKey)
        }
    }

    private func loadAddressesFromCache() {
        if let data = UserDefaults.standard.data(forKey: addressesKey),
           let savedAddresses = try? JSONDecoder().decode([Address].self, from: data) {
            addresses = savedAddresses
            print("📦 Loaded \(savedAddresses.count) addresses from cache")
        }
    }
}

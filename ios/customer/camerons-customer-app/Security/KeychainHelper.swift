//
//  KeychainHelper.swift
//  KnockBites Customer App
//
//  Security helper for storing sensitive data in iOS Keychain
//  instead of UserDefaults (which is plaintext and insecure)
//
//  CVE-2025-KB003: UserDefaults storage of PII replaced with Keychain
//

import Foundation
import Security

/// Thread-safe Keychain helper for secure data storage
final class KeychainHelper {

    static let shared = KeychainHelper()

    private let service = "com.knockbites.customer"
    private let accessGroup: String? = nil // Set for shared keychain access

    private init() {}

    // MARK: - Error Types

    enum KeychainError: LocalizedError {
        case duplicateItem
        case itemNotFound
        case unexpectedStatus(OSStatus)
        case encodingFailed
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .duplicateItem:
                return "Item already exists in keychain"
            case .itemNotFound:
                return "Item not found in keychain"
            case .unexpectedStatus(let status):
                return "Keychain error: \(status)"
            case .encodingFailed:
                return "Failed to encode data"
            case .decodingFailed:
                return "Failed to decode data"
            }
        }
    }

    // MARK: - Core Operations

    /// Save data to keychain
    func save(_ data: Data, forKey key: String) throws {
        var query = baseQuery(forKey: key)
        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Update existing item
            try update(data, forKey: key)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Update existing keychain item
    func update(_ data: Data, forKey key: String) throws {
        let query = baseQuery(forKey: key)
        let attributes: [String: Any] = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Read data from keychain
    func read(forKey key: String) -> Data? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    /// Delete item from keychain
    func delete(forKey key: String) {
        let query = baseQuery(forKey: key)
        SecItemDelete(query as CFDictionary)
    }

    /// Delete all items for this service
    func deleteAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Codable Convenience

    /// Save Codable object to keychain
    func save<T: Encodable>(_ object: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(object) else {
            throw KeychainError.encodingFailed
        }
        try save(data, forKey: key)
    }

    /// Read Codable object from keychain
    func read<T: Decodable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = read(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }

    // MARK: - Private

    private func baseQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            // Protect data - only accessible when device is unlocked after first unlock
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}

// MARK: - Secure Storage Keys

extension KeychainHelper {

    enum SecureKey {
        static let savedAddresses = "secure.addresses"
        static let paymentMethods = "secure.paymentMethods"
        static let userToken = "secure.userToken"
        static let refreshToken = "secure.refreshToken"
        static let userId = "secure.userId"
        static let orderHistory = "secure.orderHistory"
    }
}

// MARK: - Address Storage

extension KeychainHelper {

    func saveAddresses(_ addresses: [SavedAddress]) throws {
        try save(addresses, forKey: SecureKey.savedAddresses)
    }

    func getAddresses() -> [SavedAddress]? {
        return read(forKey: SecureKey.savedAddresses, as: [SavedAddress].self)
    }

    func clearAddresses() {
        delete(forKey: SecureKey.savedAddresses)
    }
}

// MARK: - Payment Method Storage

extension KeychainHelper {

    func savePaymentMethods(_ methods: [SavedPaymentMethod]) throws {
        try save(methods, forKey: SecureKey.paymentMethods)
    }

    func getPaymentMethods() -> [SavedPaymentMethod]? {
        return read(forKey: SecureKey.paymentMethods, as: [SavedPaymentMethod].self)
    }

    func clearPaymentMethods() {
        delete(forKey: SecureKey.paymentMethods)
    }
}

// MARK: - User Session Storage

extension KeychainHelper {

    func saveUserId(_ userId: String) throws {
        guard let data = userId.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(data, forKey: SecureKey.userId)
    }

    func getUserId() -> String? {
        guard let data = read(forKey: SecureKey.userId) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func clearSession() {
        delete(forKey: SecureKey.userId)
        delete(forKey: SecureKey.userToken)
        delete(forKey: SecureKey.refreshToken)
    }
}

// MARK: - Data Models (for reference - actual models may differ)

struct SavedAddress: Codable {
    let id: String
    let label: String
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let phone: String?
    let isDefault: Bool
}

struct SavedPaymentMethod: Codable {
    let id: String
    let type: String // "card", "apple_pay"
    let last4: String?
    let brand: String? // "Visa", "Mastercard"
    let expiryMonth: Int?
    let expiryYear: Int?
    let isDefault: Bool
}

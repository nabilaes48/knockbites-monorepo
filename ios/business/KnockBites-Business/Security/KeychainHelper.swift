//
//  KeychainHelper.swift
//  KnockBites Business App
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

    private let service = "com.knockbites.business"
    private let accessGroup: String? = nil

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

    func save(_ data: Data, forKey key: String) throws {
        var query = baseQuery(forKey: key)
        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            try update(data, forKey: key)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func update(_ data: Data, forKey key: String) throws {
        let query = baseQuery(forKey: key)
        let attributes: [String: Any] = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func read(forKey key: String) -> Data? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    func delete(forKey key: String) {
        let query = baseQuery(forKey: key)
        SecItemDelete(query as CFDictionary)
    }

    func deleteAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Codable Convenience

    func save<T: Encodable>(_ object: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(object) else {
            throw KeychainError.encodingFailed
        }
        try save(data, forKey: key)
    }

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
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}

// MARK: - Business App Specific Keys

extension KeychainHelper {

    enum SecureKey {
        static let staffToken = "secure.staffToken"
        static let refreshToken = "secure.refreshToken"
        static let userId = "secure.userId"
        static let storeId = "secure.storeId"
        static let userRole = "secure.userRole"
        static let printerConfig = "secure.printerConfig"
    }
}

// MARK: - Staff Session Storage

extension KeychainHelper {

    struct StaffSession: Codable {
        let userId: String
        let email: String
        let role: String
        let storeId: Int?
        let assignedStores: [Int]
        let permissions: [String]
    }

    func saveStaffSession(_ session: StaffSession) throws {
        try save(session, forKey: SecureKey.staffToken)
    }

    func getStaffSession() -> StaffSession? {
        return read(forKey: SecureKey.staffToken, as: StaffSession.self)
    }

    func clearStaffSession() {
        delete(forKey: SecureKey.staffToken)
        delete(forKey: SecureKey.refreshToken)
        delete(forKey: SecureKey.userId)
    }
}

// MARK: - Printer Configuration (may contain network credentials)

extension KeychainHelper {

    struct PrinterConfig: Codable {
        let printerType: String
        let printerAddress: String?
        let autoPrint: Bool
        let printOnStartPrep: Bool
    }

    func savePrinterConfig(_ config: PrinterConfig) throws {
        try save(config, forKey: SecureKey.printerConfig)
    }

    func getPrinterConfig() -> PrinterConfig? {
        return read(forKey: SecureKey.printerConfig, as: PrinterConfig.self)
    }
}

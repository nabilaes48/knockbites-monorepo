//
//  SecureSupabaseConfig.swift
//  KnockBites Business App
//
//  Secure configuration for Supabase connection
//

import Foundation

/// Supabase configuration
enum SecureSupabaseConfig {

    // MARK: - Supabase Connection

    static let url = "https://dsmefhuhflixoevexafm.supabase.co"

    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzbWVmaHVoZmxpeG9ldmV4YWZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTMzNjQsImV4cCI6MjA4MTE2OTM2NH0.tp-ddm8D9H4P_CLaM7ZZtKZ2DzpH2iPeDJjlj4C2P2E"

    // MARK: - Storage Configuration

    /// Storage bucket name for menu images
    static let storageBucket = "menu-images"

    /// Full storage URL
    static var storageURL: String {
        "\(url)/storage/v1/object/public/\(storageBucket)"
    }

    /// Converts a relative image path to a full Supabase storage URL
    /// - Parameter path: Relative path from database (e.g., "/images/menu/items/breakfast/item.jpg")
    /// - Returns: Full URL string or original path if already absolute
    static func imageURL(from path: String?) -> String {
        guard let path = path, !path.isEmpty else {
            return ""
        }

        // If already a complete URL, return as-is
        if path.starts(with: "http://") || path.starts(with: "https://") {
            return path
        }

        // Remove leading slash if present
        var cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path

        // Strip the database prefix "/images/menu/items/" to match actual storage structure
        // Database: /images/menu/items/breakfast/bacon.jpg
        // Storage:  breakfast/bacon.jpg
        if cleanPath.hasPrefix("images/menu/items/") {
            cleanPath = String(cleanPath.dropFirst("images/menu/items/".count))
        }

        // Construct full storage URL
        return "\(storageURL)/\(cleanPath)"
    }

    // MARK: - Store Configuration

    /// Default store ID for single-store operations
    /// In production, prefer using AuthManager.userProfile?.storeId for user-specific store access
    static let storeId: Int = 1

    // MARK: - Environment

    #if DEBUG
    static let environment: Environment = .debug
    #else
    static let environment: Environment = .production
    #endif

    enum Environment: String {
        case debug
        case staging
        case production

        var isDebug: Bool { self == .debug }
        var isProduction: Bool { self == .production }
    }

    // MARK: - Validation

    static func validateConfiguration() {
        #if DEBUG
        print("🔧 SecureSupabaseConfig Validation:")
        print("   URL: \(url.prefix(30))...")
        print("   Key: \(anonKey.prefix(20))...[redacted]")
        print("   Environment: \(environment.rawValue)")
        #endif
    }
}

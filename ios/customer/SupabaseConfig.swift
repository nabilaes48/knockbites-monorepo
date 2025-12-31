import Foundation

enum SupabaseConfig {
    // KnockBites Staging Project (knockbites-staging)
    static let url = "https://dsmefhuhflixoevexafm.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzbWVmaHVoZmxpeG9ldmV4YWZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTMzNjQsImV4cCI6MjA4MTE2OTM2NH0.tp-ddm8D9H4P_CLaM7ZZtKZ2DzpH2iPeDJjlj4C2P2E"

    // Storage bucket name (update this to match your Supabase storage bucket)
    static let storageBucket = "menu-images"

    // Full storage URL
    static let storageURL = "\(url)/storage/v1/object/public/\(storageBucket)"

    /// Converts a relative image path to a full Supabase storage URL
    /// - Parameter path: Relative path from database (e.g., "/images/menu/items/breakfast/item.jpg")
    /// - Returns: Full URL string or original path if already absolute
    static func imageURL(from path: String?) -> String {
        guard let path = path, !path.isEmpty else {
            print("⚠️ Empty image path")
            return ""
        }

        // If already a complete URL, return as-is
        if path.starts(with: "http://") || path.starts(with: "https://") {
            print("✅ Image URL already absolute: \(path)")
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
        let fullURL = "\(storageURL)/\(cleanPath)"
        print("🔧 Converting image URL:")
        print("   Database path: \(path)")
        print("   Cleaned path:  \(cleanPath)")
        print("   Full URL:      \(fullURL)")

        return fullURL
    }
}

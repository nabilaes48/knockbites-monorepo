import Foundation

enum SupabaseConfig {
    static let url = "https://jwcuebbhkwwilqfblecq.supabase.co"
    static let anonKey =
"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3Y3VlYmJoa3d3aWxxZmJsZWNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0MzYxODksImV4cCI6MjA3OTAxMjE4OX0.z03hYyyIIyfdj42Le4XeJFSK2vnd4cHvsaLA03CNM7I"

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

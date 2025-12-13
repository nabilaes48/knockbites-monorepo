//
//  SecureSupabaseConfig.swift
//  KnockBites Business App
//
//  Secure configuration loader that reads from Info.plist
//  Values are injected from xcconfig files at build time
//
//  MIGRATION: Replace SupabaseConfig.swift with this file
//  CVE-2025-KB001: Hardcoded credentials replaced with build-time injection
//

import Foundation

/// Secure configuration that reads from build-time injected values
/// NEVER hardcode credentials in this file
enum SecureSupabaseConfig {

    // MARK: - Supabase Connection

    static var url: String {
        guard let url = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              !url.isEmpty,
              url != "$(SUPABASE_URL)" else {
            #if DEBUG
            fatalError("""
                SUPABASE_URL not configured.

                To fix:
                1. Create Config/Debug.xcconfig from Config/Debug.xcconfig.example
                2. Add your Supabase URL
                3. Ensure the xcconfig is linked in your target's Build Settings
                """)
            #else
            assertionFailure("SUPABASE_URL not configured")
            return ""
            #endif
        }
        return url
    }

    static var anonKey: String {
        guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
              !key.isEmpty,
              key != "$(SUPABASE_ANON_KEY)",
              key != "YOUR_ANON_KEY_HERE" else {
            #if DEBUG
            fatalError("""
                SUPABASE_ANON_KEY not configured.

                To fix:
                1. Create Config/Debug.xcconfig from Config/Debug.xcconfig.example
                2. Add your Supabase anon key
                3. Ensure the xcconfig is linked in your target's Build Settings
                """)
            #else
            assertionFailure("SUPABASE_ANON_KEY not configured")
            return ""
            #endif
        }
        return key
    }

    // MARK: - Environment

    static var environment: Environment {
        let env = Bundle.main.infoDictionary?["ENVIRONMENT"] as? String ?? "debug"
        return Environment(rawValue: env) ?? .debug
    }

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

        _ = url
        _ = anonKey
    }
}

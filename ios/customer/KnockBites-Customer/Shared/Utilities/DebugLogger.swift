//
//  DebugLogger.swift
//  KnockBites-Customer
//
//  Production-safe logging utility that only outputs in DEBUG builds.
//

import Foundation

/// Production-safe logger that only prints in DEBUG builds.
/// Use this instead of print() to prevent sensitive data from appearing in production logs.
enum DebugLogger {
    /// Log a message only in DEBUG builds
    /// - Parameter message: The message to log
    static func log(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }

    /// Log a message with a category prefix only in DEBUG builds
    /// - Parameters:
    ///   - category: Category name (e.g., "Auth", "Network", "Cart")
    ///   - message: The message to log
    static func log(_ category: String, _ message: String) {
        #if DEBUG
        print("[\(category)] \(message)")
        #endif
    }

    /// Log an error only in DEBUG builds
    /// - Parameters:
    ///   - message: The error message
    ///   - error: The optional error object
    static func error(_ message: String, _ error: Error? = nil) {
        #if DEBUG
        if let error = error {
            print("❌ \(message): \(error.localizedDescription)")
        } else {
            print("❌ \(message)")
        }
        #endif
    }

    /// Log a success message only in DEBUG builds
    /// - Parameter message: The success message
    static func success(_ message: String) {
        #if DEBUG
        print("✅ \(message)")
        #endif
    }

    /// Log a warning only in DEBUG builds
    /// - Parameter message: The warning message
    static func warning(_ message: String) {
        #if DEBUG
        print("⚠️ \(message)")
        #endif
    }

    /// Log info only in DEBUG builds
    /// - Parameter message: The info message
    static func info(_ message: String) {
        #if DEBUG
        print("ℹ️ \(message)")
        #endif
    }
}

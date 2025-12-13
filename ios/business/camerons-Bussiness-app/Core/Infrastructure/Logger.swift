//
//  Logger.swift
//  knockbites-Bussiness-app
//
//  Created during Phase 9 - Centralized logging utility
//

import Foundation
import os.log

/// Centralized logging utility with level-based filtering.
/// Logs are only output in DEBUG builds.
enum Logger {
    /// Log levels in order of severity
    enum Level: Int, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3

        static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }
    }

    /// Categories for log filtering
    enum Category: String {
        case network = "Network"
        case cache = "Cache"
        case auth = "Auth"
        case orders = "Orders"
        case menu = "Menu"
        case marketing = "Marketing"
        case analytics = "Analytics"
        case ui = "UI"
        case general = "General"
    }

    /// Minimum level to output (can be configured)
    private static var minimumLevel: Level = .debug

    /// OS Logger instance
    private static let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.knockbites.app", category: "App")

    // MARK: - Public API

    /// Log a debug message (verbose, for development)
    static func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    /// Log an info message (general information)
    static func info(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    /// Log a warning message (potential issues)
    static func warning(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    /// Log an error message (failures)
    static func error(_ message: String, category: Category = .general, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .error, category: category, file: file, function: function, line: line)
    }

    /// Log network request
    static func networkRequest(_ endpoint: String, method: String = "GET") {
        debug("→ \(method) \(endpoint)", category: .network)
    }

    /// Log network response
    static func networkResponse(_ endpoint: String, statusCode: Int? = nil, duration: TimeInterval? = nil) {
        var message = "← \(endpoint)"
        if let statusCode = statusCode {
            message += " [\(statusCode)]"
        }
        if let duration = duration {
            message += " (\(String(format: "%.2f", duration * 1000))ms)"
        }
        debug(message, category: .network)
    }

    /// Log cache hit
    static func cacheHit(_ key: String) {
        debug("Cache HIT: \(key)", category: .cache)
    }

    /// Log cache miss
    static func cacheMiss(_ key: String) {
        debug("Cache MISS: \(key)", category: .cache)
    }

    // MARK: - Configuration

    /// Set minimum log level
    static func setMinimumLevel(_ level: Level) {
        minimumLevel = level
    }

    // MARK: - Private

    private static func log(_ message: String, level: Level, category: Category, file: String, function: String, line: Int) {
        #if DEBUG
        guard level >= minimumLevel else { return }

        let filename = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let formattedMessage = "[\(timestamp)] \(level.emoji) [\(category.rawValue)] \(message) (\(filename):\(line))"

        // Print to console
        print(formattedMessage)

        // Also log to unified logging system
        os_log("%{public}@", log: osLog, type: level.osLogType, formattedMessage)
        #endif
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Convenience Extensions

extension Logger {
    /// Start a performance timer
    static func startTimer() -> CFAbsoluteTime {
        CFAbsoluteTimeGetCurrent()
    }

    /// Log elapsed time since start
    static func logElapsed(since start: CFAbsoluteTime, operation: String, category: Category = .general) {
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let ms = elapsed * 1000
        if ms > 100 {
            warning("\(operation) took \(String(format: "%.2f", ms))ms (slow)", category: category)
        } else {
            debug("\(operation) completed in \(String(format: "%.2f", ms))ms", category: category)
        }
    }
}

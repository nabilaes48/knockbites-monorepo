//
//  DateFormatting.swift
//  knockbites-Bussiness-app
//
//  Created during Phase 4 cleanup - centralizes date formatting utilities
//

import Foundation

/// Centralized date formatting utilities for consistent date handling across the app
enum DateFormatting {

    // MARK: - ISO 8601 Formatters (for API/Database)

    /// Standard ISO 8601 formatter for Supabase timestamps
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// ISO 8601 formatter with fractional seconds (for high-precision timestamps)
    static let iso8601Fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Display Formatters

    /// Medium date and short time for general display
    static let displayDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Short date only for compact displays
    static let displayDateShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    /// Time only for order displays
    static let displayTimeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// Relative time for "5 minutes ago" style displays
    static let relativeTime: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    // MARK: - Chart/Analytics Formatters

    /// Day name for chart labels (Mon, Tue, etc.)
    static let chartDayName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    /// Month day for chart labels (Jan 5)
    static let chartMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    /// Hour for hourly charts (2PM)
    static let chartHour: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()

    // MARK: - Helper Methods

    /// Parse an ISO 8601 string from Supabase
    /// Tries both standard and fractional seconds formats
    static func parseISO8601(_ string: String) -> Date? {
        // Try standard format first
        if let date = iso8601.date(from: string) {
            return date
        }
        // Try with fractional seconds
        if let date = iso8601Fractional.date(from: string) {
            return date
        }
        return nil
    }

    /// Format a date for Supabase API calls
    static func toISO8601(_ date: Date) -> String {
        return iso8601.string(from: date)
    }

    /// Format a date for display to users
    static func toDisplayString(_ date: Date, includeTime: Bool = true) -> String {
        if includeTime {
            return displayDateTime.string(from: date)
        } else {
            return displayDateShort.string(from: date)
        }
    }

    /// Format as relative time ("5 min ago")
    static func toRelativeString(_ date: Date) -> String {
        return relativeTime.localizedString(for: date, relativeTo: Date())
    }
}

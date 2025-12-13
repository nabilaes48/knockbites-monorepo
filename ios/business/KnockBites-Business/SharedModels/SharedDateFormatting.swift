//
//  SharedDateFormatting.swift
//  KnockBites Connect — Shared Models
//
//  Canonical date parsing for all KnockBites Connect clients.
//  Supports both standard ISO 8601 and fractional seconds formats.
//

import Foundation

/// Shared date formatting utilities for all KnockBites Connect clients.
/// Ensures consistent date parsing across Business iOS, Customer iOS, and Website.
public enum SharedDateFormatting {

    // MARK: - Formatters

    /// Standard ISO 8601 formatter (no fractional seconds)
    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// ISO 8601 formatter with fractional seconds
    private static let iso8601Fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Date-only formatter for analytics
    private static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    // MARK: - Parsing

    /// Parse ISO 8601 date string, supporting both standard and fractional seconds formats.
    /// - Parameter string: The ISO 8601 date string to parse
    /// - Returns: The parsed Date, or nil if parsing fails
    public static func parseISO8601(_ string: String) -> Date? {
        // Try standard format first (more common)
        if let date = iso8601.date(from: string) {
            return date
        }
        // Try with fractional seconds
        if let date = iso8601Fractional.date(from: string) {
            return date
        }
        // Try date-only format
        if let date = dateOnly.date(from: string) {
            return date
        }
        return nil
    }

    /// Convert Date to ISO 8601 string (standard format, no fractional seconds)
    /// - Parameter date: The date to format
    /// - Returns: ISO 8601 formatted string
    public static func toISO8601(_ date: Date) -> String {
        return iso8601.string(from: date)
    }

    /// Convert Date to date-only string (yyyy-MM-dd)
    /// - Parameter date: The date to format
    /// - Returns: Date string in yyyy-MM-dd format
    public static func toDateOnly(_ date: Date) -> String {
        return dateOnly.string(from: date)
    }
}

// MARK: - Codable Date Wrapper

/// A property wrapper for decoding ISO 8601 dates with automatic format detection.
@propertyWrapper
public struct ISO8601Date: Codable {
    public var wrappedValue: Date?

    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = nil
        } else {
            let string = try container.decode(String.self)
            wrappedValue = SharedDateFormatting.parseISO8601(string)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let date = wrappedValue {
            try container.encode(SharedDateFormatting.toISO8601(date))
        } else {
            try container.encodeNil()
        }
    }
}

/// A property wrapper for required ISO 8601 dates (non-optional).
@propertyWrapper
public struct RequiredISO8601Date: Codable {
    public var wrappedValue: Date

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let date = SharedDateFormatting.parseISO8601(string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO 8601 date: \(string)"
            )
        }
        wrappedValue = date
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(SharedDateFormatting.toISO8601(wrappedValue))
    }
}

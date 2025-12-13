//
//  StoreCodeMapping.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/19/25.
//

import Foundation

/// Mapping of store IDs to their short codes for order numbering
struct StoreCodeMapping {

    /// Store ID to Code mapping (MATCHES PRODUCTION DATABASE)
    /// Format: [storeId: "CODE"]
    static let codes: [String: String] = [
        "1": "HM",   // Highland Mills
        "2": "MO",   // Monroe
        "3": "MW",   // Middletown
        "4": "NW",   // Newburgh
        "5": "WP",   // West Point
        "6": "SL",   // Slate Hill
        "7": "PS",   // Port Jervis
        "8": "GW",   // Goshen West
        "9": "GE",   // Goshen East
        "10": "CH",  // Chester
        "11": "WR",  // Warwick
        "12": "FL",  // Florida
        "13": "VV",  // Vails Gate
        "14": "WL",  // Walden
        "15": "ML",  // Maybrook
        "16": "CR",  // Cornwall
        "17": "NP",  // New Paltz
        "18": "KG",  // Kingston
        "19": "RH",  // Rhinebeck
        "20": "PK",  // Poughkeepsie
        "21": "FI",  // Fishkill
        "22": "BE",  // Beacon
        "23": "WP2", // Wappingers Falls
        "24": "HD",  // Hyde Park
        "25": "RD",  // Red Hook
        "26": "MI",  // Millbrook
        "27": "DV",  // Dover Plains
        "28": "AM",  // Amenia
        "29": "PW"   // Pawling
    ]

    /// Get store code for a given store ID
    /// - Parameter storeId: The store ID (as String)
    /// - Returns: Two-letter store code, or "XX" if not found
    static func getCode(for storeId: String) -> String {
        return codes[storeId] ?? "XX"
    }

    /// Get store code for a given store ID (Int version)
    /// - Parameter storeId: The store ID (as Int)
    /// - Returns: Two-letter store code, or "XX" if not found
    static func getCode(for storeId: Int) -> String {
        return getCode(for: String(storeId))
    }
}

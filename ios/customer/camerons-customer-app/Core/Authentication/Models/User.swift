//
//  User.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var firstName: String
    var lastName: String
    var phoneNumber: String?
    var profileImageURL: String?
    var rewardsPoints: Int
    var allergenPreferences: [String]
    var favoriteStoreId: String?
    var createdAt: Date

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    // Mock user for testing
    static let mock = User(
        id: "user_123",
        email: "john.doe@example.com",
        firstName: "John",
        lastName: "Doe",
        phoneNumber: "+1234567890",
        profileImageURL: nil,
        rewardsPoints: 250,
        allergenPreferences: ["peanuts", "shellfish"],
        favoriteStoreId: "store_1",
        createdAt: Date()
    )
}

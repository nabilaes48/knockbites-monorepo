//
//  Helpers.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import Foundation

// MARK: - Validation Helpers
struct ValidationHelper {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    static func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters
        return password.count >= 8
    }

    static func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^[0-9]{10,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        let digitsOnly = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return phonePredicate.evaluate(with: digitsOnly)
    }
}

// MARK: - Date Formatters
extension DateFormatter {
    static let orderDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

// MARK: - Currency Formatter
extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
}

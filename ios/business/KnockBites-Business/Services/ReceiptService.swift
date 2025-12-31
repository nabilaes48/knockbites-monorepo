//
//  ReceiptService.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/20/25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct ReceiptService {

    // MARK: - Receipt Template

    /// Generates a formatted receipt string for thermal printer (80mm paper)
    /// Enhanced with welcome message, customer ID, and coupon support
    static func generateReceipt(order: Order, store: Store, settings: ReceiptSettings? = nil, couponCode: String? = nil, couponDiscount: Double? = nil) -> String {
        let receiptSettings = settings ?? ReceiptSettings.current
        var receipt = ""

        // ========================================
        // HEADER: Store Information
        // ========================================
        receipt += centerText(store.name.uppercased(), width: 48)
        receipt += "\n"
        receipt += centerText(store.address, width: 48)
        receipt += "\n"
        receipt += centerText(store.phone, width: 48)
        receipt += "\n"
        receipt += separator()

        // ========================================
        // ORDER INFORMATION
        // ========================================
        receipt += "\n"
        receipt += boldText("ORDER #\(order.orderNumber)")
        receipt += "\n"
        receipt += "Date: \(formatDate(order.createdAt))\n"
        receipt += "Time: \(formatTime(order.createdAt))\n"
        receipt += separator()

        // ========================================
        // WELCOME MESSAGE
        // ========================================
        receipt += "\n"
        let firstName = order.customerName.components(separatedBy: " ").first ?? order.customerName
        let isRepeatCustomer = order.isRepeatCustomer ?? false

        if isRepeatCustomer {
            receipt += centerText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", width: 48)
            receipt += "\n"
            receipt += centerText("Welcome back, \(firstName)!", width: 48)
            receipt += "\n"
            receipt += centerText("We're delighted to serve you again.", width: 48)
            receipt += "\n"
            receipt += centerText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", width: 48)
        } else {
            receipt += centerText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", width: 48)
            receipt += "\n"
            receipt += centerText("Welcome, \(firstName)!", width: 48)
            receipt += "\n"
            receipt += centerText("Thank you for choosing \(store.name).", width: 48)
            receipt += "\n"
            receipt += centerText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", width: 48)
        }
        receipt += "\n"

        // ========================================
        // CUSTOMER INFORMATION
        // ========================================
        receipt += "\n"
        receipt += "Customer: \(order.customerName)\n"

        // Customer ID (first 8 chars of UUID)
        if let customerId = order.customerId, !customerId.isEmpty {
            let shortId = String(customerId.prefix(8)).uppercased()
            receipt += "Customer ID: \(shortId)\n"
        }

        if let phone = order.customerPhone, !phone.isEmpty {
            receipt += "Phone: \(phone)\n"
        }

        receipt += separator()

        // ========================================
        // ORDER ITEMS
        // ========================================
        receipt += "\n"
        receipt += boldText("YOUR ORDER")
        receipt += "\n\n"

        var subtotal: Double = 0

        for item in order.items {
            // Item name and price
            let itemLine = formatItemLine(item.menuItem.name, price: item.menuItem.price, quantity: item.quantity)
            receipt += itemLine
            receipt += "\n"

            // Customizations (from customizationSummary)
            if !item.customizationSummary.isEmpty {
                receipt += "  • \(item.customizationSummary)\n"
            }

            // Special instructions
            if !item.specialInstructions.isEmpty {
                receipt += "  Note: \(item.specialInstructions)\n"
            }

            receipt += "\n"
            subtotal += item.totalPrice
        }

        receipt += separator()

        // ========================================
        // PRICING
        // ========================================
        receipt += "\n"
        receipt += formatPriceLine("Subtotal:", price: subtotal)
        receipt += "\n"

        let tax = subtotal * 0.08 // 8% tax (adjust as needed)
        receipt += formatPriceLine("Tax (8%):", price: tax)
        receipt += "\n"

        let total = subtotal + tax
        receipt += boldLine()
        receipt += boldText(formatPriceLine("TOTAL:", price: total))
        receipt += boldLine()
        receipt += "\n"

        // ========================================
        // COUPON (if available)
        // ========================================
        if let code = couponCode, !code.isEmpty {
            receipt += "\n"
            receipt += centerText("┌────────────────────────────────┐", width: 48)
            receipt += "\n"
            receipt += centerText("│    🎉 SPECIAL OFFER 🎉         │", width: 48)
            receipt += "\n"
            receipt += centerText("├────────────────────────────────┤", width: 48)
            receipt += "\n"
            receipt += centerText("│  Use code: \(code.padding(toLength: 18, withPad: " ", startingAt: 0)) │", width: 48)
            receipt += "\n"

            if let discount = couponDiscount {
                let discountText = String(format: "Save $%.2f on next order!", discount)
                receipt += centerText("│  \(discountText.padding(toLength: 30, withPad: " ", startingAt: 0))│", width: 48)
            } else {
                receipt += centerText("│  Save 10% on your next order! │", width: 48)
            }
            receipt += "\n"
            receipt += centerText("└────────────────────────────────┘", width: 48)
            receipt += "\n"
            receipt += separator()
        }

        // ========================================
        // MARKETING CONTENT (Based on Settings)
        // ========================================
        if receiptSettings.includeMarketingContent {
            // LOYALTY PROGRAM PROMOTION
            if receiptSettings.includeLoyaltyPromo {
                receipt += "\n"
                receipt += centerText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", width: 48)
                receipt += "\n"
                receipt += centerText("🎉 JOIN OUR REWARDS PROGRAM! 🎉", width: 48)
                receipt += "\n"
                receipt += centerText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", width: 48)
                receipt += "\n\n"
                receipt += centerText("Earn points with every purchase!", width: 48)
                receipt += "\n"
                receipt += centerText("Get FREE food & exclusive offers", width: 48)
                receipt += "\n\n"
                receipt += centerText("Download our app or ask staff", width: 48)
                receipt += "\n"
                receipt += centerText("to sign up today!", width: 48)
                receipt += "\n"
                receipt += separator()
            }

            // SOCIAL MEDIA & WEBSITE
            if receiptSettings.includeSocialMedia {
                receipt += "\n"
                receipt += centerText("FOLLOW US FOR DEALS!", width: 48)
                receipt += "\n"
                receipt += centerText("Instagram: \(receiptSettings.instagram)", width: 48)
                receipt += "\n"
                receipt += centerText("Facebook: \(receiptSettings.facebook)", width: 48)
                receipt += "\n"
                receipt += centerText("Web: \(receiptSettings.website)", width: 48)
                receipt += "\n"
                receipt += separator()
            }

            // REFERRAL PROGRAM
            if receiptSettings.includeReferralPromo {
                receipt += "\n"
                receipt += centerText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", width: 48)
                receipt += "\n"
                receipt += centerText("REFER A FRIEND!", width: 48)
                receipt += "\n"
                receipt += centerText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", width: 48)
                receipt += "\n\n"
                receipt += centerText("You & your friend both get", width: 48)
                receipt += "\n"
                receipt += centerText("$5 OFF your next order!", width: 48)
                receipt += "\n\n"
                receipt += centerText("Ask for a referral card!", width: 48)
                receipt += "\n"
                receipt += separator()
            }

            // FEEDBACK PROMPT
            if receiptSettings.includeReviewRequest {
                receipt += "\n"
                receipt += centerText("How did we do?", width: 48)
                receipt += "\n"
                receipt += centerText("Leave us a review on Google!", width: 48)
                receipt += "\n"
                receipt += centerText("Your feedback helps us improve", width: 48)
                receipt += "\n"
                receipt += separator()
            }
        }

        // ========================================
        // THANK YOU MESSAGE
        // ========================================
        receipt += "\n"
        receipt += centerText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", width: 48)
        receipt += "\n"
        receipt += centerText("THANK YOU!", width: 48)
        receipt += "\n"
        receipt += centerText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", width: 48)
        receipt += "\n\n"
        receipt += centerText("See you soon!", width: 48)
        receipt += "\n"
        receipt += centerText("Enjoy your food!", width: 48)
        receipt += "\n\n"
        receipt += centerText("❤️", width: 48)
        receipt += "\n\n\n"

        return receipt
    }

    // MARK: - Formatting Helpers

    private static func separator() -> String {
        return "\n" + String(repeating: "-", count: 48) + "\n"
    }

    private static func boldLine() -> String {
        return "\n" + String(repeating: "=", count: 48) + "\n"
    }

    private static func centerText(_ text: String, width: Int) -> String {
        let padding = max(0, width - text.count) / 2
        return String(repeating: " ", count: padding) + text
    }

    private static func boldText(_ text: String) -> String {
        // ESC E for bold on thermal printers
        return "\u{1B}E" + text + "\u{1B}F"
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func formatItemLine(_ name: String, price: Double, quantity: Int) -> String {
        let qtyPrice = String(format: "%dx $%.2f", quantity, price)
        let maxNameWidth = 48 - qtyPrice.count - 1

        var itemName = name
        if itemName.count > maxNameWidth {
            itemName = String(itemName.prefix(maxNameWidth - 3)) + "..."
        }

        let padding = max(1, 48 - itemName.count - qtyPrice.count)
        return itemName + String(repeating: " ", count: padding) + qtyPrice
    }

    private static func formatPriceLine(_ label: String, price: Double) -> String {
        let priceStr = String(format: "$%.2f", price)
        let padding = max(1, 48 - label.count - priceStr.count)
        return label + String(repeating: " ", count: padding) + priceStr
    }

    // MARK: - Print Receipt

    /// Sends receipt to thermal printer (requires printer SDK integration)
    static func printReceipt(order: Order, store: Store, settings: ReceiptSettings? = nil) {
        let receiptText = generateReceipt(order: order, store: store, settings: settings)

        // TODO: Integration with thermal printer SDK
        // Examples:
        // - Star Micronics SDK
        // - Epson ePOS SDK
        // - Brother SDK

        print("📄 RECEIPT PREVIEW:")
        print("================================")
        print(receiptText)
        print("================================")

        // For now, save to clipboard for testing
        #if canImport(UIKit)
        UIPasteboard.general.string = receiptText
        print("✅ Receipt copied to clipboard")
        #endif
    }
}

// MARK: - Extensions

extension Store {
    var website: String? {
        // Add website field to Store model or return default
        return "www.knockbitesdeli.com"
    }
}

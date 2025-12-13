//
//  Models.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import Foundation
import CoreLocation

// MARK: - Store
struct Store: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let address: String
    let phone: String
    let latitude: Double
    let longitude: Double
    let openTime: String
    let closeTime: String
    let daysOpen: [Int]
    var isActive: Bool
    let imageURL: String?

    var isOpen: Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now) - 1

        guard daysOpen.contains(weekday) else { return false }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let openDate = formatter.date(from: openTime),
              let closeDate = formatter.date(from: closeTime) else {
            return false
        }

        let currentTime = formatter.string(from: now)
        guard let currentDate = formatter.date(from: currentTime) else { return false }

        return currentDate >= openDate && currentDate <= closeDate
    }
}

// MARK: - Business User
struct BusinessUser: Identifiable, Codable {
    let id: String
    let email: String
    let fullName: String
    let role: UserRole
    let storeId: String

    enum UserRole: String, Codable {
        case admin = "Admin"
        case manager = "Manager"
        case staff = "Staff"
    }
}

// MARK: - Category
struct Category: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let icon: String
    let sortOrder: Int
}

// MARK: - MenuItem
struct MenuItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    var price: Double
    let categoryId: String
    let imageURL: String
    var isAvailable: Bool
    let dietaryInfo: [DietaryTag]
    let customizationGroups: [CustomizationGroup]
    let calories: Int?
    let prepTime: Int

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }
}

enum DietaryTag: String, Codable, Hashable, CaseIterable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten Free"
    case dairyFree = "Dairy Free"
    case nutFree = "Nut Free"
    case spicy = "Spicy"
    case keto = "Keto"

    var icon: String {
        switch self {
        case .vegetarian: return "leaf.fill"
        case .vegan: return "leaf.circle.fill"
        case .glutenFree: return "g.circle.fill"
        case .dairyFree: return "drop.fill"
        case .nutFree: return "n.circle.fill"
        case .spicy: return "flame.fill"
        case .keto: return "k.circle.fill"
        }
    }
}

// MARK: - Customization
struct CustomizationGroup: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let isRequired: Bool
    let allowMultiple: Bool
    let options: [CustomizationOption]
}

struct CustomizationOption: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let priceModifier: Double
    let isDefault: Bool

    var formattedPrice: String {
        if priceModifier == 0 {
            return "No charge"
        } else if priceModifier > 0 {
            return String(format: "+$%.2f", priceModifier)
        } else {
            return String(format: "-$%.2f", abs(priceModifier))
        }
    }
}

// MARK: - Cart & Order Items
struct CartItem: Identifiable, Codable {
    let id: String
    let menuItem: MenuItem
    var quantity: Int
    let selectedOptions: [String: [String]]
    let specialInstructions: String

    var totalPrice: Double {
        var price = menuItem.price * Double(quantity)

        for (groupId, optionIds) in selectedOptions {
            if let group = menuItem.customizationGroups.first(where: { $0.id == groupId }) {
                for optionId in optionIds {
                    if let option = group.options.first(where: { $0.id == optionId }) {
                        price += option.priceModifier * Double(quantity)
                    }
                }
            }
        }

        return price
    }

    var customizationSummary: String {
        var summary: [String] = []

        for (groupId, optionIds) in selectedOptions {
            if let group = menuItem.customizationGroups.first(where: { $0.id == groupId }) {
                let optionNames = optionIds.compactMap { optionId in
                    group.options.first(where: { $0.id == optionId })?.name
                }
                if !optionNames.isEmpty {
                    summary.append("\(group.name): \(optionNames.joined(separator: ", "))")
                }
            }
        }

        return summary.joined(separator: "\n")
    }
}

// MARK: - Order
struct Order: Identifiable, Codable {
    let id: String
    let orderNumber: String
    let userId: String
    let customerName: String
    let storeId: String
    let items: [CartItem]
    let subtotal: Double
    let tax: Double
    let total: Double
    var status: OrderStatus
    let orderType: OrderType
    let createdAt: Date
    var estimatedReadyTime: Date?
    var completedAt: Date?

    var timeElapsed: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    var timeElapsedString: String {
        let minutes = Int(timeElapsed / 60)
        return "\(minutes) min ago"
    }

    var formattedSubtotal: String {
        String(format: "$%.2f", subtotal)
    }

    var formattedTax: String {
        String(format: "$%.2f", tax)
    }

    var formattedTotal: String {
        String(format: "$%.2f", total)
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case received = "pending"
    case preparing = "preparing"
    case ready = "ready"
    case completed = "completed"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .received: return "Received"
        case .preparing: return "Preparing"
        case .ready: return "Ready"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var icon: String {
        switch self {
        case .received: return "checkmark.circle.fill"
        case .preparing: return "flame.fill"
        case .ready: return "bag.fill"
        case .completed: return "hand.thumbsup.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .received: return "blue"
        case .preparing: return "orange"
        case .ready: return "green"
        case .completed: return "gray"
        case .cancelled: return "red"
        }
    }

    var nextStatus: OrderStatus? {
        switch self {
        case .received: return .preparing
        case .preparing: return .ready
        case .ready: return .completed
        case .completed, .cancelled: return nil
        }
    }

    var actionButtonTitle: String? {
        switch self {
        case .received: return "Start Prep"
        case .preparing: return "Mark Ready"
        case .ready: return "Complete Order"
        case .completed, .cancelled: return nil
        }
    }
}

enum OrderType: String, Codable, CaseIterable {
    case pickup = "Pickup"
    case delivery = "Delivery"
    case dineIn = "Dine In"

    var icon: String {
        switch self {
        case .pickup: return "bag.fill"
        case .delivery: return "car.fill"
        case .dineIn: return "fork.knife"
        }
    }
}

// MARK: - Analytics
struct DailySales: Identifiable, Codable {
    let id: String
    let date: Date
    let totalOrders: Int
    let totalRevenue: Double
    let averageOrderValue: Double

    var formattedRevenue: String {
        String(format: "$%.2f", totalRevenue)
    }

    var formattedAverageOrder: String {
        String(format: "$%.2f", averageOrderValue)
    }
}

struct PopularItem: Identifiable {
    let id: String
    let menuItem: MenuItem
    let orderCount: Int
    let revenue: Double

    var formattedRevenue: String {
        String(format: "$%.2f", revenue)
    }
}

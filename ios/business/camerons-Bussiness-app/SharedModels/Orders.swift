//
//  Orders.swift
//  KnockBites Connect — Shared Models
//
//  Canonical order models shared across Business iOS, Customer iOS, and Website.
//  All field names match the Supabase contract exactly.
//

import Foundation

// MARK: - Order Status

/// Canonical order status values used across all clients.
public enum SharedOrderStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case received = "received"
    case acknowledged = "acknowledged"
    case preparing = "preparing"
    case ready = "ready"
    case completed = "completed"
    case cancelled = "cancelled"
    case scheduled = "scheduled"

    /// User-friendly display name
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .received: return "Received"
        case .acknowledged: return "Acknowledged"
        case .preparing: return "Preparing"
        case .ready: return "Ready"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .scheduled: return "Scheduled"
        }
    }
}

// MARK: - Order Type

/// Canonical order type values.
public enum SharedOrderType: String, Codable, CaseIterable {
    case pickup = "pickup"
    case delivery = "delivery"
    case dineIn = "dine-in"

    /// User-friendly display name
    public var displayName: String {
        switch self {
        case .pickup: return "Pickup"
        case .delivery: return "Delivery"
        case .dineIn: return "Dine-In"
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        // Handle both "dine-in" and "dine_in" formats
        switch value.lowercased() {
        case "pickup": self = .pickup
        case "delivery": self = .delivery
        case "dine-in", "dine_in", "dinein": self = .dineIn
        default: self = .pickup  // Default fallback
        }
    }
}

// MARK: - Shared Order Model

/// Canonical order model matching the Supabase `orders` table.
/// Supports field aliases for backwards compatibility.
public struct SharedOrder: Codable, Identifiable {
    public let id: String
    public let orderNumber: String
    public let userId: String?
    public let customerId: String?
    public let customerName: String
    public let customerEmail: String?
    public let customerPhone: String?
    public let storeId: Int
    public let orderType: SharedOrderType?
    public let status: SharedOrderStatus
    public let subtotal: Double
    public let tax: Double
    public let tip: Double?
    public let total: Double
    public let specialInstructions: String?
    public let priority: String?
    public let isRepeatCustomer: Bool?
    public let createdAt: Date
    public let estimatedReadyAt: Date?
    public let completedAt: Date?
    public let updatedAt: Date?
    public let items: [SharedOrderItem]?

    // MARK: - CodingKeys with aliases

    enum CodingKeys: String, CodingKey {
        case id
        case orderNumber = "order_number"
        case userId = "user_id"
        case customerId = "customer_id"
        case customerName = "customer_name"
        case customerEmail = "customer_email"
        case customerPhone = "customer_phone"
        case storeId = "store_id"
        case orderType = "order_type"
        case status
        case subtotal, tax, tip, total
        case specialInstructions = "special_instructions"
        case priority
        case isRepeatCustomer = "is_repeat_customer"
        case createdAt = "created_at"
        case estimatedReadyAt = "estimated_ready_at"
        case completedAt = "completed_at"
        case updatedAt = "updated_at"
        case items = "order_items"
    }

    // MARK: - Custom Decoding

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        orderNumber = try container.decode(String.self, forKey: .orderNumber)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        customerId = try container.decodeIfPresent(String.self, forKey: .customerId)
        customerName = try container.decodeIfPresent(String.self, forKey: .customerName) ?? "Customer"
        customerEmail = try container.decodeIfPresent(String.self, forKey: .customerEmail)
        customerPhone = try container.decodeIfPresent(String.self, forKey: .customerPhone)
        storeId = try container.decode(Int.self, forKey: .storeId)
        orderType = try container.decodeIfPresent(SharedOrderType.self, forKey: .orderType)
        status = try container.decodeIfPresent(SharedOrderStatus.self, forKey: .status) ?? .pending
        subtotal = try container.decode(Double.self, forKey: .subtotal)
        tax = try container.decode(Double.self, forKey: .tax)
        tip = try container.decodeIfPresent(Double.self, forKey: .tip)
        total = try container.decode(Double.self, forKey: .total)
        specialInstructions = try container.decodeIfPresent(String.self, forKey: .specialInstructions)
        priority = try container.decodeIfPresent(String.self, forKey: .priority)
        isRepeatCustomer = try container.decodeIfPresent(Bool.self, forKey: .isRepeatCustomer)
        items = try container.decodeIfPresent([SharedOrderItem].self, forKey: .items)

        // Parse dates with SharedDateFormatting
        if let createdAtStr = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = SharedDateFormatting.parseISO8601(createdAtStr) ?? Date()
        } else {
            createdAt = Date()
        }

        if let estimatedStr = try container.decodeIfPresent(String.self, forKey: .estimatedReadyAt) {
            estimatedReadyAt = SharedDateFormatting.parseISO8601(estimatedStr)
        } else {
            estimatedReadyAt = nil
        }

        if let completedStr = try container.decodeIfPresent(String.self, forKey: .completedAt) {
            completedAt = SharedDateFormatting.parseISO8601(completedStr)
        } else {
            completedAt = nil
        }

        if let updatedStr = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = SharedDateFormatting.parseISO8601(updatedStr)
        } else {
            updatedAt = nil
        }
    }

    // MARK: - Initializer

    public init(
        id: String,
        orderNumber: String,
        userId: String?,
        customerId: String?,
        customerName: String,
        customerEmail: String?,
        customerPhone: String?,
        storeId: Int,
        orderType: SharedOrderType?,
        status: SharedOrderStatus,
        subtotal: Double,
        tax: Double,
        tip: Double?,
        total: Double,
        specialInstructions: String?,
        priority: String?,
        isRepeatCustomer: Bool?,
        createdAt: Date,
        estimatedReadyAt: Date?,
        completedAt: Date?,
        updatedAt: Date?,
        items: [SharedOrderItem]?
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.userId = userId
        self.customerId = customerId
        self.customerName = customerName
        self.customerEmail = customerEmail
        self.customerPhone = customerPhone
        self.storeId = storeId
        self.orderType = orderType
        self.status = status
        self.subtotal = subtotal
        self.tax = tax
        self.tip = tip
        self.total = total
        self.specialInstructions = specialInstructions
        self.priority = priority
        self.isRepeatCustomer = isRepeatCustomer
        self.createdAt = createdAt
        self.estimatedReadyAt = estimatedReadyAt
        self.completedAt = completedAt
        self.updatedAt = updatedAt
        self.items = items
    }
}

// MARK: - Shared Order Item Model

/// Canonical order item model matching the Supabase `order_items` table.
public struct SharedOrderItem: Codable, Identifiable {
    public let id: Int
    public let orderId: String?
    public let menuItemId: Int?
    public let itemName: String
    public let itemPrice: Double
    public let quantity: Int
    public let subtotal: Double
    public let specialInstructions: String?  // iOS uses this
    public let notes: String?                 // Website uses this
    public let customizations: CustomizationsValue?
    public let selectedOptions: SelectedOptionsValue?

    // Computed property to get instructions from either field
    public var instructions: String? {
        specialInstructions ?? notes
    }

    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case menuItemId = "menu_item_id"
        case itemName = "item_name"
        case itemPrice = "item_price"
        case quantity
        case subtotal
        case specialInstructions = "special_instructions"
        case notes
        case customizations
        case selectedOptions = "selected_options"
    }

    // MARK: - Flexible Customizations Type

    public enum CustomizationsValue: Codable {
        case stringArray([String])
        case string(String)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let array = try? container.decode([String].self) {
                self = .stringArray(array)
            } else if let string = try? container.decode(String.self) {
                self = .string(string)
            } else {
                self = .stringArray([])
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .stringArray(let array):
                try container.encode(array)
            case .string(let string):
                try container.encode(string)
            }
        }

        public var asArray: [String] {
            switch self {
            case .stringArray(let array): return array
            case .string(let string): return string.isEmpty ? [] : [string]
            }
        }
    }

    // MARK: - Flexible Selected Options Type

    public enum SelectedOptionsValue: Codable {
        case dictionary([String: [String]])
        case array([String])

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let dict = try? container.decode([String: [String]].self) {
                self = .dictionary(dict)
            } else if let array = try? container.decode([String].self) {
                self = .array(array)
            } else {
                self = .dictionary([:])
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .dictionary(let dict):
                try container.encode(dict)
            case .array(let array):
                try container.encode(array)
            }
        }

        public var asDictionary: [String: [String]] {
            switch self {
            case .dictionary(let dict): return dict
            case .array(let array): return ["options": array]
            }
        }
    }

    // MARK: - Initializer

    public init(
        id: Int,
        orderId: String?,
        menuItemId: Int?,
        itemName: String,
        itemPrice: Double,
        quantity: Int,
        subtotal: Double,
        specialInstructions: String?,
        notes: String?,
        customizations: CustomizationsValue?,
        selectedOptions: SelectedOptionsValue?
    ) {
        self.id = id
        self.orderId = orderId
        self.menuItemId = menuItemId
        self.itemName = itemName
        self.itemPrice = itemPrice
        self.quantity = quantity
        self.subtotal = subtotal
        self.specialInstructions = specialInstructions
        self.notes = notes
        self.customizations = customizations
        self.selectedOptions = selectedOptions
    }
}

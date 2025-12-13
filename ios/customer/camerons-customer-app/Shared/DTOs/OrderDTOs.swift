//
//  OrderDTOs.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 12/2/25.
//

import Foundation

struct OrderDTO: Codable {
    let id: String
    let order_number: String
    let store_id: Int
    let user_id: String?
    let customer_name: String?
    let customer_phone: String?
    let order_type: String
    let status: String
    let subtotal: Double
    let tax: Double
    let total: Double
    let created_at: String
    let estimated_ready_at: String?
}

struct OrderItemDTO: Codable {
    let id: Int
    let order_id: String
    let menu_item_id: Int
    let item_name: String
    let item_price: Double
    let quantity: Int
    let subtotal: Double
    let special_instructions: String?
    let selected_options: [String:[String]]?
    let customizations: [String]?
}

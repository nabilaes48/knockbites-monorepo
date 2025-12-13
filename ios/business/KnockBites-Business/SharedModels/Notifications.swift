//
//  Notifications.swift
//  KnockBites Connect — Shared Models
//
//  Canonical push notification models shared across Business iOS, Customer iOS, and Website.
//

import Foundation

// MARK: - Notification Status

/// Canonical notification status values.
public enum SharedNotificationStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case scheduled = "scheduled"
    case sending = "sending"
    case sent = "sent"
    case failed = "failed"

    public var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .scheduled: return "Scheduled"
        case .sending: return "Sending"
        case .sent: return "Sent"
        case .failed: return "Failed"
        }
    }
}

// MARK: - Shared Push Notification

/// Canonical push notification model matching the Supabase `push_notifications` table.
public struct SharedPushNotification: Codable, Identifiable {
    public let id: Int
    public let storeId: Int?
    public let title: String
    public let body: String
    public let imageUrl: String?
    public let actionUrl: String?
    public let targetSegment: String?
    public let targetCustomerIds: [Int]?
    public let targetTierIds: [Int]?
    public let scheduledFor: Date?
    public let sendImmediately: Bool
    public let status: SharedNotificationStatus?
    public let sentAt: Date?
    public let recipientsCount: Int?
    public let deliveredCount: Int?
    public let openedCount: Int?
    public let clickedCount: Int?
    public let createdAt: Date?
    public let createdBy: String?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case title, body
        case imageUrl = "image_url"
        case actionUrl = "action_url"
        case targetSegment = "target_segment"
        case targetCustomerIds = "target_customer_ids"
        case targetTierIds = "target_tier_ids"
        case scheduledFor = "scheduled_for"
        case sendImmediately = "send_immediately"
        case status
        case sentAt = "sent_at"
        case recipientsCount = "recipients_count"
        case deliveredCount = "delivered_count"
        case openedCount = "opened_count"
        case clickedCount = "clicked_count"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        storeId = try container.decodeIfPresent(Int.self, forKey: .storeId)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        actionUrl = try container.decodeIfPresent(String.self, forKey: .actionUrl)
        targetSegment = try container.decodeIfPresent(String.self, forKey: .targetSegment)
        targetCustomerIds = try container.decodeIfPresent([Int].self, forKey: .targetCustomerIds)
        targetTierIds = try container.decodeIfPresent([Int].self, forKey: .targetTierIds)
        sendImmediately = try container.decodeIfPresent(Bool.self, forKey: .sendImmediately) ?? true
        status = try container.decodeIfPresent(SharedNotificationStatus.self, forKey: .status)
        recipientsCount = try container.decodeIfPresent(Int.self, forKey: .recipientsCount)
        deliveredCount = try container.decodeIfPresent(Int.self, forKey: .deliveredCount)
        openedCount = try container.decodeIfPresent(Int.self, forKey: .openedCount)
        clickedCount = try container.decodeIfPresent(Int.self, forKey: .clickedCount)
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)

        // Date parsing
        if let scheduledStr = try container.decodeIfPresent(String.self, forKey: .scheduledFor) {
            scheduledFor = SharedDateFormatting.parseISO8601(scheduledStr)
        } else {
            scheduledFor = nil
        }

        if let sentStr = try container.decodeIfPresent(String.self, forKey: .sentAt) {
            sentAt = SharedDateFormatting.parseISO8601(sentStr)
        } else {
            sentAt = nil
        }

        if let createdStr = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = SharedDateFormatting.parseISO8601(createdStr)
        } else {
            createdAt = nil
        }

        if let updatedStr = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = SharedDateFormatting.parseISO8601(updatedStr)
        } else {
            updatedAt = nil
        }
    }

    public init(
        id: Int,
        storeId: Int?,
        title: String,
        body: String,
        imageUrl: String?,
        actionUrl: String?,
        targetSegment: String?,
        targetCustomerIds: [Int]?,
        targetTierIds: [Int]?,
        scheduledFor: Date?,
        sendImmediately: Bool,
        status: SharedNotificationStatus?,
        sentAt: Date?,
        recipientsCount: Int?,
        deliveredCount: Int?,
        openedCount: Int?,
        clickedCount: Int?,
        createdAt: Date?,
        createdBy: String?,
        updatedAt: Date?
    ) {
        self.id = id
        self.storeId = storeId
        self.title = title
        self.body = body
        self.imageUrl = imageUrl
        self.actionUrl = actionUrl
        self.targetSegment = targetSegment
        self.targetCustomerIds = targetCustomerIds
        self.targetTierIds = targetTierIds
        self.scheduledFor = scheduledFor
        self.sendImmediately = sendImmediately
        self.status = status
        self.sentAt = sentAt
        self.recipientsCount = recipientsCount
        self.deliveredCount = deliveredCount
        self.openedCount = openedCount
        self.clickedCount = clickedCount
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.updatedAt = updatedAt
    }
}

// MARK: - Create Notification Request

/// Request model for creating a new push notification.
public struct CreateNotificationRequest: Encodable {
    public let storeId: Int
    public let title: String
    public let body: String
    public let imageUrl: String?
    public let actionUrl: String?
    public let targetSegment: String?
    public let targetCustomerIds: [Int]?
    public let targetTierIds: [Int]?
    public let scheduledFor: String?
    public let sendImmediately: Bool

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case title, body
        case imageUrl = "image_url"
        case actionUrl = "action_url"
        case targetSegment = "target_segment"
        case targetCustomerIds = "target_customer_ids"
        case targetTierIds = "target_tier_ids"
        case scheduledFor = "scheduled_for"
        case sendImmediately = "send_immediately"
    }

    public init(
        storeId: Int,
        title: String,
        body: String,
        imageUrl: String? = nil,
        actionUrl: String? = nil,
        targetSegment: String? = nil,
        targetCustomerIds: [Int]? = nil,
        targetTierIds: [Int]? = nil,
        scheduledFor: Date? = nil,
        sendImmediately: Bool = true
    ) {
        self.storeId = storeId
        self.title = title
        self.body = body
        self.imageUrl = imageUrl
        self.actionUrl = actionUrl
        self.targetSegment = targetSegment
        self.targetCustomerIds = targetCustomerIds
        self.targetTierIds = targetTierIds
        self.scheduledFor = scheduledFor.map { SharedDateFormatting.toISO8601($0) }
        self.sendImmediately = sendImmediately
    }
}

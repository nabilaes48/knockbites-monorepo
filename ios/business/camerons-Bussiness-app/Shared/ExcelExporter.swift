//
//  ExcelExporter.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import Foundation

/// CSV/Excel export engine for tabular data
@MainActor
class ExcelExporter {

    // MARK: - Public Export Methods

    /// Export customer loyalty data to CSV
    func exportLoyaltyDataToCSV(
        customers: [CustomerLoyaltyListItem],
        dateRange: DateRange? = nil
    ) async throws -> URL {
        var rows: [[String]] = []

        // Headers
        let headers = ["Customer ID", "Name", "Email", "Phone", "Tier", "Points", "Joined Date"]
        rows.append(headers)

        // Data rows
        for customer in customers {
            let row = [
                "\(customer.id)",
                customer.name,
                customer.email ?? "",
                customer.phone ?? "",
                customer.tierName,
                "\(customer.points)",
                "" // Joined date not available in current model
            ]
            rows.append(row)
        }

        let filename = "Loyalty_Customers_\(Date().timeIntervalSince1970)"
        return try generateCSV(rows: rows, filename: filename)
    }

    /// Export transaction history to CSV
    func exportTransactionHistoryToCSV(
        transactions: [LoyaltyTransactionExport],
        dateRange: DateRange
    ) async throws -> URL {
        var rows: [[String]] = []

        // Headers
        let headers = [
            "Transaction ID",
            "Customer Name",
            "Type",
            "Points",
            "Order ID",
            "Description",
            "Date"
        ]
        rows.append(headers)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        // Data rows
        for transaction in transactions {
            let row = [
                "\(transaction.id)",
                transaction.customerName,
                transaction.type,
                "\(transaction.points)",
                transaction.orderId ?? "",
                transaction.description,
                dateFormatter.string(from: transaction.createdAt)
            ]
            rows.append(row)
        }

        let filename = "Loyalty_Transactions_\(dateRange.formatted)"
        return try generateCSV(rows: rows, filename: filename)
    }

    /// Export campaign performance metrics to CSV
    func exportCampaignMetricsToCSV(
        campaigns: [CampaignExport],
        period: AnalyticsPeriod
    ) async throws -> URL {
        var rows: [[String]] = []

        // Headers
        let headers = [
            "Campaign Name",
            "Type",
            "Status",
            "Start Date",
            "End Date",
            "Target Segment",
            "Sent/Scheduled",
            "Opened",
            "Clicked",
            "Converted",
            "Open Rate",
            "Click Rate",
            "Conversion Rate",
            "ROI %"
        ]
        rows.append(headers)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        // Data rows
        for campaign in campaigns {
            let openRate = campaign.sent > 0 ? Double(campaign.opened) / Double(campaign.sent) * 100 : 0
            let clickRate = campaign.sent > 0 ? Double(campaign.clicked) / Double(campaign.sent) * 100 : 0
            let conversionRate = campaign.sent > 0 ? Double(campaign.converted) / Double(campaign.sent) * 100 : 0

            let row = [
                campaign.name,
                campaign.type,
                campaign.status,
                campaign.startDate.map { dateFormatter.string(from: $0) } ?? "",
                campaign.endDate.map { dateFormatter.string(from: $0) } ?? "",
                campaign.targetSegment ?? "All Customers",
                "\(campaign.sent)",
                "\(campaign.opened)",
                "\(campaign.clicked)",
                "\(campaign.converted)",
                String(format: "%.1f%%", openRate),
                String(format: "%.1f%%", clickRate),
                String(format: "%.1f%%", conversionRate),
                String(format: "%.1f%%", campaign.roi)
            ]
            rows.append(row)
        }

        let filename = "Campaign_Performance_\(period.rawValue)_\(Date().timeIntervalSince1970)"
        return try generateCSV(rows: rows, filename: filename)
    }

    /// Export marketing analytics summary to CSV
    func exportMarketingAnalyticsToCSV(
        period: AnalyticsPeriod,
        metrics: MarketingMetrics
    ) async throws -> URL {
        var rows: [[String]] = []

        // Headers
        rows.append(["Metric", "Value", "Change"])

        // Data rows
        rows.append([
            "Notifications Sent",
            "\(metrics.notificationsSent)",
            String(format: "%+.1f%%", metrics.notificationsChange)
        ])
        rows.append([
            "Coupons Redeemed",
            "\(metrics.couponsRedeemed)",
            String(format: "%+.1f%%", metrics.couponsChange)
        ])
        rows.append([
            "Loyalty Members",
            "\(metrics.loyaltyMembers)",
            String(format: "%+.1f%%", metrics.loyaltyMembersChange)
        ])
        rows.append([
            "Points Awarded",
            "\(metrics.pointsAwarded)",
            ""
        ])
        rows.append([
            "Campaign ROI",
            String(format: "%.1f%%", metrics.campaignROI),
            ""
        ])
        rows.append([
            "Average LTV",
            String(format: "$%.2f", metrics.averageLTV),
            ""
        ])
        rows.append([
            "Acquisition Cost",
            String(format: "$%.2f", metrics.acquisitionCost),
            ""
        ])

        let filename = "Marketing_Analytics_\(period.rawValue)_\(Date().timeIntervalSince1970)"
        return try generateCSV(rows: rows, filename: filename)
    }

    /// Export rewards catalog to CSV
    func exportRewardsCatalogToCSV(
        rewards: [LoyaltyReward]
    ) async throws -> URL {
        var rows: [[String]] = []

        // Headers
        let headers = [
            "Reward ID",
            "Name",
            "Description",
            "Points Cost",
            "Category",
            "Stock Available",
            "Redemption Count",
            "Is Active",
            "Created Date"
        ]
        rows.append(headers)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        // Data rows
        for reward in rewards {
            let row: [String] = [
                "\(reward.id)",
                reward.name,
                reward.description ?? "",
                "\(reward.pointsCost)",
                reward.rewardType.displayName,
                reward.stockQuantity.map { "\($0)" } ?? "Unlimited",
                "\(reward.redemptionCount)",
                reward.isActive ? "Yes" : "No",
                dateFormatter.string(from: reward.createdAt)
            ]
            rows.append(row)
        }

        let filename = "Rewards_Catalog_\(Date().timeIntervalSince1970)"
        return try generateCSV(rows: rows, filename: filename)
    }

    /// Export sales analytics to CSV
    func exportSalesAnalyticsToCSV(
        period: AnalyticsPeriod,
        salesData: [SalesDataExport]
    ) async throws -> URL {
        var rows: [[String]] = []

        // Headers
        let headers = [
            "Date",
            "Orders",
            "Revenue",
            "Average Order Value",
            "New Customers",
            "Returning Customers"
        ]
        rows.append(headers)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        // Data rows
        for data in salesData {
            let avgOrderValue = data.orders > 0 ? data.revenue / Double(data.orders) : 0

            let row = [
                dateFormatter.string(from: data.date),
                "\(data.orders)",
                String(format: "$%.2f", data.revenue),
                String(format: "$%.2f", avgOrderValue),
                "\(data.newCustomers)",
                "\(data.returningCustomers)"
            ]
            rows.append(row)
        }

        let filename = "Sales_Analytics_\(period.rawValue)_\(Date().timeIntervalSince1970)"
        return try generateCSV(rows: rows, filename: filename)
    }

    // MARK: - Core CSV Generation

    private func generateCSV(rows: [[String]], filename: String) throws -> URL {
        var csvString = ""

        for row in rows {
            let escapedRow = row.map { escapeCSVField($0) }
            csvString += escapedRow.joined(separator: ",") + "\n"
        }

        // Save to temporary directory
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(filename).csv")

        guard let data = csvString.data(using: .utf8) else {
            throw ExportError.generationFailed
        }

        try data.write(to: tempURL)
        return tempURL
    }

    /// Escape special characters in CSV fields
    private func escapeCSVField(_ field: String) -> String {
        // If field contains comma, quote, or newline, wrap in quotes
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            // Escape quotes by doubling them
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}

// MARK: - Export Data Models

/// Transaction data for export
struct LoyaltyTransactionExport {
    let id: Int
    let customerName: String
    let type: String
    let points: Int
    let orderId: String?
    let description: String
    let createdAt: Date
}

/// Campaign data for export
struct CampaignExport {
    let name: String
    let type: String
    let status: String
    let startDate: Date?
    let endDate: Date?
    let targetSegment: String?
    let sent: Int
    let opened: Int
    let clicked: Int
    let converted: Int
    let roi: Double
}

/// Sales data for export
struct SalesDataExport {
    let date: Date
    let orders: Int
    let revenue: Double
    let newCustomers: Int
    let returningCustomers: Int
}

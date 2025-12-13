//
//  PDFReportTemplates.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import Foundation
import UIKit
import SwiftUI

// MARK: - Marketing Analytics PDF Template

struct MarketingAnalyticsPDFTemplate: PDFTemplate {
    let period: AnalyticsPeriod
    let metrics: MarketingMetrics
    let charts: [ReportChart]

    var title: String {
        "Marketing Analytics Report - \(period.rawValue.capitalized)"
    }

    var numberOfPages: Int {
        return 2 // Overview + Charts
    }

    func drawPage(pageIndex: Int, in rect: CGRect, context: CGContext) {
        if pageIndex == 0 {
            drawOverviewPage(in: rect, context: context)
        } else {
            drawChartsPage(in: rect, context: context)
        }
    }

    private func drawOverviewPage(in rect: CGRect, context: CGContext) {
        // Header
        drawHeader(title: title, in: rect, context: context)

        var yPosition: CGFloat = 100

        // Summary section
        drawSectionTitle("Key Metrics", at: yPosition, in: rect, context: context)
        yPosition += 35

        // Metric cards in 2x2 grid
        let cardWidth: CGFloat = 250
        let cardHeight: CGFloat = 100
        let spacing: CGFloat = 20

        drawMetricCard(
            title: "Total Notifications Sent",
            value: "\(metrics.notificationsSent)",
            change: metrics.notificationsChange > 0 ? "+\(String(format: "%.1f", metrics.notificationsChange))%" : nil,
            at: CGPoint(x: 40, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        drawMetricCard(
            title: "Coupons Redeemed",
            value: "\(metrics.couponsRedeemed)",
            change: metrics.couponsChange > 0 ? "+\(String(format: "%.1f", metrics.couponsChange))%" : nil,
            at: CGPoint(x: 40 + cardWidth + spacing, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        yPosition += cardHeight + spacing

        drawMetricCard(
            title: "Loyalty Members",
            value: "\(metrics.loyaltyMembers)",
            change: metrics.loyaltyMembersChange > 0 ? "+\(String(format: "%.1f", metrics.loyaltyMembersChange))%" : nil,
            at: CGPoint(x: 40, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        drawMetricCard(
            title: "Points Awarded",
            value: "\(metrics.pointsAwarded)",
            change: nil,
            at: CGPoint(x: 40 + cardWidth + spacing, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        yPosition += cardHeight + 40

        // ROI Section
        drawSectionTitle("Return on Investment", at: yPosition, in: rect, context: context)
        yPosition += 35

        let roiText = """
        Campaign ROI: \(String(format: "%.1f", metrics.campaignROI))%
        Average Customer Lifetime Value: $\(String(format: "%.2f", metrics.averageLTV))
        Customer Acquisition Cost: $\(String(format: "%.2f", metrics.acquisitionCost))
        """

        let roiAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.darkGray
        ]
        let roiAttrString = NSAttributedString(string: roiText, attributes: roiAttributes)
        roiAttrString.draw(at: CGPoint(x: 40, y: yPosition))

        // Footer
        drawFooter(pageNumber: 0, totalPages: numberOfPages, in: rect, context: context)
    }

    private func drawChartsPage(in rect: CGRect, context: CGContext) {
        // Header
        drawHeader(title: title, in: rect, context: context)

        var yPosition: CGFloat = 100

        // Charts section
        drawSectionTitle("Performance Charts", at: yPosition, in: rect, context: context)
        yPosition += 35

        for (index, chart) in charts.prefix(3).enumerated() {
            drawChart(
                image: chart.image,
                title: chart.title,
                at: CGPoint(x: 40, y: yPosition),
                size: CGSize(width: rect.width - 80, height: 180),
                context: context
            )
            yPosition += 220

            if index < charts.count - 1 && yPosition > rect.height - 300 {
                break // Don't overflow page
            }
        }

        // Footer
        drawFooter(pageNumber: 1, totalPages: numberOfPages, in: rect, context: context)
    }
}

// MARK: - Loyalty Report PDF Template

struct LoyaltyReportPDFTemplate: PDFTemplate {
    let customers: [CustomerLoyaltyListItem]
    let summary: LoyaltySummary
    let dateRange: DateRange

    var title: String {
        "Customer Loyalty Report"
    }

    var numberOfPages: Int {
        // 1 summary page + customer pages (max 15 per page)
        return 1 + (customers.count + 14) / 15
    }

    func drawPage(pageIndex: Int, in rect: CGRect, context: CGContext) {
        if pageIndex == 0 {
            drawSummaryPage(in: rect, context: context)
        } else {
            drawCustomerListPage(pageIndex: pageIndex, in: rect, context: context)
        }
    }

    private func drawSummaryPage(in rect: CGRect, context: CGContext) {
        // Header
        drawHeader(title: title, in: rect, context: context)

        var yPosition: CGFloat = 100

        // Date range
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateRangeText = "Period: \(dateFormatter.string(from: dateRange.start)) - \(dateFormatter.string(from: dateRange.end))"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        NSAttributedString(string: dateRangeText, attributes: dateAttributes).draw(at: CGPoint(x: 40, y: yPosition))
        yPosition += 35

        // Summary metrics
        drawSectionTitle("Summary", at: yPosition, in: rect, context: context)
        yPosition += 35

        let cardWidth: CGFloat = 165
        let cardHeight: CGFloat = 90
        let spacing: CGFloat = 15

        // Row 1
        drawMetricCard(
            title: "Total Members",
            value: "\(summary.totalMembers)",
            change: nil,
            at: CGPoint(x: 40, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        drawMetricCard(
            title: "Total Points",
            value: "\(summary.totalPoints)",
            change: nil,
            at: CGPoint(x: 40 + cardWidth + spacing, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        drawMetricCard(
            title: "Total Redemptions",
            value: "\(summary.totalRedemptions)",
            change: nil,
            at: CGPoint(x: 40 + (cardWidth + spacing) * 2, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        yPosition += cardHeight + spacing

        // Row 2
        drawMetricCard(
            title: "Avg Points/Member",
            value: String(format: "%.0f", summary.averagePointsPerMember),
            change: nil,
            at: CGPoint(x: 40, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        yPosition += cardHeight + 40

        // Tier distribution
        drawSectionTitle("Tier Distribution", at: yPosition, in: rect, context: context)
        yPosition += 35

        for (tier, count) in summary.tierDistribution.sorted(by: { $0.key < $1.key }) {
            let percentage = Double(count) / Double(summary.totalMembers) * 100
            let tierText = "\(tier): \(count) members (\(String(format: "%.1f", percentage))%)"
            let tierAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.darkGray
            ]
            NSAttributedString(string: tierText, attributes: tierAttributes).draw(at: CGPoint(x: 40, y: yPosition))
            yPosition += 25
        }

        // Footer
        drawFooter(pageNumber: 0, totalPages: numberOfPages, in: rect, context: context)
    }

    private func drawCustomerListPage(pageIndex: Int, in rect: CGRect, context: CGContext) {
        // Header
        drawHeader(title: title, in: rect, context: context)

        var yPosition: CGFloat = 100

        drawSectionTitle("Customer List (Page \(pageIndex))", at: yPosition, in: rect, context: context)
        yPosition += 35

        // Table header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]

        NSAttributedString(string: "Name", attributes: headerAttributes).draw(at: CGPoint(x: 40, y: yPosition))
        NSAttributedString(string: "Tier", attributes: headerAttributes).draw(at: CGPoint(x: 200, y: yPosition))
        NSAttributedString(string: "Points", attributes: headerAttributes).draw(at: CGPoint(x: 300, y: yPosition))
        NSAttributedString(string: "Email", attributes: headerAttributes).draw(at: CGPoint(x: 400, y: yPosition))

        yPosition += 20

        // Divider
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 40, y: yPosition))
        context.addLine(to: CGPoint(x: rect.width - 40, y: yPosition))
        context.strokePath()

        yPosition += 10

        // Customer rows
        let startIndex = (pageIndex - 1) * 15
        let endIndex = min(startIndex + 15, customers.count)
        let pageCustomers = Array(customers[startIndex..<endIndex])

        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]

        for customer in pageCustomers {
            NSAttributedString(string: customer.name, attributes: rowAttributes).draw(at: CGPoint(x: 40, y: yPosition))
            NSAttributedString(string: customer.tierName, attributes: rowAttributes).draw(at: CGPoint(x: 200, y: yPosition))
            NSAttributedString(string: "\(customer.points)", attributes: rowAttributes).draw(at: CGPoint(x: 300, y: yPosition))
            NSAttributedString(string: customer.email ?? "N/A", attributes: rowAttributes).draw(at: CGPoint(x: 400, y: yPosition))

            yPosition += 20
        }

        // Footer
        drawFooter(pageNumber: pageIndex, totalPages: numberOfPages, in: rect, context: context)
    }
}

// MARK: - Sales Analytics PDF Template

struct SalesAnalyticsPDFTemplate: PDFTemplate {
    let period: AnalyticsPeriod
    let revenue: Double
    let orders: Int
    let charts: [ReportChart]

    var title: String {
        "Sales Analytics Report - \(period.rawValue.capitalized)"
    }

    var numberOfPages: Int {
        return 1
    }

    func drawPage(pageIndex: Int, in rect: CGRect, context: CGContext) {
        // Header
        drawHeader(title: title, in: rect, context: context)

        var yPosition: CGFloat = 100

        // Key metrics
        drawSectionTitle("Performance Overview", at: yPosition, in: rect, context: context)
        yPosition += 35

        let cardWidth: CGFloat = 250
        let cardHeight: CGFloat = 100
        let spacing: CGFloat = 20

        drawMetricCard(
            title: "Total Revenue",
            value: String(format: "$%.2f", revenue),
            change: nil,
            at: CGPoint(x: 40, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        drawMetricCard(
            title: "Total Orders",
            value: "\(orders)",
            change: nil,
            at: CGPoint(x: 40 + cardWidth + spacing, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        yPosition += cardHeight + 20

        let avgOrderValue = orders > 0 ? revenue / Double(orders) : 0
        drawMetricCard(
            title: "Average Order Value",
            value: String(format: "$%.2f", avgOrderValue),
            change: nil,
            at: CGPoint(x: 40, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        yPosition += cardHeight + 40

        // Charts
        if !charts.isEmpty {
            drawSectionTitle("Trends", at: yPosition, in: rect, context: context)
            yPosition += 35

            if let firstChart = charts.first {
                drawChart(
                    image: firstChart.image,
                    title: firstChart.title,
                    at: CGPoint(x: 40, y: yPosition),
                    size: CGSize(width: rect.width - 80, height: 200),
                    context: context
                )
            }
        }

        // Footer
        drawFooter(pageNumber: 0, totalPages: numberOfPages, in: rect, context: context)
    }
}

// MARK: - Advanced Analytics PDF Template

struct AdvancedAnalyticsPDFTemplate: PDFTemplate {
    let period: AnalyticsPeriod
    let viewModel: AdvancedAnalyticsViewModel
    let chartImages: [String: UIImage]

    var title: String {
        "Advanced Analytics Dashboard - \(period.rawValue.capitalized)"
    }

    var numberOfPages: Int {
        return 3 // Overview + Charts pages
    }

    func drawPage(pageIndex: Int, in rect: CGRect, context: CGContext) {
        switch pageIndex {
        case 0:
            drawOverviewPage(in: rect, context: context)
        case 1:
            drawChartsPage1(in: rect, context: context)
        case 2:
            drawChartsPage2(in: rect, context: context)
        default:
            break
        }
    }

    private func drawOverviewPage(in rect: CGRect, context: CGContext) {
        // Header
        drawHeader(title: title, in: rect, context: context)

        var yPosition: CGFloat = 100

        // Key metrics
        drawSectionTitle("Key Performance Indicators", at: yPosition, in: rect, context: context)
        yPosition += 35

        let cardWidth: CGFloat = 130
        let cardHeight: CGFloat = 90
        let spacing: CGFloat = 10

        // Row 1
        drawMetricCard(
            title: "Revenue",
            value: String(format: "$%.0f", viewModel.totalRevenue),
            change: String(format: "%+.1f%%", viewModel.revenueChange),
            at: CGPoint(x: 40, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        drawMetricCard(
            title: "Members",
            value: "\(viewModel.activeMembers)",
            change: String(format: "%+.1f%%", viewModel.memberChange),
            at: CGPoint(x: 40 + cardWidth + spacing, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        drawMetricCard(
            title: "Points",
            value: "\(viewModel.pointsAwarded)",
            change: String(format: "%+.1f%%", viewModel.pointsChange),
            at: CGPoint(x: 40 + (cardWidth + spacing) * 2, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        drawMetricCard(
            title: "Redemptions",
            value: "\(viewModel.totalRedemptions)",
            change: String(format: "%+.1f%%", viewModel.redemptionsChange),
            at: CGPoint(x: 40 + (cardWidth + spacing) * 3, y: yPosition),
            size: CGSize(width: cardWidth, height: cardHeight),
            context: context
        )

        yPosition += cardHeight + 40

        // Tier distribution summary
        drawSectionTitle("Member Tier Distribution", at: yPosition, in: rect, context: context)
        yPosition += 35

        for tier in viewModel.tierDistribution {
            let tierText = "\(tier.name): \(tier.count) members (\(Int(tier.percentage))%)"
            let tierAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.darkGray
            ]
            NSAttributedString(string: tierText, attributes: tierAttributes).draw(at: CGPoint(x: 40, y: yPosition))
            yPosition += 25
        }

        yPosition += 20

        // Top rewards
        drawSectionTitle("Top Performing Rewards", at: yPosition, in: rect, context: context)
        yPosition += 35

        for (index, reward) in viewModel.topRewards.prefix(5).enumerated() {
            let rewardText = "\(index + 1). \(reward.name): \(reward.redemptions) redemptions"
            let rewardAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.darkGray
            ]
            NSAttributedString(string: rewardText, attributes: rewardAttributes).draw(at: CGPoint(x: 40, y: yPosition))
            yPosition += 25
        }

        // Footer
        drawFooter(pageNumber: 0, totalPages: numberOfPages, in: rect, context: context)
    }

    private func drawChartsPage1(in rect: CGRect, context: CGContext) {
        // Header
        drawHeader(title: title, in: rect, context: context)

        var yPosition: CGFloat = 100

        drawSectionTitle("Revenue & Points Analysis", at: yPosition, in: rect, context: context)
        yPosition += 35

        // Placeholder for revenue trend chart
        drawChart(
            image: chartImages["revenue"],
            title: "Revenue Trend",
            at: CGPoint(x: 40, y: yPosition),
            size: CGSize(width: rect.width - 80, height: 200),
            context: context
        )

        yPosition += 240

        // Placeholder for points activity chart
        drawChart(
            image: chartImages["points"],
            title: "Loyalty Points Activity",
            at: CGPoint(x: 40, y: yPosition),
            size: CGSize(width: rect.width - 80, height: 200),
            context: context
        )

        // Footer
        drawFooter(pageNumber: 1, totalPages: numberOfPages, in: rect, context: context)
    }

    private func drawChartsPage2(in rect: CGRect, context: CGContext) {
        // Header
        drawHeader(title: title, in: rect, context: context)

        var yPosition: CGFloat = 100

        drawSectionTitle("Campaign Performance & Engagement", at: yPosition, in: rect, context: context)
        yPosition += 35

        // Placeholder for campaign performance chart
        drawChart(
            image: chartImages["campaigns"],
            title: "Campaign Performance by Type",
            at: CGPoint(x: 40, y: yPosition),
            size: CGSize(width: rect.width - 80, height: 200),
            context: context
        )

        yPosition += 240

        // Placeholder for engagement chart
        drawChart(
            image: chartImages["engagement"],
            title: "Customer Engagement Trend",
            at: CGPoint(x: 40, y: yPosition),
            size: CGSize(width: rect.width - 80, height: 180),
            context: context
        )

        // Footer
        drawFooter(pageNumber: 2, totalPages: numberOfPages, in: rect, context: context)
    }
}

// MARK: - Marketing Metrics Model

struct MarketingMetrics {
    let notificationsSent: Int
    let notificationsChange: Double
    let couponsRedeemed: Int
    let couponsChange: Double
    let loyaltyMembers: Int
    let loyaltyMembersChange: Double
    let pointsAwarded: Int
    let campaignROI: Double
    let averageLTV: Double
    let acquisitionCost: Double
}

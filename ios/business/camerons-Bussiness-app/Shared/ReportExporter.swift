//
//  ReportExporter.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import Foundation
import PDFKit
import SwiftUI
import UIKit

/// Export error types
enum ExportError: LocalizedError {
    case formatNotSupported
    case generationFailed
    case fileWriteFailed

    var errorDescription: String? {
        switch self {
        case .formatNotSupported:
            return "This export format is not yet supported. Please try PDF export."
        case .generationFailed:
            return "Failed to generate the report. Please try again."
        case .fileWriteFailed:
            return "Failed to save the exported file. Please check storage permissions."
        }
    }
}

/// PDF report generation engine using PDFKit
@MainActor
class ReportExporter {

    // MARK: - Public Export Methods

    /// Export marketing analytics to PDF
    func exportMarketingAnalyticsToPDF(
        period: AnalyticsPeriod,
        metrics: MarketingMetrics,
        charts: [ReportChart]
    ) async throws -> URL {
        let template = MarketingAnalyticsPDFTemplate(
            period: period,
            metrics: metrics,
            charts: charts
        )
        return try await generatePDF(template: template, filename: "Marketing_Analytics_\(period.rawValue)")
    }

    /// Export customer loyalty report to PDF
    func exportLoyaltyReportToPDF(
        customers: [CustomerLoyaltyListItem],
        summary: LoyaltySummary,
        dateRange: DateRange
    ) async throws -> URL {
        let template = LoyaltyReportPDFTemplate(
            customers: customers,
            summary: summary,
            dateRange: dateRange
        )
        return try await generatePDF(template: template, filename: "Loyalty_Report_\(dateRange.formatted)")
    }

    /// Export sales analytics to PDF
    func exportSalesAnalyticsToPDF(
        period: AnalyticsPeriod,
        revenue: Double,
        orders: Int,
        charts: [ReportChart]
    ) async throws -> URL {
        let template = SalesAnalyticsPDFTemplate(
            period: period,
            revenue: revenue,
            orders: orders,
            charts: charts
        )
        return try await generatePDF(template: template, filename: "Sales_Analytics_\(period.rawValue)")
    }

    /// Export advanced analytics dashboard to PDF
    func exportAdvancedAnalyticsToPDF(
        period: AnalyticsPeriod,
        viewModel: AdvancedAnalyticsViewModel
    ) async throws -> URL {
        let charts = await captureAdvancedAnalyticsCharts(viewModel: viewModel)
        let template = AdvancedAnalyticsPDFTemplate(
            period: period,
            viewModel: viewModel,
            chartImages: charts
        )
        return try await generatePDF(template: template, filename: "Advanced_Analytics_\(period.rawValue)")
    }

    // MARK: - Core PDF Generation

    private func generatePDF(template: PDFTemplate, filename: String) async throws -> URL {
        let pdfMetadata = [
            kCGPDFContextCreator: "KnockBites Business App",
            kCGPDFContextAuthor: "Marketing System",
            kCGPDFContextTitle: template.title
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetadata as [String: Any]

        // US Letter size: 8.5" x 11" = 612 x 792 points
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            // Render each page
            for pageIndex in 0..<template.numberOfPages {
                context.beginPage()

                let ctx = context.cgContext
                template.drawPage(pageIndex: pageIndex, in: pageRect, context: ctx)
            }
        }

        // Save to temporary directory
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(filename)_\(Date().timeIntervalSince1970).pdf")

        try data.write(to: tempURL)
        return tempURL
    }

    // MARK: - Chart Capture

    /// Capture SwiftUI Chart as UIImage
    func captureChart<Content: View>(
        chart: Content,
        size: CGSize
    ) async -> UIImage? {
        let controller = UIHostingController(rootView: chart.frame(width: size.width, height: size.height))
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    private func captureAdvancedAnalyticsCharts(
        viewModel: AdvancedAnalyticsViewModel
    ) async -> [String: UIImage] {
        var images: [String: UIImage] = [:]

        // In a real implementation, we would capture actual SwiftUI Charts
        // For now, we'll use placeholder images
        // This would be replaced with actual chart rendering

        return images
    }

    // MARK: - Share Sheet

    /// Present share sheet for PDF
    func shareDocument(url: URL, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX,
                                       y: viewController.view.bounds.midY,
                                       width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        viewController.present(activityVC, animated: true)
    }
}

// MARK: - Supporting Types

struct DateRange {
    let start: Date
    let end: Date

    var formatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: start))_to_\(formatter.string(from: end))"
    }
}

struct LoyaltySummary {
    let totalMembers: Int
    let totalPoints: Int
    let totalRedemptions: Int
    let averagePointsPerMember: Double
    let tierDistribution: [String: Int]
}

struct ReportChart {
    let title: String
    let type: ChartType
    let image: UIImage?

    enum ChartType {
        case line, bar, pie, area
    }
}

// MARK: - PDF Template Protocol

protocol PDFTemplate {
    var title: String { get }
    var numberOfPages: Int { get }

    func drawPage(pageIndex: Int, in rect: CGRect, context: CGContext)
}

// MARK: - PDF Drawing Helpers

extension PDFTemplate {

    /// Draw header with logo and title
    func drawHeader(title: String, in rect: CGRect, context: CGContext) {
        let headerHeight: CGFloat = 80
        let headerRect = CGRect(x: 0, y: 0, width: rect.width, height: headerHeight)

        // Background
        context.setFillColor(UIColor(Color.brandPrimary).cgColor)
        context.fill(headerRect)

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        let titleSize = titleString.size()
        let titleY = (headerHeight - titleSize.height) / 2
        titleString.draw(at: CGPoint(x: 40, y: titleY))

        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = "Generated: \(dateFormatter.string(from: Date()))"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        let dateAttrString = NSAttributedString(string: dateString, attributes: dateAttributes)
        let dateSize = dateAttrString.size()
        dateAttrString.draw(at: CGPoint(x: rect.width - dateSize.width - 40, y: headerHeight - dateSize.height - 10))
    }

    /// Draw footer with page number
    func drawFooter(pageNumber: Int, totalPages: Int, in rect: CGRect, context: CGContext) {
        let footerHeight: CGFloat = 40
        let footerY = rect.height - footerHeight

        // Line
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 40, y: footerY))
        context.addLine(to: CGPoint(x: rect.width - 40, y: footerY))
        context.strokePath()

        // Page number
        let pageText = "Page \(pageNumber + 1) of \(totalPages)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        let attrString = NSAttributedString(string: pageText, attributes: attributes)
        let size = attrString.size()
        attrString.draw(at: CGPoint(x: (rect.width - size.width) / 2, y: footerY + 15))

        // Branding
        let brandText = "KnockBites Business App"
        let brandAttrString = NSAttributedString(string: brandText, attributes: attributes)
        brandAttrString.draw(at: CGPoint(x: 40, y: footerY + 15))
    }

    /// Draw metric card
    func drawMetricCard(
        title: String,
        value: String,
        change: String?,
        at origin: CGPoint,
        size: CGSize,
        context: CGContext
    ) {
        let rect = CGRect(origin: origin, size: size)

        // Card background
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
        context.setFillColor(UIColor.systemGray6.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()

        // Border
        context.setStrokeColor(UIColor.systemGray4.cgColor)
        context.setLineWidth(1)
        context.addPath(path.cgPath)
        context.strokePath()

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        titleString.draw(at: CGPoint(x: origin.x + 12, y: origin.y + 12))

        // Value
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let valueString = NSAttributedString(string: value, attributes: valueAttributes)
        valueString.draw(at: CGPoint(x: origin.x + 12, y: origin.y + 32))

        // Change indicator
        if let change = change {
            let changeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: change.hasPrefix("+") ? UIColor.systemGreen : UIColor.systemRed
            ]
            let changeString = NSAttributedString(string: change, attributes: changeAttributes)
            changeString.draw(at: CGPoint(x: origin.x + 12, y: origin.y + size.height - 24))
        }
    }

    /// Draw section title
    func drawSectionTitle(_ title: String, at y: CGFloat, in rect: CGRect, context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        let attrString = NSAttributedString(string: title, attributes: attributes)
        attrString.draw(at: CGPoint(x: 40, y: y))
    }

    /// Draw chart image
    func drawChart(image: UIImage?, title: String, at origin: CGPoint, size: CGSize, context: CGContext) {
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.black
        ]
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        titleString.draw(at: origin)

        // Chart image
        let chartRect = CGRect(
            x: origin.x,
            y: origin.y + 25,
            width: size.width,
            height: size.height
        )

        if let image = image {
            image.draw(in: chartRect)
        } else {
            // Placeholder
            context.setFillColor(UIColor.systemGray5.cgColor)
            context.fill(chartRect)

            let placeholderText = "Chart"
            let placeholderAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ]
            let placeholderString = NSAttributedString(string: placeholderText, attributes: placeholderAttributes)
            let textSize = placeholderString.size()
            placeholderString.draw(at: CGPoint(
                x: chartRect.midX - textSize.width / 2,
                y: chartRect.midY - textSize.height / 2
            ))
        }
    }
}

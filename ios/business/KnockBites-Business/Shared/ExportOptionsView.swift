//
//  ExportOptionsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI
import Combine

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ExportViewModel()

    let exportType: ExportType
    let onExport: (ExportFormat, ExportOptions) async throws -> URL

    @State private var selectedFormat: ExportFormat = .pdf
    @State private var selectedDateRange: DateRangeOption = .last30Days
    @State private var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var includeCharts = true
    @State private var includeCustomerList = true
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                // Format selection
                Section("Export Format") {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            HStack {
                                Image(systemName: format.icon)
                                Text(format.displayName)
                            }
                            .tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(selectedFormat.description)
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                // Date range
                Section("Date Range") {
                    Picker("Period", selection: $selectedDateRange) {
                        ForEach(DateRangeOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }

                    if selectedDateRange == .custom {
                        DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                    }
                }

                // Options based on export type
                if selectedFormat == .pdf {
                    Section("Include in Report") {
                        Toggle("Charts & Graphs", isOn: $includeCharts)

                        if exportType == .loyalty {
                            Toggle("Customer List", isOn: $includeCustomerList)
                        }
                    }
                }

                // File info preview
                Section("Export Details") {
                    HStack {
                        Text("File Name")
                        Spacer()
                        Text(generateFilename())
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }

                    HStack {
                        Text("Estimated Size")
                        Spacer()
                        Text(estimatedFileSize())
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("Export \(exportType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: performExport) {
                        if isExporting {
                            ProgressView()
                        } else {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export")
                            }
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export Failed", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func performExport() {
        Task {
            isExporting = true
            defer { isExporting = false }

            do {
                let options = ExportOptions(
                    format: selectedFormat,
                    dateRange: selectedDateRange.dateRange(customStart: customStartDate, customEnd: customEndDate),
                    includeCharts: includeCharts,
                    includeCustomerList: includeCustomerList
                )

                let url = try await onExport(selectedFormat, options)
                exportedURL = url
                showShareSheet = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func generateFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())

        let ext = selectedFormat == .pdf ? "pdf" : "csv"
        return "\(exportType.filenamePrefix)_\(dateStr).\(ext)"
    }

    private func estimatedFileSize() -> String {
        // Rough estimates
        switch selectedFormat {
        case .pdf:
            return includeCharts ? "500 KB - 2 MB" : "100 KB - 500 KB"
        case .csv:
            return "50 KB - 200 KB"
        }
    }
}

// MARK: - Supporting Types

enum ExportType {
    case marketingAnalytics
    case loyalty
    case salesAnalytics
    case advancedAnalytics

    var displayName: String {
        switch self {
        case .marketingAnalytics: return "Marketing Analytics"
        case .loyalty: return "Loyalty Report"
        case .salesAnalytics: return "Sales Analytics"
        case .advancedAnalytics: return "Advanced Analytics"
        }
    }

    var filenamePrefix: String {
        switch self {
        case .marketingAnalytics: return "Marketing_Analytics"
        case .loyalty: return "Loyalty_Report"
        case .salesAnalytics: return "Sales_Analytics"
        case .advancedAnalytics: return "Advanced_Analytics"
        }
    }
}

enum ExportFormat: CaseIterable {
    case pdf
    case csv

    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .csv: return "CSV"
        }
    }

    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .csv: return "tablecells"
        }
    }

    var description: String {
        switch self {
        case .pdf: return "Formatted report with charts and visualizations"
        case .csv: return "Spreadsheet data for Excel or Google Sheets"
        }
    }
}

enum DateRangeOption: CaseIterable {
    case last7Days
    case last30Days
    case last90Days
    case thisMonth
    case lastMonth
    case thisYear
    case custom

    var displayName: String {
        switch self {
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .last90Days: return "Last 90 Days"
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .thisYear: return "This Year"
        case .custom: return "Custom Range"
        }
    }

    func dateRange(customStart: Date? = nil, customEnd: Date? = nil) -> DateRange {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return DateRange(start: start, end: now)

        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return DateRange(start: start, end: now)

        case .last90Days:
            let start = calendar.date(byAdding: .day, value: -90, to: now) ?? now
            return DateRange(start: start, end: now)

        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: components) ?? now
            return DateRange(start: start, end: now)

        case .lastMonth:
            let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            let components = calendar.dateComponents([.year, .month], from: lastMonthDate)
            let start = calendar.date(from: components) ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
            return DateRange(start: start, end: end)

        case .thisYear:
            let components = calendar.dateComponents([.year], from: now)
            let start = calendar.date(from: components) ?? now
            return DateRange(start: start, end: now)

        case .custom:
            return DateRange(start: customStart ?? now, end: customEnd ?? now)
        }
    }
}

struct ExportOptions {
    let format: ExportFormat
    let dateRange: DateRange
    let includeCharts: Bool
    let includeCustomerList: Bool
}

// MARK: - View Model (extracted to Shared/ViewModels/ExportViewModel.swift)

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

// MARK: - Preview

#Preview {
    ExportOptionsView(
        exportType: .marketingAnalytics,
        onExport: { format, options in
            try await Task.sleep(nanoseconds: 2_000_000_000)
            return URL(fileURLWithPath: "/tmp/test.pdf")
        }
    )
}

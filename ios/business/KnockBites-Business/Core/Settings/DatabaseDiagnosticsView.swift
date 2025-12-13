//
//  DatabaseDiagnosticsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI
import Combine
import Supabase
import PostgREST

struct DatabaseDiagnosticsView: View {
    @StateObject private var viewModel = DatabaseDiagnosticsViewModel()

    var body: some View {
        List {
            Section("Connection Status") {
                HStack {
                    Text("Supabase URL")
                    Spacer()
                    Text(SupabaseConfig.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Store ID")
                    Spacer()
                    Text("\(SupabaseConfig.storeId)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Connection")
                    Spacer()
                    if viewModel.isConnected {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Not Connected", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }

            Section("Orders in Database") {
                if viewModel.isLoadingOrders {
                    HStack {
                        ProgressView()
                        Text("Fetching orders...")
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Text("Total Orders")
                        Spacer()
                        Text("\(viewModel.totalOrders)")
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.totalOrders > 0 ? .green : .red)
                    }

                    HStack {
                        Text("Pending Orders")
                        Spacer()
                        Text("\(viewModel.pendingOrders)")
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }

                    HStack {
                        Text("Completed Orders")
                        Spacer()
                        Text("\(viewModel.completedOrders)")
                            .fontWeight(.bold)
                    }
                }
            }

            Section("Recent Orders") {
                if viewModel.recentOrders.isEmpty {
                    Text("No orders found")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(viewModel.recentOrders) { order in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Order #\(order.orderNumber)")
                                    .font(.headline)
                                Spacer()
                                Text(order.status.rawValue.uppercased())
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(statusColor(for: order.status).opacity(0.2))
                                    .foregroundColor(statusColor(for: order.status))
                                    .cornerRadius(4)
                            }

                            Text(order.customerName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Text(order.createdAt, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "$%.2f", order.total))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Actions") {
                Button(action: {
                    viewModel.testConnection()
                }) {
                    HStack {
                        Image(systemName: "network")
                        Text("Test Connection")
                        Spacer()
                        if viewModel.isTesting {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isTesting)

                Button(action: {
                    viewModel.fetchOrders()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Orders")
                        Spacer()
                        if viewModel.isLoadingOrders {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isLoadingOrders)

                Button(action: {
                    viewModel.fetchAllStoreOrders()
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Check ALL Store Orders")
                        Spacer()
                        if viewModel.isLoadingOrders {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isLoadingOrders)
            }

            if let error = viewModel.errorMessage {
                Section("Error Details") {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Database Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.testConnection()
            viewModel.fetchOrders()
        }
    }

    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .received: return .blue
        case .preparing: return .orange
        case .ready: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

// MARK: - View Model (extracted to Core/Settings/ViewModels/DatabaseDiagnosticsViewModel.swift)

#Preview {
    NavigationView {
        DatabaseDiagnosticsView()
    }
}

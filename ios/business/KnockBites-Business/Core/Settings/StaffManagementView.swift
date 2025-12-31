//
//  StaffManagementView.swift
//  KnockBites-Business
//
//  Staff management view for viewing and managing team members
//

import SwiftUI

struct StaffManagementView: View {
    @StateObject private var viewModel = StaffManagementViewModel()
    @State private var searchQuery = ""
    @State private var filterRole: String? = nil
    @State private var showAddStaff = false

    var filteredStaff: [StaffMember] {
        viewModel.staff.filter { member in
            let matchesSearch = searchQuery.isEmpty ||
                member.name.localizedCaseInsensitiveContains(searchQuery) ||
                member.email.localizedCaseInsensitiveContains(searchQuery)
            let matchesRole = filterRole == nil || member.role == filterRole
            return matchesSearch && matchesRole
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats Cards
                if !viewModel.isLoading {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.md) {
                            StaffStatCard(title: "Total Staff", value: "\(viewModel.staff.count)", icon: "person.3.fill", color: .brandPrimary)
                            StaffStatCard(title: "Admins", value: "\(viewModel.adminCount)", icon: "shield.fill", color: .blue)
                            StaffStatCard(title: "Managers", value: "\(viewModel.managerCount)", icon: "briefcase.fill", color: .green)
                            StaffStatCard(title: "Active", value: "\(viewModel.activeCount)", icon: "checkmark.circle.fill", color: .orange)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, Spacing.sm)
                    }
                }

                // Search and Filter
                VStack(spacing: Spacing.sm) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textSecondary)
                        TextField("Search staff...", text: $searchQuery)
                    }
                    .padding(Spacing.sm)
                    .background(Color.surfaceSecondary)
                    .cornerRadius(CornerRadius.md)
                    .padding(.horizontal)

                    // Role Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            StaffFilterChip(title: "All", isSelected: filterRole == nil) {
                                filterRole = nil
                            }
                            StaffFilterChip(title: "Super Admin", isSelected: filterRole == "super_admin") {
                                filterRole = "super_admin"
                            }
                            StaffFilterChip(title: "Admin", isSelected: filterRole == "admin") {
                                filterRole = "admin"
                            }
                            StaffFilterChip(title: "Manager", isSelected: filterRole == "manager") {
                                filterRole = "manager"
                            }
                            StaffFilterChip(title: "Staff", isSelected: filterRole == "staff") {
                                filterRole = "staff"
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, Spacing.sm)
                .background(Color(.systemBackground))

                // Staff List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading staff...")
                    Spacer()
                } else if filteredStaff.isEmpty {
                    Spacer()
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "person.3")
                            .font(.system(size: 50))
                            .foregroundColor(.textSecondary)
                        Text("No staff members found")
                            .font(AppFonts.headline)
                            .foregroundColor(.textPrimary)
                        Text("Add your first team member to get started")
                            .font(AppFonts.body)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredStaff) { member in
                            StaffMemberRow(member: member, viewModel: viewModel)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.fetchStaff()
                    }
                }
            }
            .navigationTitle("Staff Management")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddStaff = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.brandPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAddStaff) {
                AddStaffView(viewModel: viewModel, isPresented: $showAddStaff)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchStaff()
            }
        }
    }
}

// MARK: - Staff Member Row
struct StaffMemberRow: View {
    let member: StaffMember
    @ObservedObject var viewModel: StaffManagementViewModel
    @State private var showActions = false

    var roleColor: Color {
        switch member.role {
        case "super_admin": return .purple
        case "admin": return .blue
        case "manager": return .green
        case "staff": return .orange
        default: return .gray
        }
    }

    var roleIcon: String {
        switch member.role {
        case "super_admin": return "crown.fill"
        case "admin": return "shield.fill"
        case "manager": return "briefcase.fill"
        case "staff": return "person.fill"
        default: return "person.fill"
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Role Icon
            ZStack {
                Circle()
                    .fill(roleColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: roleIcon)
                    .font(.system(size: 20))
                    .foregroundColor(roleColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.name)
                        .font(AppFonts.headline)
                        .foregroundColor(.textPrimary)

                    // Status Badge
                    Text(member.isActive ? "Active" : "Inactive")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(member.isActive ? .green : .gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(member.isActive ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                        .cornerRadius(4)
                }

                Text(member.email)
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)

                HStack(spacing: Spacing.sm) {
                    // Role Badge
                    Text(member.roleDisplayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(roleColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(roleColor.opacity(0.1))
                        .cornerRadius(6)

                    // Store
                    if let storeName = member.storeName {
                        HStack(spacing: 2) {
                            Image(systemName: "storefront")
                                .font(.system(size: 10))
                            Text(storeName)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.textSecondary)
                    }
                }
            }

            Spacer()

            // Actions
            Menu {
                if member.role != "super_admin" {
                    Button(action: { viewModel.toggleStaffStatus(member) }) {
                        Label(member.isActive ? "Deactivate" : "Activate",
                              systemImage: member.isActive ? "person.fill.xmark" : "person.fill.checkmark")
                    }

                    Button(role: .destructive, action: { viewModel.deleteStaff(member) }) {
                        Label("Remove", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Add Staff View
struct AddStaffView: View {
    @ObservedObject var viewModel: StaffManagementViewModel
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var role = "staff"
    @State private var storeId: Int? = nil
    @State private var isInviting = false

    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Phone (Optional)", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("Role & Assignment") {
                    Picker("Role", selection: $role) {
                        Text("Staff").tag("staff")
                        Text("Manager").tag("manager")
                        Text("Admin").tag("admin")
                    }

                    if role != "super_admin" {
                        Picker("Store", selection: $storeId) {
                            Text("Select Store").tag(nil as Int?)
                            ForEach(viewModel.stores, id: \.id) { store in
                                Text(store.name).tag(store.id as Int?)
                            }
                        }
                    }
                }

                Section("Permissions") {
                    Text(permissionsText)
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .navigationTitle("Add Staff Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: inviteStaff) {
                        if isInviting {
                            ProgressView()
                        } else {
                            Text("Send Invite")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(name.isEmpty || email.isEmpty || isInviting)
                }
            }
        }
    }

    var permissionsText: String {
        switch role {
        case "admin":
            return "Orders, Menu, Analytics, Settings, Staff"
        case "manager":
            return "Orders, Menu, Analytics, Settings"
        case "staff":
            return "Orders only"
        default:
            return "Orders only"
        }
    }

    func inviteStaff() {
        isInviting = true
        Task {
            let success = await viewModel.inviteStaff(
                name: name,
                email: email,
                phone: phone.isEmpty ? nil : phone,
                role: role,
                storeId: storeId
            )

            await MainActor.run {
                isInviting = false
                if success {
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Helper Views (Private to avoid conflicts)
private struct StaffStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)
        }
        .frame(width: 120)
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

private struct StaffFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.brandPrimary : Color.surfaceSecondary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Staff Member Model
struct StaffMember: Identifiable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let role: String
    let storeId: Int?
    let storeName: String?
    let permissions: [String]
    let isActive: Bool
    let createdAt: Date?

    var roleDisplayName: String {
        switch role {
        case "super_admin": return "Super Admin"
        case "admin": return "Admin"
        case "manager": return "Manager"
        case "staff": return "Staff"
        default: return role.capitalized
        }
    }
}

// MARK: - Store Model for Picker
struct StoreOption: Identifiable {
    let id: Int
    let name: String
}

#Preview {
    StaffManagementView()
}

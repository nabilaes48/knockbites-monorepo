//
//  StaffManagementViewModel.swift
//  KnockBites-Business
//
//  ViewModel for staff management operations
//

import Foundation
import Supabase

@MainActor
class StaffManagementViewModel: ObservableObject {
    @Published var staff: [StaffMember] = []
    @Published var stores: [StoreOption] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseManager.shared.client

    // MARK: - Computed Properties

    var adminCount: Int {
        staff.filter { $0.role == "admin" || $0.role == "super_admin" }.count
    }

    var managerCount: Int {
        staff.filter { $0.role == "manager" }.count
    }

    var activeCount: Int {
        staff.filter { $0.isActive }.count
    }

    // MARK: - Fetch Staff

    func fetchStaff() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch staff profiles
            let profiles: [StaffProfileResponse] = try await supabase
                .from("user_profiles")
                .select()
                .in("role", values: ["super_admin", "admin", "manager", "staff"])
                .order("created_at", ascending: false)
                .execute()
                .value

            // Fetch stores for mapping
            let storesData: [StoreResponse] = try await supabase
                .from("stores")
                .select("id, name")
                .execute()
                .value

            stores = storesData.map { StoreOption(id: $0.id, name: $0.name) }

            // Map to StaffMember
            staff = profiles.map { profile in
                let storeName = storesData.first { $0.id == profile.store_id }?.name

                return StaffMember(
                    id: profile.id,
                    name: profile.full_name ?? "Unknown",
                    email: profile.email ?? "",
                    phone: profile.phone,
                    role: profile.role,
                    storeId: profile.store_id,
                    storeName: storeName,
                    permissions: profile.permissions ?? [],
                    isActive: profile.is_active ?? true,
                    createdAt: parseDate(profile.created_at)
                )
            }

            DebugLogger.success("Loaded \(staff.count) staff members")
        } catch {
            DebugLogger.error("Failed to fetch staff", error)
            errorMessage = "Failed to load staff: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Invite Staff

    func inviteStaff(name: String, email: String, phone: String?, role: String, storeId: Int?) async -> Bool {
        do {
            // Get default permissions based on role
            let permissions = getDefaultPermissions(for: role)

            // Create user profile (invitation will be sent via Edge Function if configured)
            let newProfile = NewStaffProfile(
                email: email,
                full_name: name,
                phone: phone,
                role: role,
                store_id: storeId,
                permissions: permissions,
                is_active: true,
                invite_status: "pending"
            )

            // For now, create the profile directly
            // In production, this would call an Edge Function to send invitation email
            try await supabase
                .from("user_profiles")
                .insert(newProfile)
                .execute()

            DebugLogger.success("Invited staff: \(name)")

            // Refresh staff list
            await fetchStaff()
            return true
        } catch {
            DebugLogger.error("Failed to invite staff", error)
            await MainActor.run {
                errorMessage = "Failed to invite staff: \(error.localizedDescription)"
            }
            return false
        }
    }

    // MARK: - Toggle Staff Status

    func toggleStaffStatus(_ member: StaffMember) {
        Task {
            do {
                try await supabase
                    .from("user_profiles")
                    .update(["is_active": !member.isActive])
                    .eq("id", value: member.id)
                    .execute()

                DebugLogger.success("Toggled status for: \(member.name)")

                // Update local state
                if let index = staff.firstIndex(where: { $0.id == member.id }) {
                    staff[index] = StaffMember(
                        id: member.id,
                        name: member.name,
                        email: member.email,
                        phone: member.phone,
                        role: member.role,
                        storeId: member.storeId,
                        storeName: member.storeName,
                        permissions: member.permissions,
                        isActive: !member.isActive,
                        createdAt: member.createdAt
                    )
                }
            } catch {
                DebugLogger.error("Failed to toggle staff status", error)
                errorMessage = "Failed to update staff status"
            }
        }
    }

    // MARK: - Delete Staff

    func deleteStaff(_ member: StaffMember) {
        Task {
            do {
                try await supabase
                    .from("user_profiles")
                    .delete()
                    .eq("id", value: member.id)
                    .execute()

                DebugLogger.success("Deleted staff: \(member.name)")

                // Update local state
                staff.removeAll { $0.id == member.id }
            } catch {
                DebugLogger.error("Failed to delete staff", error)
                errorMessage = "Failed to remove staff member"
            }
        }
    }

    // MARK: - Helpers

    private func getDefaultPermissions(for role: String) -> [String] {
        switch role {
        case "super_admin":
            return ["orders", "menu", "analytics", "settings", "staff", "all-stores"]
        case "admin":
            return ["orders", "menu", "analytics", "settings", "staff"]
        case "manager":
            return ["orders", "menu", "analytics", "settings"]
        case "staff":
            return ["orders"]
        default:
            return ["orders"]
        }
    }

    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
}

// MARK: - Response Models

private struct StaffProfileResponse: Codable {
    let id: String
    let email: String?
    let full_name: String?
    let phone: String?
    let role: String
    let store_id: Int?
    let permissions: [String]?
    let is_active: Bool?
    let created_at: String?
    let invite_status: String?
}

private struct StoreResponse: Codable {
    let id: Int
    let name: String
}

private struct NewStaffProfile: Encodable {
    let email: String
    let full_name: String
    let phone: String?
    let role: String
    let store_id: Int?
    let permissions: [String]
    let is_active: Bool
    let invite_status: String
}

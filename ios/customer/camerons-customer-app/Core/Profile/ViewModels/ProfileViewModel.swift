//
//  ProfileViewModel.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var isGuest: Bool = true
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let profileKey = "userProfile"
    private let isGuestKey = "isGuestMode"

    init() {
        // Load cached profile
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let savedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = savedProfile
        } else {
            self.profile = UserProfile()
        }

        // Load guest mode status
        self.isGuest = UserDefaults.standard.bool(forKey: isGuestKey)
    }

    // MARK: - Fetch Profile from Supabase

    func fetchProfile() async {
        isLoading = true
        errorMessage = nil

        print("📥 Fetching user profile from Supabase...")

        do {
            let fetchedProfile = try await SupabaseManager.shared.getUserProfile()
            profile = fetchedProfile

            // Cache profile locally
            saveProfileLocally()

            print("✅ Loaded user profile from Supabase")
        } catch {
            print("❌ Failed to fetch profile: \(error.localizedDescription)")
            errorMessage = "Failed to load profile"

            // Use cached profile on failure
            loadProfileFromCache()
        }

        isLoading = false
    }

    // MARK: - Profile Management (with Supabase sync)

    func updateDietaryPreferences(_ preferences: Set<DietaryTag>) async {
        profile.dietaryPreferences = preferences
        await syncProfile()
    }

    func addDietaryPreference(_ tag: DietaryTag) async {
        profile.dietaryPreferences.insert(tag)
        await syncProfile()
    }

    func removeDietaryPreference(_ tag: DietaryTag) async {
        profile.dietaryPreferences.remove(tag)
        await syncProfile()
    }

    func updateAllergens(_ allergens: Set<DietaryTag>) async {
        profile.allergens = allergens
        await syncProfile()
    }

    func addAllergen(_ tag: DietaryTag) async {
        profile.allergens.insert(tag)
        await syncProfile()
    }

    func removeAllergen(_ tag: DietaryTag) async {
        profile.allergens.remove(tag)
        await syncProfile()
    }

    func updateSpicyTolerance(_ tolerance: SpicyTolerance) async {
        profile.spicyTolerance = tolerance
        await syncProfile()
    }

    func clearProfile() {
        profile = UserProfile()
        saveProfileLocally()
    }

    // MARK: - Supabase Sync

    private func syncProfile() async {
        print("🔄 Syncing profile to Supabase...")

        do {
            try await SupabaseManager.shared.updateUserProfile(profile)

            // Also cache locally for offline access
            saveProfileLocally()

            print("✅ Profile synced successfully")

            ToastManager.shared.show(
                "Profile updated",
                icon: "checkmark.circle.fill",
                type: .success
            )
        } catch {
            print("❌ Failed to sync profile: \(error.localizedDescription)")

            ToastManager.shared.show(
                "Failed to update profile",
                icon: "exclamationmark.triangle",
                type: .error
            )
        }
    }

    // MARK: - Local Cache Management

    private func saveProfileLocally() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }

    private func loadProfileFromCache() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let savedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = savedProfile
            print("📦 Loaded profile from cache")
        }
    }

    // MARK: - Item Compatibility

    func isItemCompatible(with item: MenuItem) -> Bool {
        let itemTags = Set(item.dietaryInfo)

        // Check if item meets dietary preferences
        if !profile.dietaryPreferences.isEmpty {
            let hasPreference = !profile.dietaryPreferences.isDisjoint(with: itemTags)
            if !hasPreference {
                return false
            }
        }

        // Check for allergens
        if !profile.allergens.isEmpty {
            let hasAllergen = !profile.allergens.isDisjoint(with: itemTags)
            if hasAllergen {
                return false
            }
        }

        // Check spicy tolerance
        if profile.spicyTolerance == .none && itemTags.contains(.spicy) {
            return false
        }

        return true
    }

    func getWarnings(for item: MenuItem) -> [String] {
        var warnings: [String] = []
        let itemTags = Set(item.dietaryInfo)

        // Check for allergen warnings
        let allergenMatches = profile.allergens.intersection(itemTags)
        if !allergenMatches.isEmpty {
            let allergenNames = allergenMatches.map { $0.rawValue }.joined(separator: ", ")
            warnings.append("⚠️ Contains allergen: \(allergenNames)")
        }

        // Check spicy warning
        if profile.spicyTolerance == .none && itemTags.contains(.spicy) {
            warnings.append("⚠️ Contains spicy ingredients")
        } else if profile.spicyTolerance == .mild && itemTags.contains(.spicy) {
            warnings.append("🌶️ May be too spicy for your preference")
        }

        return warnings
    }

    func hasCompatibilityIssue(with item: MenuItem) -> Bool {
        let itemTags = Set(item.dietaryInfo)

        // Has allergen
        if !profile.allergens.isDisjoint(with: itemTags) {
            return true
        }

        // Too spicy
        if profile.spicyTolerance == .none && itemTags.contains(.spicy) {
            return true
        }

        return false
    }
}

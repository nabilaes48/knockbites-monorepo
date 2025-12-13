//
//  StoreViewModel.swift
//  knockbites-customer-app
//
//  Created by Claude on 11/18/25.
//

import SwiftUI
import CoreLocation
import Combine

@MainActor
class StoreViewModel: ObservableObject {
    @Published var stores: [Store] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userLocation: CLLocation?

    private let locationManager = CLLocationManager()

    func loadStores(sortByProximity: Bool = true) async {
        isLoading = true
        errorMessage = nil

        do {
            var fetchedStores = try await SupabaseManager.shared.fetchStores()
            print("✅ Loaded \(fetchedStores.count) stores from Supabase")

            // Sort by proximity if user location available
            if sortByProximity, let userLoc = userLocation {
                fetchedStores = fetchedStores.sorted { store1, store2 in
                    let loc1 = CLLocation(latitude: store1.coordinates.latitude, longitude: store1.coordinates.longitude)
                    let loc2 = CLLocation(latitude: store2.coordinates.latitude, longitude: store2.coordinates.longitude)
                    return loc1.distance(from: userLoc) < loc2.distance(from: userLoc)
                }
                print("📍 Stores sorted by proximity to user location")
            }

            stores = fetchedStores

        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load stores: \(error)")
        }

        isLoading = false
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.startUpdatingLocation()

        // Get current location synchronously if available
        if let location = locationManager.location {
            userLocation = location
            print("📍 Got user location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }

    func distanceToStore(_ store: Store) -> Double? {
        guard let userLoc = userLocation else { return nil }
        let storeLoc = CLLocation(latitude: store.coordinates.latitude, longitude: store.coordinates.longitude)
        return storeLoc.distance(from: userLoc)
    }

    func formattedDistance(_ store: Store) -> String? {
        guard let distance = distanceToStore(store) else { return nil }
        let miles = distance / 1609.34 // Convert meters to miles
        if miles < 0.1 {
            return "Nearby"
        } else if miles < 1.0 {
            return String(format: "%.1f mi", miles)
        } else {
            return String(format: "%.0f mi", miles)
        }
    }

    func store(for id: String) -> Store? {
        stores.first { $0.id == id }
    }
}

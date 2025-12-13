//
//  AppTelemetry.swift
//  knockbites-Bussiness-app
//
//  Created during Phase 10 - Release-ready analytics and error tracking
//

import Foundation
import OSLog

/// Lightweight telemetry system for tracking app health, performance, and user behavior.
/// Provides hooks for future integration with analytics platforms (Firebase, Mixpanel, etc.)
actor AppTelemetry {
    static let shared = AppTelemetry()

    // MARK: - Configuration

    private var isEnabled: Bool {
        #if DEBUG
        return false // Disable in debug builds
        #else
        return true // Enable in release builds
        #endif
    }

    private var events: [TelemetryEvent] = []
    private let maxStoredEvents = 100

    private init() {}

    // MARK: - Models

    enum EventType: String {
        case screenView = "screen_view"
        case buttonTap = "button_tap"
        case apiCall = "api_call"
        case apiSuccess = "api_success"
        case apiFailure = "api_failure"
        case error = "error"
        case performance = "performance"
        case userAction = "user_action"
    }

    struct TelemetryEvent {
        let type: EventType
        let name: String
        let timestamp: Date
        let properties: [String: Any]
        let duration: TimeInterval?

        var id: String {
            "\(type.rawValue)-\(name)-\(timestamp.timeIntervalSince1970)"
        }
    }

    // MARK: - Public API

    /// Track a screen view
    func trackScreenView(_ screenName: String, properties: [String: Any] = [:]) {
        track(.screenView, name: screenName, properties: properties)
    }

    /// Track a button tap or user interaction
    func trackUserAction(_ action: String, properties: [String: Any] = [:]) {
        track(.userAction, name: action, properties: properties)
    }

    /// Track an API call start
    func trackAPICall(_ endpoint: String, method: String = "GET") {
        track(.apiCall, name: endpoint, properties: ["method": method])
    }

    /// Track an API success
    func trackAPISuccess(_ endpoint: String, duration: TimeInterval, properties: [String: Any] = [:]) {
        var props = properties
        props["endpoint"] = endpoint
        track(.apiSuccess, name: endpoint, properties: props, duration: duration)
    }

    /// Track an API failure
    func trackAPIFailure(_ endpoint: String, error: Error, duration: TimeInterval) {
        track(.apiFailure, name: endpoint, properties: [
            "endpoint": endpoint,
            "error": error.localizedDescription
        ], duration: duration)
    }

    /// Track a generic error
    func trackError(_ error: Error, context: [String: Any] = [:]) {
        var props = context
        props["error_type"] = String(describing: type(of: error))
        props["error_message"] = error.localizedDescription

        if let appError = error as? AppError {
            props["app_error_type"] = String(describing: appError)
        }

        track(.error, name: "error_occurred", properties: props)
    }

    /// Track performance metrics
    func trackPerformance(_ metric: String, duration: TimeInterval, properties: [String: Any] = [:]) {
        track(.performance, name: metric, properties: properties, duration: duration)
    }

    /// Get breadcrumb trail for debugging
    func getBreadcrumbs(limit: Int = 20) -> [TelemetryEvent] {
        Array(events.suffix(limit))
    }

    /// Clear all stored events
    func clearEvents() {
        events.removeAll()
    }

    // MARK: - Private Methods

    private func track(_ type: EventType, name: String, properties: [String: Any] = [:], duration: TimeInterval? = nil) {
        guard isEnabled else { return }

        let event = TelemetryEvent(
            type: type,
            name: name,
            timestamp: Date(),
            properties: properties,
            duration: duration
        )

        // Store event
        events.append(event)

        // Trim if needed
        if events.count > maxStoredEvents {
            events.removeFirst(events.count - maxStoredEvents)
        }

        // Log to console in debug
        #if DEBUG
        logEvent(event)
        #endif

        // TODO: Send to analytics platform
        // - Firebase Analytics
        // - Mixpanel
        // - PostHog
        // - Custom backend
    }

    private func logEvent(_ event: TelemetryEvent) {
        let logger = OSLog(subsystem: "com.knockbites.app", category: "Telemetry")

        var message = "[Telemetry] \(event.type.rawValue): \(event.name)"

        if let duration = event.duration {
            message += " (duration: \(String(format: "%.2f", duration))s)"
        }

        if !event.properties.isEmpty {
            message += " properties: \(event.properties)"
        }

        os_log("%{public}@", log: logger, type: .info, message)
    }
}

// MARK: - Convenience Extensions

extension AppTelemetry {
    /// Track time-to-first-data for a screen
    func trackTimeToData(_ screenName: String, duration: TimeInterval) {
        trackPerformance("time_to_first_data", duration: duration, properties: [
            "screen": screenName
        ])
    }

    /// Track repository failure
    func trackRepositoryFailure(_ repository: String, operation: String, error: Error) {
        trackError(error, context: [
            "repository": repository,
            "operation": operation
        ])
    }

    /// Track repository success with timing
    func trackRepositorySuccess(_ repository: String, operation: String, duration: TimeInterval, recordCount: Int = 0) {
        trackPerformance("repository_operation", duration: duration, properties: [
            "repository": repository,
            "operation": operation,
            "record_count": recordCount
        ])
    }
}

// MARK: - Analytics Integration Points

extension AppTelemetry {
    /// Configure third-party analytics (call on app launch)
    func configure() {
        // TODO: Initialize Firebase Analytics
        // FirebaseApp.configure()

        // TODO: Initialize Mixpanel
        // Mixpanel.initialize(token: "YOUR_TOKEN")

        // TODO: Initialize PostHog
        // PostHogSDK.shared.setup(...)

        Logger.info("AppTelemetry configured", category: .general)
    }

    /// Set user identifier for analytics
    func setUserID(_ userID: String) {
        // TODO: Set user ID in analytics platforms
        // Analytics.setUserID(userID)
        // Mixpanel.identify(distinctId: userID)

        Logger.info("User identified: \(userID)", category: .auth)
    }

    /// Set user properties
    func setUserProperties(_ properties: [String: Any]) {
        // TODO: Set user properties in analytics platforms
        // Analytics.setUserProperty(...)
        // Mixpanel.people.set(...)

        Logger.debug("User properties set", category: .auth)
    }

    /// Clear user data (on logout)
    func clearUserData() {
        // TODO: Reset analytics user
        // Analytics.resetAnalyticsData()
        // Mixpanel.reset()

        clearEvents()
        Logger.info("User data cleared", category: .auth)
    }
}

// MARK: - Performance Timing Helper

struct PerformanceTimer {
    private let start: Date
    private let operation: String
    private let category: String

    init(operation: String, category: String = "general") {
        self.start = Date()
        self.operation = operation
        self.category = category
    }

    func end(properties: [String: Any] = [:]) async {
        let duration = Date().timeIntervalSince(start)
        await AppTelemetry.shared.trackPerformance(operation, duration: duration, properties: properties)
    }
}

// MARK: - Usage Examples

/*

 // MARK: - Screen View Tracking

 struct DashboardView: View {
     var body: some View {
         VStack {
             // ... content
         }
         .onAppear {
             Task {
                 await AppTelemetry.shared.trackScreenView("dashboard")
             }
         }
     }
 }

 // MARK: - API Call Tracking

 func fetchOrders() async throws -> [Order] {
     let timer = PerformanceTimer(operation: "fetch_orders")

     do {
         let orders = try await OrdersRepository.shared.fetchOrders()
         await AppTelemetry.shared.trackAPISuccess("orders", duration: Date().timeIntervalSince(timer.start))
         await timer.end(properties: ["count": orders.count])
         return orders
     } catch {
         await AppTelemetry.shared.trackAPIFailure("orders", error: error, duration: Date().timeIntervalSince(timer.start))
         throw error
     }
 }

 // MARK: - Error Tracking

 catch {
     await AppTelemetry.shared.trackError(error, context: [
         "screen": "dashboard",
         "action": "load_orders"
     ])
 }

 // MARK: - User Action Tracking

 Button("Mark Ready") {
     Task {
         await AppTelemetry.shared.trackUserAction("mark_order_ready", properties: [
             "order_id": order.id,
             "status": order.status
         ])
     }
 }

 // MARK: - App Launch

 @main
 struct KnockBitesApp: App {
     init() {
         Task {
             await AppTelemetry.shared.configure()
         }
     }
 }

 */

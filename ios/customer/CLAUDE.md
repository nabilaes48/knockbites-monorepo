# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cameron's Customer App is an iOS application built with SwiftUI and Swift 5.0 for ordering food from Cameron's restaurants. Targets iOS 17.0+ and supports iPhone/iPad.

**Bundle Identifier:** `com.camerons-customer.app.camerons-customer-app`

## Building and Running

```bash
# Build the app
xcodebuild -project camerons-customer-app.xcodeproj -scheme camerons-customer-app -configuration Debug build

# Run all tests (unit + UI)
xcodebuild test -project camerons-customer-app.xcodeproj -scheme camerons-customer-app -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a specific test class
xcodebuild test -project camerons-customer-app.xcodeproj -scheme camerons-customer-app -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'camerons-customer-appTests/camerons_customer_appTests'

# Clean build
xcodebuild clean -project camerons-customer-app.xcodeproj -scheme camerons-customer-app
```

## Fastlane (App Store Deployment)

```bash
# Build and upload to TestFlight
fastlane ios beta

# Build and upload to App Store (production release)
fastlane ios release

# Build only (no upload)
fastlane ios build

# Run tests via fastlane
fastlane ios test

# Increment build number
fastlane ios bump_build

# Increment version (patch/minor/major)
fastlane ios bump_version type:patch

# Take App Store screenshots (all devices)
fastlane ios screenshots

# Quick screenshots (iPhone 16 Pro Max only - faster for testing)
fastlane ios screenshots_quick

# Upload screenshots only
fastlane ios upload_screenshots

# Upload metadata only (no build, no screenshots)
fastlane ios metadata

# Full release: screenshots + metadata + build + upload
fastlane ios full_release

# Refresh metadata and screenshots only (no new build)
fastlane ios refresh

# Submit for App Store review
fastlane ios submit_review

# Download existing metadata from App Store Connect
fastlane ios download_metadata

# Sync certificates and provisioning profiles
fastlane ios sync_certs

# Register new device
fastlane ios add_device name:"Device Name" udid:"UDID"
```

## Dependencies

**Supabase Swift SDK** (v2.37.0) - database, auth, storage, real-time subscriptions.

## Project Structure

```
camerons-customer-app/
├── SupabaseConfig.swift              # Supabase URL, keys, imageURL(from:) helper
├── SupabaseManager.swift             # Singleton for all database operations
├── camerons-customer-app/
│   ├── camerons_customer_appApp.swift    # App entry point (@main)
│   ├── Core/                         # Feature modules (MVVM pattern)
│   │   ├── Authentication/           # Login, signup, AuthManager singleton
│   │   ├── Home/                     # MainTabView, store selector
│   │   ├── Menu/                     # Menu browsing, ItemDetailView
│   │   ├── Cart/                     # CartViewModel, checkout
│   │   ├── Orders/                   # Order history, tracking
│   │   ├── Favorites/                # Saved favorite items
│   │   ├── Rewards/                  # Loyalty program
│   │   └── Profile/                  # User settings, preferences
│   ├── Shared/
│   │   ├── Components/               # Reusable UI (PortionSelectorButton, etc.)
│   │   ├── DTOs/                     # Data Transfer Objects for Supabase
│   │   ├── Extensions/               # Color+Theme, View+Extensions
│   │   ├── Services/                 # RealtimeManager for live order updates
│   │   └── Utilities/                # Models.swift, Constants, Notifications
│   └── Assets.xcassets/
├── camerons-customer-appTests/       # Swift Testing framework (@Test, #expect)
└── database-migrations/              # SQL migration files
```

## Architecture

### MVVM Pattern
Each `Core/` feature module has `Views/`, `ViewModels/` (`@MainActor ObservableObject`), and optionally `Models/`. Shared models are in `Shared/Utilities/Models.swift`.

### App Entry Point (`camerons_customer_appApp.swift`)
- **Auth Flow**: `LoginView` → `StoreSelectionWrapper` → `MainTabView`
- **Global State** via `@EnvironmentObject`:
  - `AuthManager`: Supabase Auth singleton, observes `authStateChanges`
  - `CartViewModel`: Cart + selected store
  - `FavoritesViewModel`, `ProfileViewModel`, `PaymentMethodViewModel`
- **Settings**: `AppSettings.shared` via custom environment key
- **Singletons**: `AuthManager.shared`, `AppSettings.shared`, `ToastManager.shared`, `SupabaseManager.shared`

### Supabase Integration
- **SupabaseManager**: Singleton for all database operations
- **SupabaseConfig**: URL, keys, `imageURL(from:)` converts relative paths to storage URLs
- **RealtimeManager**: Live order status updates via Supabase Realtime V2

**Key Operations**:
- `fetchStores()`, `fetchMenuItems()`, `fetchCategories()`
- `fetchMenuItemCustomizations(for:)`: Portion-based customizations
- `submitOrder()`: Returns `(orderId: String, orderNumber: String)`

### UI & Design System
- **Design Tokens**: `Constants.swift` (`AppFonts`, `Spacing`, `CornerRadius`)
- **Theme**: `Color+Theme.swift` for semantic colors
- **Toast**: `ToastManager.shared.show(message, icon, type)`, add `.withToast()` modifier
- **Loading**: `.loading(viewModel.isLoading)` modifier for overlays

### Key Data Models (`Models.swift`)
- **MenuItem**: Price, dietary info, `customizationGroups`, `portionCustomizations`
- **CartItem**: `selectedOptions: [String: [String]]`, `portionSelections: [Int: PortionLevel]`, `totalPrice` computed
- **PortionLevel**: `.none`, `.light`, `.regular`, `.extra` with emoji indicators
- **MenuItemCustomization**: Portion-based customizations with tiered pricing
- **Order**: Status tracking, `orderNumber` (human-readable)

### Swift Configuration
- Swift 5.0, iOS 17.0+
- MainActor by default (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- Swift Testing framework (`@Test`, `#expect(...)`)

## Development Patterns

### Adding Features
- Create feature module in `Core/[FeatureName]/` with `Views/` and `ViewModels/`
- ViewModels: `@MainActor class [Name]ViewModel: ObservableObject`
- Shared models go in `Shared/Utilities/Models.swift`
- Reusable components in `Shared/Components/`

### Authentication
- `AuthManager.shared` singleton manages auth via Supabase
- Sign up creates user + customer profile in `customer_profiles`
- Session auto-persists via Supabase SDK
- Auth state: `@Published var isAuthenticated: Bool`

### Supabase Operations
```swift
// Fetch data
let stores = try await SupabaseManager.shared.fetchStores()
let items = try await SupabaseManager.shared.fetchMenuItems()
let customizations = try await SupabaseManager.shared.fetchMenuItemCustomizations(for: itemId)

// Submit order
let (orderId, orderNumber) = try await SupabaseManager.shared.submitOrder(...)

// Real-time (uses Notification.Name.orderStatusChanged)
RealtimeManager.shared.subscribeToOrder(orderId:) // Posts NotificationCenter updates

// Images
let url = SupabaseConfig.imageURL(from: relativePath)
```

### Portion-Based Customizations

The app supports two customization systems:

**Legacy System** (still supported):
```swift
selectedOptions: [String: [String]] // groupId: [optionIds]
```

**Portion-Based System** (current):
```swift
portionSelections: [Int: PortionLevel] // customizationId: portion
```

**UI Components** in `Shared/Components/`:
- `PortionSelectorButton`: 4-level selector (None/Light/Regular/Extra)
- `IngredientRow`: Ingredient name + portion buttons
- `CategorySection`: Groups by category (🥗 Vegetables, 🥫 Sauces, ✨ Extras)

**Pricing**:
- Free items (vegetables, sauces): $0 at all portions
- Premium items: Tiered pricing (None=$0, Light/Regular/Extra=charged)

### Testing
Uses Swift Testing framework:
```swift
import Testing

@Test func example() async throws {
    #expect(condition)
}
```

## Database Tables

Key tables accessed via `SupabaseManager`:
- `stores`: Store locations with coordinates
- `menu_items`: Menu with `category_id`, prices, availability
- `menu_item_customizations`: Portion-based ingredient customizations
- `categories`: Menu categories with sort order
- `orders` / `order_items`: Order records with auto-generated `order_number`
- `customers`: Customer profiles linked to `auth.users` via `auth_user_id` (UUID)
- `customer_favorites`: User's favorited menu items
- `customer_addresses`: Saved delivery addresses

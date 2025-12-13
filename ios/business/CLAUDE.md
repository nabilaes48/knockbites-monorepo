# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Reference

### Build & Run
```bash
# Build for Debug
xcodebuild -scheme camerons-Bussiness-app -configuration Debug build

# Build and run on simulator
xcodebuild -scheme camerons-Bussiness-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Clean build folder
xcodebuild -scheme camerons-Bussiness-app clean
```

### Testing
```bash
# Run all tests
xcodebuild test -scheme camerons-Bussiness-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run only unit tests
xcodebuild test -scheme camerons-Bussiness-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:camerons-Bussiness-appTests

# Run a single test
xcodebuild test -scheme camerons-Bussiness-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:camerons-Bussiness-appTests/camerons_Bussiness_appTests/example
```

### Database Migrations
Database migrations are in `database/migrations/`. Apply via Supabase Dashboard → SQL Editor:
- **024** - Analytics views (required for analytics features)
- **025_v2** - Row Level Security policies (critical for security)
- **042-044** - Portion-based customizations (iOS implementation pending)

## Project Overview

Restaurant management iOS app (SwiftUI) with Supabase backend. The Node.js backend in `/backend` is legacy and not actively used.

**Key specs:**
- iOS 18.0+ / SwiftUI / Swift 5.0
- Bundle ID: `com.-camerons.app.camerons-Bussiness-app`
- Package: Supabase Swift SDK (SPM)

## Architecture

### MVVM Pattern
- **Models**: `Shared/Models.swift` - Core data structures (Store, Order, MenuItem, CartItem)
- **ViewModels**: Feature-specific in `Core/*/` folders (e.g., `DashboardViewModel`, `KitchenViewModel`)
- **Views**: SwiftUI views using `@StateObject` and `@EnvironmentObject`

### Key Files
| File | Purpose |
|------|---------|
| `SupabaseManager.swift` | Singleton for all Supabase API calls |
| `camerons-Bussiness-app/Auth/AuthManager.swift` | Authentication state, RBAC, session management |
| `camerons-Bussiness-app/Shared/Models.swift` | Core data models |
| `camerons-Bussiness-app/Services/AnalyticsService.swift` | Real analytics data from Supabase |

### Services Layer
Business logic lives in `Services/`, not ViewModels:
- `AnalyticsService.swift` - Fetches from PostgreSQL analytics views
- `MarketingService.swift` - Loyalty, coupons, referrals
- `NotificationsService.swift` - Push notification campaigns

### Order Status Flows
**Dashboard** (general management): `received` → `preparing` → `ready` → `completed`

**Kitchen Display** (granular Kanban): `received` → `acknowledged` → `preparing` → `ready` → `pickedUp` → `completed`
- Drag-and-drop between columns using `.onDrag()` / `.onDrop()`
- State persists in UserDefaults (key: `kitchen_orders`)

### RBAC System
```swift
// Check specific permission
authManager.hasDetailedPermission("orders.create")
authManager.hasDetailedPermission("analytics.financial")

// Check store access
authManager.hasStoreAccess(storeId: storeId)

// Check management hierarchy
authManager.canManageUser(targetUser)
authManager.isSuperAdmin()
```

## Testing Frameworks

### Unit Tests (Swift Testing)
```swift
import Testing
@testable import camerons_Bussiness_app

struct MyFeatureTests {
    @Test func example() async throws {
        #expect(condition == true)
    }
}
```

### UI Tests (XCTest)
Traditional `XCTestCase` subclasses with `XCUIApplication()`.

## Development Guidelines

### Real Data Philosophy
- **NO MOCK DATA** in production code - all views show real Supabase data
- Empty/zero values indicate missing database records, not placeholder data
- `MockDataService.swift` exists but should not be used in production views

### Adding Features
1. Create views in appropriate `Core/` subfolder
2. Add models to `Shared/Models.swift` with `Codable` conformance
3. Complex business logic goes in `Services/`
4. Add `#Preview` macros to all new views

### iOS Sync (Web-to-iOS Parity)
When implementing features that exist on web but not iOS:
1. Check `README_IOS_SYNC.md` and `IOS_SYNC_FILES_INDEX.md`
2. Review relevant migration files in `database/migrations/`
3. Migrations 042-044 are deployed but iOS implementation is pending

### Pending Implementation
- **Portion-Based Customizations**: Database ready (13 ingredient templates, 6 menu items). See `IOS_SYNC_PORTION_CUSTOMIZATIONS.md` for Swift implementation guide.
- **Order Number Format**: Web uses `[STORE_CODE]-[YYMMDD]-[SEQUENCE]` (e.g., HM-251119-001)

## Important Notes

- Primary backend is **Supabase**, not the Node.js backend
- Default actor isolation is `MainActor` (important for UI updates)
- Analytics features require migration 024 to be executed
- Security RLS policies (migration 025) must be run for data protection
- Kitchen and Dashboard have distinct order status pipelines - don't conflate them

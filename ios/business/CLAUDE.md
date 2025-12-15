# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Reference

### Build & Run
```bash
# Build for Debug
xcodebuild -scheme KnockBites-Business -configuration Debug build

# Build and run on simulator
xcodebuild -scheme KnockBites-Business -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Clean build folder
xcodebuild -scheme KnockBites-Business clean
```

### Testing
```bash
# Run all tests
xcodebuild test -scheme KnockBites-Business -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run only unit tests
xcodebuild test -scheme KnockBites-Business -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:KnockBites-BusinessTests

# Run a single test
xcodebuild test -scheme KnockBites-Business -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:KnockBites-BusinessTests/knockbites_Bussiness_appTests/example
```

### Database Migrations
Database migrations are in `database/migrations/`. Apply via Supabase Dashboard → SQL Editor:
- **024** - Analytics views (required for analytics features)
- **025_v2** - Row Level Security policies (critical for security)

## Project Overview

Restaurant management iOS app (SwiftUI) with Supabase backend. The Node.js backend in `_archived/backend/` is legacy and not actively used.

**Key specs:**
- iOS 18.0+ / SwiftUI / Swift 5.0
- Bundle ID: `com.-camerons.app.camerons-Bussiness-app`
- Package: Supabase Swift SDK (SPM)

## Architecture

### MVVM + Repository Pattern
```
Views → ViewModels → Repositories/Services → SupabaseManager → Supabase
```

### Directory Structure
| Directory | Purpose |
|-----------|---------|
| `KnockBites-Business/Core/` | Feature modules (Dashboard, Kitchen, Menu, Analytics, Marketing, Settings) |
| `KnockBites-Business/Core/Data/Repositories/` | Data access layer (OrdersRepository, MenuRepository, etc.) |
| `KnockBites-Business/Services/` | Business logic (AnalyticsService, MarketingService, NotificationsService) |
| `KnockBites-Business/SharedModels/` | Domain-separated Codable models (Orders, Menu, Loyalty, etc.) |
| `KnockBites-Business/Shared/` | UI components, utilities, legacy Models.swift |
| `KnockBites-Business/Auth/` | Authentication and RBAC |

### Key Files
| File | Purpose |
|------|---------|
| `SupabaseManager.swift` | Singleton for all Supabase API calls |
| `KnockBites-Business/Auth/AuthManager.swift` | Authentication state, RBAC, session management |
| `KnockBites-Business/Auth/RBACModels.swift` | Store assignments, user hierarchy, permission audit |
| `KnockBites-Business/Shared/Models.swift` | Core data models (Store, MenuItem, CartItem) |
| `KnockBites-Business/SharedModels/Orders.swift` | Order and OrderItem models |

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
@testable import knockbites_Bussiness_app

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
1. Create views in appropriate `Core/` subfolder with accompanying ViewModel
2. Add domain models to `SharedModels/` (e.g., `SharedModels/Orders.swift`)
3. Data access goes in `Core/Data/Repositories/`
4. Complex business logic goes in `Services/`
5. Add `#Preview` macros to all new views

## Important Notes

- Primary backend is **Supabase**, not the Node.js backend
- Default actor isolation is `MainActor` (important for UI updates)
- Analytics features require migration 024 to be executed
- Security RLS policies (migration 025) must be run for data protection
- Kitchen and Dashboard have distinct order status pipelines - don't conflate them

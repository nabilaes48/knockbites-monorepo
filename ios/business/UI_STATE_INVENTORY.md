# UI State Inventory - Phase 8

This document catalogs all loading, error, and empty state patterns across the app.

## Summary

| Screen | Loading | Empty | Error | Notes |
|--------|---------|-------|-------|-------|
| DashboardView | `ProgressView("Loading orders...")` | Custom inline empty state | Alert dialog | Has inline empty states for active/completed |
| KitchenDisplayView | None visible | None | `errorMessage` in VM (unused) | No loading indicator shown |
| MenuManagementView | `ProgressView("Loading menu...")` | None | Alert dialog | Good pattern |
| MarketingDashboardView | Via sections | None | None visible | isLoading passed to sections |
| AnalyticsView | `ProgressView("Loading analytics...")` | Conditional sections | Alert dialog | Good pattern |
| MoreView | None | None | None | Static content |
| SettingsView | None | None | None | Static content |
| CustomerLoyaltyView | `ProgressView()` | `EmptyStateView` | `ErrorStateView` | **Best pattern** |
| AutomatedCampaignsView | Via viewModel | `EmptyStateView` | `ErrorStateView` banner | Good pattern |
| RewardsCatalogView | Via viewModel | `EmptyStateView` | None visible | Partial |
| BulkPointsAwardView | `ProgressView()` | `EmptyStateView` | Alert dialog | Good pattern |
| DatabaseDiagnosticsView | Multiple `ProgressView()` | Text | Text error | Inline indicators |

---

## Detailed Inventory

### 1. DashboardView
**File:** `Core/Dashboard/DashboardView.swift`

| State | Implementation | Pattern |
|-------|---------------|---------|
| Loading | `ProgressView("Loading orders...")` in ZStack | Raw ProgressView |
| Empty (active) | Custom VStack with icon, title, subtitle | **Inline custom** |
| Empty (completed) | Custom VStack with icon, title | **Inline custom** |
| Error | `.alert("Error", isPresented:)` with OK button | Alert dialog |

**Issues:**
- Custom empty states instead of `EmptyStateView`
- Loading uses raw ProgressView

---

### 2. KitchenDisplayView
**File:** `Core/Kitchen/KitchenDisplayView.swift`

| State | Implementation | Pattern |
|-------|---------------|---------|
| Loading | **None visible** | Missing |
| Empty | **None visible** | Missing |
| Error | `errorMessage` in VM but not displayed | **Bug** |

**Issues:**
- No loading indicator during initial load
- `errorMessage` published but never shown in UI
- No empty state when no orders in selected tab

---

### 3. MenuManagementView
**File:** `Core/Menu/MenuManagementView.swift`

| State | Implementation | Pattern |
|-------|---------------|---------|
| Loading | `ProgressView("Loading menu...")` | Raw ProgressView |
| Empty | **None** | Missing |
| Error | `.alert("Error", isPresented:)` | Alert dialog |

**Issues:**
- No empty state when menu is empty
- Loading uses raw ProgressView

---

### 4. MarketingDashboardView
**File:** `Core/Marketing/MarketingDashboardView.swift`

| State | Implementation | Pattern |
|-------|---------------|---------|
| Loading | `isLoading` passed to `CouponPerformanceSection` | Delegated |
| Empty | None at dashboard level | Sections handle |
| Error | `errorMessage` in VM but not shown | **Bug** |

**Issues:**
- Error message not displayed
- No top-level loading state

---

### 5. AnalyticsView
**File:** `Core/Analytics/AnalyticsView.swift`

| State | Implementation | Pattern |
|-------|---------------|---------|
| Loading | `ProgressView("Loading analytics...")` in ZStack | Raw ProgressView |
| Empty | Conditional `if !viewModel.data.isEmpty` | Sections hidden |
| Error | `.alert("Error", isPresented:)` | Alert dialog |

**Issues:**
- Sections just don't render if empty (no user feedback)
- Loading uses raw ProgressView

---

### 6. CustomerLoyaltyView
**File:** `Core/Marketing/CustomerLoyaltyView.swift`

| State | Implementation | Pattern |
|-------|---------------|---------|
| Loading | `ProgressView()` centered | Raw ProgressView |
| Empty | `EmptyStateView` with icon, title, message | **Shared component** |
| Error | `ErrorStateView` fullScreen | **Shared component** |

**Notes:** This is the **best pattern** currently in use. Uses shared components.

---

### 7. AutomatedCampaignsView
**File:** `Core/Marketing/AutomatedCampaignsView.swift`

| State | Implementation | Pattern |
|-------|---------------|---------|
| Loading | Via `viewModel.isLoading` | Inferred |
| Empty | `EmptyStateView` | **Shared component** |
| Error | `ErrorStateView` banner style | **Shared component** |

**Notes:** Good use of shared components.

---

### 8. RewardsCatalogView
**File:** `Core/Marketing/RewardsCatalogView.swift`

| State | Implementation | Pattern |
|-------|---------------|---------|
| Loading | Via `viewModel.isLoading` | Inferred |
| Empty | `EmptyStateView` | **Shared component** |
| Error | **None visible** | Missing |

---

### 9. BulkPointsAwardView
**File:** `Core/Marketing/BulkPointsAwardView.swift`

| State | Implementation | Pattern |
|-------|---------------|---------|
| Loading | `ProgressView()` | Raw ProgressView |
| Empty | `EmptyStateView` for customers | **Shared component** |
| Error | `.alert("Error", isPresented:)` | Alert dialog |

---

### 10. DatabaseDiagnosticsView
**File:** `Core/Settings/DatabaseDiagnosticsView.swift`

| State | Implementation | Pattern |
|-------|---------------|---------|
| Loading | Multiple inline `ProgressView()` | Raw ProgressView |
| Empty | `Text("No orders found")` | Inline text |
| Error | `Text(error)` inline | Inline text |

---

## Pattern Summary

### Current Loading Patterns
1. `ProgressView("Message...")` - Most common (7 instances)
2. `ProgressView()` alone - 5 instances
3. Passed via `isLoading` prop - 3 instances

### Current Empty State Patterns
1. `EmptyStateView` shared component - 4 instances (**preferred**)
2. Custom inline VStack - 3 instances
3. None/hidden sections - 4 instances
4. Plain `Text("No data")` - 1 instance

### Current Error Patterns
1. `.alert("Error", isPresented:)` - 6 instances
2. `ErrorStateView` shared component - 2 instances (**preferred**)
3. None/silent - 4 instances (**bugs**)

---

## Recommended Actions

### Priority 1: Create `LoadingStateView`
Replace raw `ProgressView` with consistent shared component.

### Priority 2: Fix Missing Error Displays
- KitchenDisplayView: Display `errorMessage`
- MarketingDashboardView: Display `errorMessage`

### Priority 3: Standardize Empty States
Replace custom empty states with `EmptyStateView`:
- DashboardView (active orders, completed orders)
- MenuManagementView
- AnalyticsView sections

### Priority 4: Create Alert/Toast Helper
Replace repeated `.alert()` patterns with reusable modifier.

### Priority 5: Create `AppError` Abstraction
Map raw errors to user-friendly messages consistently.

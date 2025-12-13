# Customer iOS App Design System Mapping

**Generated:** 2025-12-02
**Phase:** 10 — Cross-Platform Feature Parity
**Purpose:** Map Business iOS design tokens to Customer iOS app implementation

---

## Overview

The Customer iOS app should **directly adopt** the same `DesignSystem.swift` from the Business iOS app. This ensures perfect visual consistency across both iOS platforms.

**Source of Truth:** Business iOS `camerons-Bussiness-app/Shared/DesignSystem.swift`

**Strategy:** Share the design system file across both iOS apps.

---

## 1. Recommended Approach: Shared Swift Package

### Option A: File Duplication (Simple)

**Copy the design system to Customer app:**

```bash
# In Customer iOS repository
cp ../camerons-Bussiness-app/camerons-Bussiness-app/Shared/DesignSystem.swift ./Shared/
```

**Pros:**
- Simple and immediate
- No additional dependencies

**Cons:**
- Manual sync required
- Risk of drift

---

### Option B: Swift Package (Recommended)

**Create shared package:**

```
CameronsDesignSystem/
├── Package.swift
├── Sources/
│   └── CameronsDesignSystem/
│       ├── Colors.swift
│       ├── Typography.swift
│       ├── Spacing.swift
│       ├── Shadows.swift
│       ├── Animations.swift
│       └── ButtonStyles.swift
```

**Benefits:**
- Single source of truth
- Automatic updates
- Version control
- Reusable across any iOS project

---

## 2. Design System Adoption Checklist

### Customer iOS App Should Have:

| Component | Status | Action Required |
|-----------|--------|-----------------|
| **Colors** | ⚠️ Unknown | Adopt from Business app |
| **Typography** | ⚠️ Unknown | Adopt AppFonts struct |
| **Spacing** | ⚠️ Unknown | Adopt Spacing constants |
| **Corner Radius** | ⚠️ Unknown | Adopt CornerRadius constants |
| **Shadows** | ⚠️ Unknown | Adopt AppShadow system |
| **Animations** | ⚠️ Unknown | Adopt AnimationDuration |
| **Button Styles** | ⚠️ Unknown | Adopt PrimaryButtonStyle, etc. |
| **Card Styles** | ⚠️ Unknown | Adopt cardStyle modifier |
| **Icon Sizes** | ⚠️ Unknown | Adopt IconSize constants |
| **Order Status Colors** | ⚠️ Unknown | Adopt status colors |

---

## 3. Key Differences for Customer App

While most of the design system should be identical, the Customer app has some unique needs:

### 3.1 Customer-Specific Colors

```swift
// Additional colors for Customer app
extension Color {
    // Loyalty/Gamification
    static let rewardGold = Color(hex: "#FFD700")
    static let tierBronze = Color(hex: "#CD7F32")
    static let tierSilver = Color(hex: "#C0C0C0")
    static let tierGold = Color(hex: "#FFD700")
    static let tierPlatinum = Color(hex: "#E5E4E2")

    // Cart/Checkout
    static let cartAccent = Color.brandPrimary
    static let checkoutSuccess = Color.success

    // Ratings
    static let ratingStar = Color.yellow
}
```

### 3.2 Customer-Specific Typography

```swift
// Additional typography for Customer app
extension AppFonts {
    static let priceDisplay = Font.system(size: 28, weight: .bold, design: .rounded)
    static let itemName = Font.system(size: 20, weight: .semibold)
    static let loyaltyPoints = Font.system(size: 32, weight: .black, design: .rounded)
}
```

### 3.3 Customer-Specific Button Styles

```swift
// Add to Cart button
struct AddToCartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(Color.success)
            .cornerRadius(CornerRadius.lg)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.fast), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == AddToCartButtonStyle {
    static var addToCart: AddToCartButtonStyle { AddToCartButtonStyle() }
}
```

---

## 4. Component Mapping

### Business App → Customer App Equivalents

| Business Component | Customer Equivalent | Notes |
|--------------------|---------------------|-------|
| Order status card | Order tracking card | Same design, different data |
| Menu item management | Menu item browsing | Same card, remove edit controls |
| Analytics charts | Personal stats (if added) | Similar visual style |
| Kitchen Kanban | Order progress stepper | Different layout, same colors |
| Dashboard header | Home header | Similar structure |
| Settings list | Profile/Settings list | Identical |

---

## 5. Usage Examples

### Order Status Card (Customer App)

```swift
struct CustomerOrderCardView: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(order.orderNumber)
                    .font(AppFonts.orderNumber)

                Spacer()

                StatusBadge(status: order.status)
            }

            Text(order.storeName)
                .font(AppFonts.subheadline)
                .foregroundColor(.textSecondary)

            Text("$\(order.total, specifier: "%.2f")")
                .font(AppFonts.title2)

            EstimatedTimeView(readyAt: order.estimatedReadyAt)
        }
        .cardStyle() // Uses shared card style
    }
}
```

### Menu Item Card (Customer App)

```swift
struct MenuItemCardView: View {
    let item: MenuItem
    @State private var quantity = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.surfaceSecondary)
            }
            .frame(height: 200)
            .cornerRadius(CornerRadius.lg)

            Text(item.name)
                .font(AppFonts.headline)

            Text(item.description ?? "")
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)
                .lineLimit(2)

            HStack {
                Text("$\(item.price, specifier: "%.2f")")
                    .font(AppFonts.title3)

                Spacer()

                Button("Add to Cart") {
                    // Add to cart logic
                }
                .buttonStyle(.addToCart)
            }
        }
        .cardStyle()
    }
}
```

### Loyalty Balance Card (Customer App)

```swift
struct LoyaltyBalanceCardView: View {
    let points: Int
    let tier: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Your Points")
                .font(AppFonts.headline)
                .foregroundColor(.textSecondary)

            Text("\(points)")
                .font(AppFonts.loyaltyPoints)
                .foregroundColor(.brandPrimary)

            HStack(spacing: Spacing.sm) {
                Image(systemName: "star.fill")
                    .font(.system(size: IconSize.md))
                    .foregroundColor(tierColor(tier))

                Text(tier)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(Color.surface)
        .cornerRadius(CornerRadius.xl)
        .shadow(color: AppShadow.md, radius: 8, x: 0, y: 4)
    }

    private func tierColor(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "bronze": return .tierBronze
        case "silver": return .tierSilver
        case "gold": return .tierGold
        case "platinum": return .tierPlatinum
        default: return .brandPrimary
        }
    }
}
```

---

## 6. Alignment Verification

### Visual Consistency Checklist

Test the following to ensure design parity:

- [ ] Order status colors match across apps
- [ ] Button styles look identical
- [ ] Card shadows are the same
- [ ] Typography scales match
- [ ] Spacing feels consistent
- [ ] Corner radii match
- [ ] Animations have same duration
- [ ] Dark mode looks consistent

### Component Parity Checklist

- [ ] Order cards use same design
- [ ] Menu item cards use same base design
- [ ] Settings screens use same list style
- [ ] Navigation bars use same styling
- [ ] Tab bars use same styling
- [ ] Loading states use same spinners
- [ ] Error states use same colors
- [ ] Success states use same colors

---

## 7. Current Status Assessment

| Component | Business iOS | Customer iOS | Alignment Status |
|-----------|--------------|--------------|------------------|
| **Colors** | ✅ Defined | ⚠️ Unknown | Needs audit |
| **Typography** | ✅ Defined | ⚠️ Unknown | Needs audit |
| **Spacing** | ✅ Defined | ⚠️ Unknown | Needs audit |
| **Corner Radius** | ✅ Defined | ⚠️ Unknown | Needs audit |
| **Shadows** | ✅ Defined | ⚠️ Unknown | Needs audit |
| **Animations** | ✅ Defined | ⚠️ Unknown | Needs audit |
| **Button Styles** | ✅ 3 styles | ⚠️ Unknown | Needs audit |
| **Card Styles** | ✅ Defined | ⚠️ Unknown | Needs audit |
| **Icon Sizes** | ✅ Defined | ⚠️ Unknown | Needs audit |
| **Order Status** | ✅ 5 colors | ⚠️ Unknown | Needs audit |

---

## 8. Migration Plan

### Phase 1: Audit (Week 1)
1. ✅ Review Customer iOS codebase
2. ✅ Document existing design tokens
3. ✅ Identify inconsistencies with Business app
4. ✅ Take screenshots for comparison

### Phase 2: Adopt Core System (Week 2)
1. ✅ Copy `DesignSystem.swift` to Customer app
2. ✅ Replace hardcoded colors with tokens
3. ✅ Replace hardcoded spacing with tokens
4. ✅ Replace hardcoded radii with tokens

### Phase 3: Implement Button Styles (Week 2)
1. ✅ Update all primary buttons to use `.primary` style
2. ✅ Update all secondary buttons to use `.secondary` style
3. ✅ Add custom `.addToCart` style
4. ✅ Test all button interactions

### Phase 4: Implement Card Styles (Week 3)
1. ✅ Apply `.cardStyle()` to all cards
2. ✅ Ensure consistent shadows
3. ✅ Verify spacing within cards
4. ✅ Test light/dark mode

### Phase 5: Visual QA (Week 3)
1. ✅ Side-by-side comparison with Business app
2. ✅ Fix any visual discrepancies
3. ✅ Test on multiple device sizes
4. ✅ Validate accessibility

---

## 9. Differences to Preserve

Some Customer app elements should intentionally differ:

### Customer-Specific UI Elements

| Element | Why Different | Guidance |
|---------|---------------|----------|
| Add to Cart button | Customer-specific action | Use green (success color) |
| Loyalty point display | Gamification emphasis | Use larger, bolder typography |
| Tier badges | Visual hierarchy | Use tier-specific colors |
| Price displays | Customer focus | Use priceDisplay font |
| Ratings/Reviews | Social proof | Use ratingStar color |

### Business-Only UI Elements

These should NOT appear in Customer app:

- Kitchen Kanban board
- Analytics charts (unless personal stats)
- Marketing campaign management
- User role badges
- Multi-store switching (unless customer has preferences)
- Bulk operations UI
- Admin controls

---

## 10. Testing Strategy

### Visual Regression Testing

```swift
// SnapshotTests.swift
import SnapshotTesting
import XCTest

class DesignSystemSnapshotTests: XCTestCase {
    func testOrderCard() {
        let card = CustomerOrderCardView(order: mockOrder)
        assertSnapshot(matching: card, as: .image(layout: .device(config: .iPhone13)))
    }

    func testMenuItemCard() {
        let card = MenuItemCardView(item: mockMenuItem)
        assertSnapshot(matching: card, as: .image(layout: .device(config: .iPhone13)))
    }

    func testLoyaltyCard() {
        let card = LoyaltyBalanceCardView(points: 1250, tier: "Gold")
        assertSnapshot(matching: card, as: .image(layout: .device(config: .iPhone13)))
    }
}
```

### Manual Testing Checklist

**Compare Customer App vs Business App:**

- [ ] Screenshot order status card from both apps - colors match?
- [ ] Screenshot primary button from both apps - identical?
- [ ] Screenshot secondary button from both apps - identical?
- [ ] Screenshot card shadow from both apps - same elevation?
- [ ] Test button press animation - same duration?
- [ ] Test dark mode - consistent colors?
- [ ] Test Dynamic Type - scales the same?
- [ ] Test on iPad - spacing scales appropriately?

---

## 11. Action Items

### Immediate (This Week)
1. ✅ **Access Customer iOS repository**
2. ✅ **Audit existing design tokens**
3. ✅ **Copy DesignSystem.swift**
4. ✅ **Replace 10 most-used hardcoded values**

### Short-Term (Next 2 Weeks)
1. ✅ **Migrate all buttons to use styles**
2. ✅ **Migrate all cards to use `.cardStyle()`**
3. ✅ **Add customer-specific extensions**
4. ✅ **Visual QA against Business app**

### Long-Term (Next Month)
1. ✅ **Create shared Swift package**
2. ✅ **Set up snapshot testing**
3. ✅ **Document customer-specific patterns**
4. ✅ **Train team on design system**

---

## 12. Key Contacts

| Role | Responsibility | Contact |
|------|----------------|---------|
| Design System Owner | Maintains DesignSystem.swift | TBD |
| iOS Lead (Business) | Business app design decisions | TBD |
| iOS Lead (Customer) | Customer app design decisions | TBD |
| Design Lead | Visual consistency | TBD |

---

## Appendix: Complete Design System Reference

See Business iOS file for complete implementation:
- **File:** `camerons-Bussiness-app/Shared/DesignSystem.swift`
- **Phase 9 Report:** `PHASE9_CLEANUP_REPORT.md`
- **Website Mapping:** `Website/design-system-mapping.md`

---

**End of Customer iOS App Design System Mapping**

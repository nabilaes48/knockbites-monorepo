# iOS Implementation Plan: Portion-Based Customizations

**Goal**: Match web app design and functionality 100% for the portion-based ingredient customization system

**Status**: Database ✅ Ready | Web App ✅ Complete | iOS App 🔄 Implementation Required

---

## 📋 Executive Summary

This plan implements the modern portion-based customization system in the iOS business app to achieve 100% feature parity with the web application. The database is already deployed with 13 ingredient templates and 6 configured menu items.

### Success Criteria
- ✅ iOS app can fetch and display ingredient templates from database
- ✅ Portion selector UI matches web app design (○ None, ◔ Light, ◑ Regular, ● Extra)
- ✅ Real-time price calculation works correctly
- ✅ Order submission includes portion selections
- ✅ UI/UX matches web app quality and responsiveness

---

## 🎯 Phase 1: Data Models (Day 1)

### 1.1 Create New Models File

**File**: `camerons-Bussiness-app/Shared/IngredientModels.swift`

**What to Add**:
```swift
import Foundation

// MARK: - Portion Level Enum
enum PortionLevel: String, Codable, CaseIterable {
    case none, light, regular, extra

    var emoji: String {
        switch self {
        case .none: return "○"
        case .light: return "◔"
        case .regular: return "◑"
        case .extra: return "●"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .none: return "No portion"
        case .light: return "Small amount (25%)"
        case .regular: return "Standard serving (50%)"
        case .extra: return "Generous portion (100%)"
        }
    }
}

// MARK: - Ingredient Category
enum IngredientCategory: String, Codable, CaseIterable {
    case vegetables
    case sauces
    case extras

    var displayName: String {
        switch self {
        case .vegetables: return "Fresh Vegetables"
        case .sauces: return "Signature Sauces"
        case .extras: return "Premium Extras"
        }
    }

    var icon: String {
        switch self {
        case .vegetables: return "leaf.fill"
        case .sauces: return "drop.fill"
        case .extras: return "sparkles"
        }
    }

    var emoji: String {
        switch self {
        case .vegetables: return "🥗"
        case .sauces: return "🥫"
        case .extras: return "✨"
        }
    }

    var color: Color {
        switch self {
        case .vegetables: return .green
        case .sauces: return .orange
        case .extras: return .purple
        }
    }
}

// MARK: - Portion Pricing
struct PortionPricing: Codable {
    let none: Double
    let light: Double
    let regular: Double
    let extra: Double

    subscript(level: PortionLevel) -> Double {
        switch level {
        case .none: return none
        case .light: return light
        case .regular: return regular
        case .extra: return extra
        }
    }

    var hasCharge: Bool {
        light > 0 || regular > 0 || extra > 0
    }
}

// MARK: - Ingredient Template
struct IngredientTemplate: Codable, Identifiable {
    let id: Int
    let name: String
    let category: IngredientCategory
    let supportsPortions: Bool
    let portionPricing: PortionPricing
    let defaultPortion: PortionLevel
    let displayOrder: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, category
        case supportsPortions = "supports_portions"
        case portionPricing = "portion_pricing"
        case defaultPortion = "default_portion"
        case displayOrder = "display_order"
        case isActive = "is_active"
    }

    var isPremium: Bool {
        portionPricing.hasCharge
    }
}

// MARK: - Menu Item Customization (Enhanced)
struct MenuItemCustomization: Codable, Identifiable {
    let id: Int
    let menuItemId: Int
    let templateId: Int?
    let name: String
    let type: String
    let category: String?
    let supportsPortions: Bool
    let portionPricing: PortionPricing?
    let defaultPortion: PortionLevel?
    let isRequired: Bool
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case menuItemId = "menu_item_id"
        case templateId = "template_id"
        case name, type, category
        case supportsPortions = "supports_portions"
        case portionPricing = "portion_pricing"
        case defaultPortion = "default_portion"
        case isRequired = "is_required"
        case displayOrder = "display_order"
    }

    var ingredientCategory: IngredientCategory? {
        guard let category = category else { return nil }
        return IngredientCategory(rawValue: category)
    }

    var isPremium: Bool {
        portionPricing?.hasCharge ?? false
    }
}

// MARK: - Portion Selection (State Management)
struct PortionSelection {
    var selections: [Int: PortionLevel] = [:]

    mutating func setSelection(_ portion: PortionLevel, for customizationId: Int) {
        selections[customizationId] = portion
    }

    func getSelection(for customizationId: Int) -> PortionLevel? {
        selections[customizationId]
    }

    func calculateAdditionalCost(customizations: [MenuItemCustomization]) -> Double {
        var total: Double = 0

        for customization in customizations where customization.supportsPortions {
            if let pricing = customization.portionPricing,
               let selectedPortion = selections[customization.id] {
                total += pricing[selectedPortion]
            }
        }

        return total
    }

    func toCustomizationStrings(customizations: [MenuItemCustomization]) -> [String] {
        var result: [String] = []

        for customization in customizations {
            if let portion = selections[customization.id], portion != .none {
                result.append("\(portion.displayName) \(customization.name)")
            }
        }

        return result
    }
}
```

**Why**: Separate file keeps models organized and follows Swift best practices

---

## 🔌 Phase 2: API Integration (Day 1-2)

### 2.1 Update SupabaseManager

**File**: `SupabaseManager.swift`

**Add These Functions**:

```swift
// MARK: - Ingredient Templates

/// Fetch all active ingredient templates
func fetchIngredientTemplates() async throws -> [IngredientTemplate] {
    let response = try await supabase
        .from("ingredient_templates")
        .select()
        .eq("is_active", value: true)
        .order("category")
        .order("display_order")
        .execute()

    let templates = try JSONDecoder().decode([IngredientTemplate].self, from: response.data)
    print("✅ Fetched \(templates.count) ingredient templates")
    return templates
}

/// Fetch ingredient templates by category
func fetchIngredientTemplates(category: IngredientCategory) async throws -> [IngredientTemplate] {
    let response = try await supabase
        .from("ingredient_templates")
        .select()
        .eq("is_active", value: true)
        .eq("category", value: category.rawValue)
        .order("display_order")
        .execute()

    return try JSONDecoder().decode([IngredientTemplate].self, from: response.data)
}

// MARK: - Menu Item Customizations

/// Fetch customizations for a specific menu item
func fetchMenuItemCustomizations(menuItemId: Int) async throws -> [MenuItemCustomization] {
    let response = try await supabase
        .from("menu_item_customizations")
        .select()
        .eq("menu_item_id", value: menuItemId)
        .order("category")
        .order("display_order")
        .execute()

    let customizations = try JSONDecoder().decode([MenuItemCustomization].self, from: response.data)
    print("✅ Fetched \(customizations.count) customizations for menu item \(menuItemId)")
    return customizations
}

/// Fetch only portion-based customizations for a menu item
func fetchPortionCustomizations(menuItemId: Int) async throws -> [MenuItemCustomization] {
    let response = try await supabase
        .from("menu_item_customizations")
        .select()
        .eq("menu_item_id", value: menuItemId)
        .eq("supports_portions", value: true)
        .order("category")
        .order("display_order")
        .execute()

    return try JSONDecoder().decode([MenuItemCustomization].self, from: response.data)
}
```

**Testing**:
```swift
// Test in DatabaseDiagnosticsView or create a test button
Task {
    do {
        let templates = try await SupabaseManager.shared.fetchIngredientTemplates()
        print("Templates: \(templates.map { $0.name })")
        // Expected: 13 templates

        let customizations = try await SupabaseManager.shared.fetchPortionCustomizations(menuItemId: 84)
        print("All American customizations: \(customizations.count)")
        // Expected: 9 customizations
    } catch {
        print("Error: \(error)")
    }
}
```

---

## 🎨 Phase 3: UI Components (Day 2-3)

### 3.1 Create PortionSelector Component

**File**: `camerons-Bussiness-app/Shared/PortionSelector.swift`

```swift
import SwiftUI

struct PortionSelectorButton: View {
    let portion: PortionLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(portion.emoji)
                    .font(.system(size: 24))

                Text(portion.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.brandPrimary : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected ? Color.brandPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct PortionSelectorRow: View {
    @Binding var selectedPortion: PortionLevel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(PortionLevel.allCases, id: \.self) { portion in
                PortionSelectorButton(
                    portion: portion,
                    isSelected: selectedPortion == portion,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPortion = portion
                        }
                    }
                )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PortionSelectorRow(selectedPortion: .constant(.regular))
        PortionSelectorRow(selectedPortion: .constant(.extra))
    }
    .padding()
}
```

### 3.2 Create Ingredient Row Component

**File**: `camerons-Bussiness-app/Shared/IngredientCustomizationRow.swift`

```swift
import SwiftUI

struct IngredientCustomizationRow: View {
    let customization: MenuItemCustomization
    @Binding var selectedPortion: PortionLevel

    var priceText: String? {
        guard let pricing = customization.portionPricing,
              pricing[selectedPortion] > 0 else {
            return nil
        }
        return String(format: "+$%.2f", pricing[selectedPortion])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(customization.name)
                    .font(.body)
                    .fontWeight(.semibold)

                Spacer()

                if let price = priceText {
                    Text(price)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.brandPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.brandPrimary.opacity(0.1))
                        )
                }
            }

            PortionSelectorRow(selectedPortion: $selectedPortion)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 16) {
        // Free ingredient
        IngredientCustomizationRow(
            customization: MenuItemCustomization(
                id: 1,
                menuItemId: 84,
                templateId: 1,
                name: "Lettuce",
                type: "single",
                category: "vegetables",
                supportsPortions: true,
                portionPricing: PortionPricing(none: 0, light: 0, regular: 0, extra: 0),
                defaultPortion: .regular,
                isRequired: false,
                displayOrder: 1
            ),
            selectedPortion: .constant(.regular)
        )

        // Premium ingredient
        IngredientCustomizationRow(
            customization: MenuItemCustomization(
                id: 2,
                menuItemId: 84,
                templateId: 10,
                name: "Extra Cheese",
                type: "single",
                category: "extras",
                supportsPortions: true,
                portionPricing: PortionPricing(none: 0, light: 0.75, regular: 1.00, extra: 1.50),
                defaultPortion: .none,
                isRequired: false,
                displayOrder: 20
            ),
            selectedPortion: .constant(.regular)
        )
    }
    .padding()
}
```

---

## 📱 Phase 4: Menu Item Customization View (Day 3-4)

### 4.1 Create MenuItemCustomizationView

**File**: `camerons-Bussiness-app/Core/Menu/MenuItemCustomizationView.swift`

```swift
import SwiftUI

struct MenuItemCustomizationView: View {
    let menuItem: MenuItem
    @Environment(\.dismiss) var dismiss
    @State private var customizations: [MenuItemCustomization] = []
    @State private var portionSelections = PortionSelection()
    @State private var specialInstructions = ""
    @State private var quantity = 1
    @State private var isLoading = true
    @State private var errorMessage: String?

    var groupedCustomizations: [IngredientCategory: [MenuItemCustomization]] {
        Dictionary(grouping: customizations.filter { $0.supportsPortions }) { customization in
            customization.ingredientCategory ?? .extras
        }
    }

    var additionalCost: Double {
        portionSelections.calculateAdditionalCost(customizations: customizations)
    }

    var totalPrice: Double {
        (menuItem.price + additionalCost) * Double(quantity)
    }

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading customizations...")
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await loadCustomizations() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    mainContent
                }
            }
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadCustomizations()
            }
        }
    }

    var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Menu Item Header
                menuItemHeader

                VStack(alignment: .leading, spacing: 16) {
                    // Customizations by Category
                    ForEach(IngredientCategory.allCases, id: \.self) { category in
                        if let ingredients = groupedCustomizations[category], !ingredients.isEmpty {
                            customizationSection(category: category, ingredients: ingredients)
                        }
                    }

                    // Special Instructions
                    specialInstructionsSection

                    // Quantity
                    quantitySection
                }
                .padding(.horizontal)
                .padding(.bottom, 100) // Space for bottom button
            }
        }
        .safeAreaInset(edge: .bottom) {
            addToOrderButton
        }
    }

    var menuItemHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(menuItem.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(menuItem.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Base Price:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(menuItem.formattedPrice)
                        .font(.headline)
                        .foregroundColor(.brandPrimary)
                }
            }
            .padding(.horizontal)
        }
    }

    func customizationSection(category: IngredientCategory, ingredients: [MenuItemCustomization]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(category.displayName)
                    .font(.headline)
            } icon: {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
            }

            ForEach(ingredients) { ingredient in
                IngredientCustomizationRow(
                    customization: ingredient,
                    selectedPortion: Binding(
                        get: {
                            portionSelections.getSelection(for: ingredient.id)
                                ?? ingredient.defaultPortion
                                ?? .regular
                        },
                        set: { newValue in
                            portionSelections.setSelection(newValue, for: ingredient.id)
                        }
                    )
                )
            }
        }
    }

    var specialInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Special Instructions")
                .font(.headline)

            TextEditor(text: $specialInstructions)
                .frame(height: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(.systemGray4), lineWidth: 1)
                )
        }
    }

    var quantitySection: some View {
        HStack {
            Text("Quantity")
                .font(.headline)

            Spacer()

            HStack(spacing: 16) {
                Button {
                    if quantity > 1 {
                        quantity -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(quantity > 1 ? .brandPrimary : .gray)
                }
                .disabled(quantity <= 1)

                Text("\(quantity)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(width: 40)

                Button {
                    quantity += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.brandPrimary)
                }
            }
        }
    }

    var addToOrderButton: some View {
        Button {
            addToOrder()
        } label: {
            HStack {
                Image(systemName: "cart.fill")

                Text("Add to Order")

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if additionalCost > 0 {
                        Text("+ \(String(format: "$%.2f", additionalCost))")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Text(String(format: "$%.2f", totalPrice))
                        .fontWeight(.bold)
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.brandPrimary)
            .cornerRadius(12)
            .shadow(radius: 4)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    func loadCustomizations() async {
        isLoading = true
        errorMessage = nil

        do {
            customizations = try await SupabaseManager.shared.fetchPortionCustomizations(
                menuItemId: Int(menuItem.id) ?? 0
            )

            // Set default portions
            for customization in customizations {
                if let defaultPortion = customization.defaultPortion {
                    portionSelections.setSelection(defaultPortion, for: customization.id)
                }
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to load customizations: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func addToOrder() {
        // TODO: Implement order submission
        let customizationStrings = portionSelections.toCustomizationStrings(customizations: customizations)

        print("Adding to order:")
        print("- Item: \(menuItem.name)")
        print("- Quantity: \(quantity)")
        print("- Base Price: \(menuItem.price)")
        print("- Additional Cost: \(additionalCost)")
        print("- Total: \(totalPrice)")
        print("- Customizations: \(customizationStrings)")
        print("- Special Instructions: \(specialInstructions)")

        dismiss()
    }
}
```

---

## 🔗 Phase 5: Integration with Existing Views (Day 4)

### 5.1 Update MenuManagementView

Add a button to test customizations:

```swift
// In MenuManagementView.swift, add to each menu item row:

.contextMenu {
    Button {
        selectedMenuItem = item
        showCustomizationModal = true
    } label: {
        Label("Customize", systemImage: "slider.horizontal.3")
    }
}
.sheet(item: $selectedMenuItem) { item in
    MenuItemCustomizationView(menuItem: item)
}
```

### 5.2 Update Models.swift

Add menu item ID conversion helper:

```swift
// In MenuItem struct, add:
var numericId: Int? {
    Int(id)
}
```

---

## ✅ Phase 6: Testing & Verification (Day 5)

### 6.1 Database Verification

Add to DatabaseDiagnosticsView:

```swift
Section("Portion Customizations") {
    Button("Test Ingredient Templates") {
        Task {
            do {
                let templates = try await SupabaseManager.shared.fetchIngredientTemplates()
                print("✅ Found \(templates.count) templates")
                for template in templates {
                    print("  - \(template.name) (\(template.category.rawValue))")
                }
            } catch {
                print("❌ Error: \(error)")
            }
        }
    }

    Button("Test All American Customizations") {
        Task {
            do {
                let customizations = try await SupabaseManager.shared.fetchPortionCustomizations(menuItemId: 84)
                print("✅ Found \(customizations.count) customizations")
                for custom in customizations {
                    print("  - \(custom.name): default \(custom.defaultPortion?.rawValue ?? "none")")
                }
            } catch {
                print("❌ Error: \(error)")
            }
        }
    }
}
```

### 6.2 UI Testing Checklist

- [ ] Open MenuManagementView
- [ ] Long-press on "All American" sandwich
- [ ] Select "Customize"
- [ ] Modal opens with loading state
- [ ] Three categories appear: 🥗 Vegetables, 🥫 Sauces, ✨ Extras
- [ ] Each ingredient has 4 portion buttons (○ ◔ ◑ ●)
- [ ] Default portions are pre-selected (Lettuce = Regular)
- [ ] Tap different portions - selection changes with animation
- [ ] Extra Cheese shows price (+$1.00 for Regular)
- [ ] Total price updates in real-time
- [ ] Quantity buttons work (+/-)
- [ ] Special instructions can be entered
- [ ] "Add to Order" button shows correct total

### 6.3 Price Calculation Testing

```swift
// Test cases:
// 1. Lettuce Regular = $0 (free)
// 2. Extra Cheese Regular = +$1.00
// 3. Extra Cheese Extra = +$1.50
// 4. Multiple selections add up correctly
// 5. Quantity multiplies total correctly
```

---

## 📊 Phase 7: Code Quality & Polish (Day 5-6)

### 7.1 Add Loading States

- ✅ Skeleton screens while loading
- ✅ Error states with retry
- ✅ Empty states if no customizations

### 7.2 Add Animations

- ✅ Portion button selection (0.2s ease)
- ✅ Price updates (smooth number transitions)
- ✅ Modal presentation

### 7.3 Accessibility

```swift
// Add to PortionSelectorButton:
.accessibilityLabel("\(portion.displayName) portion")
.accessibilityHint(portion.description)
.accessibilityAddTraits(isSelected ? [.isSelected] : [])
```

### 7.4 Error Handling

- ✅ Network failures
- ✅ Invalid menu item IDs
- ✅ Missing customizations
- ✅ Pricing calculation errors

---

## 🚀 Phase 8: Advanced Features (Day 6-7)

### 8.1 Caching Strategy

```swift
// Add to SupabaseManager
class IngredientCache {
    static let shared = IngredientCache()
    private var cache: [Int: [MenuItemCustomization]] = [:]
    private let cacheExpiry: TimeInterval = 300 // 5 minutes

    func get(menuItemId: Int) -> [MenuItemCustomization]? {
        cache[menuItemId]
    }

    func set(menuItemId: Int, customizations: [MenuItemCustomization]) {
        cache[menuItemId] = customizations
    }
}
```

### 8.2 Offline Support

```swift
// Save last known customizations to UserDefaults
func cacheCustomizations(_ customizations: [MenuItemCustomization], for menuItemId: Int) {
    // Implementation
}
```

### 8.3 Analytics Tracking

```swift
// Track customization usage
func trackCustomizationUsage(
    menuItemId: Int,
    customizationId: Int,
    portion: PortionLevel
) {
    // Analytics implementation
}
```

---

## 📋 Success Metrics

### Functional Requirements
- ✅ All 13 ingredient templates load correctly
- ✅ All 6 configured menu items show customizations
- ✅ Portion selectors work on all devices (iPhone, iPad)
- ✅ Price calculations are accurate
- ✅ Order submission includes portion data

### UI/UX Requirements
- ✅ Design matches web app 100%
- ✅ Animations are smooth (60fps)
- ✅ Loading states are informative
- ✅ Error states are helpful
- ✅ Accessibility standards met

### Performance Requirements
- ✅ Customizations load in <1 second
- ✅ UI interactions respond in <100ms
- ✅ Memory usage is efficient
- ✅ No memory leaks

---

## 🗓️ Timeline Summary

| Phase | Days | Description |
|-------|------|-------------|
| Phase 1 | 1 | Data models |
| Phase 2 | 1-2 | API integration |
| Phase 3 | 2-3 | UI components |
| Phase 4 | 3-4 | Main view |
| Phase 5 | 4 | Integration |
| Phase 6 | 5 | Testing |
| Phase 7 | 5-6 | Polish |
| Phase 8 | 6-7 | Advanced features |

**Total Time**: 7 days for core implementation + testing + polish

---

## 📝 Implementation Checklist

### Day 1: Foundation
- [ ] Create `IngredientModels.swift`
- [ ] Add models to Xcode project
- [ ] Update SupabaseManager with API functions
- [ ] Test API calls in DatabaseDiagnosticsView

### Day 2: UI Components
- [ ] Create `PortionSelector.swift`
- [ ] Create `IngredientCustomizationRow.swift`
- [ ] Add preview tests
- [ ] Verify on iPhone and iPad simulators

### Day 3: Main View
- [ ] Create `MenuItemCustomizationView.swift`
- [ ] Implement loading states
- [ ] Implement error handling
- [ ] Add quantity selector
- [ ] Add special instructions

### Day 4: Integration
- [ ] Connect to MenuManagementView
- [ ] Test full flow
- [ ] Fix any issues

### Day 5: Testing & Refinement
- [ ] Run all test cases
- [ ] Fix bugs
- [ ] Add polish (animations, etc.)
- [ ] Accessibility audit

### Day 6: Advanced Features
- [ ] Implement caching
- [ ] Add offline support
- [ ] Add analytics
- [ ] Performance optimization

### Day 7: Final Review
- [ ] Code review
- [ ] Documentation
- [ ] Demo to stakeholders
- [ ] Deploy to TestFlight

---

## 🔍 Common Issues & Solutions

### Issue: Customizations not loading
**Check**:
1. Menu item ID is numeric (convert String to Int)
2. Migration 044 ran successfully
3. RLS policies allow SELECT on `menu_item_customizations`

### Issue: Prices not updating
**Check**:
1. `portionPricing` decoding correctly
2. `PortionSelection.calculateAdditionalCost()` is called
3. State binding is correct

### Issue: UI not matching web
**Reference**:
- Web file: `src/components/ui/PortionSelector.tsx`
- Copy exact spacing, colors, fonts
- Use DesignSystem.swift for consistency

---

## 📚 Resources

### Documentation
- `IOS_SYNC_PORTION_CUSTOMIZATIONS.md` - Complete Swift guide
- `PORTION_BASED_CUSTOMIZATIONS.md` - Feature specifications
- `RUN_MIGRATION_044.md` - Database verification

### Web Reference
- `src/components/ui/PortionSelector.tsx` - Portion selector design
- `src/components/order/ItemCustomizationModalV2.tsx` - Modal layout
- Design tokens and styling

### Database
- Table: `ingredient_templates` (13 rows)
- Table: `menu_item_customizations` (54 rows for 6 items)
- Test with menu_item_id = 84 ("All American")

---

## ✅ Definition of Done

- [ ] All data models implemented and tested
- [ ] All API functions working correctly
- [ ] UI components match web design 100%
- [ ] Customization flow works end-to-end
- [ ] All test cases pass
- [ ] No console errors or warnings
- [ ] Performance meets requirements
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Merged to main branch

---

**Next Steps**: Start with Phase 1 (Day 1) - Create data models and test API integration

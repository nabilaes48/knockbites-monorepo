# iOS Apps Rebranding Guide: KnockBites

This guide covers rebranding the iOS Customer and Business apps from Cameron's to KnockBites.

## Brand Assets

### Colors
| Color | Old (Cameron's) | New (KnockBites) |
|-------|-----------------|------------------|
| Primary | `#2196F3` (Blue) | `#FF8C42` (Orange) |
| Secondary | `#FF8C42` (Orange) | `#E84393` (Pink) |
| Accent | `#4CAF50` (Green) | `#4CAF50` (Green) |
| Background Dark | `#262626` | `#1a1a2e` |

### Typography
- Brand Name: **KnockBites** (not "Knock Bites")
- Tagline: "Fresh Food, Always Delicious"

---

## Files to Update

### 1. App Configuration

#### `Config.plist` / `Info.plist`
```xml
<!-- Update these values -->
<key>CFBundleDisplayName</key>
<string>KnockBites</string>

<key>CFBundleName</key>
<string>KnockBites</string>

<key>CFBundleIdentifier</key>
<string>com.knockbites.customer</string> <!-- or .business -->
```

#### `Constants.swift` or `AppConfig.swift`
```swift
// Update branding constants
struct AppConfig {
    static let appName = "KnockBites"
    static let tagline = "Fresh Food, Always Delicious"
    static let supportEmail = "support@knockbites.com"
    static let websiteURL = "https://knockbites.com"
    static let primaryColor = UIColor(hex: "#FF8C42")
    static let secondaryColor = UIColor(hex: "#E84393")
}
```

---

### 2. Assets Catalog (`Assets.xcassets`)

#### App Icons
Replace all app icon sizes with KnockBites yummy face logo:
- `AppIcon.appiconset/`
  - 20x20, 29x29, 40x40, 60x60 (iPhone)
  - 20x20, 29x29, 40x40, 76x76, 83.5x83.5 (iPad)
  - 1024x1024 (App Store)

#### Logo Images
- `logo.imageset/` - KnockBites wordmark
- `logo-icon.imageset/` - Yummy face icon only
- `logo-horizontal.imageset/` - Icon + wordmark

#### Color Sets
Update or add:
```
Colors/
├── PrimaryColor.colorset/    → #FF8C42
├── SecondaryColor.colorset/  → #E84393
├── AccentColor.colorset/     → #4CAF50
└── BackgroundDark.colorset/  → #1a1a2e
```

---

### 3. Launch Screen (`LaunchScreen.storyboard`)

Update:
- Logo image to KnockBites
- Background gradient: `#FF8C42` → `#E84393`
- Remove any "Cameron's" text

---

### 4. String Files

#### `Localizable.strings`
```swift
// Search and replace
"Cameron's" = "KnockBites";
"Cameron's Connect" = "KnockBites";
"Cameron's 24-7 Deli" = "KnockBites";
"cameronsconnect.com" = "knockbites.com";
"support@cameronsconnect.com" = "support@knockbites.com";
```

#### `InfoPlist.strings`
```swift
"CFBundleDisplayName" = "KnockBites";
```

---

### 5. SwiftUI Views

#### Search and Replace in All `.swift` Files
```bash
# Run from iOS project root
find . -name "*.swift" -exec sed -i '' 's/Cameron'\''s Connect/KnockBites/g' {} \;
find . -name "*.swift" -exec sed -i '' 's/Cameron'\''s/KnockBites/g' {} \;
find . -name "*.swift" -exec sed -i '' 's/#2196F3/#FF8C42/g' {} \;
find . -name "*.swift" -exec sed -i '' 's/cameronsconnect\.com/knockbites.com/g' {} \;
```

#### Specific Views to Update
- `HeaderView.swift` - Logo and brand name
- `SplashView.swift` - Launch animation
- `AboutView.swift` - Company info
- `SettingsView.swift` - Support links
- `OrderConfirmationView.swift` - Footer branding

---

### 6. Navigation Bar / Tab Bar

#### Update Tint Colors
```swift
// In AppDelegate or SceneDelegate
UINavigationBar.appearance().tintColor = UIColor(hex: "#FF8C42")
UITabBar.appearance().tintColor = UIColor(hex: "#FF8C42")
```

---

### 7. Push Notification Configuration

#### `GoogleService-Info.plist` (if using Firebase)
- Create new Firebase project for KnockBites
- Download new `GoogleService-Info.plist`

#### APNs Configuration
- Update bundle ID in Apple Developer portal
- Generate new push certificates for `com.knockbites.customer`

---

## App Store Updates

### App Store Connect

1. **App Name**: KnockBites (Customer / Business)
2. **Subtitle**: Fresh Food Ordering
3. **Description**: Update all mentions of Cameron's
4. **Keywords**: knockbites, food ordering, deli, sandwiches
5. **Screenshots**: Retake with new branding
6. **App Icon**: Upload new 1024x1024 icon

### Privacy Policy URL
`https://knockbites.com/privacy`

### Support URL
`https://knockbites.com/contact`

### Marketing URL
`https://knockbites.com`

---

## Testing Checklist

- [ ] App icon displays correctly
- [ ] Launch screen shows KnockBites branding
- [ ] All screens show correct colors
- [ ] No "Cameron's" text anywhere
- [ ] Support email links to support@knockbites.com
- [ ] Website links go to knockbites.com
- [ ] Push notifications work with new bundle ID
- [ ] Deep links work with new URL scheme

---

## Logo Assets

The KnockBites logo SVG is available at:
- Web: `/public/favicon.svg`
- Export sizes needed for iOS:
  - 1024x1024 (App Store)
  - 180x180 (iPhone @3x)
  - 120x120 (iPhone @2x)
  - 167x167 (iPad Pro)
  - 152x152 (iPad)
  - 76x76 (iPad @1x)

### Logo Style
- Rounded square background (`#1a1a2e`)
- Yummy face blob with gradient (`#FF8C42` → `#E84393`)
- Closed happy eyes
- Tongue sticking out
- Blush marks on cheeks

---

## Questions?

Contact: support@knockbites.com

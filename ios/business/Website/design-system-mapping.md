# Website Design System Mapping

**Generated:** 2025-12-02
**Phase:** 10 — Cross-Platform Feature Parity
**Purpose:** Map Business iOS design tokens to Website (React/CSS) implementation

---

## Overview

This document provides a comprehensive mapping between the Business iOS app's `DesignSystem.swift` and the corresponding CSS/JavaScript implementation required for the Camerons Connect website.

**Source of Truth:** Business iOS `camerons-Bussiness-app/Shared/DesignSystem.swift`

---

## 1. Color System

### Brand Colors

| iOS Token | Value | CSS Variable | CSS Value | Status |
|-----------|-------|--------------|-----------|--------|
| `Color.brandPrimary` | blue | `--brand-primary` | `#007AFF` | ⚠️ Verify |
| `Color.brandSecondary` | orange | `--brand-secondary` | `#FF9500` | ⚠️ Verify |

**Recommendation:** Define exact hex values in both platforms.

```css
:root {
  --brand-primary: #007AFF;
  --brand-secondary: #FF9500;
}
```

```swift
// Update iOS to match
static let brandPrimary = Color(hex: "#007AFF")
static let brandSecondary = Color(hex: "#FF9500")
```

---

### Semantic Colors

| iOS Token | iOS Value | CSS Variable | CSS Value | Usage |
|-----------|-----------|--------------|-----------|-------|
| `Color.success` | green | `--color-success` | `#34C759` | Success states, ready status |
| `Color.warning` | orange | `--color-warning` | `#FF9500` | Warning messages, preparing status |
| `Color.error` | red | `--color-error` | `#FF3B30` | Error states, cancelled status |
| `Color.info` | blue | `--color-info` | `#007AFF` | Information messages |

```css
:root {
  --color-success: #34C759;
  --color-warning: #FF9500;
  --color-error: #FF3B30;
  --color-info: #007AFF;
}
```

---

### Text Colors

| iOS Token | iOS Value | CSS Variable | CSS Value | Usage |
|-----------|-----------|--------------|-----------|-------|
| `Color.textPrimary` | `.primary` | `--text-primary` | `#000000` (light) / `#FFFFFF` (dark) | Main text |
| `Color.textSecondary` | `.secondary` | `--text-secondary` | `#8E8E93` | Secondary text |

```css
/* Light mode */
:root {
  --text-primary: #000000;
  --text-secondary: #8E8E93;
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
  :root {
    --text-primary: #FFFFFF;
    --text-secondary: #98989D;
  }
}
```

---

### Surface Colors

| iOS Token | iOS Value | CSS Variable | CSS Value (Light) | CSS Value (Dark) |
|-----------|-----------|--------------|-------------------|------------------|
| `Color.surface` | `.systemBackground` | `--surface` | `#FFFFFF` | `#000000` |
| `Color.surfaceSecondary` | `.secondarySystemBackground` | `--surface-secondary` | `#F2F2F7` | `#1C1C1E` |
| `Color.surfaceTertiary` | `.tertiarySystemBackground` | `--surface-tertiary` | `#FFFFFF` | `#2C2C2E` |

```css
:root {
  --surface: #FFFFFF;
  --surface-secondary: #F2F2F7;
  --surface-tertiary: #FFFFFF;
}

@media (prefers-color-scheme: dark) {
  :root {
    --surface: #000000;
    --surface-secondary: #1C1C1E;
    --surface-tertiary: #2C2C2E;
  }
}
```

---

### Order Status Colors

| iOS Token | iOS Value | CSS Variable | CSS Value | Usage |
|-----------|-----------|--------------|-----------|-------|
| `Color.statusReceived` | blue | `--status-received` | `#007AFF` | New orders |
| `Color.statusPreparing` | orange | `--status-preparing` | `#FF9500` | Orders being prepared |
| `Color.statusReady` | green | `--status-ready` | `#34C759` | Orders ready for pickup |
| `Color.statusCompleted` | gray | `--status-completed` | `#8E8E93` | Completed orders |
| `Color.statusCancelled` | red | `--status-cancelled` | `#FF3B30` | Cancelled orders |

```css
:root {
  --status-received: #007AFF;
  --status-preparing: #FF9500;
  --status-ready: #34C759;
  --status-completed: #8E8E93;
  --status-cancelled: #FF3B30;
}
```

**Usage Example:**
```jsx
<div className="order-card" data-status="preparing">
  <span className="status-badge">Preparing</span>
</div>
```

```css
.status-badge[data-status="preparing"] {
  background-color: var(--status-preparing);
  color: white;
}
```

---

## 2. Typography System

### Font Scale

| iOS Token | iOS Size | Weight | CSS Class | CSS Declaration |
|-----------|----------|--------|-----------|-----------------|
| `AppFonts.largeTitle` | 34pt | bold | `.text-large-title` | `font-size: 34px; font-weight: 700;` |
| `AppFonts.title` | 28pt | semibold | `.text-title` | `font-size: 28px; font-weight: 600;` |
| `AppFonts.title2` | 22pt | semibold | `.text-title2` | `font-size: 22px; font-weight: 600;` |
| `AppFonts.title3` | 20pt | semibold | `.text-title3` | `font-size: 20px; font-weight: 600;` |
| `AppFonts.headline` | 17pt | semibold | `.text-headline` | `font-size: 17px; font-weight: 600;` |
| `AppFonts.subheadline` | 15pt | regular | `.text-subheadline` | `font-size: 15px; font-weight: 400;` |
| `AppFonts.body` | 17pt | regular | `.text-body` | `font-size: 17px; font-weight: 400;` |
| `AppFonts.callout` | 16pt | regular | `.text-callout` | `font-size: 16px; font-weight: 400;` |
| `AppFonts.caption` | 12pt | regular | `.text-caption` | `font-size: 12px; font-weight: 400;` |
| `AppFonts.caption2` | 11pt | regular | `.text-caption2` | `font-size: 11px; font-weight: 400;` |

### Special Typography

| iOS Token | iOS Spec | CSS Class | CSS Declaration |
|-----------|----------|-----------|-----------------|
| `AppFonts.metric` | 32pt, bold, rounded | `.text-metric` | `font-size: 32px; font-weight: 700; font-variant-numeric: tabular-nums;` |
| `AppFonts.metricSmall` | 24pt, semibold, rounded | `.text-metric-small` | `font-size: 24px; font-weight: 600; font-variant-numeric: tabular-nums;` |
| `AppFonts.orderNumber` | 18pt, bold, monospaced | `.text-order-number` | `font-size: 18px; font-weight: 700; font-family: monospace;` |

**CSS Implementation:**

```css
/* Base font family */
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
}

/* Typography classes */
.text-large-title { font-size: 34px; font-weight: 700; line-height: 1.2; }
.text-title { font-size: 28px; font-weight: 600; line-height: 1.3; }
.text-title2 { font-size: 22px; font-weight: 600; line-height: 1.3; }
.text-title3 { font-size: 20px; font-weight: 600; line-height: 1.4; }
.text-headline { font-size: 17px; font-weight: 600; line-height: 1.4; }
.text-subheadline { font-size: 15px; font-weight: 400; line-height: 1.4; }
.text-body { font-size: 17px; font-weight: 400; line-height: 1.5; }
.text-callout { font-size: 16px; font-weight: 400; line-height: 1.5; }
.text-caption { font-size: 12px; font-weight: 400; line-height: 1.3; }
.text-caption2 { font-size: 11px; font-weight: 400; line-height: 1.3; }

/* Special typography */
.text-metric {
  font-size: 32px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
  line-height: 1.2;
}

.text-metric-small {
  font-size: 24px;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  line-height: 1.2;
}

.text-order-number {
  font-size: 18px;
  font-weight: 700;
  font-family: 'SF Mono', Monaco, 'Courier New', monospace;
  line-height: 1.3;
}
```

---

## 3. Spacing System

| iOS Token | Value (pt) | Value (px) | CSS Variable | Usage |
|-----------|------------|------------|--------------|-------|
| `Spacing.xs` | 4pt | 4px | `--spacing-xs` | Minimal gaps |
| `Spacing.sm` | 8pt | 8px | `--spacing-sm` | Small gaps |
| `Spacing.md` | 12pt | 12px | `--spacing-md` | Medium gaps |
| `Spacing.lg` | 16pt | 16px | `--spacing-lg` | Large gaps, default padding |
| `Spacing.xl` | 24pt | 24px | `--spacing-xl` | Extra large gaps |
| `Spacing.xxl` | 32pt | 32px | `--spacing-xxl` | Section spacing |
| `Spacing.xxxl` | 48pt | 48px | `--spacing-xxxl` | Page-level spacing |

```css
:root {
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 12px;
  --spacing-lg: 16px;
  --spacing-xl: 24px;
  --spacing-xxl: 32px;
  --spacing-xxxl: 48px;
}

/* Utility classes */
.p-xs { padding: var(--spacing-xs); }
.p-sm { padding: var(--spacing-sm); }
.p-md { padding: var(--spacing-md); }
.p-lg { padding: var(--spacing-lg); }
.p-xl { padding: var(--spacing-xl); }
.p-xxl { padding: var(--spacing-xxl); }
.p-xxxl { padding: var(--spacing-xxxl); }

.gap-xs { gap: var(--spacing-xs); }
.gap-sm { gap: var(--spacing-sm); }
.gap-md { gap: var(--spacing-md); }
.gap-lg { gap: var(--spacing-lg); }
.gap-xl { gap: var(--spacing-xl); }
```

---

## 4. Corner Radius

| iOS Token | Value (pt) | Value (px) | CSS Variable | Usage |
|-----------|------------|------------|--------------|-------|
| `CornerRadius.sm` | 4pt | 4px | `--radius-sm` | Small elements |
| `CornerRadius.md` | 8pt | 8px | `--radius-md` | Buttons, inputs |
| `CornerRadius.lg` | 12pt | 12px | `--radius-lg` | Cards, modals |
| `CornerRadius.xl` | 16pt | 16px | `--radius-xl` | Large cards |
| `CornerRadius.xxl` | 24pt | 24px | `--radius-xxl` | Hero elements |
| `CornerRadius.full` | 9999pt | 9999px | `--radius-full` | Pills, avatars |

```css
:root {
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-xxl: 24px;
  --radius-full: 9999px;
}

/* Utility classes */
.rounded-sm { border-radius: var(--radius-sm); }
.rounded-md { border-radius: var(--radius-md); }
.rounded-lg { border-radius: var(--radius-lg); }
.rounded-xl { border-radius: var(--radius-xl); }
.rounded-xxl { border-radius: var(--radius-xxl); }
.rounded-full { border-radius: var(--radius-full); }
```

---

## 5. Shadow System

| iOS Token | Opacity | Radius | Offset | CSS Variable | CSS Value |
|-----------|---------|--------|--------|--------------|-----------|
| `AppShadow.sm` | 0.05 | - | - | `--shadow-sm` | `0 1px 2px rgba(0,0,0,0.05)` |
| `AppShadow.md` | 0.10 | - | - | `--shadow-md` | `0 2px 4px rgba(0,0,0,0.10)` |
| `AppShadow.lg` | 0.15 | - | - | `--shadow-lg` | `0 4px 6px rgba(0,0,0,0.15)` |
| `AppShadow.card()` | 0.10 | 8pt | (0, 4) | `--shadow-card` | `0 4px 8px rgba(0,0,0,0.10)` |
| `AppShadow.elevated()` | 0.15 | 12pt | (0, 6) | `--shadow-elevated` | `0 6px 12px rgba(0,0,0,0.15)` |

```css
:root {
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 2px 4px rgba(0, 0, 0, 0.10);
  --shadow-lg: 0 4px 6px rgba(0, 0, 0, 0.15);
  --shadow-card: 0 4px 8px rgba(0, 0, 0, 0.10);
  --shadow-elevated: 0 6px 12px rgba(0, 0, 0, 0.15);
}

/* Dark mode shadows */
@media (prefers-color-scheme: dark) {
  :root {
    --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.3);
    --shadow-md: 0 2px 4px rgba(0, 0, 0, 0.4);
    --shadow-lg: 0 4px 6px rgba(0, 0, 0, 0.5);
    --shadow-card: 0 4px 8px rgba(0, 0, 0, 0.4);
    --shadow-elevated: 0 6px 12px rgba(0, 0, 0, 0.5);
  }
}
```

---

## 6. Animation Durations

| iOS Token | Value (seconds) | Value (ms) | CSS Variable | Usage |
|-----------|-----------------|------------|--------------|-------|
| `AnimationDuration.fast` | 0.15s | 150ms | `--duration-fast` | Quick transitions |
| `AnimationDuration.normal` | 0.25s | 250ms | `--duration-normal` | Standard animations |
| `AnimationDuration.slow` | 0.35s | 350ms | `--duration-slow` | Slow, noticeable animations |

```css
:root {
  --duration-fast: 150ms;
  --duration-normal: 250ms;
  --duration-slow: 350ms;
  --easing: cubic-bezier(0.4, 0.0, 0.2, 1); /* iOS-like easing */
}

/* Transition utilities */
.transition-fast {
  transition: all var(--duration-fast) var(--easing);
}

.transition-normal {
  transition: all var(--duration-normal) var(--easing);
}

.transition-slow {
  transition: all var(--duration-slow) var(--easing);
}
```

---

## 7. Icon Sizes

| iOS Token | Value (pt) | Value (px) | CSS Variable | Usage |
|-----------|------------|------------|--------------|-------|
| `IconSize.sm` | 16pt | 16px | `--icon-sm` | Small icons |
| `IconSize.md` | 20pt | 20px | `--icon-md` | Default icons |
| `IconSize.lg` | 24pt | 24px | `--icon-lg` | Large icons |
| `IconSize.xl` | 32pt | 32px | `--icon-xl` | Extra large icons |
| `IconSize.xxl` | 48pt | 48px | `--icon-xxl` | Hero icons |

```css
:root {
  --icon-sm: 16px;
  --icon-md: 20px;
  --icon-lg: 24px;
  --icon-xl: 32px;
  --icon-xxl: 48px;
}

/* Icon utility classes */
.icon-sm { width: var(--icon-sm); height: var(--icon-sm); }
.icon-md { width: var(--icon-md); height: var(--icon-md); }
.icon-lg { width: var(--icon-lg); height: var(--icon-lg); }
.icon-xl { width: var(--icon-xl); height: var(--icon-xl); }
.icon-xxl { width: var(--icon-xxl); height: var(--icon-xxl); }
```

---

## 8. Button Styles

### Primary Button

**iOS Implementation:**
```swift
.buttonStyle(.primary)
```

**CSS Implementation:**
```css
.btn-primary {
  font-size: 17px;
  font-weight: 600;
  color: white;
  background-color: var(--brand-primary);
  padding: var(--spacing-lg);
  border-radius: var(--radius-lg);
  border: none;
  width: 100%;
  cursor: pointer;
  transition: all var(--duration-fast) var(--easing);
}

.btn-primary:hover {
  opacity: 0.9;
}

.btn-primary:active {
  opacity: 0.8;
  transform: scale(0.98);
}
```

**React Component:**
```jsx
<button className="btn-primary" onClick={handleSubmit}>
  Submit Order
</button>
```

---

### Secondary Button

**iOS Implementation:**
```swift
.buttonStyle(.secondary)
```

**CSS Implementation:**
```css
.btn-secondary {
  font-size: 17px;
  font-weight: 600;
  color: var(--brand-primary);
  background-color: var(--surface-secondary);
  padding: var(--spacing-lg);
  border-radius: var(--radius-lg);
  border: 1px solid rgba(0, 122, 255, 0.3);
  width: 100%;
  cursor: pointer;
  transition: all var(--duration-fast) var(--easing);
}

.btn-secondary:hover {
  background-color: var(--surface-tertiary);
}

.btn-secondary:active {
  opacity: 0.8;
  transform: scale(0.98);
}
```

---

### Destructive Button

**iOS Implementation:**
```swift
.buttonStyle(.destructive)
```

**CSS Implementation:**
```css
.btn-destructive {
  font-size: 17px;
  font-weight: 600;
  color: white;
  background-color: var(--color-error);
  padding: var(--spacing-lg);
  border-radius: var(--radius-lg);
  border: none;
  width: 100%;
  cursor: pointer;
  transition: all var(--duration-fast) var(--easing);
}

.btn-destructive:hover {
  opacity: 0.9;
}

.btn-destructive:active {
  opacity: 0.8;
  transform: scale(0.98);
}
```

---

## 9. Card Style

**iOS Implementation:**
```swift
VStack { ... }
  .cardStyle()
```

**CSS Implementation:**
```css
.card {
  padding: var(--spacing-lg);
  background-color: var(--surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
}

.card-elevated {
  padding: var(--spacing-lg);
  background-color: var(--surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-elevated);
}
```

**React Component:**
```jsx
<div className="card">
  <h3>Order #HM-251202-001</h3>
  <p>Status: Preparing</p>
</div>
```

---

## 10. Complete CSS Design System

```css
/* ========================================
   CAMERONS CONNECT DESIGN SYSTEM
   Source: Business iOS DesignSystem.swift
   ======================================== */

/* Colors */
:root {
  /* Brand */
  --brand-primary: #007AFF;
  --brand-secondary: #FF9500;

  /* Semantic */
  --color-success: #34C759;
  --color-warning: #FF9500;
  --color-error: #FF3B30;
  --color-info: #007AFF;

  /* Text */
  --text-primary: #000000;
  --text-secondary: #8E8E93;

  /* Surfaces */
  --surface: #FFFFFF;
  --surface-secondary: #F2F2F7;
  --surface-tertiary: #FFFFFF;

  /* Order Status */
  --status-received: #007AFF;
  --status-preparing: #FF9500;
  --status-ready: #34C759;
  --status-completed: #8E8E93;
  --status-cancelled: #FF3B30;

  /* Spacing */
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 12px;
  --spacing-lg: 16px;
  --spacing-xl: 24px;
  --spacing-xxl: 32px;
  --spacing-xxxl: 48px;

  /* Border Radius */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-xxl: 24px;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 2px 4px rgba(0, 0, 0, 0.10);
  --shadow-lg: 0 4px 6px rgba(0, 0, 0, 0.15);
  --shadow-card: 0 4px 8px rgba(0, 0, 0, 0.10);
  --shadow-elevated: 0 6px 12px rgba(0, 0, 0, 0.15);

  /* Animation */
  --duration-fast: 150ms;
  --duration-normal: 250ms;
  --duration-slow: 350ms;
  --easing: cubic-bezier(0.4, 0.0, 0.2, 1);

  /* Icons */
  --icon-sm: 16px;
  --icon-md: 20px;
  --icon-lg: 24px;
  --icon-xl: 32px;
  --icon-xxl: 48px;
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
  :root {
    --text-primary: #FFFFFF;
    --text-secondary: #98989D;
    --surface: #000000;
    --surface-secondary: #1C1C1E;
    --surface-tertiary: #2C2C2E;
    --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.3);
    --shadow-md: 0 2px 4px rgba(0, 0, 0, 0.4);
    --shadow-lg: 0 4px 6px rgba(0, 0, 0, 0.5);
    --shadow-card: 0 4px 8px rgba(0, 0, 0, 0.4);
    --shadow-elevated: 0 6px 12px rgba(0, 0, 0, 0.5);
  }
}

/* Typography */
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
  font-size: 17px;
  line-height: 1.5;
  color: var(--text-primary);
  background-color: var(--surface);
}

.text-large-title { font-size: 34px; font-weight: 700; line-height: 1.2; }
.text-title { font-size: 28px; font-weight: 600; line-height: 1.3; }
.text-title2 { font-size: 22px; font-weight: 600; line-height: 1.3; }
.text-title3 { font-size: 20px; font-weight: 600; line-height: 1.4; }
.text-headline { font-size: 17px; font-weight: 600; line-height: 1.4; }
.text-subheadline { font-size: 15px; font-weight: 400; line-height: 1.4; }
.text-body { font-size: 17px; font-weight: 400; line-height: 1.5; }
.text-callout { font-size: 16px; font-weight: 400; line-height: 1.5; }
.text-caption { font-size: 12px; font-weight: 400; line-height: 1.3; }
.text-caption2 { font-size: 11px; font-weight: 400; line-height: 1.3; }

/* Buttons */
.btn-primary {
  font-size: 17px;
  font-weight: 600;
  color: white;
  background-color: var(--brand-primary);
  padding: var(--spacing-lg);
  border-radius: var(--radius-lg);
  border: none;
  width: 100%;
  cursor: pointer;
  transition: all var(--duration-fast) var(--easing);
}

.btn-primary:hover { opacity: 0.9; }
.btn-primary:active { opacity: 0.8; transform: scale(0.98); }

.btn-secondary {
  font-size: 17px;
  font-weight: 600;
  color: var(--brand-primary);
  background-color: var(--surface-secondary);
  padding: var(--spacing-lg);
  border-radius: var(--radius-lg);
  border: 1px solid rgba(0, 122, 255, 0.3);
  width: 100%;
  cursor: pointer;
  transition: all var(--duration-fast) var(--easing);
}

.btn-secondary:hover { background-color: var(--surface-tertiary); }
.btn-secondary:active { opacity: 0.8; transform: scale(0.98); }

.btn-destructive {
  font-size: 17px;
  font-weight: 600;
  color: white;
  background-color: var(--color-error);
  padding: var(--spacing-lg);
  border-radius: var(--radius-lg);
  border: none;
  width: 100%;
  cursor: pointer;
  transition: all var(--duration-fast) var(--easing);
}

.btn-destructive:hover { opacity: 0.9; }
.btn-destructive:active { opacity: 0.8; transform: scale(0.98); }

/* Cards */
.card {
  padding: var(--spacing-lg);
  background-color: var(--surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
}
```

---

## 11. React/TypeScript Integration

### Design System Hook

```typescript
// hooks/useDesignSystem.ts
export const useDesignSystem = () => {
  return {
    colors: {
      brandPrimary: 'var(--brand-primary)',
      brandSecondary: 'var(--brand-secondary)',
      success: 'var(--color-success)',
      warning: 'var(--color-warning)',
      error: 'var(--color-error)',
      statusReceived: 'var(--status-received)',
      statusPreparing: 'var(--status-preparing)',
      statusReady: 'var(--status-ready)',
      statusCompleted: 'var(--status-completed)',
      statusCancelled: 'var(--status-cancelled)',
    },
    spacing: {
      xs: 'var(--spacing-xs)',
      sm: 'var(--spacing-sm)',
      md: 'var(--spacing-md)',
      lg: 'var(--spacing-lg)',
      xl: 'var(--spacing-xl)',
      xxl: 'var(--spacing-xxl)',
      xxxl: 'var(--spacing-xxxl)',
    },
    radius: {
      sm: 'var(--radius-sm)',
      md: 'var(--radius-md)',
      lg: 'var(--radius-lg)',
      xl: 'var(--radius-xl)',
      xxl: 'var(--radius-xxl)',
      full: 'var(--radius-full)',
    },
  };
};
```

### Component Example

```tsx
// components/OrderCard.tsx
import { useDesignSystem } from '../hooks/useDesignSystem';

interface OrderCardProps {
  orderNumber: string;
  status: 'received' | 'preparing' | 'ready' | 'completed';
  total: number;
}

export const OrderCard: React.FC<OrderCardProps> = ({ orderNumber, status, total }) => {
  const ds = useDesignSystem();

  return (
    <div className="card">
      <div className="text-order-number">{orderNumber}</div>
      <span className="status-badge" data-status={status}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
      <div className="text-metric">${total.toFixed(2)}</div>
    </div>
  );
};
```

---

## 12. Current Status Assessment

| Component | iOS Status | Web Status | Alignment |
|-----------|------------|------------|-----------|
| Colors | ✅ Defined | ⚠️ Unknown | Needs audit |
| Typography | ✅ Defined | ⚠️ Unknown | Needs audit |
| Spacing | ✅ Defined | ⚠️ Unknown | Needs audit |
| Corner Radius | ✅ Defined | ⚠️ Unknown | Needs audit |
| Shadows | ✅ Defined | ⚠️ Unknown | Needs audit |
| Animations | ✅ Defined | ⚠️ Unknown | Needs audit |
| Button Styles | ✅ Defined | ⚠️ Unknown | Needs audit |
| Card Styles | ✅ Defined | ⚠️ Unknown | Needs audit |

---

## 13. Action Items

### Immediate (Week 1)
1. ✅ Audit existing website CSS
2. ✅ Create `design-system.css` with all tokens
3. ✅ Replace hardcoded values with CSS variables
4. ✅ Test light/dark mode

### Short-Term (Week 2)
1. ✅ Create React component library matching iOS
2. ✅ Implement button components
3. ✅ Implement card components
4. ✅ Document usage in Storybook

### Long-Term (Week 3+)
1. ✅ Automate design token sync
2. ✅ Add design system testing
3. ✅ Consider using CSS-in-JS (styled-components/emotion)
4. ✅ Create design system documentation site

---

**End of Website Design System Mapping**

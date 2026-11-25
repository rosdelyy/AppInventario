---
name: Retail Pulse
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#444651'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#757682'
  outline-variant: '#c5c5d3'
  surface-tint: '#4059aa'
  primary: '#00236f'
  on-primary: '#ffffff'
  primary-container: '#1e3a8a'
  on-primary-container: '#90a8ff'
  inverse-primary: '#b6c4ff'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#3e2400'
  on-tertiary: '#ffffff'
  tertiary-container: '#5c3800'
  on-tertiary-container: '#ef9900'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b6c4ff'
  on-primary-fixed: '#00164e'
  on-primary-fixed-variant: '#264191'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  title-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.03em
  numeric-keypad:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.75rem
  gutter-tablet: 1rem
  margin: 1rem
  margin-tablet: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
  space-2xl: 2rem
---

## Brand & Style

This design system is engineered for local merchants, retail staff, and small business owners who require rapid, error-free operational execution in fast-paced point-of-sale and inventory environments.

### Personality & Emotional Response
The interface evokes absolute operational command, financial precision, and effortless efficiency. It balances the robust reliability of enterprise-grade commerce platforms with the approachable, frictionless ergonomics of modern mobile consumer applications. Interactions feel immediate, reassuring, and tactile, eliminating anxiety during checkout queues, stock counting, and reconciliation tasks.

### Design Movement: Modern Utility & Tactile Ergonomics
The visual language merges **Modern Corporate Utility** with **Tactile Micro-affordances**:
- **Information Density with Breathing Room:** Dense data (SKUs, inventory levels, prices) is paired with generous touch targets (minimum 48×48dp) to prevent accidental taps during one-handed handheld usage.
- **Physicality and State Clarity:** Critical action buttons, keypads, and state badges employ subtle inner borders and deliberate press states that physically confirm user inputs on outdoor, low-light, or high-glare counter screens.
- **Visual Hygiene:** Heavy reduction of decorative clutter. Form strictly follows operational speed: stock health and transaction totals command the immediate visual focal point.

## Colors

The palette is tuned specifically for quick cognitive parsing in high-turnover retail environments. Color carries functional, non-negotiable operational meaning.

### Palette Architecture
- **Primary (`#1E3A8A` - Navy Indigo):** Represents financial security, brand infrastructure, and stable control. Applied to primary app navigation, top app bars, primary transaction actions, and structural headers.
- **Secondary (`#10B981` - Emerald Green):** Represents revenue generation, confirmed transactions, optimal stock levels, and terminal payment confirmations.
- **Tertiary (`#F59E0B` - Amber Alert):** Warns of low-stock thresholds, pending syncs, and items requiring reorder attention without blocking active checkout flows.
- **Critical / Out of Stock (`#EF4444` - Crimson Red):** High-priority alert state reserved for depleted inventory, failed payments, voids, and returns.
- **Neutral Core (`#0F172A` - Slate Black):** High-legibility base for typography and high-contrast numerical readouts. Paired with surface neutrals `#F8FAFC` (canvas background), `#FFFFFF` (card surfaces), and `#E2E8F0` (structural dividers).

### Accessibility & Sunlight Legibility
All text elements on light backgrounds maintain at least a 4.5:1 contrast ratio (AA), with large numerical totals exceeding 7:1 (AAA). Badges and alert states must not rely solely on color: each functional color pairing is backed by high-contrast foreground typography and dedicated iconography.

## Typography

Plus Jakarta Sans is utilized across all typography levels for its crisp geometric terminals, open apertures, and exceptional legibility on small-to-medium mobile viewports.

### Numerical and Monetary Hierarchies
- **Tabular Figures:** Always apply `font-variant-numeric: tabular-nums` to prices, inventory counts, currency totals, and barcode readouts to prevent horizontal jitter during rapid number updates.
- **Display Readouts:** `display-lg` and `display-lg-mobile` are strictly reserved for cash register running totals, cart balances, and final checkout screens.
- **Micro-Labels:** `label-sm` is uppercase-tracked for product metadata tags (e.g., `SKU-8921`, `LOTE #4`, `PASILLO B`).

## Layout & Spacing

The layout system is tailored for vertical single-hand mobile interactions (viewports 360px–428px wide) with seamless scaling up to standard retail POS tablets (768px–1024px).

### Layout System
- **Mobile Handheld (360px - 599px):** 4-column fluid grid. Outer margins are fixed to `1rem` (16px) with an inner column gutter of `0.75rem` (12px). All primary action triggers reside within the thumb-reach zone in the lower 40% of the screen.
- **Tablet / Countertop POS (600px - 1024px):** 8 to 12-column adaptive grid. Outer margins expand to `1.5rem` (24px). The UI automatically splits into a master-detail split layout: catalog/scanner on the left 60%, continuous ticket/cart on the right 40%.

### Spacing Rules
- **Touch Target Threshold:** Interactive controls must never measure below 48×48dp, even when using smaller typography or icons.
- **Vertical Rythm:** Card internals use `space-md` (12px) or `space-lg` (16px) internal padding. Grouped form controls rely on `space-md` spacing, while distinct thematic modules are separated by `space-xl` (24px).

## Elevation & Depth

Visual hierarchy is maintained via clean planar surfaces and low-contrast edge definition, preventing screen muddiness under intense retail fluorescent lighting or sunlight.

### Depth Architecture
1. **Canvas Surface (Level 0):** Flat background in `#F8FAFC`. Zero elevation.
2. **Card & Sheet Surfaces (Level 1):** Solid `#FFFFFF` surfaces paired with a crisp 1px border in `#E2E8F0` and an ultra-subtle ambient drop: `box-shadow: 0 1px 3px 0 rgba(15, 23, 42, 0.05)`.
3. **Floating Controls & Modals (Level 2):** Floating Action Buttons (e.g., Quick Scan Barcode FAB), floating sticky summary bars, and quick product selectors: `box-shadow: 0 4px 12px -2px rgba(15, 23, 42, 0.08), 0 2px 6px -1px rgba(15, 23, 42, 0.04)`.
4. **Bottom Sheets & Checkout Drawers (Level 3):** Modal bottom sheets for cash tenders or discount entry: `box-shadow: 0 -8px 24px -4px rgba(15, 23, 42, 0.12)`. Paired with a 40% opacity slate scrim (`#0F172A66`).

### Tactile Feedback States
Active press states use a downward scale transition (`transform: scale(0.98)`) and an instant elevation drop to surface level 0 to give immediate physical confirmation during rapid item ringing.

## Shapes

The design system adopts a balanced **Rounded (level 2)** shape standard:
- **Base UI elements:** Input fields, numeric keypad keys, and list items have a corner radius of `0.5rem` (8px).
- **Cards and Sheet Containers:** Product cards, modal bottom sheets, and summary modules use `rounded-lg` at `1rem` (16px).
- **Pills / Badges:** Stock indicators, filter chips, and status badges use fully rounded caps (`rounded-full` / 9999px) to clearly differentiate metadata tags from interactive square buttons and input fields.

## Components

### 1. Stock Status Badges
High-prominence tags with specific semantic pairings:
- **In Stock:** `#ECFDF5` background, `#065F46` label, secondary green dot indicator.
- **Low Stock:** `#FFFBEB` background, `#92400E` label, amber warning dot indicator.
- **Out of Stock:** `#FEF2F2` background, `#991B1B` label, red exclamation indicator.
Height: 24px; padding: 2px 8px; typography: `label-sm`.

### 2. Buttons & Keypad Triggers
- **Primary Action (Cobrar / Confirmar):** Solid `#10B981` (emerald green) or `#1E3A8A` (navy blue), full-width on mobile viewports, 52px height, `label-lg` bold typography.
- **Secondary / Void:** Ghost or bordered styling with a 1px `#CBD5E1` outline, `#0F172A` text, and minimum 48px height.
- **Point-of-Sale Numeric Keypad:** Large numeric grid keys with a minimum 60px height, centered `numeric-keypad` typography, 1px surface border, and active haptic/visual press state.

### 3. Finger-Optimized Quantity Inputs & Barcode Trigger
- **Increment/Decrement Steppers:** Minimum 48×48dp plus/minus touch areas flanking a high-contrast tabular number readout.
- **Barcode Input Bar:** Integrated continuous-search text input featuring a persistent right-aligned camera scan button (44×44dp touch area) colored in primary `#1E3A8A`.

### 4. POS Product Cards & List Items
- **Card Format (Grid View):** 1:1 square aspect ratio image container, bold product name truncated to 2 lines, bottom bar containing the price (`title-md`) and stock badge. Tap adds item immediately to active sale; long press opens product details/edit.
- **List Item (Inventory Management):** Compact 68px row containing SKU, stock quantity counter, price, and current status pill. Swipe left reveals rapid actions (Ajustar Stock / Desactivar).

### 5. Standard Bottom Navigation
Fixed 5-tab bar anchored to the bottom screen edge:
1. **Venta (POS / Caja):** Cash register icon.
2. **Inventario:** Warehouse/box icon.
3. **Movimientos / Historial:** Receipt/clock icon.
4. **Clientes / Créditos:** Users icon.
5. **Ajustes:** Sliders/cog icon.
Height: 64px + safe area inset. Inactive icons in `#64748B`; active tab highlighted in `#1E3A8A` with a 4px primary indicator pill.
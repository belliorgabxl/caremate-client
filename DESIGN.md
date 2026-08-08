---
name: CareMate
description: A home-care and medical-transport booking app for Thai family caregivers — a colorful, modern, luxury interface built on cool-white ground with jewel-tone brand colors and frosted-glass hero surfaces over blurred aurora color.
colors:
  primary: "#1668E3"
  primary-dark: "#0D4EA8"
  primary-light: "#E6F0FE"
  on-primary-container: "#0A3D91"
  background: "#F5F9FF"
  surface: "#FFFFFF"
  surface-alt: "#EFF5FC"
  border: "#DCE7F5"
  text-primary: "#10233F"
  text-secondary: "#54677E"
  text-tertiary: "#8FA0B5"
  success: "#12A150"
  danger: "#E0342C"
  warning: "#E08A00"
  info: "#0B84C4"
  coral-transport: "#FF6F5C"
  emerald-homecare: "#0EA66B"
  amethyst-medication: "#7C3AED"
  rose-errand: "#E8478D"
typography:
  display:
    fontFamily: "Manrope, sans-serif"
    fontSize: "40px"
    fontWeight: 800
    letterSpacing: "-0.5px"
  headline:
    fontFamily: "Manrope, sans-serif"
    fontSize: "24px"
    fontWeight: 800
    letterSpacing: "-0.2px"
  title:
    fontFamily: "Manrope, sans-serif"
    fontSize: "19px"
    fontWeight: 800
  body:
    fontFamily: "Manrope, sans-serif"
    fontSize: "15px"
    fontWeight: 500
    lineHeight: 1.4
  label:
    fontFamily: "Manrope, sans-serif"
    fontSize: "12.5px"
    fontWeight: 700
rounded:
  sm: "14px"
  md: "20px"
  lg: "28px"
  xl: "32px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  xxl: "24px"
  xxxl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    padding: "16px 24px"
    height: "56px"
  button-outlined:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    rounded: "{rounded.md}"
    height: "56px"
  card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.md}"
  card-glass:
    backgroundColor: "rgba(255,255,255,0.55)"
    blur: "24px"
    rounded: "{rounded.md}"
---

# Design System: CareMate

## Overview

**Creative North Star: "Aurora Glass"**

CareMate's visual identity is a colorful, modern, luxury evolution of a
Material 3 healthcare app: cool-white ground (kept, not warmed) so four
jewel-tone brand colors — Sapphire, Coral, Emerald, Amethyst — read vivid
against it, with soft blurred "aurora" color blobs sitting behind
frosted-glass hero cards at the top of key screens. This direction is
pinned (PRODUCT.md, 2026-08-05) and **replaces "Premium Clinic Companion"**
and its One Blue Rule — itself the direction that replaced the earlier,
fully-discarded "Report Book" exploration. Two pivots deep: this file
describes only the current, live system.

**Key Characteristics:**
- Cool-white ground; jewel-tone color now carries real brand weight, not just small categorization tints.
- Aurora blobs (blurred, low-alpha jewel-tone circles) anchored behind a screen's hero region — a color *source*, not standalone decoration.
- Frosted glass (`BackdropFilter` blur + translucent white + hairline border) on the one or two hero cards per screen that sit over an aurora blob; ordinary list/grid cards stay solid white.
- Generous corner radius (20px cards, 999px pills), two-layer soft shadows, no gradients anywhere — color and blur carry the "luxury" read, not gradient fills.
- Iconography stays literal and medical (stethoscope/health-and-safety/medication-style Material icons); icon badges now carry a soft colored shadow + fine ring, never a flat alpha-tint circle alone.

## Colors

Cool-white ground; four jewel-tone hues at full brand weight, each anchoring its own category and its own hero moments.

### Primary / Brand
- **Sapphire** (`#1668E3`, `primary`): global chrome — nav, focus rings, default CTAs, transport-adjacent moments. Feeds `ColorScheme.fromSeed`.
- **Deep Sapphire** (`#0D4EA8`, `primary-dark`): pressed/emphasis states.
- **Sky Container** (`#E6F0FE`, `primary-light`): light-blue emphasis surface — selected nav pill, primary-container backgrounds.

### Jewel Palette (full brand weight — the One Blue Rule no longer applies)
- **Coral** (`#FF6F5C`, `coral-transport`): รับ-ส่งพบแพทย์ / transport category — icon fills, matching CTAs, aurora blob.
- **Emerald** (`#0EA66B`, `emerald-homecare`): ดูแลรายชั่วโมง / home-care category, and doubles as the M3 `secondary` role app-wide.
- **Amethyst** (`#7C3AED`, `amethyst-medication`): ซื้อยา / medication category, and doubles as the M3 `tertiary` role app-wide.
- **Rose** (`#E8478D`, `rose-errand`): สมาชิกของฉัน / errand-adjacent category, a fifth accent alongside the four named jewels.

These are the same `AppColors.serviceTransport/serviceHomeCare/serviceMedication/serviceErrand` tokens from the prior system, deepened toward true jewel saturation and promoted to brand-weight status — no call site needed renaming.

### Neutral
- **Cool White** (`#F5F9FF`, `background`): scaffold background — kept cool, not warmed, so jewel colors pop rather than blend in.
- **Pure Surface** (`#FFFFFF`, `surface`): solid (non-glass) cards, sheets, dialogs.
- **Mist** (`#EFF5FC`, `surface-alt`): input fills, subtle section backgrounds.
- **Navy Ink** (`#10233F`, `text-primary`): all primary text.
- **Slate** (`#54677E`, `text-secondary`) / **Mist Gray** (`#8FA0B5`, `text-tertiary`): supporting and disabled text.

### Named Rules
**The Jewel Palette Rule** (replaces the One Blue Rule). Sapphire, Coral, Emerald, and Amethyst all carry real brand weight — hero glass tints, matching CTAs, aurora blobs — not just small icon tints. Rose stays a fifth categorization-only accent. A screen may still lead with Sapphire as its default/neutral action color; it is no longer the *only* color permitted to.
**The No-Gradient Rule** (unchanged, scoped). No gradient fill, gradient text, or gradient border on any surface, button, card, or text. The one exception is the aurora blobs themselves, which are solid low-alpha color blurred via `ImageFilter`/`BackdropFilter` — a blur, not an authored gradient — and only ever sit behind glass, never under flat content.

## Typography

**Display/Body Font:** Manrope (via `google_fonts`), system fallback. Unchanged by this pivot.

### Hierarchy
- **Display** (800, 40px, -0.5 tracking): rare, top-of-flow moments only.
- **Headline** (800, 24px): page/section-defining headings.
- **Title** (800/700, 17-19px): card titles, list-item primary text.
- **Body** (500, 15-16px, 1.4-1.45 line height): descriptions, addresses, all running copy.
- **Label** (700, 11.5-14.5px): buttons, badges, nav labels, dense metadata.

### Named Rules
**The Weight-Over-Size Rule.** Hierarchy is built primarily through font weight (500→700→800) and color, not through many discrete sizes.

## Layout

Single-column, generously padded (20px horizontal) `ListView`/`Column` screens with 24-32px vertical rhythm between sections. Sections lead with a heading (no eyebrow/kicker above it — banned, not just discouraged) and, where useful, a one-line subtitle. The top ~400-460px of a screen (greeting, stats, first summary card) is the aurora/glass hero region; everything below reverts to plain solid-white cards on cool-white ground.

## Elevation & Depth

Real Material 3 elevation plus one new material: frosted glass over blurred color.

### Shadow Vocabulary
- **Card lift** (two-layer: `0,1/blur 2/#1A10233F` + `0,8/blur 24/#0F10233F`): hero cards, primary CTAs, elevated summary panels, and all glass cards. Implemented as `AppCard(elevated: true)` / `AppCard(glass: true)`.
- **Soft lift** (`offset 0,2 / blur 8 / rgba(16,35,63,0.05)`): default `AppCard` — list-row cards, grid tiles, smaller elements.
- **Icon-badge shadow**: a soft shadow in the icon's own hue (real offset + blur, never zero-offset) plus a 1px ring at ~18% alpha of the same hue — `CircleIconAvatar` now carries this by default; a flat alpha-tint circle alone is the old, superseded state.

### Aurora & Glass
- **`AuroraBackground`** (`lib/shared/widgets/aurora_background.dart`): 3-4 large jewel-tone circles at ~50% alpha, blurred together via `ImageFiltered`, anchored non-scrolling behind a screen's hero region. It is a color source, not a decoration — only place it where a glass card will sit over it.
- **`AppCard(glass: true)`**: `BackdropFilter` blur (`sigma 24`) + `Colors.white` at 55% alpha + a 1.2px white hairline at 65% alpha + the Card-lift shadow. Use only where an `AuroraBackground` is actually behind the card; elsewhere it just frosts the plain background, which is a wasted effect, not a broken one — prefer `elevated: true` there instead.

### Named Rules
**The Real-Blur Rule.** Every shadow carries real offset and blur. A flat colored glow behind an element is decoration, not this system's depth language.
**The Glass-Reveals-Color Rule.** Blur is only ever used where it reveals the aurora color underneath (hero cards over blobs). Never apply `glass` as a generic "frosted" style on a surface with nothing colorful behind it — that is glass-as-decoration, which the craft floor bans.

## Shapes

Generous, consistent rounding: 14px on small chips/tags, 20px on cards and buttons, 28-32px on hero/sheet-level surfaces, pill (999px) on badges and the nav indicator. No sharp corners anywhere in this system.

## Components

### Buttons
- **Shape:** 20px radius, 56px minimum height.
- **Primary:** `FilledButton`, solid `primary` (Sapphire) blue, white text, zero elevation.
- **Category-matched CTA:** a button inside a category's own flow (e.g. "จองเพิ่ม" on a transport booking) may use that category's jewel color instead of Sapphire — new under the Jewel Palette Rule; the default action elsewhere stays Sapphire.
- **Outlined/Secondary:** `border` colored 1.4px border, `primary` text, transparent fill.
- **Icon buttons:** filled `surface-alt` background chip with `primary` icon color, 14px radius.

### Icon Badges (`CircleIconAvatar`)
- **Tonal (default):** the icon's own hue at 12% alpha fill, a 1px ring at 18% alpha, icon in full hue, plus the icon-badge shadow above. Never a flat tint circle with no ring/shadow — that reads as the old, pre-luxury state.
- **Filled:** solid hue fill, white icon, a stronger colored shadow (~30% alpha) for a "lifted chip" read — used for the one or two most important badges on a screen (e.g. a Care Tip card), not every icon.

### Cards
- **Corner Style:** 20px (`rounded.md`).
- **Default (`AppCard()`):** `surface` white, 1px `border`, Soft-lift shadow. List/grid rows.
- **Elevated (`AppCard(elevated: true)`):** borderless, Card-lift shadow, solid `surface` fill. Hero-level cards not sitting over an aurora blob.
- **Glass (`AppCard(glass: true)`):** see Aurora & Glass above. Reserve for the one or two hero cards per screen that actually sit over an `AuroraBackground`.
- **Internal Padding:** 20-22px on default/elevated, 22px+ on glass hero cards — never cramped.

### Inputs / Fields
- **Style:** filled `surface-alt`, no visible border at rest, 20px radius.
- **Focus:** 2px `primary` border appears.
- **Error:** 1.4px `danger` border at rest, 2px on focus.

### Navigation
`NavigationBar` (Material 3): white surface, pill-shaped `primary-light` indicator behind the selected icon, `primary` selected label/icon color, `text-secondary` unselected. 68px height.

## Do's and Don'ts

### Do:
- **Do** let Sapphire, Coral, Emerald, and Amethyst each carry real brand weight in their own category's flow — icon fills, matching CTAs, aurora blobs, hero glass tints.
- **Do** reserve `glass` for cards that actually sit over an `AuroraBackground`; use `elevated` for other hero cards, and the plain default for list/grid rows — the three-tier hierarchy is the point, not uniform treatment.
- **Do** give every icon badge its shadow + ring; a flat tint circle is the pre-pivot look.
- **Do** keep 20-32px corner radii and 56px button heights consistent across every screen.

### Don't:
- **Don't** use a gradient fill, gradient text, or gradient border anywhere — the aurora blobs are blurred solid color, not an authored gradient, and stay the one exception.
- **Don't** apply `glass`/`BackdropFilter` to a card with no aurora blob behind it — that's decoration, not the material this system built.
- **Don't** reintroduce the discarded "Report Book" kraft/stamp motifs, or the superseded One-Blue-only restraint — both are fully replaced, not alternates.
- **Don't** use a colored left/right border bar above 1px as a list-item accent — use an icon chip or tag instead.
- **Don't** let card density crowd out whitespace — when a screen feels tight, remove content or split screens before shrinking padding.

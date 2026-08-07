# Design

Direction name: **Tidewater**. Supersedes "Aurora Glass" (2026-08-05
pass) — same instinct (soft color wash behind hero content, frosted hero
cards) but the color story and background technique both change: brand
hue now comes from the real app icon gradient instead of a flat sapphire,
and the background trades heavy backdrop-blur "glass" for the sharper,
cheaper radial-wash + dot-grid technique already proven in the sibling
Partner app (`flutter-partner-app/packages/core_ui/lib/src/widgets/
cm_background.dart`) — same family device, re-tinted to this app's own
identity so the two apps read as siblings, not twins.

## Relationship to the Partner app

Deliberately shared: soft radial-wash background behind hero content,
pill-shaped primary actions, warm/tinted (never flat neutral) shadows,
generous corner radii, dot-grid texture as ambient surface detail.

Deliberately different: Partner is warm (orange accent `#FF6B35` + cream
ground); this app is cool (teal→blue accent, mist-white ground). Partner
uses IBM Plex Sans Thai at a slightly heavier default weight for its
operator/dispatch context; this app uses the same typeface family for
Thai-glyph correctness but leans on weight/size contrast rather than
color count — the customer app has one accent hue family, not an orange +
sage duo.

## Color

Source of truth: the real `assets/images/app_icon.png` gradient — sampled
top `#26DAD2` (teal) to bottom `#04ACCF` (cyan-blue). Neither endpoint is
accessible as a solid fill under white text (~2.7:1), so a deepened
`primary` carries all interactive/text-bearing surfaces; the true logo
gradient is reserved for decorative surfaces (background wash, hero
gradients, icon fills) where no text sits directly on top.

```
primary        #0E7A94   -- buttons, links, icons, focus rings (4.97:1 on white)
primaryDark    #0A5E73   -- pressed/hover state, deep text-on-tint
primaryLight   #E3F6F5   -- tint backgrounds, selected chips
accentGradientStart #22D3C6  -- decorative only (wash/hero gradients)
accentGradientEnd   #0EA5C4  -- decorative only (wash/hero gradients)
onPrimary      #FFFFFF

background     #F3FAFA   -- cool mist-white ground (vs. Partner's warm cream)
surface        #FFFFFF
surfaceAlt     #EAF6F5
border         #D7EBEA
textPrimary    #0F2A2E
textSecondary  #4E6B6E
textTertiary   #86A0A2
```

Semantic (success/warning/danger/info) and the four service-category
jewel tones (transport/home-care/medication/errand) are unchanged from
the previous system — they're independent accents, not brand identity,
and every booking/member screen outside this pass's flagship scope
(Login, Home) still depends on them.

## Typography

**IBM Plex Sans Thai** throughout (`GoogleFonts.ibmPlexSansThaiTextTheme`)
— matches the Partner app's family and is confirmed to cover Thai
glyphs, unlike the previous Manrope choice (Latin-only; every Thai string
in the app was silently falling back to the system font). Verify any
future typeface swap against a Thai-rendered screenshot, not the font
name alone.

Weight carries hierarchy the way the old system used color: headlines at
w800, section titles w700, body w500. No change to the existing type
scale (sizes/line-heights) from the previous pass — only the family and
Thai-coverage fix.

## Background technique — "Tide wash"

Full recipe (see `lib/shared/widgets/aurora_background.dart`):

1. Base: vertical linear gradient, mist-white → pale teal-white
   (`background` → `surfaceAlt`), not a flat fill.
2. 2-3 soft radial color blobs (teal/blue, `accentGradientStart`/`End` at
   low alpha), fading to transparent — **no `BackdropFilter` blur**. The
   previous system blurred a solid-color circle to fake softness; a
   `RadialGradient` fading to transparent is sharper, cheaper, and reads
   as intentional rather than a stock "frosted card" template.
3. Fine dot-grid texture overlay at very low alpha — the ambient detail
   that makes the wash read as a considered surface rather than a
   default gradient div.

Frosted glass (`AppCard(glass: true)`, real `BackdropFilter`) stays
reserved for the one or two hero cards actually sitting over a wash —
never a default treatment, per the existing DESIGN rule.

## Components

Reuse everything in `lib/shared/widgets/` unchanged in structure; only
tokens (color/font) flow through. One shape change: primary/secondary
buttons move from `AppRadius.md` (20) to `AppRadius.pill` (999) to share
the Partner app's pill-action language while keeping this app's own
color underneath.

## Motion

No change from the existing system this pass — compositor-friendly
properties only (transform/opacity), reduced-motion respected. Not
revisited in this pass; a future `/impeccable animate` pass can look at
motion specifically.

## Rollout status

**This pass: global tokens (`AppColors`, `AppTheme`, `AuroraBackground`)
+ flagship screens (Login, Home) only**, verified live on-device. Every
other screen (Register, Booking wizard/status/history, Members, Payment,
Profile group) still visually reads as the old "Aurora Glass" system
until a follow-up pass rolls Tidewater out to them — same incremental
approach the original Aurora Glass rollout used. Don't assume the whole
app matches this file yet; check which screens have actually been
touched (`git status` / recent commits) before claiming full rollout.

---
target: Home page (lib/features/home/presentation/pages/home_page.dart)
total_score: 23
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 2
timestamp: 2026-08-06T09-19-39Z
slug: ib-features-home-presentation-pages-home-page-dart
---
Method: dual-agent (A: a9b4c69c79157f792 · B: a627c8f1d3ff7b478)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | No error state — a failed `_load()` (lines 43-57, no try/catch) leaves an infinite spinner forever |
| 2 | Match Between System and Real World | 2 | Dev-facing "โหมดจำลอง" snackbar mixes the English word "Notification" into a Thai sentence and exposes a fake affordance for a feature the product architecture doesn't have (no push, polling-only) |
| 3 | User Control and Freedom | 3 | Pull-to-refresh present; nothing destructive to undo on this screen |
| 4 | Consistency and Standards | 3 | `_StatsCard`/`_PaymentSummaryCard`/`_CareTipCard` are hand-rolled duplicates of the shared `stat_card.dart`/`hero_header_card.dart` already in `lib/shared/widgets/` |
| 5 | Error Prevention | 3 | Nothing destructive to prevent on this read-mostly screen |
| 6 | Recognition Rather Than Recall | 3 | Notification bell and members-shortcut `IconButton`s (lines 74-84, 125-138) have no tooltip/semantic label |
| 7 | Flexibility and Efficiency | 2 | Multiple booking entry points exist, but nothing shortcuts a repeat booking for a specific relative |
| 8 | Aesthetic and Minimalist Design | 3 | Good token discipline (no raw hex/gradients, grep-confirmed) but risks 3 glass cards stacked at once, and off-DESIGN.md-scale spacing literals (14/18/3/2px) |
| 9 | Error Recovery | 1 | No error UI anywhere on this screen; a load failure is silent and permanent |
| 10 | Help and Documentation | 1 | A stuck `PENDING` booking (a documented, known backend gap) gets zero reassurance copy on this screen |
| **Total** | | **23/40** | **Acceptable — significant improvements needed** |

## Design Specificity Verdict

**LLM assessment (Assessment A):** Home is meaningfully authored for CareMate, not a generic dashboard skin. The urgent-first ordering (pending payment → active booking → payment-clear empty state, lines 149-201) is a real product decision that reflects the polling-based, no-push-notification architecture — a caregiver who owes money or has a booking mid-flight sees it first. The family/relative preview correctly reflects "booking for a relative" as first-class. But two details betray generic-dashboard defaults leaking through: a notification bell that exists purely to apologize for itself in a product whose architecture has no notifications at all, and a hardcoded male-gendered greeting particle ("สวัสดีครับ") in an app that models gender as a real field elsewhere.

**Deterministic scan (Assessment B):** The bundled detector has no Dart/Flutter engine — its `SCANNABLE_EXTENSIONS` list covers only `.html/.css/.js/.ts/.jsx/.tsx/.vue/.svelte/.astro`. The `[]` result on `home_page.dart` is a tooling gap, not a clean-code signal, and carries no weight either way. A manual static scan (grep + source read) found `home_page.dart` fully token-clean (no raw hex, no `Colors.*` literals, no gradients — the aurora blobs are correctly plain alpha-blurred `BoxDecoration` circles, the one sanctioned exception).

**Visual overlays:** Not available. No browser automation applies to this native Flutter/Android app, and no user-visible detector overlay exists for Dart source. The one real evidence photo captured this session is the **login screen**, not Home (the session was logged out; reaching an authenticated Home required a multi-step PDPA-gated registration judged not worth the cost for this run) — it confirms the Aurora Glass system renders faithfully live (blurred solid-color blobs, real glass translucency, high-contrast Sapphire CTA) but says nothing about Home's own layout or overflow behavior. Home itself was not visually observed this run.

## Overall Impression

The bones are right — urgent-first content ordering, correct jewel-color category tagging, clean token discipline — but the screen was verified happy-path-only and it shows: no error state exists at all, a fake notification affordance leaks dev-mode language to real users, and the signature "glass hero" effect is structurally at risk of frosting plain background once more than one urgent card is showing simultaneously (a pending payment *and* an active booking is a completely normal real-world state for this product, not an edge case). The single biggest opportunity is closing the gap between "verified once on the happy path" and what a returning caregiver with money owed and a booking in flight actually sees.

## What's Working

- **Urgent-first section ordering** (lines 149-201): pending-payment and active-booking cards surface before anything else, which is a genuine product-aware decision given the no-push, poll-only architecture — not decoration.
- **Jewel Palette Rule applied correctly** in `_QuickActionsGrid` (line 321): each service category tags with its own hue rather than defaulting to Sapphire everywhere.
- **Clean token discipline**: grep-confirmed zero raw hex/`Colors.*` literals and zero gradients anywhere in `home_page.dart` or the aurora/glass shared widgets — the No-Gradient Rule and `AppColors` usage are honored throughout.

## Priority Issues

**[P0] No error state on load failure**
- **Why it matters**: `_load()` (lines 43-57) has no try/catch. Any network failure — the exact kind of real-world condition this app must handle given its direct-to-backend, no-BFF architecture — leaves a permanent spinner with no retry, no message, no escape. A caregiver under time pressure hits a dead screen.
- **Fix**: Wrap `_load()` in try/catch; add an error variant of `EmptyState` with a retry action.
- **Suggested command**: `/impeccable harden`

**[P1] Fake notification affordance leaking dev-mode language**
- **Why it matters**: Both assessments independently flagged this. The bell (lines 74-86) opens a snackbar reading "ยังไม่มี Notification จริงในโหมดจำลอง" — English word mid-Thai-sentence (violates the project's Thai-only UI copy convention) and dev-facing "simulation mode" wording shown to real users, for a feature (notifications) the product architecture explicitly doesn't have.
- **Fix**: Remove the bell until real notifications exist, or repoint it at booking history/status, which is the thing this product actually offers instead of push.
- **Suggested command**: `/impeccable clarify`

**[P1] Glass-card stacking likely exceeds the aurora band**
- **Why it matters**: Both assessments independently converged here from different evidence. Assessment A flagged that when both `hasPendingPayment` and `hasActiveBooking` are true, three glass cards (`_StatsCard`, `_PaymentSummaryCard`, `_UpcomingBookingCard`) stack in sequence. Assessment B measured it: `AuroraBackground` is a fixed 460px `Positioned` element, and the cumulative height of greeting + subtitle + CTA row + `_StatsCard` alone plausibly approaches or exceeds that before the payment card even starts — meaning `glass` may be frosting plain white background, the exact anti-pattern DESIGN.md's Glass-Reveals-Color Rule bans. This is not a rare edge case; a pending payment plus an active booking is a normal state for this product.
- **Fix**: Demote `_UpcomingBookingCard` (and `_PaymentSummaryCard` when both render) to `elevated: true` instead of `glass: true` when stacked below the aurora band; verify on-device with both states active.
- **Suggested command**: `/impeccable polish`

**[P2] Touch targets under 44px on every section "see more" link**
- **Why it matters**: Assessment B traced this to source: `TextButtonThemeData` (`app_theme.dart:177-182`) sets no `minimumSize`, so `SectionHeader`'s action `TextButton` (`section_header.dart:45`) falls back to Material's default `(64, 36)` — a 36px tap height. This isn't a one-off; it affects every "ดูเพิ่ม/ดูรายการ/ทั้งหมด/จัดการ" link across the whole screen (lines 154, 165, 206, 216), and by extension anywhere else `SectionHeader` is reused app-wide.
- **Fix**: Set an explicit `minimumSize: Size(48, 48)` (or equivalent padding) in `TextButtonThemeData`.
- **Suggested command**: `/impeccable audit`

**[P2] Hardcoded gendered greeting ignores the user's own stored gender field**
- **Why it matters**: Line 104 always renders "สวัสดีครับ" (male-gendered particle) regardless of the logged-in user's `gender` field, which this app models as a real first-class value (`male`/`female`/`other`) elsewhere. For a female or non-binary user this is a small but real credibility ding on the very first line of the app's home surface.
- **Fix**: Branch the greeting particle on `user.gender`.
- **Suggested command**: `/impeccable clarify`

## Persona Red Flags

**Jordan (first-timer)**: Greeted with "ครับ" regardless of their actual gender — an immediate small credibility ding. Lands on a screen with 10+ independently tappable targets on first render (primary CTA, icon-only member shortcut, icon-only notification bell, 4-card quick-actions grid, up to 5 family avatars, booking-card buttons) with no cue about where to start beyond position. If their first booking ends up `PENDING` (a known, documented matching-retry gap), the `StatusBadge` gives zero explanation that this is expected — nothing on this screen reassures them it isn't broken.

**Casey (distracted, thumb-zone, interruption-prone)**: The primary CTA sits reachably near the top, which is good. But the icon-only notification bell and members shortcut (no tooltip/label on either) demand icon recall under a quick, interrupted glance — exactly the condition this persona fails at. If interrupted and returning to a state with both a pending payment and an active booking, the P1 glass-stacking issue above means the visual hierarchy that's supposed to say "handle this first" may itself be visually muddied.

## Minor Observations

- `_load()` awaits members then bookings sequentially instead of `Future.wait` — needless added latency on every screen open.
- `_StatsCard`, `_PaymentSummaryCard`, and `_CareTipCard` are hand-rolled rather than reusing the already-built `stat_card.dart`/`hero_header_card.dart` shared widgets — not a DESIGN.md violation (they're on-system), but a maintenance/drift risk.
- Several spacing literals (`14`, `18`, `3`, `2`px, at lines 363-364, 373, 427, 616, 666, among others) don't correspond to any value in DESIGN.md's spacing scale (4/8/12/16/20/24/32) — off-scale, not just un-tokenized.
- The booking address `Text` (line 464) has no `maxLines`/overflow handling — an unusually long address could stretch the card unpredictably tall.
- The loading state (line 89) is a bare `CircularProgressIndicator` with no `AuroraBackground` behind it, which is a small but real gap against CLAUDE.md's "every screen is Aurora Glass" claim.

## Questions to Consider

- What would this screen look like if it were verified once against its *worst* realistic state (pending payment + active booking + a load failure) instead of only the happy path it's been checked against so far?
- Does the notification bell earn its place at all, or does it exist only because dashboards conventionally have one — for a product whose actual differentiator is poll-based status visibility, not push?
- What would tapping a family member's avatar do if it jumped straight into the booking wizard with that person pre-selected, instead of opening the generic member list?

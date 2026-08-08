# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Primary users are family members/caregivers — typically an adult child or
relative acting as the household's care coordinator — who book and manage
home-care visits and medical transport on behalf of their relatives (up to
5, per `maxRelatives`), not only for themselves. They are comfortable with
apps but are managing someone else's care logistics under time pressure, so
the booking flow treats "who is this booking for" (self vs. a specific
relative) as a first-class decision, not an afterthought.

## Product Purpose

CareMate lets a user book, pay for, and track home-care and
medical-transport services — for themselves or for a relative on their
account — from service selection through matching to completion. Success is
a booking that gets created, paid, matched to a care partner, and completed,
with the user able to see where it stands at every stage (no push
notifications; the client polls status).

## Positioning

The differentiator is trust and accountability in who shows up: caregivers
and transport partners are vetted/verified and matched to each booking,
rather than the app being a plain scheduling/aggregation layer over
independent providers. Booking-status visibility during matching (including
the known matching-retry gap that can leave a booking `PENDING` for a while)
is part of making that trust legible, not just a technical necessity.

## Operating Context

- Thai-language UI throughout; mobile app (Android + iOS) talking directly
  to a Go/Fiber backend (`care-mate-backend`) via `dio` — no mock data layer,
  no BFF (the former Next.js proxy is no longer in the loop).
- Auth is a single HttpOnly session cookie, not a bearer token.
- Booking is a 5-step flow: service → time range → recipient (self or a
  named relative) → location (map picker with search) → confirm → pay →
  poll mission status. Destination is only required for transport-slug
  services.
- Payment includes PromptPay QR, generated client-side (EMVCo/CRC16), plus
  other methods fetched from the backend as real UUIDs (not slugs).
- Relative/member records carry gender (`male`/`female`/`other`, English
  values with Thai display labels) and blood type (`A`/`B`/`AB`/`O`).
- Registration has a frontend-enforced PDPA consent gate (full-screen
  policy the user must scroll to the end of) — the backend has no consent
  field to receive it yet.

## Capabilities and Constraints

- No environment switching: `apiBaseUrl` and other config are hardcoded
  Dart consts; targeting a different backend means hand-editing and
  rebuilding.
- Real, load-bearing backend inconsistencies the client must keep handling
  (not bugs to "fix" away): `data`/`Data`/`result`/bare response envelopes;
  snake_case vs. camelCase per-endpoint; some relative fields only persist
  via a follow-up `PATCH` after `POST` due to a backend gap; no `DELETE
  /user-relatives/{id}` yet.
- No push/webhook for booking status — status is polled (5s while
  `PENDING`, 20s once `MATCHED`/`IN_PROGRESS`).
- Known open gaps: Settings page was blank as of last check (unverified
  since); PromptPay QR never scan-tested against a real bank app; the
  member add/edit sheet has no address/map-picker field yet.
- Platform is adaptive by product intent (Android + iOS both real, first-
  class targets), but the current implementation is Material-only
  (`MaterialApp.router`, no Cupertino) — the iOS visual fork has not been
  built yet. Treat this as the acknowledged gap between intent and current
  state, not as evidence to fall back to Android-only.

## Brand Commitments

Name is "CareMate." UI copy is Thai throughout. A real logo now exists
(`assets/images/caremate-logo.png`/`.svg`, teal-to-blue gradient rounded-
square mark of two figures inside a heart, with a "CareMate" wordmark) and
is wired as the app's Android/iOS launcher icon (cropped to the mark alone
via `tool/crop_icon.dart` → `assets/images/app_icon.png`, generated with
`flutter_launcher_icons`). Note the logo's own teal-blue gradient is a fixed
brand asset, not subject to the in-app No-Gradient Rule below, which governs
UI surfaces only.

**Visual direction (pinned 2026-08-05, explicit — third iteration this
session): "Aurora Glass."** Colorful, modern, luxury: cool-white ground
(kept, not warmed) with four jewel-tone brand colors — Sapphire, Coral,
Emerald, Amethyst — carrying real brand weight (hero glass tints, matching
CTAs, category identity), not confined to small tints. Blurred "aurora"
color blobs anchor behind a screen's hero region; the one or two hero cards
sitting over a blob get a frosted-glass treatment (real `BackdropFilter`
blur + translucent white + hairline border); ordinary list/grid cards stay
solid white. No gradients on UI surfaces (the aurora blobs are blurred solid
color, not an authored gradient). Rounded corners, two-layer soft shadows,
accessible typography/contrast, meaningful medical iconography (now with a
soft colored shadow + fine ring on every icon badge) all carry forward
unchanged from the prior iteration.

This direction **replaces "Premium Clinic Companion"** (blue/white,
restrained One Blue Rule) the same way that replaced the earlier, fully
discarded "Report Book" exploration — each pivot fully supersedes the last,
none are kept as fallbacks. Craft bar named by the user for the underlying
Material 3 execution still applies: Zocdoc / One Medical, Google Fitbit /
Health, Oscar Health / Ro — now read through a more colorful, glass-forward
lens per this pivot. This is a standing preference — apply it to every
future screen without re-litigating the direction; only the pace of rollout
across screens is still being decided per-session.

## Evidence on Hand

No testimonials, case studies, press, or brand imagery on hand.
`booking-flow.md` (repo root) is the backend team's API contract for the
booking/payment/matching flow — a technical reference, not marketing
evidence. Future design work must not fabricate customer proof.

## Product Principles

- Booking on behalf of a relative is a first-class path, equal in weight to
  booking for oneself — recipient, address, and health info per relative
  all matter.
- Status visibility during matching is core to the trust pitch, not a nice-
  to-have — especially through the known `PENDING`-stuck gap.
- The client must reflect real backend behavior (envelope shape, casing,
  UUID-vs-slug payment IDs, RFC3339-with-offset timestamps) exactly as
  audited against the Go source, never an assumed "clean" contract.
- Thai-first UX and the fixed English-value/Thai-label convention for
  gender and blood type are contract, not stylistic choice.
- Known product debt (blank settings page, unverified PromptPay scan, no
  relative address picker, Android-only visual language despite adaptive
  intent) is real and should be named, not hidden, when touched.

## Accessibility & Inclusion

No confirmed accessibility standard is on record. Primary users are family
caregivers coordinating care for relatives — plausibly including elderly or
less tech-comfortable people either as bookers or as the subject of a
booking — which suggests legibility and touch-target generosity matter, but
this has not been confirmed as a hard requirement.

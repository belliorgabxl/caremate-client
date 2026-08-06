# CareMate — Flutter client app

## What this is
Flutter app (`client_app`) for booking home-care/medical-transport services. Real API
client via `dio` (`lib/core/network/api_client.dart`) — no mock data layer.

Three repos:
- `D:\SandBox\caremate` — **this repo**.
- `D:\SandBox\StartUp\caremate-client` (Next.js) — **not used by this app anymore**
  (was a BFF proxy layer, now bypassed — app calls the Go backend directly).
- `D:\SandBox\StartUp\care-mate-backend` (Go/Fiber) — this app calls **this** directly.
  Has its own `CLAUDE.md`. `booking-flow.md` (repo root here) is the backend team's
  frontend-facing spec for the booking/payment/matching API — read it before touching
  that flow again.

**Cross-repo writes are blocked from this session** (permission classifier). Backend/
Next.js work needs a session opened in that repo. Reads across repos are fine and were
used to audit real routes/DTOs (see `care-mate-backend/internal/dto/*.go` for ground
truth on request/response shapes — the frontend has been burned more than once by
assuming a field name instead of checking).

## Config — no `.env`, no env switching
`lib/core/config/app_config.dart` hardcodes everything as Dart `const`s: `apiBaseUrl`
(`http://10.0.2.2:3001/api/v1` — `10.0.2.2` is the **Android-emulator-only** alias for
the host's `localhost`; a physical device needs the host's real LAN IP), `promptPayId`,
`maxRelatives` (5), `platformFee` (20.0), `billingStepMinutes` (30). No
`flutter_dotenv`/`envied`/build flavors — switching environments means hand-editing
this file and rebuilding. Worth adding proper env config if this ever targets more than
one backend.

## Architecture conventions
- `lib/features/<feature>/{data,domain,presentation}/...`; `data/` = repos + plain
  Riverpod `Provider<T>`; pages are `ConsumerStatefulWidget`, load via `ref.read(...)`
  in `initState`.
- `go_router`, flat constants in `app_routes.dart`. Always `context.go`, never `push`;
  detail pages use their own `BackButton(onPressed: () => context.go(parent))`. Routes
  needing a path param (e.g. booking status) use `AppRoutes.xStatus = '/x/:id'` +
  a `AppRoutes.xStatusPath(id)` helper, with rich extra data passed via `context.go(path,
  extra: object)` and read off `state.extra` in the router.
- Reuse `lib/shared/widgets/`: `AppCard`, `AppTextField`, `PrimaryButton`,
  `SectionHeader`, `StatusBadge`, `CircleIconAvatar`, `HeroHeaderCard`, `EmptyState`,
  `LocationPickerPage` (map picker, now with search — see below).
- All UI copy is Thai. No codegen — models hand-write `fromJson`/`toJson`.
- Gender fields app-wide use English values `male`/`female`/`other` with Thai labels
  (`ชาย`/`หญิง`/`อื่นๆ`) — never send Thai literals as the field value, only as display
  labels. Blood type is `A`/`B`/`AB`/`O` only.

## Visual redesign — "Aurora Glass" world (rolled out app-wide)
Full-app visual redesign complete across every screen: `PRODUCT.md` and
`DESIGN.md` (both repo root) are the source of truth for product context and
the design system — read `DESIGN.md` before touching UI on any screen. Three
pivots deep this session, each fully superseding the last (none kept as
fallbacks): **Report Book** (kraft-paper/ink-stamp, discarded) → **Premium
Clinic Companion** (restrained blue/white, One Blue Rule, superseded) →
**Aurora Glass** (current): cool-white ground, four jewel-tone brand colors
at full weight (Sapphire/Coral/Emerald/Amethyst — `AppColors.primary` +
`serviceTransport/HomeCare/Medication`, deepened and promoted from mere
category tints, plus Rose/`serviceErrand` as a fifth accent), blurred
"aurora" color blobs (`AuroraBackground`) anchored behind a screen's hero
region, frosted-glass hero cards (`AppCard(glass: true)`, real
`BackdropFilter` blur) sitting over them, plain solid-white cards everywhere
else. No gradients on UI surfaces — the aurora blobs are blurred solid
color, not an authored gradient; that exception is scoped and documented in
`DESIGN.md`. Icon badges (`CircleIconAvatar`) now carry a soft colored
shadow + fine ring by default, not a flat tint circle.

**Rollout status: every screen done.** Home, Splash, `MainScaffold` bottom
nav (now Thai-labeled), Auth (Login/Register), Booking (wizard + status +
history), Members, Payment, and the full Profile group (Profile/Settings/
Addresses/Health Info/Personal Info) are all built to Aurora Glass. The
booking wizard, status page, Members, and Profile also apply the Jewel
Palette Rule concretely — selected/active elements tint with their own
service category color (e.g. a selected transport service card renders
Coral) instead of defaulting to Sapphire everywhere. Booking history was
deliberately left without an `AuroraBackground` (flat list of equal-weight
items, no natural glass hero — forcing one would violate DESIGN.md's "glass
only where it reveals real color behind it" rule); Payment's QR card is
`elevated`, not `glass`, to protect scan contrast against a frosted
background. Verified live end-to-end on-device: fresh registration through
PDPA consent → Home → Booking → Members → Profile → Settings, all rendering
correctly with no crashes. **Settings page's long-standing "renders blank"
issue (see Known issues) did not reproduce** — it now shows full content
(security-level card, toggles, login history) end-to-end.
`DESIGN.md`'s Do's and Don'ts has the hard rules (e.g. `glass` only where an
`AuroraBackground` is actually behind the card; category color tabs are a
small icon chip/tag, never a colored border-left bar above 1px).

A real app icon now exists too: `assets/images/caremate-logo.png` (source)
→ `tool/crop_icon.dart` crops the mark out of the wordmark → `assets/images/
app_icon.png` → `flutter_launcher_icons` (dev dependency, config in
`pubspec.yaml`) generates Android adaptive + legacy mipmaps and the iOS
`Assets.xcassets` set. Re-run `dart run flutter_launcher_icons` after ever
replacing `app_icon.png`.

Next planned step: none pending — the design rollout itself is done. Future
work here is refinement (a finish/polish review pass hasn't been run) or
new features on top of the now-consistent system.

## API integration essentials
- **Auth = one HttpOnly cookie, no bearer token.** `POST /authentication/login` and
  `POST /authentication/register` both set `caremate_session` via `Set-Cookie`.
  `AuthRepository._saveSessionCookie()` reads it off the Dio response headers and
  stores it via `LocalStorage`; `ApiClient`'s interceptor replays it as `Cookie` on
  every request.
- `ApiClient.unwrap()` handles the `data`/`Data`/`result`/bare envelope inconsistency;
  `pickField()` (in `booking.dart`) handles snake_case vs camelCase per-field — both
  are real, confirmed backend inconsistencies, not bugs to "fix."
- **Timestamps to the backend must be RFC3339 with an explicit offset.** Dart's
  `DateTime.toIso8601String()` on a local (non-UTC) `DateTime` omits the timezone
  entirely (`2026-08-05T09:00:00.000`, no `Z`/offset) — Go's
  `time.Parse(time.RFC3339, ...)` rejects that outright. `booking_repository.dart` has
  a `_toRfc3339()` helper for this; use it (or the same pattern) anywhere else a
  `DateTime` gets sent to this backend.
- **Payment method IDs must be the real UUID from `GET /payments/methods`**, not a
  slug string. The PromptPay method's real slug is `qr_promptpay` (confirmed via live
  curl against the backend) — the generic `"cash"` example in `booking-flow.md`'s JSON
  sample is not the real value, don't copy it verbatim. `PaymentMethod` model keeps
  both `id` (UUID, send this) and `slug` (compare against this) separately — never
  conflate them again.
- `care/services`' `requiresDestination` is `slug == 'transport'` exactly, not a
  loose heuristic.
- No push/webhook for booking status — after `POST /payments/confirm`, the client must
  **poll** `GET /bookings/:id/mission` (see `BookingStatusPage` for the reference
  polling implementation: 5s while `PENDING`, 20s once `MATCHED`/`IN_PROGRESS`, stop on
  terminal states, soft warning after 10min stuck `PENDING` per the backend's known
  matching-retry gap).
- Endpoint → repo: `authentication/*` → `auth_repository.dart`. `users/*` →
  `profile_repository.dart` / `booking_repository.dart`. `user-relatives` →
  `member_repository.dart`. `care/services`, `bookings*` → `booking_repository.dart`.
  `payments*` → `payment_repository.dart`.
- PromptPay QR is generated **client-side** (`payment/data/promptpay_qr.dart`,
  EMVCo/CRC16 algorithm) — no backend endpoint for it, ported from the old Next.js
  proxy's `promptpay-qr` npm package. **Still unverified against a real bank app scan.**

## Backend compatibility notes (audited against real Go source, not guessed)
- `DELETE /user-relatives/{id}` doesn't exist on the backend yet — `softDelete()`
  will 404 until it's added there.
- `GET /bookings` / `/bookings/history` return raw `domain.Booking` rows: snake_case
  only, no service/partner name preloaded, amount field is `fee` not `total_amount`.
  `POST /bookings/create`'s response and `user-relatives` responses, by contrast, are
  camelCase — the inconsistency is real and per-endpoint.
- `POST /user-relatives` (`CreateUserRelativeRequest`) has no `nickname`/`bloodType`
  fields at all, and its `dateOfBirth` is accepted but never persisted by the repo
  (backend bug) — only `PATCH` (`UpdateUserRelativeRequest`) actually writes those
  columns. `MemberRepository.create()` works around this with a follow-up `PATCH`
  right after the `POST`.
- Registration (`POST /authentication/register`)'s `RegisterRequest` only requires
  `phone`/`firstName`/`lastName` server-side (`nickname`/`gender`/`dateOfBirth`/`email`
  are nullable) — but the **app's register form requires all of them anyway** as a
  frontend policy choice (per explicit instruction), so `firstName`/`lastName`/
  `nickname`/`gender`/`dateOfBirth`/`email` are all validated required before submit.
  Address/health-info/emergency-contact remain deferred to the profile pages.
- Registration has a PDPA consent gate — **but the backend's `RegisterRequest`
  DTO has no consent/PDPA field at all**, confirmed against
  `internal/dto/authentication_dto.go`. Consent is recorded client-side
  (`LocalStorage.savePdpaConsentGiven(version)` — UTC timestamp + policy version
  in `SharedPreferences`, keys `cm_pdpa_consent_at`/`cm_pdpa_consent_version`).
  `PdpaConsentDialog` (`lib/features/auth/presentation/widgets/pdpa_consent_dialog.dart`)
  is a full-screen modal (`Navigator.push`, not a go_router route — it's a
  transient step inside `RegisterPage._register()`, not an addressable page)
  shown **after** the register form validates, right before the account is
  actually created. The accept button/checkbox stay disabled until the user
  scrolls the policy `ListView` to its end (`ScrollController` listener,
  `_scrolledToEnd`); declining (X button or the scroll gate never clearing)
  returns `null` and aborts registration before any API call.
  **`GET /pdpa` is now real** (per the backend team's "PDPA API — Frontend
  Integration Guide", 2026-08-06 — not independently re-audited against Go
  source the way the rest of this section is, but treated as ground truth):
  public, no auth, base path `/api/v1/pdpa` (so `/pdpa` relative to
  `apiBaseUrl`). Envelope-wrapped `{ id, version, title, content, summary,
  is_active, effective_date, updated_at }` — `content` is **pre-rendered
  HTML** (`<h2>...</h2><p>...</p><ul><li>...</li></ul>`), rendered as-is via
  the `flutter_html` package's `Html` widget in `PdpaConsentDialog`, no
  markdown parsing. `PdpaPolicy.fromJson` (`pdpa_policy.dart`) matches this
  shape. `AuthRepository.fetchPdpaPolicy()` calls it; on any failure
  (network error, or the documented 404 `"no active pdpa document"` if no
  version has been activated server-side) it falls back to
  `_fallbackPolicy` (same file, version `bundled-2026-08-04`, same ~10
  sections as before, now authored as an inline HTML string) — registration
  is never blocked on this call.
  - Two more endpoints from the same spec are wired into `AuthRepository`
    but **not yet called from any screen**: `fetchPdpaPolicyVersion(version)`
    (`GET /pdpa/:version` — the exact text a user agreed to at signup, even
    if a newer version is now active) and `fetchPdpaVersions()` (`GET
    /pdpa/versions` — metadata-only list, no `content`, for a future
    version-history UI).
  - `POST /authentication/register` gains two optional fields, already being
    sent by `AuthRepository.register()`: `pdpaConsent: true`,
    `pdpaConsentVersion: "<version the user actually saw>"`. **Still
    unconfirmed against the register endpoint's real DTO** — this new spec
    only covers `/pdpa/*`, not `/authentication/register`; currently assumed
    to be harmless no-ops server-side since the backend ignores unknown
    fields.
  - Not yet built: no endpoint to persist server-side or to read consent
    status back (e.g. for a future profile/settings display) — would need
    something like `GET /users/pdpa-consent` returning
    `{ consentGiven, consentVersion, consentAt }`. Nothing in the Flutter app
    calls this yet.

## Session log (most recent first)
- **2026-08-06 (latest)**: Wired the real PDPA API (backend team handed over a
  "PDPA API — Frontend Integration Guide" spec, `GET /pdpa`, `/pdpa/versions`,
  `/pdpa/:version`, public/no-auth, base path `/api/v1/pdpa`) — see "Backend
  compatibility notes" above for the full contract. Rewrote `PdpaPolicy`
  (`pdpa_policy.dart`) from the old proposed `{version, title, sections[]}`
  shape to the real `{id, version, title, content (HTML), summary, is_active,
  effective_date, updated_at}` one, added `PdpaVersionSummary` for the
  `/versions` list endpoint. `AuthRepository` now calls `GET /pdpa` (was
  `GET /legal/pdpa`, which never existed) plus two new methods,
  `fetchPdpaPolicyVersion()`/`fetchPdpaVersions()`, for the other two
  endpoints — neither is wired into a screen yet. Since `content` is
  pre-rendered HTML, added `flutter_html` (new dependency) and swapped
  `PdpaConsentDialog`'s manual section-list rendering for an `Html` widget;
  `_fallbackPolicy` (used on any fetch failure, incl. the documented 404 when
  no version is active yet) rewritten as an inline HTML string with the same
  content. `flutter analyze` clean project-wide. Not manually verified
  on-device against a live backend response yet — only against the fallback
  path (no backend was running this session).
- **2026-08-05 (latest)**: Finished the "Aurora Glass" pivot (see "Visual redesign"
  above) and rolled it out to every remaining screen — Splash, `MainScaffold` bottom
  nav (Thai-labeled now), Booking (wizard/status/history), Members, Payment, and the
  full Profile group. Added `AppCard.glass`/`.elevated` variants, `AuroraBackground`,
  and a colored-shadow-plus-ring upgrade to `CircleIconAvatar`. Also wired a real app
  icon end-to-end (`tool/crop_icon.dart` + `flutter_launcher_icons`, both platforms).
  Bulk of the rollout (Booking/Members/Payment/Profile) was done via four parallel
  background agents, each given the same reference-pattern context and DESIGN.md;
  all four came back clean on `flutter analyze` with sound, disclosed judgment calls
  (e.g. Payment's QR card kept opaque for scan contrast, Booking history left
  aurora-free since it has no natural glass hero). Verified everything together with
  a full rebuild + live on-device walkthrough: registered a fresh test account
  through the PDPA flow, then navigated Home → Booking → Members → Profile →
  Settings — all render correctly, no crashes. Incidentally re-verified and closed
  the long-standing "Settings page renders blank" known issue (no longer reproduces).
  **Nothing from this session is committed** — still working-tree only, per the same
  pattern as the rest of this session.
- **2026-08-05 (later)**: Ran `/impeccable init` again to reconcile this file — its
  "Visual redesign" section still described the discarded "Report Book" direction as
  in-progress, while `DESIGN.md`/`PRODUCT.md` already recorded the pivot to "Premium
  Clinic Companion" (blue/white Material 3) as pinned. Confirmed against the working
  tree (no `report*` tokens, no `report_widgets.dart`, `app_colors.dart`/`app_theme.dart`/
  `home_page.dart`/`app_card.dart` all modified toward the new system, plus a real
  `caremate-logo.png`/`.svg` added) and rewrote the section to match current code.
- **2026-08-05**: Started the full-app visual redesign (`/impeccable init` then a
  new-work direction roll). Wrote `PRODUCT.md` (platform recorded as
  `adaptive` — Android + iOS both real targets by product intent, though the
  app is Material-only today; iOS/Cupertino fork is acknowledged debt, not
  built). Rolled a direction through the concept-seed process (2 rounds,
  user re-rolled once) and landed on "Report Book": bookings read as stamped,
  signed entries in an official record, echoing the Thai school
  progress-report ritual. Built Home as the flagship (see "Visual redesign"
  section above), verified on-device across two fix rounds — caught and
  fixed a stray white Material `EmptyState` and a colored-border-left
  craft-floor violation (now documented as a hard Don't in `DESIGN.md`).
  Wrote `DESIGN.md` documenting both the new and legacy token systems.
  Hit the known emulator black-screen bug mid-session (see Known issues);
  resolved with the documented `emu kill` + `-no-snapshot-load` cold boot,
  unrelated to the code changes. **Nothing from this session is committed
  yet** — paused here per explicit instruction to continue tomorrow. Next:
  review Home, then roll the Report Book system out to the booking wizard.
- **2026-08-04**: Added a PDPA consent gate to registration, as a full-screen
  modal (`PdpaConsentDialog`) triggered from inside `RegisterPage._register()`
  right after form validation and before the register API call — not a
  separate route/step before the form (an earlier version of this session's
  work put it before the form and gated `/register` via go_router; that was
  wrong per explicit correction and has been reverted — `AppRoutes.pdpaConsent`
  no longer exists). User must scroll the full policy to the bottom before the
  checkbox/accept button become interactive. Backend has no consent field to
  receive this yet (see Backend compatibility notes) — frontend-only
  enforcement, with the policy content itself meant to come from a proposed
  `GET /legal/pdpa` (bundled fallback used today since that route 404s).
- **2026-08-03**: Member edit flow added (was create-only). Booking flow overhauled
  end-to-end against `booking-flow.md`: fixed the RFC3339 bug and the payment-method-
  UUID-vs-slug bug (both were silently breaking every booking creation), added the
  missing mission-status polling (`BookingStatusPage`), turned the single-scroll
  booking form into a real 5-step wizard (service → time-range → recipient → location
  → confirm) with a free start/end time-range picker (quick presets + custom
  `showTimePicker`, not fixed slots). Added location search (forward geocoding via the
  `geocoding` package — free, native-platform geocoder, no API key) to
  `LocationPickerPage`, so it's available everywhere that widget is used (booking
  pickup/destination, profile addresses). Registration form now requires
  nickname/gender/dateOfBirth/email up front. Verified live end-to-end on-device
  (real booking created → paid → confirmed → reached `PENDING`/matching, confirmed via
  direct backend query).
- **2026-08-02**: Full migration off the Next.js BFF to calling `care-mate-backend`
  directly (endpoint remap, not just base-URL swap — see old commit history / backend
  audit). PromptPay QR ported client-side. LINE OAuth login removed entirely, replaced
  with phone-based login/register. Root-caused and fixed the emulator black-screen
  render bug (see below).

## Known issues (open)
- ~~Settings page (`/profile/settings`) was blank as of last check~~ — **re-verified
  2026-08-05, resolved/no longer reproduces.** Navigated to it live on-device
  (registered account → Profile → ตั้งค่าความปลอดภัย) after the Aurora Glass rollout
  touched this file and it renders full content correctly (security-level card,
  toggle rows, login history). The earlier `ListTile` `Row`+`Flexible` crash fix
  must have actually resolved the blank-render symptom too; cause of the original
  blank-render was never isolated separately, but it no longer manifests. Re-check
  if it resurfaces, but stop assuming it's broken.
- **Emulator black-screen / solid-black render, recurring.** Root cause varies —
  confirmed at least twice this project: (1) a specific 16k-page-size AVD image
  (`sdk gphone16k` API 37)'s GPU passthrough is fundamentally broken on this machine —
  avoid that image, use a normal `sdk gphone64` image instead; (2) even on a normal
  image, a long-running emulator process can get its GPU/EGL state wedged after hours
  up, or come back from an auto-relaunch as a **stale snapshot restore** (not a clean
  boot) with confusing leftover app state. Fix each time: `adb -s <id> emu kill` then
  cold-boot with `emulator -avd <name> -no-snapshot-load`. Don't assume a black screen
  or weird app state is a code bug without a screenshot + logcat check first.
- PromptPay QR generator: logic/CRC verified against the official test vector, never
  scan-tested against a real bank app.
- Members page still has no map-picker integration for its own address field (the
  add/edit member sheet has no location field at all yet) — `LocationPickerPage` would
  drop in the same way it does for booking/profile addresses.
- `GET /bookings/{id}/mission` is now used (booking status polling); `GET
  /users/booking-check` is still unused, no screen for it.

## Debug tooling notes
- `adb` isn't on PATH — prefix commands with
  `export PATH="$PATH:/c/Users/Predator/AppData/Local/Android/Sdk/platform-tools"`.
- Git Bash mangles POSIX-looking remote paths in `adb shell`/`adb exec-out` args (e.g.
  `/sdcard/...` gets rewritten to a Windows path). Workaround: double the leading slash
  (`//sdcard/...`) on the *specific argument*, don't set `MSYS_NO_PATHCONV=1` globally
  (it also breaks legitimate local Windows-style path args in the same command).
- Prefer `adb shell uiautomator dump` + grep for `bounds="[...]"` over eyeballing
  screenshot pixel coordinates for tap targets — screenshots returned to the model are
  scaled (~1.2x smaller than real device pixels) and it's easy to tap the wrong thing,
  especially once a keyboard or bottom sheet shifts the layout.
- `adb shell input text` cannot send non-ASCII text (Thai, etc.) — it only simulates
  hardware keycodes, throws on unmappable characters. To test Thai input, fix the
  emulator's IME instead (see below), don't try to script it via `input text`.
- If Thai typing doesn't work in-app, it's almost always the emulator's Gboard having
  no Thai language subtype enabled (`adb shell settings get secure
  enabled_input_methods`), not an app bug — enable it via `adb shell settings put
  secure enabled_input_methods "...;<thai-subtype-hash>"` (get the hash from `adb
  shell ime list -a`), then `adb shell ime set <imeId>` to reload.
- Rebuild loop: `flutter build apk --debug` → `adb install -r -d ...` → `adb shell am
  force-stop <pkg>` → `adb shell am start -n <pkg>/.MainActivity`. Always force-stop
  before relaunching when testing state changes — `am start` on an already-running
  process just resumes it, which has caused real confusion (looked like a navigation
  bug, was actually stale state).

## Not done / out of scope
- No env switching for `apiBaseUrl` (see Config section above).
- Windows desktop platform (`windows/`) was scaffolded as a debugging aid, never
  actually built/used — needs Windows Developer Mode enabled to build at all.
- The 2026-08-03 session's work is committed (`414ab98 complete booking
  flow`). **Everything from the 2026-08-05 session (PRODUCT.md, DESIGN.md, the
  full Aurora Glass rollout across every screen, the app icon pipeline) is
  uncommitted as of this writing** — check `git status` / `git log` before
  assuming otherwise; don't assume everything below `414ab98` in the log
  reflects current working-tree state. `report_widgets.dart` never existed in
  a commit (built and discarded entirely within this uncommitted session).

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
  **Proposed backend contract, unimplemented — not audited against real Go
  source like the rest of this section, don't treat as confirmed:**
  - `GET /legal/pdpa` (public): `{ version, title, sections: [{ title, body }] }`,
    envelope-wrapped like other endpoints. The dialog calls this on load and
    falls back to a bundled copy (`_fallbackPolicy` in the same file, version
    `bundled-2026-08-04`, ~10 sections covering controller identity, data
    categories, the sensitive-data/health-info carve-out under PDPA s.26,
    legal basis, third-party disclosure, retention, security, data-subject
    rights, DPO contact, policy changes) on any failure — including the
    current 404, since the route doesn't exist yet — so registration is
    never blocked on it.
  - `POST /authentication/register` gains two optional fields, already being
    sent by `AuthRepository.register()`: `pdpaConsent: true`,
    `pdpaConsentVersion: "<version the user actually saw>"`. Currently
    harmless no-ops server-side since the backend ignores unknown fields.
  - Not yet built: no endpoint to persist server-side or to read consent
    status back (e.g. for a future profile/settings display) — would need
    something like `GET /users/pdpa-consent` returning
    `{ consentGiven, consentVersion, consentAt }`. Nothing in the Flutter app
    calls this yet.

## Session log (most recent first)
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
- **Settings page (`/profile/settings`) was blank as of last check** — a real crash
  there was already fixed (a `ListTile` title `Row`+`Flexible` infinite-width layout
  assertion), but the page still rendered nothing after that fix, cause not isolated.
  **Not re-verified in the 2026-08-03 session** — check it before assuming it's still
  broken or assuming it's fine.
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
- Entire session's work as of 2026-08-03 is committed (`414ab98 complete booking
  flow`) — check `git status` / `git log` before assuming anything is still
  uncommitted.

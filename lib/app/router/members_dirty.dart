import 'package:flutter/foundation.dart';

/// Flipped true by `MembersPage` after any successful create/update/delete/
/// setDefault. `BookingPage` listens for this and silently refetches its own
/// member list when it fires (see its `initState`/`_onMembersDirty`).
///
/// Needed because `StatefulShellRoute.indexedStack` (the bottom-tab shell —
/// see `app_router.dart`) keeps every tab's widget alive across switches
/// instead of rebuilding it, so `BookingPage.initState` — where it originally
/// fetched the member list — only ever runs once per app session. Without
/// this, adding a member on the Members tab would never show up back on the
/// Booking tab.
final membersDirty = ValueNotifier<bool>(false);

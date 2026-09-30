import 'package:flutter/foundation.dart';

/// Ticks every time the user switches to the Booking tab — including
/// re-tapping it while already active (see `MainScaffold._onTap`).
///
/// `StatefulShellRoute.indexedStack` keeps `BookingPage` alive across tab
/// switches, so its `initState` (where the bank-account gate and member list
/// are first loaded) only ever runs once per app session. Without this,
/// re-entering the tab after adding a bank account elsewhere — or after it
/// was somehow removed — would never re-run that check.
final bookingTabActivated = ValueNotifier<int>(0);

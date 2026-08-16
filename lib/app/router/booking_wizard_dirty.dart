import 'package:flutter/foundation.dart';

/// Set to `true` once the booking wizard (`BookingPage`) has state worth
/// losing (past the first "pick a service" step) and back to `false` once
/// that state is gone for a legitimate reason (fresh page load, successful
/// submit, or the page being disposed). `MainScaffold` reads this before
/// switching bottom-nav tabs away from the booking tab so a stray tap
/// doesn't silently discard an in-progress booking — same top-level
/// `ValueNotifier` idiom as `nav_direction.dart`.
final bookingWizardDirty = ValueNotifier<bool>(false);

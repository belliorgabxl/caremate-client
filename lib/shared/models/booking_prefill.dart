import 'address.dart';

/// Carries best-effort defaults into [BookingPage] via go_router's `extra:`
/// — never serialized over the network, so no `fromJson`/`toJson`. Every
/// field is optional and matching is best-effort: [BookingPage] applies
/// whichever fields resolve against its loaded `_services`/`_members` lists
/// and silently ignores the rest (e.g. a `serviceSlug` that doesn't match
/// any loaded [CareService] just leaves the default selection in place).
class BookingPrefill {
  const BookingPrefill({
    this.serviceSlug,
    this.memberId,
    this.pickupAddress,
    this.destinationAddress,
  });

  /// Matches `CareService.slug` — the wizard pre-selects the service whose
  /// slug equals this, if found among the loaded services.
  final String? serviceSlug;

  /// Matches `CareMember.id`.
  final String? memberId;

  final Address? pickupAddress;
  final Address? destinationAddress;
}

import '../../../core/config/app_config.dart';

int roundUpToBillingStep(int minutes) {
  if (minutes <= 0) return 0;
  final step = AppConfig.billingStepMinutes;
  return ((minutes + step - 1) ~/ step) * step;
}

double calculateServiceFee({
  required double baseFeePerHour,
  required int durationMinutes,
}) {
  final billableMinutes = roundUpToBillingStep(durationMinutes);
  return baseFeePerHour * (billableMinutes / 60);
}

double calculateTotal({
  required double baseFeePerHour,
  required int durationMinutes,
}) {
  return calculateServiceFee(
        baseFeePerHour: baseFeePerHour,
        durationMinutes: durationMinutes,
      ) +
      AppConfig.platformFee;
}

/// Mirrors the backend's `DISTANCE_TIERED` formula
/// (`pkg/calculate.DistanceTieredFee`) — [baseFeeFirstKm] is a minimum fare
/// covering the first km; [ratePerKm] applies only to distance beyond that.
/// A trip of 1km or less is charged exactly [baseFeeFirstKm].
double calculateDistanceTieredFee({
  required double baseFeeFirstKm,
  required double ratePerKm,
  required double distanceKm,
}) {
  if (distanceKm <= 1) return baseFeeFirstKm;
  return baseFeeFirstKm + ratePerKm * (distanceKm - 1);
}

/// Estimates a service's fee using whichever formula its `pricingModel`
/// selects — `DISTANCE_TIERED` prices purely by distance (ignoring
/// `baseFeePerHour`/duration entirely), everything else falls back to the
/// hourly formula. This is a presentational estimate only; the real total
/// always comes back authoritative from `POST /bookings/create`.
double calculateEstimatedTotal({
  required String pricingModel,
  required double baseFeePerHour,
  required double ratePerKm,
  required double baseFeeFirstKm,
  required int durationMinutes,
  required double distanceKm,
}) {
  if (pricingModel == 'DISTANCE_TIERED') {
    // Unlike the hourly estimate below, no separate platform-fee add-on here:
    // the backend's platform fee is a revenue split taken FROM this fee, not
    // an extra charge on top of it (`fee` IS `payment.totalAmount` — see
    // `internal/services/booking_service.go`). Adding `AppConfig.platformFee`
    // here would inflate the wizard's estimate above what the payment page
    // and the actual charge both show.
    return calculateDistanceTieredFee(
      baseFeeFirstKm: baseFeeFirstKm,
      ratePerKm: ratePerKm,
      distanceKm: distanceKm,
    );
  }
  return calculateTotal(
    baseFeePerHour: baseFeePerHour,
    durationMinutes: durationMinutes,
  );
}

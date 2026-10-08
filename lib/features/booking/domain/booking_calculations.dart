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

/// Mirrors the backend fee (`CreateBooking` in
/// `internal/services/booking_service.go`): the platform fee is a cut taken
/// from this amount, never added on top. Presentational only — the
/// authoritative total comes back from `POST /bookings/create`.
double calculateEstimatedTotal({
  required String pricingModel,
  required double baseFeePerHour,
  required double ratePerKm,
  required double baseFeeFirstKm,
  required double flatFee,
  required int durationMinutes,
  required double distanceKm,
}) {
  return switch (pricingModel) {
    'DISTANCE_TIERED' => calculateDistanceTieredFee(
      baseFeeFirstKm: baseFeeFirstKm,
      ratePerKm: ratePerKm,
      distanceKm: distanceKm,
    ),
    'FLAT_PER_BOOKING' || 'MONTHLY_PACKAGE' => flatFee,
    'HOURLY_PLUS_DISTANCE' =>
      calculateServiceFee(
            baseFeePerHour: baseFeePerHour,
            durationMinutes: durationMinutes,
          ) +
          ratePerKm * distanceKm,
    _ => calculateServiceFee(
      baseFeePerHour: baseFeePerHour,
      durationMinutes: durationMinutes,
    ),
  };
}

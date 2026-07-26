import '../../../core/config/app_config.dart';

int roundUpToBillingStep(int minutes) {
  if (minutes <= 0) return 0;
  final step = AppConfig.billingStepMinutes;
  return ((minutes + step - 1) ~/ step) * step;
}

double calculateServiceFee({required double baseFeePerHour, required int durationMinutes}) {
  final billableMinutes = roundUpToBillingStep(durationMinutes);
  return baseFeePerHour * (billableMinutes / 60);
}

double calculateTotal({required double baseFeePerHour, required int durationMinutes}) {
  return calculateServiceFee(baseFeePerHour: baseFeePerHour, durationMinutes: durationMinutes) +
      AppConfig.platformFee;
}

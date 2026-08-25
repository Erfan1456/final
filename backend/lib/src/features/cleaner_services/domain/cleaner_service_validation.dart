import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';

/// Pricing and currency validation for cleaner service offerings.
abstract final class CleanerServiceValidation {
  /// Minimum hourly rate in minor units.
  static const int minHourlyRateMinor = 1;

  /// Maximum hourly rate in minor units.
  static const int maxHourlyRateMinor = 100000000;

  static final RegExp _currency = RegExp(r'^[A-Za-z]{3}$');

  /// Requires an integer minor-unit amount. Rejects doubles and strings.
  static int requireHourlyRateMinor(Object? raw) {
    if (raw is! int) {
      throw const ProfileValidationException(
        code: 'invalid_hourly_rate',
        message: 'Hourly rate must be a whole number in minor units.',
      );
    }
    if (raw < minHourlyRateMinor || raw > maxHourlyRateMinor) {
      throw const ProfileValidationException(
        code: 'invalid_hourly_rate',
        message: 'Hourly rate is outside the allowed range.',
      );
    }
    return raw;
  }

  /// Requires three ASCII letters and normalizes to uppercase.
  static String requireCurrencyCode(Object? raw) {
    if (raw is! String) {
      throw const ProfileValidationException(
        code: 'invalid_currency_code',
        message: 'Currency code must be three letters.',
      );
    }
    final trimmed = raw.trim();
    if (!_currency.hasMatch(trimmed)) {
      throw const ProfileValidationException(
        code: 'invalid_currency_code',
        message: 'Currency code must be three letters.',
      );
    }
    return trimmed.toUpperCase();
  }

  /// Requires a JSON boolean.
  static bool requireActive(Object? raw) {
    if (raw is! bool) {
      throw const ProfileValidationException(
        message: 'Active flag must be a boolean.',
      );
    }
    return raw;
  }
}

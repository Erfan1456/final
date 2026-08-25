import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';

/// Address field validation. Backend-owned; not a GIS/geocoding layer.
abstract final class AddressValidation {
  /// Maximum label length after trim.
  static const int labelMax = 40;

  /// Maximum line1 length after trim.
  static const int line1Max = 120;

  /// Maximum line2 length after trim.
  static const int line2Max = 120;

  /// Maximum city length after trim.
  static const int cityMax = 80;

  /// Maximum region length after trim.
  static const int regionMax = 80;

  /// Maximum postal-code length after trim.
  static const int postalCodeMax = 20;

  static final RegExp _countryCode = RegExp(r'^[A-Za-z]{2}$');

  /// Required trimmed string with 1–[max] Unicode code points.
  static String requireText(
    Object? raw, {
    required int max,
    required String label,
  }) {
    if (raw is! String) {
      throw ProfileValidationException(message: '$label is required.');
    }
    final trimmed = raw.trim();
    final length = trimmed.runes.length;
    if (length < 1 || length > max) {
      throw ProfileValidationException(
        message: '$label must be between 1 and $max characters.',
      );
    }
    return trimmed;
  }

  /// Optional line2. Empty becomes `null`. Max 120 code points.
  static String? optionalLine2(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'Address line 2 is invalid.',
      );
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.runes.length > line2Max) {
      throw const ProfileValidationException(
        message: 'Address line 2 must be at most 120 characters.',
      );
    }
    return trimmed;
  }

  /// Exactly two ASCII letters, stored uppercase.
  static String requireCountryCode(Object? raw) {
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'Country code is required.',
      );
    }
    final trimmed = raw.trim();
    if (!_countryCode.hasMatch(trimmed)) {
      throw const ProfileValidationException(
        message: 'Country code must be two letters.',
      );
    }
    return trimmed.toUpperCase();
  }
}

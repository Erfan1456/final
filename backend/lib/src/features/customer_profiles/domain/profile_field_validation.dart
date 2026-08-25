import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';

/// Shared customer/cleaner profile field validation.
abstract final class ProfileFieldValidation {
  /// Minimum full-name Unicode code points.
  static const int fullNameMinCodePoints = 2;

  /// Maximum full-name Unicode code points.
  static const int fullNameMaxCodePoints = 100;

  static final RegExp _e164 = RegExp(r'^\+[0-9]{8,15}$');

  /// Trims [raw], rejects control characters, and enforces 2–100 code points.
  static String requireFullName(Object? raw) {
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'Full name is required.',
      );
    }
    final trimmed = raw.trim();
    if (_hasControlCharacters(trimmed)) {
      throw const ProfileValidationException(
        message: 'Full name contains invalid characters.',
      );
    }
    final length = trimmed.runes.length;
    if (length < fullNameMinCodePoints || length > fullNameMaxCodePoints) {
      throw const ProfileValidationException(
        message: 'Full name must be between 2 and 100 characters.',
      );
    }
    return trimmed;
  }

  /// Empty/whitespace becomes `null`. Non-empty values must be simplified E.164.
  static String? optionalPhoneE164(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'Phone number is invalid.',
      );
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (!_e164.hasMatch(trimmed)) {
      throw const ProfileValidationException(
        message: 'Enter a phone number in E.164 format.',
      );
    }
    return trimmed;
  }

  static bool _hasControlCharacters(String value) {
    for (final rune in value.runes) {
      if (rune <= 0x1F || (rune >= 0x7F && rune <= 0x9F)) {
        return true;
      }
    }
    return false;
  }
}

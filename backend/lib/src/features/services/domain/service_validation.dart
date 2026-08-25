import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_billing_model.dart';

/// Validation for platform-owned service catalog fields.
abstract final class ServiceValidation {
  /// Minimum slug length.
  static const int slugMinLength = 2;

  /// Maximum slug length.
  static const int slugMaxLength = 60;

  /// Minimum name Unicode code points.
  static const int nameMinCodePoints = 2;

  /// Maximum name Unicode code points.
  static const int nameMaxCodePoints = 100;

  /// Minimum description Unicode code points.
  static const int descriptionMinCodePoints = 10;

  /// Maximum description Unicode code points.
  static const int descriptionMaxCodePoints = 500;

  static final RegExp _slug = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

  /// Validates a catalog slug.
  static String requireSlug(Object? raw) {
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'Service slug is required.',
      );
    }
    final trimmed = raw.trim();
    if (trimmed.length < slugMinLength || trimmed.length > slugMaxLength) {
      throw const ProfileValidationException(
        message: 'Service slug must be between 2 and 60 characters.',
      );
    }
    if (!_slug.hasMatch(trimmed)) {
      throw const ProfileValidationException(
        message: 'Service slug format is invalid.',
      );
    }
    return trimmed;
  }

  /// Trims [raw] and enforces 2–100 Unicode code points without controls.
  static String requireName(Object? raw) {
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'Service name is required.',
      );
    }
    final trimmed = raw.trim();
    if (_hasControlCharacters(trimmed)) {
      throw const ProfileValidationException(
        message: 'Service name contains invalid characters.',
      );
    }
    final length = trimmed.runes.length;
    if (length < nameMinCodePoints || length > nameMaxCodePoints) {
      throw const ProfileValidationException(
        message: 'Service name must be between 2 and 100 characters.',
      );
    }
    return trimmed;
  }

  /// Trims [raw], rejects HTML/control characters, and enforces length.
  static String requireDescription(Object? raw) {
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'Service description is required.',
      );
    }
    final trimmed = raw.trim();
    if (_hasControlCharacters(trimmed) || _looksLikeHtml(trimmed)) {
      throw const ProfileValidationException(
        message: 'Service description must be plain text.',
      );
    }
    final length = trimmed.runes.length;
    if (length < descriptionMinCodePoints ||
        length > descriptionMaxCodePoints) {
      throw const ProfileValidationException(
        message: 'Service description must be between 10 and 500 characters.',
      );
    }
    return trimmed;
  }

  /// Parses the billing-model wire value.
  static ServiceBillingModel requireBillingModel(Object? raw) {
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'Billing model is required.',
      );
    }
    try {
      return ServiceBillingModel.fromWire(raw.trim());
    } on FormatException {
      throw const ProfileValidationException(
        message: 'Billing model is not supported.',
      );
    }
  }

  static bool _hasControlCharacters(String value) {
    for (final rune in value.runes) {
      if (rune <= 0x1F || (rune >= 0x7F && rune <= 0x9F)) {
        return true;
      }
    }
    return false;
  }

  static bool _looksLikeHtml(String value) {
    return value.contains('<') || value.contains('>');
  }
}

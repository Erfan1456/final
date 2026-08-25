import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';

/// Cleaner onboarding field validation.
abstract final class CleanerProfileValidation {
  /// Minimum bio Unicode code points.
  static const int bioMin = 20;

  /// Maximum bio Unicode code points.
  static const int bioMax = 1000;

  /// Minimum service-area Unicode code points.
  static const int serviceAreaMin = 2;

  /// Maximum service-area Unicode code points.
  static const int serviceAreaMax = 120;

  /// Minimum years of experience.
  static const int yearsExperienceMin = 0;

  /// Maximum years of experience.
  static const int yearsExperienceMax = 50;

  /// Minimum rejection-reason Unicode code points.
  static const int rejectionReasonMin = 5;

  /// Maximum rejection-reason Unicode code points.
  static const int rejectionReasonMax = 500;

  /// Required plain-text bio, 20–1000 Unicode code points after trim.
  static String requireBio(Object? raw) {
    if (raw is! String) {
      throw const ProfileValidationException(message: 'Bio is required.');
    }
    final trimmed = raw.trim();
    final length = trimmed.runes.length;
    if (length < bioMin || length > bioMax) {
      throw const ProfileValidationException(
        message: 'Bio must be between 20 and 1000 characters.',
      );
    }
    return trimmed;
  }

  /// Integer years of experience, 0–50 inclusive. Rejects doubles and strings.
  static int requireYearsExperience(Object? raw) {
    if (raw is! int) {
      throw const ProfileValidationException(
        message: 'Years of experience must be a whole number.',
      );
    }
    if (raw < yearsExperienceMin || raw > yearsExperienceMax) {
      throw const ProfileValidationException(
        message: 'Years of experience must be between 0 and 50.',
      );
    }
    return raw;
  }

  /// Required human-readable service-area text, 2–120 code points after trim.
  static String requireServiceArea(Object? raw) {
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'Service area is required.',
      );
    }
    final trimmed = raw.trim();
    final length = trimmed.runes.length;
    if (length < serviceAreaMin || length > serviceAreaMax) {
      throw const ProfileValidationException(
        message: 'Service area must be between 2 and 120 characters.',
      );
    }
    return trimmed;
  }

  /// Required rejection reason, 5–500 Unicode code points after trim.
  static String requireRejectionReason(Object? raw) {
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'A rejection reason is required.',
      );
    }
    final trimmed = raw.trim();
    final length = trimmed.runes.length;
    if (length < rejectionReasonMin || length > rejectionReasonMax) {
      throw const ProfileValidationException(
        message: 'Rejection reason must be between 5 and 500 characters.',
      );
    }
    return trimmed;
  }
}

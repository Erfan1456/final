// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_moderation_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Review input validation.
abstract final class ReviewValidation {
  static const int ratingMin = 1;
  static const int ratingMax = 5;
  static const int commentMaxCodePoints = 1000;
  static const int reasonMinCodePoints = 5;
  static const int reasonMaxCodePoints = 500;
  static const int defaultLimit = 20;
  static const int minLimit = 1;
  static const int maxLimit = 50;
  static const int publicDetailLimit = 10;
  static const String verifiedCustomerDisplayName = 'Verified customer';

  /// Requires an integer 1–5. Rejects double and numeric strings.
  static int requireRating(Object? raw) {
    if (raw is! int) {
      throw const InvalidReviewRatingException();
    }
    if (raw < ratingMin || raw > ratingMax) {
      throw const InvalidReviewRatingException();
    }
    return raw;
  }

  /// Optional comment. Empty becomes null. Max 1000 Unicode code points.
  static String? optionalComment(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw const InvalidReviewCommentException(
        message: 'Review comment must be plain text.',
      );
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (_hasDisallowedControls(trimmed)) {
      throw const InvalidReviewCommentException(
        message: 'Review comment contains invalid characters.',
      );
    }
    if (trimmed.runes.length > commentMaxCodePoints) {
      throw const InvalidReviewCommentException(
        message: 'Review comment must be at most 1000 characters.',
      );
    }
    return trimmed;
  }

  /// Required hide reason of 5–500 Unicode code points.
  static String requireReason(Object? raw) {
    if (raw is! String) {
      throw const InvalidReviewReasonException(
        message: 'Reason must be plain text.',
      );
    }
    final trimmed = raw.trim();
    if (_hasDisallowedControls(trimmed)) {
      throw const InvalidReviewReasonException(
        message: 'Reason contains invalid characters.',
      );
    }
    if (trimmed.runes.length < reasonMinCodePoints ||
        trimmed.runes.length > reasonMaxCodePoints) {
      throw const InvalidReviewReasonException(
        message: 'Reason must be between 5 and 500 characters.',
      );
    }
    return trimmed;
  }

  static ReviewModerationStatus? optionalStatus(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw const InvalidReviewStateException();
    }
    try {
      return ReviewModerationStatus.fromWire(raw.trim());
    } on FormatException {
      throw const InvalidReviewStateException();
    }
  }

  static int? optionalRatingFilter(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      if (parsed == null) {
        throw const InvalidReviewRatingException();
      }
      return requireRating(parsed);
    }
    return requireRating(raw);
  }

  static int requireLimit(Object? raw) {
    if (raw == null) {
      return defaultLimit;
    }
    final value = raw is int
        ? raw
        : raw is String
        ? int.tryParse(raw.trim())
        : null;
    if (value == null || value < minLimit || value > maxLimit) {
      throw const InvalidReviewStateException();
    }
    return value;
  }

  static ObjectId? optionalAfter(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is ObjectId) {
      return raw;
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        return ObjectId.fromHexString(raw.trim());
      } catch (_) {
        throw const ReviewNotFoundException();
      }
    }
    throw const ReviewNotFoundException();
  }

  static bool _hasDisallowedControls(String value) {
    for (final rune in value.runes) {
      if (rune == 0x09 || rune == 0x0A || rune == 0x0D) {
        continue;
      }
      if (rune < 0x20 || rune == 0x7F) {
        return true;
      }
    }
    return false;
  }
}

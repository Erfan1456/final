// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_category.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Dispute input validation.
abstract final class DisputeValidation {
  static const int subjectMinCodePoints = 5;
  static const int subjectMaxCodePoints = 120;
  static const int descriptionMinCodePoints = 20;
  static const int descriptionMaxCodePoints = 3000;
  static const int resolutionMinCodePoints = 10;
  static const int resolutionMaxCodePoints = 3000;
  static const int defaultLimit = 20;
  static const int minLimit = 1;
  static const int maxLimit = 50;
  static const String fallbackCustomerDisplayName = 'Customer';

  static DisputeCategory requireCategory(Object? raw) {
    if (raw is! String) {
      throw const InvalidDisputeCategoryException();
    }
    try {
      return DisputeCategory.fromWire(raw.trim());
    } on FormatException {
      throw const InvalidDisputeCategoryException();
    }
  }

  static DisputeStatus? optionalStatus(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw const InvalidDisputeStateException();
    }
    try {
      return DisputeStatus.fromWire(raw.trim());
    } on FormatException {
      throw const InvalidDisputeStateException();
    }
  }

  static DisputeCategory? optionalCategory(Object? raw) {
    if (raw == null) {
      return null;
    }
    return requireCategory(raw);
  }

  static String requireSubject(Object? raw) {
    if (raw is! String) {
      throw const InvalidDisputeSubjectException(
        message: 'Subject must be plain text.',
      );
    }
    final trimmed = raw.trim();
    if (_hasAnyControls(trimmed)) {
      throw const InvalidDisputeSubjectException(
        message: 'Subject contains invalid characters.',
      );
    }
    if (trimmed.runes.length < subjectMinCodePoints ||
        trimmed.runes.length > subjectMaxCodePoints) {
      throw const InvalidDisputeSubjectException(
        message: 'Subject must be between 5 and 120 characters.',
      );
    }
    return trimmed;
  }

  static String requireDescription(Object? raw) {
    if (raw is! String) {
      throw const InvalidDisputeDescriptionException(
        message: 'Description must be plain text.',
      );
    }
    final trimmed = raw.trim();
    if (_hasDisallowedControls(trimmed)) {
      throw const InvalidDisputeDescriptionException(
        message: 'Description contains invalid characters.',
      );
    }
    if (trimmed.runes.length < descriptionMinCodePoints ||
        trimmed.runes.length > descriptionMaxCodePoints) {
      throw const InvalidDisputeDescriptionException(
        message: 'Description must be between 20 and 3000 characters.',
      );
    }
    return trimmed;
  }

  static String requireResolution(Object? raw) {
    if (raw is! String) {
      throw const InvalidDisputeResolutionException(
        message: 'Resolution must be plain text.',
      );
    }
    final trimmed = raw.trim();
    if (_hasDisallowedControls(trimmed)) {
      throw const InvalidDisputeResolutionException(
        message: 'Resolution contains invalid characters.',
      );
    }
    if (trimmed.runes.length < resolutionMinCodePoints ||
        trimmed.runes.length > resolutionMaxCodePoints) {
      throw const InvalidDisputeResolutionException(
        message: 'Resolution must be between 10 and 3000 characters.',
      );
    }
    return trimmed;
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
      throw const InvalidDisputeStateException();
    }
    return value;
  }

  static ObjectId? optionalAfter(Object? raw) {
    return optionalObjectId(raw);
  }

  static ObjectId? optionalObjectId(Object? raw) {
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
        throw const DisputeNotFoundException();
      }
    }
    throw const DisputeNotFoundException();
  }

  static bool _hasAnyControls(String value) {
    for (final rune in value.runes) {
      if (rune < 0x20 || rune == 0x7F) {
        return true;
      }
    }
    return false;
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

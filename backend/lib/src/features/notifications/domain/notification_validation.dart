// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Notification list query validation.
abstract final class NotificationValidation {
  static const int defaultLimit = 20;
  static const int minLimit = 1;
  static const int maxLimit = 50;

  /// Parses list query. [unread] is optional.
  static ({bool? unread, int limit, ObjectId? after}) parseListQuery({
    Object? unread,
    Object? limitRaw,
    Object? after,
  }) {
    return (
      unread: _optionalBool(unread),
      limit: _requireLimit(limitRaw),
      after: _optionalObjectId(after),
    );
  }

  static bool? _optionalBool(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is bool) {
      return raw;
    }
    if (raw is String) {
      final value = raw.trim().toLowerCase();
      if (value == 'true') {
        return true;
      }
      if (value == 'false') {
        return false;
      }
    }
    throw const ProfileValidationException(
      message: 'unread must be true or false.',
    );
  }

  static int _requireLimit(Object? raw) {
    if (raw == null) {
      return defaultLimit;
    }
    final value = raw is int
        ? raw
        : raw is String
        ? int.tryParse(raw.trim())
        : null;
    if (value == null || value < minLimit || value > maxLimit) {
      throw const ProfileValidationException(
        message: 'limit must be between 1 and 50.',
      );
    }
    return value;
  }

  static ObjectId? _optionalObjectId(Object? raw) {
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
        throw const NotificationNotFoundException();
      }
    }
    throw const NotificationNotFoundException();
  }
}

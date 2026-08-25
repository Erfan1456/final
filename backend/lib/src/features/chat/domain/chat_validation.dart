// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Chat input validation. Plain text only; no HTML/Markdown requirements.
abstract final class ChatValidation {
  /// Minimum message Unicode code points after trim.
  static const int bodyMinCodePoints = 1;

  /// Maximum message Unicode code points after trim.
  static const int bodyMaxCodePoints = 2000;

  /// Default message page size.
  static const int defaultMessageLimit = 50;

  /// Minimum message page size.
  static const int minMessageLimit = 1;

  /// Maximum message page size.
  static const int maxMessageLimit = 100;

  /// Unpaginated conversation list cap.
  static const int conversationListCap = 50;

  /// Requires an ASCII-safe Idempotency-Key. Does not lowercase.
  static String requireIdempotencyKey(String? raw) {
    return BookingValidation.requireIdempotencyKey(raw);
  }

  /// Requires a trimmed plaintext body of 1–2000 Unicode code points.
  ///
  /// Newlines and tabs are allowed. Other control characters are rejected.
  static String requireBody(Object? raw) {
    if (raw is! String) {
      throw const InvalidMessageException(
        message: 'Message body must be plain text.',
      );
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const InvalidMessageException(
        message: 'Message body is required.',
      );
    }
    if (_hasDisallowedControls(trimmed)) {
      throw const InvalidMessageException(
        message: 'Message body contains invalid characters.',
      );
    }
    if (trimmed.runes.length < bodyMinCodePoints ||
        trimmed.runes.length > bodyMaxCodePoints) {
      throw const InvalidMessageException(
        message: 'Message body must be between 1 and 2000 characters.',
      );
    }
    return trimmed;
  }

  /// Parses message list query. [before] and [after] cannot both be set.
  static ({int limit, ObjectId? before, ObjectId? after}) parseMessageQuery({
    Object? limitRaw,
    Object? before,
    Object? after,
  }) {
    final beforeId = _optionalObjectId(before);
    final afterId = _optionalObjectId(after);
    if (beforeId != null && afterId != null) {
      throw const InvalidMessageCursorException();
    }
    return (
      limit: _requireLimit(limitRaw),
      before: beforeId,
      after: afterId,
    );
  }

  static int _requireLimit(Object? raw) {
    if (raw == null) {
      return defaultMessageLimit;
    }
    final value = raw is int
        ? raw
        : raw is String
        ? int.tryParse(raw.trim())
        : null;
    if (value == null || value < minMessageLimit || value > maxMessageLimit) {
      throw const InvalidMessageCursorException();
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
        throw const InvalidMessageCursorException();
      }
    }
    throw const InvalidMessageCursorException();
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

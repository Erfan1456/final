import 'dart:convert';

import 'package:hashlib/hashlib.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Booking input validation. Backend-owned; not a payment or GIS layer.
abstract final class BookingValidation {
  /// Maximum customer notes Unicode code points after trim.
  static const int notesMaxCodePoints = 500;

  /// Minimum required cleaner decline/cancel reason code points.
  static const int requiredReasonMinCodePoints = 5;

  /// Maximum reason Unicode code points after trim.
  static const int reasonMaxCodePoints = 500;

  /// Minimum Idempotency-Key length after trim.
  static const int idempotencyKeyMin = 16;

  /// Maximum Idempotency-Key length after trim.
  static const int idempotencyKeyMax = 128;

  /// Default list page size.
  static const int defaultLimit = 20;

  /// Minimum list page size.
  static const int minLimit = 1;

  /// Maximum list page size.
  static const int maxLimit = 50;

  /// Neutral cleaner-facing label when no customer profile exists.
  static const String fallbackCustomerDisplayName = 'Customer';

  /// Requires an ASCII-safe Idempotency-Key. Does not lowercase.
  static String requireIdempotencyKey(String? raw) {
    if (raw == null) {
      throw const IdempotencyKeyRequiredException();
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const IdempotencyKeyRequiredException();
    }
    if (trimmed.length < idempotencyKeyMin ||
        trimmed.length > idempotencyKeyMax) {
      throw const InvalidIdempotencyKeyException();
    }
    for (final unit in trimmed.codeUnits) {
      if (unit < 0x20 || unit > 0x7E) {
        throw const InvalidIdempotencyKeyException();
      }
    }
    return trimmed;
  }

  /// Optional customer notes. Empty/whitespace becomes `null`.
  static String? optionalCustomerNotes(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw const InvalidCustomerNotesException(
        message: 'Customer notes must be plain text.',
      );
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (_hasControlCharacters(trimmed)) {
      throw const InvalidCustomerNotesException(
        message: 'Customer notes contain invalid characters.',
      );
    }
    if (trimmed.runes.length > notesMaxCodePoints) {
      throw const InvalidCustomerNotesException(
        message: 'Customer notes must be at most 500 characters.',
      );
    }
    return trimmed;
  }

  /// Optional cancellation reason. Empty/whitespace becomes `null`.
  static String? optionalReason(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'Reason must be plain text.',
      );
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (_hasControlCharacters(trimmed)) {
      throw const ProfileValidationException(
        message: 'Reason contains invalid characters.',
      );
    }
    if (trimmed.runes.length > reasonMaxCodePoints) {
      throw const ProfileValidationException(
        message: 'Reason must be at most 500 characters.',
      );
    }
    return trimmed;
  }

  /// Required decline/cancel reason of 5–500 Unicode code points.
  static String requireReason(Object? raw) {
    final value = optionalReason(raw);
    if (value == null || value.runes.length < requiredReasonMinCodePoints) {
      throw const ProfileValidationException(
        message: 'Reason must be between 5 and 500 characters.',
      );
    }
    return value;
  }

  /// Canonical fingerprint payload. Deterministic and timestamp-free.
  static String fingerprintCanonical({
    required ObjectId customerUserId,
    required ObjectId availabilitySlotId,
    required ObjectId addressId,
    required String? customerNotes,
  }) {
    return jsonEncode(<Object?>[
      customerUserId.oid,
      availabilitySlotId.oid,
      addressId.oid,
      customerNotes,
    ]);
  }

  /// SHA-256 of [canonical] as lowercase hexadecimal.
  static String fingerprintHex(String canonical) {
    return sha256.string(canonical, utf8).hex();
  }

  /// SHA-256 fingerprint of booking-creation intent.
  static String requestFingerprint({
    required ObjectId customerUserId,
    required ObjectId availabilitySlotId,
    required ObjectId addressId,
    required String? customerNotes,
  }) {
    return fingerprintHex(
      fingerprintCanonical(
        customerUserId: customerUserId,
        availabilitySlotId: availabilitySlotId,
        addressId: addressId,
        customerNotes: customerNotes,
      ),
    );
  }

  /// Parses an optional booking status list filter.
  static BookingStatus? optionalStatus(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'status must be a booking status.',
      );
    }
    try {
      return BookingStatus.fromWire(raw.trim());
    } on FormatException {
      throw const ProfileValidationException(
        message: 'status must be a booking status.',
      );
    }
  }

  /// Parses `limit` with default 20, bounds 1–50.
  static int requireLimit(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return defaultLimit;
    }
    final value = raw is int
        ? raw
        : (raw is String ? int.tryParse(raw.trim()) : null);
    if (value == null || value < minLimit || value > maxLimit) {
      throw const ProfileValidationException(
        message: 'limit must be between 1 and 50.',
      );
    }
    return value;
  }

  /// Parses an optional descending `_id` cursor.
  static ObjectId? optionalCursor(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'after must be a document cursor.',
      );
    }
    try {
      return ObjectId.fromHexString(raw.trim());
    } catch (_) {
      throw const ProfileValidationException(
        message: 'after must be a document cursor.',
      );
    }
  }

  /// Parses an optional ObjectId query value.
  static ObjectId? optionalObjectId(Object? raw, {required String field}) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is ObjectId) {
      return raw;
    }
    if (raw is! String) {
      throw ProfileValidationException(message: '$field is invalid.');
    }
    try {
      return ObjectId.fromHexString(raw.trim());
    } catch (_) {
      throw ProfileValidationException(message: '$field is invalid.');
    }
  }

  /// Parses an optional ISO-8601 timestamp and normalizes to UTC.
  static DateTime? optionalUtcDateTime(Object? raw, {required String field}) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is DateTime) {
      return raw.toUtc();
    }
    if (raw is! String) {
      throw ProfileValidationException(message: '$field is invalid.');
    }
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) {
      throw ProfileValidationException(message: '$field is invalid.');
    }
    return parsed.toUtc();
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

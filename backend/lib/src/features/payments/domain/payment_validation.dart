import 'dart:convert';

import 'package:hashlib/hashlib.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Payment input validation. Amount and currency are never taken from clients.
abstract final class PaymentValidation {
  /// Minimum refund reason Unicode code points after trim.
  static const int reasonMinCodePoints = 5;

  /// Maximum refund reason Unicode code points after trim.
  static const int reasonMaxCodePoints = 500;

  /// Default admin list page size.
  static const int defaultLimit = 20;

  /// Minimum list page size.
  static const int minLimit = 1;

  /// Maximum list page size.
  static const int maxLimit = 50;

  /// Minimum sandbox webhook secret UTF-8 byte length.
  static const int sandboxWebhookSecretMinBytes = 32;

  /// Reuses booking Idempotency-Key rules. Does not lowercase.
  static String requireIdempotencyKey(String? raw) {
    return BookingValidation.requireIdempotencyKey(raw);
  }

  /// Canonical start-payment fingerprint payload. Amount is not included.
  static String fingerprintCanonical({
    required ObjectId customerUserId,
    required ObjectId bookingId,
  }) {
    return jsonEncode(<Object?>[customerUserId.oid, bookingId.oid]);
  }

  /// SHA-256 of start-payment intent.
  static String requestFingerprint({
    required ObjectId customerUserId,
    required ObjectId bookingId,
  }) {
    return BookingValidation.fingerprintHex(
      fingerprintCanonical(
        customerUserId: customerUserId,
        bookingId: bookingId,
      ),
    );
  }

  /// Canonical refund fingerprint payload.
  static String refundFingerprintCanonical({
    required ObjectId paymentId,
    required int amountMinor,
    required String reason,
  }) {
    return jsonEncode(<Object?>[paymentId.oid, amountMinor, reason]);
  }

  /// SHA-256 of refund intent.
  static String refundRequestFingerprint({
    required ObjectId paymentId,
    required int amountMinor,
    required String reason,
  }) {
    return BookingValidation.fingerprintHex(
      refundFingerprintCanonical(
        paymentId: paymentId,
        amountMinor: amountMinor,
        reason: reason,
      ),
    );
  }

  /// SHA-256 of exact raw webhook body bytes as lowercase hex.
  static String payloadSha256(List<int> bodyBytes) {
    return sha256.convert(bodyBytes).hex();
  }

  /// Required refund reason of 5–500 Unicode code points.
  static String requireRefundReason(Object? raw) {
    if (raw == null || raw is! String) {
      throw const InvalidRefundReasonException(
        message: 'Reason must be between 5 and 500 characters.',
      );
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.runes.length < reasonMinCodePoints) {
      throw const InvalidRefundReasonException(
        message: 'Reason must be between 5 and 500 characters.',
      );
    }
    if (_hasControlCharacters(trimmed)) {
      throw const InvalidRefundReasonException(
        message: 'Reason contains invalid characters.',
      );
    }
    if (trimmed.runes.length > reasonMaxCodePoints) {
      throw const InvalidRefundReasonException(
        message: 'Reason must be between 5 and 500 characters.',
      );
    }
    return trimmed;
  }

  /// Remaining refundable amount for [payment].
  static int remainingRefundable(Payment payment) {
    return payment.amountMinor - payment.refundedAmountMinor;
  }

  /// Parses a provided refund amount without remaining-balance checks.
  static int parseProvidedRefundAmount(Object amountRaw) {
    final value = amountRaw is int
        ? amountRaw
        : (amountRaw is String ? int.tryParse(amountRaw.trim()) : null);
    if (value == null || value < 1) {
      throw const InvalidRefundAmountException();
    }
    return value;
  }

  /// Validates a refund amount. Null means the remaining refundable amount.
  static int requireRefundAmount({
    required Payment payment,
    required Object? amountRaw,
  }) {
    final remaining = remainingRefundable(payment);
    if (remaining < 1) {
      throw const InvalidRefundAmountException();
    }
    if (amountRaw == null) {
      return remaining;
    }
    final value = parseProvidedRefundAmount(amountRaw);
    if (value > remaining) {
      throw const InvalidRefundAmountException();
    }
    return value;
  }

  /// Parses an optional payment status filter.
  static PaymentStatus? optionalStatus(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'status must be a payment status.',
      );
    }
    try {
      return PaymentStatus.fromWire(raw.trim());
    } on FormatException {
      throw const ProfileValidationException(
        message: 'status must be a payment status.',
      );
    }
  }

  /// Parses an optional provider filter.
  static PaymentProviderType? optionalProvider(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'provider must be a payment provider.',
      );
    }
    try {
      return PaymentProviderType.fromWire(raw.trim());
    } on FormatException {
      throw const ProfileValidationException(
        message: 'provider must be a payment provider.',
      );
    }
  }

  /// Parses an optional currency filter.
  static String? optionalCurrency(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'currency must be a currency code.',
      );
    }
    final value = raw.trim().toUpperCase();
    if (value.length != 3) {
      throw const ProfileValidationException(
        message: 'currency must be a currency code.',
      );
    }
    return value;
  }

  /// Parses `limit` with default 20, bounds 1–50.
  static int requireLimit(Object? raw) {
    return BookingValidation.requireLimit(raw);
  }

  /// Parses an optional descending `_id` cursor.
  static ObjectId? optionalCursor(Object? raw) {
    return BookingValidation.optionalCursor(raw);
  }

  /// Parses an optional ObjectId query filter.
  static ObjectId? optionalObjectId(Object? raw, {required String field}) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw ProfileValidationException(
        message: '$field must be a document id.',
      );
    }
    try {
      return ObjectId.fromHexString(raw.trim());
    } catch (_) {
      throw ProfileValidationException(
        message: '$field must be a document id.',
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
}

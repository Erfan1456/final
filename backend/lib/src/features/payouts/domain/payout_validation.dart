import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_status.dart';
import 'package:home_cleaning_marketplace_api/src/http/api_date_time.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Payout input validation. Destination credentials are never accepted.
abstract final class PayoutValidation {
  /// Minimum rejection reason Unicode code points after trim.
  static const int reasonMinCodePoints = 5;

  /// Maximum rejection reason Unicode code points after trim.
  static const int reasonMaxCodePoints = 500;

  /// Default list page size.
  static const int defaultLimit = 20;

  /// Minimum sandbox payout webhook secret UTF-8 byte length.
  static const int sandboxPayoutWebhookSecretMinBytes = 32;

  /// Maximum finance summary range in days.
  static const int maxFinanceRangeDays = 366;

  /// Default finance summary lookback in days.
  static const int defaultFinanceRangeDays = 30;

  static final RegExp _currency = RegExp(r'^[A-Za-z]{3}$');

  /// Reuses booking Idempotency-Key rules. Does not lowercase.
  static String requireIdempotencyKey(String? raw) {
    return BookingValidation.requireIdempotencyKey(raw);
  }

  /// Requires a positive integer minor-unit amount.
  ///
  /// Rejects doubles and string numbers.
  static int requireAmountMinor(Object? raw) {
    if (raw is! int) {
      throw const InvalidPayoutAmountException();
    }
    if (raw < 1) {
      throw const InvalidPayoutAmountException();
    }
    return raw;
  }

  /// Requires three ASCII letters and normalizes to uppercase.
  static String requireCurrencyCode(Object? raw) {
    if (raw is! String) {
      throw const InvalidPayoutCurrencyException();
    }
    final trimmed = raw.trim();
    if (!_currency.hasMatch(trimmed)) {
      throw const InvalidPayoutCurrencyException();
    }
    return trimmed.toUpperCase();
  }

  /// Canonical payout-request fingerprint payload.
  static String fingerprintCanonical({
    required ObjectId cleanerUserId,
    required int amountMinor,
    required String currencyCode,
  }) {
    return jsonEncode(<Object?>[cleanerUserId.oid, amountMinor, currencyCode]);
  }

  /// SHA-256 of payout intent.
  static String requestFingerprint({
    required ObjectId cleanerUserId,
    required int amountMinor,
    required String currencyCode,
  }) {
    return BookingValidation.fingerprintHex(
      fingerprintCanonical(
        cleanerUserId: cleanerUserId,
        amountMinor: amountMinor,
        currencyCode: currencyCode,
      ),
    );
  }

  /// Required rejection reason of 5–500 Unicode code points.
  static String requireRejectionReason(Object? raw) {
    if (raw == null || raw is! String) {
      throw const InvalidPayoutRejectionReasonException(
        message: 'Reason must be between 5 and 500 characters.',
      );
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.runes.length < reasonMinCodePoints) {
      throw const InvalidPayoutRejectionReasonException(
        message: 'Reason must be between 5 and 500 characters.',
      );
    }
    if (_hasControlCharacters(trimmed)) {
      throw const InvalidPayoutRejectionReasonException(
        message: 'Reason contains invalid characters.',
      );
    }
    if (trimmed.runes.length > reasonMaxCodePoints) {
      throw const InvalidPayoutRejectionReasonException(
        message: 'Reason must be between 5 and 500 characters.',
      );
    }
    return trimmed;
  }

  /// Parses an optional payout status filter.
  static PayoutStatus? optionalStatus(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'status must be a payout status.',
      );
    }
    try {
      return PayoutStatus.fromWire(raw.trim());
    } on FormatException {
      throw const ProfileValidationException(
        message: 'status must be a payout status.',
      );
    }
  }

  /// Admin list default status when omitted.
  static PayoutStatus defaultAdminStatus(Object? raw) {
    return optionalStatus(raw) ?? PayoutStatus.requested;
  }

  /// Parses an optional currency filter.
  static String? optionalCurrency(Object? raw) {
    return PaymentValidation.optionalCurrency(raw);
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
    return PaymentValidation.optionalObjectId(raw, field: field);
  }

  /// Parses finance `[from, to]` with a 30-day default and 366-day maximum.
  static ({DateTime from, DateTime to}) requireFinanceRange({
    required Object? fromRaw,
    required Object? toRaw,
    required DateTime now,
  }) {
    final utcNow = now.toUtc();
    DateTime from;
    DateTime to;
    try {
      if ((fromRaw == null || (fromRaw is String && fromRaw.trim().isEmpty)) &&
          (toRaw == null || (toRaw is String && toRaw.trim().isEmpty))) {
        to = utcNow;
        from = utcNow.subtract(const Duration(days: defaultFinanceRangeDays));
      } else {
        from = ApiDateTime.parseRequiredUtc(fromRaw, field: 'from');
        to = ApiDateTime.parseRequiredUtc(toRaw, field: 'to');
      }
    } on FormatException catch (error) {
      throw ProfileValidationException(message: error.message);
    }
    if (to.isBefore(from)) {
      throw const ProfileValidationException(
        message: 'to must be on or after from.',
      );
    }
    if (to.difference(from) > const Duration(days: maxFinanceRangeDays)) {
      throw const ProfileValidationException(
        message: 'Date range must be at most 366 days.',
      );
    }
    return (from: from, to: to);
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

import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_entry_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_validation.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Earnings query validation. Amounts are never taken from clients.
abstract final class EarningsValidation {
  /// Deterministic source-event key for the original service earning.
  static String serviceEarningSourceEventKey(ObjectId bookingId) {
    return 'earning:booking:${bookingId.oid}';
  }

  /// Deterministic source-event key for a provider refund event.
  static String refundEventSourceEventKey({
    required String provider,
    required String providerEventId,
  }) {
    return 'refund:$provider:$providerEventId';
  }

  /// Catch-up key when refunds already exist on the payment at earning time.
  static String refundCatchupSourceEventKey(ObjectId paymentId) {
    return 'refund:catchup:payment:${paymentId.oid}';
  }

  /// Parses an optional ledger entry-type filter.
  static EarningsEntryType? optionalEntryType(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'entry_type must be a ledger entry type.',
      );
    }
    try {
      return EarningsEntryType.fromWire(raw.trim());
    } on FormatException {
      throw const ProfileValidationException(
        message: 'entry_type must be a ledger entry type.',
      );
    }
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
}

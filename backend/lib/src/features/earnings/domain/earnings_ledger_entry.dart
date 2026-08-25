import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_entry_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Immutable append-only earnings ledger row.
///
/// Amounts are integer minor units. Commission is snapshotted at creation.
class EarningsLedgerEntry {
  /// Creates a ledger entry. [id] is the MongoDB `_id`.
  const EarningsLedgerEntry({
    required this.id,
    required this.cleanerUserId,
    required this.bookingId,
    required this.paymentId,
    required this.entryType,
    required this.grossAmountMinor,
    required this.commissionBps,
    required this.platformFeeMinor,
    required this.cleanerAmountMinor,
    required this.currencyCode,
    required this.sourceEventKey,
    required this.createdAt,
  });

  /// Parses a MongoDB `earnings_ledger` document.
  factory EarningsLedgerEntry.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => EarningsDocumentException(message);
    return EarningsLedgerEntry(
      id: DocumentFields.requireObjectId(document, '_id', error),
      cleanerUserId: DocumentFields.requireObjectId(
        document,
        'cleaner_user_id',
        error,
      ),
      bookingId: DocumentFields.requireObjectId(document, 'booking_id', error),
      paymentId: DocumentFields.requireObjectId(document, 'payment_id', error),
      entryType: EarningsEntryType.fromWire(
        DocumentFields.requireString(document, 'entry_type', error),
      ),
      grossAmountMinor: DocumentFields.requireInt(
        document,
        'gross_amount_minor',
        error,
      ),
      commissionBps: DocumentFields.requireInt(
        document,
        'commission_bps',
        error,
      ),
      platformFeeMinor: DocumentFields.requireInt(
        document,
        'platform_fee_minor',
        error,
      ),
      cleanerAmountMinor: DocumentFields.requireInt(
        document,
        'cleaner_amount_minor',
        error,
      ),
      currencyCode: DocumentFields.requireString(
        document,
        'currency_code',
        error,
      ),
      sourceEventKey: DocumentFields.requireString(
        document,
        'source_event_key',
        error,
      ),
      createdAt: DocumentFields.requireUtcDateTime(
        document,
        'created_at',
        error,
      ),
    );
  }

  /// MongoDB `_id`.
  final ObjectId id;

  /// Cleaner `users._id`.
  final ObjectId cleanerUserId;

  /// Related `bookings._id`.
  final ObjectId bookingId;

  /// Authoritative `payments._id`.
  final ObjectId paymentId;

  /// Ledger entry type.
  final EarningsEntryType entryType;

  /// Gross amount in minor units. Negative for refund adjustments.
  final int grossAmountMinor;

  /// Snapshotted commission basis points from the original earning.
  final int commissionBps;

  /// Platform fee in minor units. Negative for refund adjustments.
  final int platformFeeMinor;

  /// Cleaner amount in minor units. Negative for refund adjustments.
  final int cleanerAmountMinor;

  /// ISO 4217 currency copied from the payment. Never converted.
  final String currencyCode;

  /// Deterministic uniqueness key. Not exposed in cleaner DTOs.
  final String sourceEventKey;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// MongoDB document representation.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'cleaner_user_id': cleanerUserId,
      'booking_id': bookingId,
      'payment_id': paymentId,
      'entry_type': entryType.wireValue,
      'gross_amount_minor': grossAmountMinor,
      'commission_bps': commissionBps,
      'platform_fee_minor': platformFeeMinor,
      'cleaner_amount_minor': cleanerAmountMinor,
      'currency_code': currencyCode,
      'source_event_key': sourceEventKey,
      'created_at': createdAt.toUtc(),
    };
  }

  /// Cleaner/admin-safe JSON. Omits [sourceEventKey].
  Map<String, Object?> toPublicJson() {
    return <String, Object?>{
      'id': id.oid,
      'booking_id': bookingId.oid,
      'payment_id': paymentId.oid,
      'entry_type': entryType.wireValue,
      'gross_amount_minor': grossAmountMinor,
      'commission_bps': commissionBps,
      'platform_fee_minor': platformFeeMinor,
      'cleaner_amount_minor': cleanerAmountMinor,
      'currency_code': currencyCode,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() =>
      'EarningsLedgerEntry(id: ${id.oid}, type: ${entryType.wireValue})';
}

/// One keyset page of ledger entries.
class EarningsLedgerPage {
  /// Creates a page with an optional descending `_id` cursor.
  const EarningsLedgerPage({required this.items, required this.nextCursor});

  /// Page items.
  final List<EarningsLedgerEntry> items;

  /// Hex `_id` cursor for the next page, or `null`.
  final String? nextCursor;
}

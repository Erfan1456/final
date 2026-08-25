import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Authoritative payment attempt. Quote amount/currency come from the booking.
///
/// Does not store card data, secrets, tokens, or raw provider payloads.
class Payment {
  /// Creates a payment attempt. [id] is the MongoDB `_id`.
  const Payment({
    required this.id,
    required this.bookingId,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.provider,
    required this.status,
    required this.amountMinor,
    required this.currencyCode,
    required this.attemptNumber,
    required this.clientIdempotencyKey,
    required this.requestFingerprint,
    required this.paymentActive,
    required this.settlementRecorded,
    required this.refundedAmountMinor,
    required this.createdAt,
    required this.updatedAt,
    this.providerPaymentId,
    this.providerReference,
    this.failureCode,
    this.failureMessage,
    this.authorizedAt,
    this.paidAt,
    this.failedAt,
    this.cancelledAt,
    this.refundedAt,
  });

  /// Parses a MongoDB `payments` document.
  factory Payment.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => PaymentDocumentException(message);
    return Payment(
      id: DocumentFields.requireObjectId(document, '_id', error),
      bookingId: DocumentFields.requireObjectId(document, 'booking_id', error),
      customerUserId: DocumentFields.requireObjectId(
        document,
        'customer_user_id',
        error,
      ),
      cleanerUserId: DocumentFields.requireObjectId(
        document,
        'cleaner_user_id',
        error,
      ),
      provider: PaymentProviderType.fromWire(
        DocumentFields.requireString(document, 'provider', error),
      ),
      status: PaymentStatus.fromWire(
        DocumentFields.requireString(document, 'status', error),
      ),
      amountMinor: DocumentFields.requireInt(document, 'amount_minor', error),
      currencyCode: DocumentFields.requireString(
        document,
        'currency_code',
        error,
      ),
      providerPaymentId: DocumentFields.optionalString(
        document,
        'provider_payment_id',
        error,
      ),
      providerReference: DocumentFields.optionalString(
        document,
        'provider_reference',
        error,
      ),
      attemptNumber: DocumentFields.requireInt(
        document,
        'attempt_number',
        error,
      ),
      clientIdempotencyKey: DocumentFields.requireString(
        document,
        'client_idempotency_key',
        error,
      ),
      requestFingerprint: DocumentFields.requireString(
        document,
        'request_fingerprint',
        error,
      ),
      paymentActive: DocumentFields.requireBool(
        document,
        'payment_active',
        error,
      ),
      settlementRecorded: DocumentFields.requireBool(
        document,
        'settlement_recorded',
        error,
      ),
      failureCode: DocumentFields.optionalString(
        document,
        'failure_code',
        error,
      ),
      failureMessage: DocumentFields.optionalString(
        document,
        'failure_message',
        error,
      ),
      authorizedAt: DocumentFields.optionalUtcDateTime(
        document,
        'authorized_at',
        error,
      ),
      paidAt: DocumentFields.optionalUtcDateTime(document, 'paid_at', error),
      failedAt: DocumentFields.optionalUtcDateTime(
        document,
        'failed_at',
        error,
      ),
      cancelledAt: DocumentFields.optionalUtcDateTime(
        document,
        'cancelled_at',
        error,
      ),
      refundedAt: DocumentFields.optionalUtcDateTime(
        document,
        'refunded_at',
        error,
      ),
      refundedAmountMinor: DocumentFields.requireInt(
        document,
        'refunded_amount_minor',
        error,
      ),
      createdAt: DocumentFields.requireUtcDateTime(
        document,
        'created_at',
        error,
      ),
      updatedAt: DocumentFields.requireUtcDateTime(
        document,
        'updated_at',
        error,
      ),
    );
  }

  /// MongoDB `_id`.
  final ObjectId id;

  /// Related `bookings._id`.
  final ObjectId bookingId;

  /// Paying customer `users._id`.
  final ObjectId customerUserId;

  /// Assigned cleaner `users._id`.
  final ObjectId cleanerUserId;

  /// Provider that owns this attempt.
  final PaymentProviderType provider;

  /// Current attempt status.
  final PaymentStatus status;

  /// Quoted total copied from the booking. Never client-supplied.
  final int amountMinor;

  /// Currency copied from the booking. Never client-supplied.
  final String currencyCode;

  /// Opaque provider payment identifier.
  final String? providerPaymentId;

  /// Optional opaque provider reference.
  final String? providerReference;

  /// 1-based attempt number for this booking.
  final int attemptNumber;

  /// Customer-scoped idempotency key. Not exposed in public DTOs.
  final String clientIdempotencyKey;

  /// SHA-256 hex of start-payment intent. Not exposed in public DTOs.
  final String requestFingerprint;

  /// Explicit concurrency field matching [PaymentStatus.paymentActive].
  final bool paymentActive;

  /// Explicit uniqueness field matching [PaymentStatus.settlementRecorded].
  final bool settlementRecorded;

  /// Safe provider failure code, if any.
  final String? failureCode;

  /// Safe provider failure message, if any.
  final String? failureMessage;

  /// UTC authorization timestamp.
  final DateTime? authorizedAt;

  /// UTC paid timestamp.
  final DateTime? paidAt;

  /// UTC failed timestamp.
  final DateTime? failedAt;

  /// UTC cancelled timestamp.
  final DateTime? cancelledAt;

  /// UTC refund timestamp.
  final DateTime? refundedAt;

  /// Cumulative refunded amount in minor units.
  final int refundedAmountMinor;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last-update timestamp.
  final DateTime updatedAt;

  /// Remaining refundable amount in minor units.
  int get remainingRefundableMinor => amountMinor - refundedAmountMinor;

  /// MongoDB document representation. Does not copy secrets or card data.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'booking_id': bookingId,
      'customer_user_id': customerUserId,
      'cleaner_user_id': cleanerUserId,
      'provider': provider.wireValue,
      'status': status.wireValue,
      'amount_minor': amountMinor,
      'currency_code': currencyCode,
      'provider_payment_id': providerPaymentId,
      'provider_reference': providerReference,
      'attempt_number': attemptNumber,
      'client_idempotency_key': clientIdempotencyKey,
      'request_fingerprint': requestFingerprint,
      'payment_active': paymentActive,
      'settlement_recorded': settlementRecorded,
      'failure_code': failureCode,
      'failure_message': failureMessage,
      'authorized_at': authorizedAt?.toUtc(),
      'paid_at': paidAt?.toUtc(),
      'failed_at': failedAt?.toUtc(),
      'cancelled_at': cancelledAt?.toUtc(),
      'refunded_at': refundedAt?.toUtc(),
      'refunded_amount_minor': refundedAmountMinor,
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  /// Customer/admin-safe JSON. Omits idempotency, fingerprint, and secrets.
  Map<String, Object?> toPublicJson({
    Map<String, Object?>? sandboxSession,
  }) {
    return <String, Object?>{
      'id': id.oid,
      'booking_id': bookingId.oid,
      'provider': provider.wireValue,
      'status': status.wireValue,
      'amount_minor': amountMinor,
      'currency_code': currencyCode,
      'attempt_number': attemptNumber,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'paid_at': paidAt?.toUtc().toIso8601String(),
      'failed_at': failedAt?.toUtc().toIso8601String(),
      'cancelled_at': cancelledAt?.toUtc().toIso8601String(),
      'refunded_at': refundedAt?.toUtc().toIso8601String(),
      'refunded_amount_minor': refundedAmountMinor,
      if (sandboxSession != null) 'sandbox_session': sandboxSession,
    };
  }

  /// Admin-safe JSON with party identifiers and failure metadata.
  Map<String, Object?> toAdminJson({
    String? bookingStatus,
    String? serviceName,
  }) {
    return <String, Object?>{
      ...toPublicJson(),
      'customer_user_id': customerUserId.oid,
      'cleaner_user_id': cleanerUserId.oid,
      'provider_payment_id': providerPaymentId,
      'provider_reference': providerReference,
      'failure_code': failureCode,
      'failure_message': failureMessage,
      'authorized_at': authorizedAt?.toUtc().toIso8601String(),
      if (bookingStatus != null) 'booking_status': bookingStatus,
      if (serviceName != null) 'service_snapshot_name': serviceName,
    };
  }

  @override
  String toString() => 'Payment(id: ${id.oid}, status: ${status.wireValue})';
}

/// One keyset page of payments.
class PaymentPage {
  /// Creates a page with an optional descending `_id` cursor.
  const PaymentPage({required this.items, required this.nextCursor});

  /// Page items.
  final List<Payment> items;

  /// Hex `_id` cursor for the next page, or `null`.
  final String? nextCursor;
}

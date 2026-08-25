import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Cleaner payout request. Does not store bank, card, or wallet credentials.
class PayoutRequest {
  /// Creates a payout request. [id] is the MongoDB `_id`.
  const PayoutRequest({
    required this.id,
    required this.cleanerUserId,
    required this.amountMinor,
    required this.currencyCode,
    required this.status,
    required this.attemptNumber,
    required this.clientIdempotencyKey,
    required this.requestFingerprint,
    required this.payoutActive,
    required this.requestedAt,
    required this.createdAt,
    required this.updatedAt,
    this.provider,
    this.providerPayoutId,
    this.processingAt,
    this.paidAt,
    this.failedAt,
    this.cancelledAt,
    this.rejectedAt,
    this.failureCode,
    this.failureMessage,
    this.rejectionReason,
    this.processedBy,
  });

  /// Parses a MongoDB `payout_requests` document.
  factory PayoutRequest.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => PayoutDocumentException(message);
    return PayoutRequest(
      id: DocumentFields.requireObjectId(document, '_id', error),
      cleanerUserId: DocumentFields.requireObjectId(
        document,
        'cleaner_user_id',
        error,
      ),
      amountMinor: DocumentFields.requireInt(document, 'amount_minor', error),
      currencyCode: DocumentFields.requireString(
        document,
        'currency_code',
        error,
      ),
      status: PayoutStatus.fromWire(
        DocumentFields.requireString(document, 'status', error),
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
      payoutActive: DocumentFields.requireBool(
        document,
        'payout_active',
        error,
      ),
      provider: DocumentFields.optionalString(document, 'provider', error),
      providerPayoutId: DocumentFields.optionalString(
        document,
        'provider_payout_id',
        error,
      ),
      requestedAt: DocumentFields.requireUtcDateTime(
        document,
        'requested_at',
        error,
      ),
      processingAt: DocumentFields.optionalUtcDateTime(
        document,
        'processing_at',
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
      rejectedAt: DocumentFields.optionalUtcDateTime(
        document,
        'rejected_at',
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
      rejectionReason: DocumentFields.optionalString(
        document,
        'rejection_reason',
        error,
      ),
      processedBy: DocumentFields.optionalObjectId(
        document,
        'processed_by',
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

  /// Requesting cleaner `users._id`.
  final ObjectId cleanerUserId;

  /// Requested amount in integer minor units.
  final int amountMinor;

  /// ISO 4217 currency. Never converted.
  final String currencyCode;

  /// Current request status.
  final PayoutStatus status;

  /// 1-based attempt number for this cleaner (all currencies).
  final int attemptNumber;

  /// Cleaner-scoped idempotency key. Not exposed in public DTOs.
  final String clientIdempotencyKey;

  /// SHA-256 hex of payout intent. Not exposed in public DTOs.
  final String requestFingerprint;

  /// Explicit concurrency field matching [PayoutStatus.payoutActive].
  final bool payoutActive;

  /// Provider wire value when processing has started.
  final String? provider;

  /// Opaque provider payout identifier.
  final String? providerPayoutId;

  /// UTC request timestamp.
  final DateTime requestedAt;

  /// UTC processing timestamp.
  final DateTime? processingAt;

  /// UTC paid timestamp.
  final DateTime? paidAt;

  /// UTC failed timestamp.
  final DateTime? failedAt;

  /// UTC cancelled timestamp.
  final DateTime? cancelledAt;

  /// UTC rejected timestamp.
  final DateTime? rejectedAt;

  /// Safe provider failure code.
  final String? failureCode;

  /// Safe provider failure message.
  final String? failureMessage;

  /// Administrator rejection reason.
  final String? rejectionReason;

  /// Administrator who processed or rejected the request.
  final ObjectId? processedBy;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last-update timestamp.
  final DateTime updatedAt;

  /// MongoDB document representation. Does not copy secrets or destinations.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'cleaner_user_id': cleanerUserId,
      'amount_minor': amountMinor,
      'currency_code': currencyCode,
      'status': status.wireValue,
      'attempt_number': attemptNumber,
      'client_idempotency_key': clientIdempotencyKey,
      'request_fingerprint': requestFingerprint,
      'payout_active': payoutActive,
      'provider': provider,
      'provider_payout_id': providerPayoutId,
      'requested_at': requestedAt.toUtc(),
      'processing_at': processingAt?.toUtc(),
      'paid_at': paidAt?.toUtc(),
      'failed_at': failedAt?.toUtc(),
      'cancelled_at': cancelledAt?.toUtc(),
      'rejected_at': rejectedAt?.toUtc(),
      'failure_code': failureCode,
      'failure_message': failureMessage,
      'rejection_reason': rejectionReason,
      'processed_by': processedBy,
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  /// Cleaner-safe JSON. Omits admin ids, idempotency, and fingerprints.
  Map<String, Object?> toCleanerJson() {
    return <String, Object?>{
      'id': id.oid,
      'amount_minor': amountMinor,
      'currency_code': currencyCode,
      'status': status.wireValue,
      'attempt_number': attemptNumber,
      'requested_at': requestedAt.toUtc().toIso8601String(),
      'processing_at': processingAt?.toUtc().toIso8601String(),
      'paid_at': paidAt?.toUtc().toIso8601String(),
      'failed_at': failedAt?.toUtc().toIso8601String(),
      'cancelled_at': cancelledAt?.toUtc().toIso8601String(),
      'rejected_at': rejectedAt?.toUtc().toIso8601String(),
      'failure_code': failureCode,
      'failure_message': failureMessage,
      'rejection_reason': rejectionReason,
    };
  }

  /// Admin-safe JSON. Omits idempotency key, fingerprint, and secrets.
  Map<String, Object?> toAdminJson({
    String? cleanerDisplayName,
    bool? simulationAvailable,
  }) {
    return <String, Object?>{
      ...toCleanerJson(),
      'cleaner_user_id': cleanerUserId.oid,
      if (cleanerDisplayName != null)
        'cleaner_display_name': cleanerDisplayName,
      'provider': provider,
      'provider_payout_id': providerPayoutId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      if (simulationAvailable != null)
        'simulation_available': simulationAvailable,
    };
  }

  @override
  String toString() =>
      'PayoutRequest(id: ${id.oid}, status: ${status.wireValue})';
}

/// One keyset page of payout requests.
class PayoutPage {
  /// Creates a page with an optional descending `_id` cursor.
  const PayoutPage({required this.items, required this.nextCursor});

  /// Page items.
  final List<PayoutRequest> items;

  /// Hex `_id` cursor for the next page, or `null`.
  final String? nextCursor;
}

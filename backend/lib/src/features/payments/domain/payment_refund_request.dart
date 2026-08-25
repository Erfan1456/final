import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/refund_request_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Idempotent refund command issued by an authenticated actor.
class PaymentRefundRequest {
  /// Creates a refund request.
  const PaymentRefundRequest({
    required this.id,
    required this.paymentId,
    required this.adminUserId,
    required this.idempotencyKey,
    required this.amountMinor,
    required this.reason,
    required this.requestFingerprint,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parses a MongoDB `payment_refund_requests` document.
  factory PaymentRefundRequest.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => PaymentDocumentException(message);
    return PaymentRefundRequest(
      id: DocumentFields.requireObjectId(document, '_id', error),
      paymentId: DocumentFields.requireObjectId(document, 'payment_id', error),
      adminUserId: DocumentFields.requireObjectId(
        document,
        'admin_user_id',
        error,
      ),
      idempotencyKey: DocumentFields.requireString(
        document,
        'idempotency_key',
        error,
      ),
      amountMinor: DocumentFields.requireInt(document, 'amount_minor', error),
      reason: DocumentFields.requireString(document, 'reason', error),
      requestFingerprint: DocumentFields.requireString(
        document,
        'request_fingerprint',
        error,
      ),
      status: RefundRequestStatus.fromWire(
        DocumentFields.requireString(document, 'status', error),
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

  /// Target `payments._id`.
  final ObjectId paymentId;

  /// Requesting authenticated user. Admin refunds use the admin user id.
  final ObjectId adminUserId;

  /// Actor-scoped idempotency key. Not exposed in public DTOs.
  final String idempotencyKey;

  /// Refund amount in minor units for this request.
  final int amountMinor;

  /// Trimmed refund reason.
  final String reason;

  /// SHA-256 hex of refund intent. Not exposed in public DTOs.
  final String requestFingerprint;

  /// Command status. Payment refund state is driven by webhook.
  final RefundRequestStatus status;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last-update timestamp.
  final DateTime updatedAt;

  /// MongoDB document representation.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'payment_id': paymentId,
      'admin_user_id': adminUserId,
      'idempotency_key': idempotencyKey,
      'amount_minor': amountMinor,
      'reason': reason,
      'request_fingerprint': requestFingerprint,
      'status': status.wireValue,
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  @override
  String toString() =>
      'PaymentRefundRequest(id: ${id.oid}, status: ${status.wireValue})';
}

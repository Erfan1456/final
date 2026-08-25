import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_processing_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Idempotent record of a provider webhook event.
///
/// Stores a payload hash and identifiers only. Does not persist signatures,
/// secrets, or the full raw payload.
class PaymentWebhookEvent {
  /// Creates a webhook-event record.
  const PaymentWebhookEvent({
    required this.id,
    required this.provider,
    required this.providerEventId,
    required this.eventType,
    required this.providerPaymentId,
    required this.payloadSha256,
    required this.processingStatus,
    required this.createdAt,
    this.processedAt,
  });

  /// Parses a MongoDB `payment_webhook_events` document.
  factory PaymentWebhookEvent.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => PaymentDocumentException(message);
    return PaymentWebhookEvent(
      id: DocumentFields.requireObjectId(document, '_id', error),
      provider: PaymentProviderType.fromWire(
        DocumentFields.requireString(document, 'provider', error),
      ),
      providerEventId: DocumentFields.requireString(
        document,
        'provider_event_id',
        error,
      ),
      eventType: DocumentFields.requireString(document, 'event_type', error),
      providerPaymentId: DocumentFields.requireString(
        document,
        'provider_payment_id',
        error,
      ),
      payloadSha256: DocumentFields.requireString(
        document,
        'payload_sha256',
        error,
      ),
      processingStatus: PaymentWebhookProcessingStatus.fromWire(
        DocumentFields.requireString(document, 'processing_status', error),
      ),
      processedAt: DocumentFields.optionalUtcDateTime(
        document,
        'processed_at',
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

  /// Provider that emitted the event.
  final PaymentProviderType provider;

  /// Provider-unique event identifier.
  final String providerEventId;

  /// Provider event type wire value.
  final String eventType;

  /// Provider payment identifier referenced by the event.
  final String providerPaymentId;

  /// SHA-256 hex of the exact raw request body.
  final String payloadSha256;

  /// Processing lifecycle status.
  final PaymentWebhookProcessingStatus processingStatus;

  /// UTC processed timestamp when applicable.
  final DateTime? processedAt;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// MongoDB document representation.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'provider': provider.wireValue,
      'provider_event_id': providerEventId,
      'event_type': eventType,
      'provider_payment_id': providerPaymentId,
      'payload_sha256': payloadSha256,
      'processing_status': processingStatus.wireValue,
      'processed_at': processedAt?.toUtc(),
      'created_at': createdAt.toUtc(),
    };
  }

  /// Admin-safe event summary. Omits payload hash, signatures, and secrets.
  Map<String, Object?> toAdminJson() {
    return <String, Object?>{
      'provider_event_id': providerEventId,
      'event_type': eventType,
      'processing_status': processingStatus.wireValue,
      'processed_at': processedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() =>
      'PaymentWebhookEvent(id: ${id.oid}, '
      'status: ${processingStatus.wireValue})';
}

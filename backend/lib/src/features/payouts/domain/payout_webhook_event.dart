import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_processing_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Idempotent record of a payout provider webhook event.
///
/// Stores a payload hash and identifiers only. Does not persist signatures,
/// secrets, or the full raw payload.
class PayoutProviderEvent {
  /// Creates a webhook-event record.
  const PayoutProviderEvent({
    required this.id,
    required this.provider,
    required this.providerEventId,
    required this.eventType,
    required this.providerPayoutId,
    required this.payloadSha256,
    required this.processingStatus,
    required this.createdAt,
    this.processedAt,
  });

  /// Parses a MongoDB `payout_provider_events` document.
  factory PayoutProviderEvent.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => PayoutDocumentException(message);
    return PayoutProviderEvent(
      id: DocumentFields.requireObjectId(document, '_id', error),
      provider: PayoutProviderType.fromWire(
        DocumentFields.requireString(document, 'provider', error),
      ),
      providerEventId: DocumentFields.requireString(
        document,
        'provider_event_id',
        error,
      ),
      eventType: DocumentFields.requireString(document, 'event_type', error),
      providerPayoutId: DocumentFields.requireString(
        document,
        'provider_payout_id',
        error,
      ),
      payloadSha256: DocumentFields.requireString(
        document,
        'payload_sha256',
        error,
      ),
      processingStatus: PayoutWebhookProcessingStatus.fromWire(
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
  final PayoutProviderType provider;

  /// Provider-unique event identifier.
  final String providerEventId;

  /// Provider event type wire value.
  final String eventType;

  /// Provider payout identifier referenced by the event.
  final String providerPayoutId;

  /// SHA-256 hex of the exact raw request body.
  final String payloadSha256;

  /// Processing lifecycle status.
  final PayoutWebhookProcessingStatus processingStatus;

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
      'provider_payout_id': providerPayoutId,
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
      'PayoutProviderEvent(id: ${id.oid}, '
      'status: ${processingStatus.wireValue})';
}

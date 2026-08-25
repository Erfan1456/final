// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistent in-app notification. Never stores secrets or full addresses.
class AppNotification {
  /// Creates a notification.
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.dedupeKey,
    required this.createdAt,
    this.resourceType,
    this.resourceId,
    this.readAt,
  });

  /// Parses a MongoDB `notifications` document.
  factory AppNotification.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => NotificationDocumentException(message);
    return AppNotification(
      id: DocumentFields.requireObjectId(document, '_id', error),
      userId: DocumentFields.requireObjectId(document, 'user_id', error),
      type: NotificationType.fromWire(
        DocumentFields.requireString(document, 'type', error),
      ),
      title: DocumentFields.requireString(document, 'title', error),
      body: DocumentFields.requireString(document, 'body', error),
      resourceType: DocumentFields.optionalString(
        document,
        'resource_type',
        error,
      ),
      resourceId: DocumentFields.optionalObjectId(
        document,
        'resource_id',
        error,
      ),
      dedupeKey: DocumentFields.requireString(document, 'dedupe_key', error),
      readAt: DocumentFields.optionalUtcDateTime(document, 'read_at', error),
      createdAt: DocumentFields.requireUtcDateTime(
        document,
        'created_at',
        error,
      ),
    );
  }

  final ObjectId id;
  final ObjectId userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? resourceType;
  final ObjectId? resourceId;
  final String dedupeKey;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'user_id': userId,
      'type': type.wireValue,
      'title': title,
      'body': body,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'dedupe_key': dedupeKey,
      'read_at': readAt?.toUtc(),
      'created_at': createdAt.toUtc(),
    };
  }

  /// Safe JSON. Omits dedupe_key.
  Map<String, Object?> toPublicJson() {
    return <String, Object?>{
      'id': id.oid,
      'type': type.wireValue,
      'title': title,
      'body': body,
      'resource_type': resourceType,
      'resource_id': resourceId?.oid,
      'read_at': readAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}

import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Open future bookable window for one cleaner and one service.
class AvailabilitySlot {
  /// Creates a slot. [id] is the MongoDB `_id`.
  const AvailabilitySlot({
    required this.id,
    required this.cleanerUserId,
    required this.serviceId,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parses a MongoDB `availability_slots` document.
  factory AvailabilitySlot.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => AvailabilityDocumentException(message);
    return AvailabilitySlot(
      id: DocumentFields.requireObjectId(document, '_id', error),
      cleanerUserId: DocumentFields.requireObjectId(
        document,
        'cleaner_user_id',
        error,
      ),
      serviceId: DocumentFields.requireObjectId(document, 'service_id', error),
      startAt: DocumentFields.requireUtcDateTime(document, 'start_at', error),
      endAt: DocumentFields.requireUtcDateTime(document, 'end_at', error),
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

  /// Owning cleaner `users._id`. Never taken from an HTTP body.
  final ObjectId cleanerUserId;

  /// Platform `services._id`.
  final ObjectId serviceId;

  /// Inclusive window start, stored UTC.
  final DateTime startAt;

  /// Exclusive-adjacent window end, stored UTC.
  final DateTime endAt;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last-update timestamp.
  final DateTime updatedAt;

  /// MongoDB document representation.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'cleaner_user_id': cleanerUserId,
      'service_id': serviceId,
      'start_at': startAt.toUtc(),
      'end_at': endAt.toUtc(),
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  /// Safe JSON for cleaner management and customer discovery.
  Map<String, Object?> toPublicJson() {
    return <String, Object?>{
      'id': id.oid,
      'service_id': serviceId.oid,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() =>
      'AvailabilitySlot(id: ${id.oid}, cleaner: ${cleanerUserId.oid})';
}

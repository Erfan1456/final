import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// One embedded status-history row. Not a separate collection.
class BookingStatusHistoryEntry {
  /// Creates a history entry.
  const BookingStatusHistoryEntry({
    required this.toStatus,
    required this.actorUserId,
    required this.actorRole,
    required this.createdAt,
    this.fromStatus,
    this.reason,
  });

  /// Parses an embedded `status_history` element.
  factory BookingStatusHistoryEntry.fromDocument(
    Map<String, dynamic> document,
  ) {
    Exception error(String message) => BookingDocumentException(message);
    final fromRaw = DocumentFields.optionalString(
      document,
      'from_status',
      error,
    );
    return BookingStatusHistoryEntry(
      fromStatus: fromRaw == null ? null : BookingStatus.fromWire(fromRaw),
      toStatus: BookingStatus.fromWire(
        DocumentFields.requireString(document, 'to_status', error),
      ),
      actorUserId: DocumentFields.requireObjectId(
        document,
        'actor_user_id',
        error,
      ),
      actorRole: UserRole.fromWire(
        DocumentFields.requireString(document, 'actor_role', error),
      ),
      reason: DocumentFields.optionalString(document, 'reason', error),
      createdAt: DocumentFields.requireUtcDateTime(
        document,
        'created_at',
        error,
      ),
    );
  }

  /// Previous status, or `null` for creation.
  final BookingStatus? fromStatus;

  /// Status after this transition.
  final BookingStatus toStatus;

  /// Actor `users._id`.
  final ObjectId actorUserId;

  /// Actor persisted role.
  final UserRole actorRole;

  /// Optional reason supplied by the actor.
  final String? reason;

  /// UTC timestamp of the transition.
  final DateTime createdAt;

  /// BSON nested document.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      'from_status': fromStatus?.wireValue,
      'to_status': toStatus.wireValue,
      'actor_user_id': actorUserId,
      'actor_role': actorRole.wireValue,
      'reason': reason,
      'created_at': createdAt.toUtc(),
    };
  }

  /// Public JSON. Does not include security or session fields.
  Map<String, Object?> toPublicJson() {
    return <String, Object?>{
      'from_status': fromStatus?.wireValue,
      'to_status': toStatus.wireValue,
      'actor_user_id': actorUserId.oid,
      'actor_role': actorRole.wireValue,
      'reason': reason,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}

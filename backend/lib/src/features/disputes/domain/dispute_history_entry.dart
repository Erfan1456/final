// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// One embedded dispute lifecycle row. Not a separate collection.
class DisputeHistoryEntry {
  /// Creates a history entry.
  const DisputeHistoryEntry({
    required this.toStatus,
    required this.actorUserId,
    required this.actorRole,
    required this.createdAt,
    this.fromStatus,
    this.note,
  });

  /// Parses an embedded `history` element.
  factory DisputeHistoryEntry.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => DisputeDocumentException(message);
    final fromRaw = DocumentFields.optionalString(
      document,
      'from_status',
      error,
    );
    return DisputeHistoryEntry(
      fromStatus: fromRaw == null ? null : DisputeStatus.fromWire(fromRaw),
      toStatus: DisputeStatus.fromWire(
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
      note: DocumentFields.optionalString(document, 'note', error),
      createdAt: DocumentFields.requireUtcDateTime(
        document,
        'created_at',
        error,
      ),
    );
  }

  /// Previous status, or `null` for creation.
  final DisputeStatus? fromStatus;

  /// Status after this transition.
  final DisputeStatus toStatus;

  /// Actor `users._id`.
  final ObjectId actorUserId;

  /// Actor persisted role.
  final UserRole actorRole;

  /// Optional operational note.
  final String? note;

  /// UTC timestamp of the transition.
  final DateTime createdAt;

  /// BSON nested document.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      'from_status': fromStatus?.wireValue,
      'to_status': toStatus.wireValue,
      'actor_user_id': actorUserId,
      'actor_role': actorRole.wireValue,
      'note': note,
      'created_at': createdAt.toUtc(),
    };
  }

  /// Public JSON. Does not include contact or security fields.
  Map<String, Object?> toPublicJson() {
    return <String, Object?>{
      'from_status': fromStatus?.wireValue,
      'to_status': toStatus.wireValue,
      'actor_user_id': actorUserId.oid,
      'actor_role': actorRole.wireValue,
      'note': note,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}

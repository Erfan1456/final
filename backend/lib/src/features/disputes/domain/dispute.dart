// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_category.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_history_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// One booking-scoped operational dispute.
class Dispute {
  /// Creates a dispute. [id] is the MongoDB `_id`.
  const Dispute({
    required this.id,
    required this.bookingId,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.openedByUserId,
    required this.openedByRole,
    required this.category,
    required this.status,
    required this.subject,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
    this.resolution,
    this.resolvedBy,
    this.resolvedAt,
  });

  /// Parses a MongoDB `disputes` document.
  factory Dispute.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => DisputeDocumentException(message);
    final historyRaw = DocumentFields.requireList(document, 'history', error);
    return Dispute(
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
      openedByUserId: DocumentFields.requireObjectId(
        document,
        'opened_by_user_id',
        error,
      ),
      openedByRole: UserRole.fromWire(
        DocumentFields.requireString(document, 'opened_by_role', error),
      ),
      category: DisputeCategory.fromWire(
        DocumentFields.requireString(document, 'category', error),
      ),
      status: DisputeStatus.fromWire(
        DocumentFields.requireString(document, 'status', error),
      ),
      subject: DocumentFields.requireString(document, 'subject', error),
      description: DocumentFields.requireString(document, 'description', error),
      resolution: DocumentFields.optionalString(document, 'resolution', error),
      resolvedBy: DocumentFields.optionalObjectId(
        document,
        'resolved_by',
        error,
      ),
      resolvedAt: DocumentFields.optionalUtcDateTime(
        document,
        'resolved_at',
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
      history: [
        for (final item in historyRaw)
          if (item is Map)
            DisputeHistoryEntry.fromDocument(
              Map<String, dynamic>.from(item),
            ),
      ],
    );
  }

  final ObjectId id;
  final ObjectId bookingId;
  final ObjectId customerUserId;
  final ObjectId cleanerUserId;
  final ObjectId openedByUserId;
  final UserRole openedByRole;
  final DisputeCategory category;
  final DisputeStatus status;
  final String subject;
  final String description;
  final String? resolution;
  final ObjectId? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DisputeHistoryEntry> history;

  /// MongoDB document representation. No credentials or contact internals.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'booking_id': bookingId,
      'customer_user_id': customerUserId,
      'cleaner_user_id': cleanerUserId,
      'opened_by_user_id': openedByUserId,
      'opened_by_role': openedByRole.wireValue,
      'category': category.wireValue,
      'status': status.wireValue,
      'subject': subject,
      'description': description,
      'resolution': resolution,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toUtc(),
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
      'history': [for (final entry in history) entry.toDocument()],
    };
  }

  Map<String, Object?> _sharedJson() {
    return <String, Object?>{
      'id': id.oid,
      'booking_id': bookingId.oid,
      'category': category.wireValue,
      'status': status.wireValue,
      'subject': subject,
      'description': description,
      'resolution': resolution,
      'history': [for (final entry in history) entry.toPublicJson()],
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'resolved_at': resolvedAt?.toUtc().toIso8601String(),
    };
  }

  /// Customer-facing JSON. Cleaner identity is a public display name only.
  Map<String, Object?> toCustomerJson({required String cleanerPublicName}) {
    return <String, Object?>{
      ..._sharedJson(),
      'cleaner_public_name': cleanerPublicName,
    };
  }

  /// Cleaner-facing JSON. Customer identity is a display name only.
  Map<String, Object?> toCleanerJson({required String customerDisplayName}) {
    return <String, Object?>{
      ..._sharedJson(),
      'customer_display_name': customerDisplayName,
    };
  }

  /// Admin operational JSON. Includes participant ids, not credentials.
  Map<String, Object?> toAdminJson() {
    return <String, Object?>{
      ..._sharedJson(),
      'customer_user_id': customerUserId.oid,
      'cleaner_user_id': cleanerUserId.oid,
      'opened_by_user_id': openedByUserId.oid,
      'opened_by_role': openedByRole.wireValue,
      'resolved_by': resolvedBy?.oid,
    };
  }
}

/// One keyset page of disputes.
class DisputePage {
  /// Creates a page with an optional descending `_id` cursor.
  const DisputePage({required this.items, required this.nextCursor});

  final List<Dispute> items;
  final String? nextCursor;
}

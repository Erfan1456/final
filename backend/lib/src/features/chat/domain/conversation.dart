// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// One booking-scoped conversation. Booking remains participant authority.
class Conversation {
  /// Creates a conversation. [id] is the MongoDB `_id`.
  const Conversation({
    required this.id,
    required this.bookingId,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
  });

  /// Parses a MongoDB `conversations` document.
  factory Conversation.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => ConversationDocumentException(message);
    return Conversation(
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
      lastMessageAt: DocumentFields.optionalUtcDateTime(
        document,
        'last_message_at',
        error,
      ),
    );
  }

  /// MongoDB `_id`.
  final ObjectId id;

  /// Owning booking.
  final ObjectId bookingId;

  /// Booking customer.
  final ObjectId customerUserId;

  /// Booking cleaner.
  final ObjectId cleanerUserId;

  /// UTC creation time.
  final DateTime createdAt;

  /// UTC last-update time.
  final DateTime updatedAt;

  /// UTC last message time, or conversation creation when none yet.
  final DateTime? lastMessageAt;

  /// Whether [userId] is a conversation participant.
  bool isParticipant(ObjectId userId) {
    return userId == customerUserId || userId == cleanerUserId;
  }

  /// The other participant relative to [userId].
  ObjectId otherPartyId(ObjectId userId) {
    return userId == customerUserId ? cleanerUserId : customerUserId;
  }

  /// MongoDB document. No email/phone/address/token/payment fields.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'booking_id': bookingId,
      'customer_user_id': customerUserId,
      'cleaner_user_id': cleanerUserId,
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
      'last_message_at': lastMessageAt?.toUtc(),
    };
  }
}

/// Safe conversation summary for the authenticated participant.
class ConversationSummaryDto {
  /// Creates a list-item DTO.
  const ConversationSummaryDto({
    required this.id,
    required this.bookingId,
    required this.otherPartyDisplayName,
    required this.otherPartyRole,
    required this.bookingStatus,
    required this.unreadCount,
    this.lastMessagePreview,
    this.lastMessageAt,
  });

  final ObjectId id;
  final ObjectId bookingId;
  final String otherPartyDisplayName;
  final String otherPartyRole;
  final String bookingStatus;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

  /// Safe JSON. No email/phone/address.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id.oid,
      'booking_id': bookingId.oid,
      'other_party_display_name': otherPartyDisplayName,
      'other_party_role': otherPartyRole,
      'booking_status': bookingStatus,
      'last_message_preview': lastMessagePreview,
      'last_message_at': lastMessageAt?.toUtc().toIso8601String(),
      'unread_count': unreadCount,
    };
  }
}

/// Safe conversation detail.
class ConversationDetailDto {
  /// Creates a detail DTO.
  const ConversationDetailDto({
    required this.id,
    required this.bookingId,
    required this.otherPartyDisplayName,
    required this.otherPartyRole,
    required this.bookingStatus,
    required this.readOnly,
    required this.unreadCount,
    this.lastMessageAt,
  });

  final ObjectId id;
  final ObjectId bookingId;
  final String otherPartyDisplayName;
  final String otherPartyRole;
  final String bookingStatus;
  final bool readOnly;
  final int unreadCount;
  final DateTime? lastMessageAt;

  /// Safe JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id.oid,
      'booking_id': bookingId.oid,
      'other_party_display_name': otherPartyDisplayName,
      'other_party_role': otherPartyRole,
      'booking_status': bookingStatus,
      'read_only': readOnly,
      'unread_count': unreadCount,
      'last_message_at': lastMessageAt?.toUtc().toIso8601String(),
    };
  }
}

// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Immutable booking-chat message.
class ChatMessage {
  /// Creates a message. [id] is the MongoDB `_id`.
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.senderRole,
    required this.body,
    required this.clientIdempotencyKey,
    required this.createdAt,
  });

  /// Parses a MongoDB `messages` document.
  factory ChatMessage.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => MessageDocumentException(message);
    final role = UserRole.fromWire(
      DocumentFields.requireString(document, 'sender_role', error),
    );
    if (role != UserRole.customer && role != UserRole.cleaner) {
      throw const MessageDocumentException(
        'sender_role must be customer or cleaner.',
      );
    }
    return ChatMessage(
      id: DocumentFields.requireObjectId(document, '_id', error),
      conversationId: DocumentFields.requireObjectId(
        document,
        'conversation_id',
        error,
      ),
      senderUserId: DocumentFields.requireObjectId(
        document,
        'sender_user_id',
        error,
      ),
      senderRole: role,
      body: DocumentFields.requireString(document, 'body', error),
      clientIdempotencyKey: DocumentFields.requireString(
        document,
        'client_idempotency_key',
        error,
      ),
      createdAt: DocumentFields.requireUtcDateTime(
        document,
        'created_at',
        error,
      ),
    );
  }

  final ObjectId id;
  final ObjectId conversationId;
  final ObjectId senderUserId;
  final UserRole senderRole;
  final String body;
  final String clientIdempotencyKey;
  final DateTime createdAt;

  /// MongoDB document. No recipient contact or secret fields.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'conversation_id': conversationId,
      'sender_user_id': senderUserId,
      'sender_role': senderRole.wireValue,
      'body': body,
      'client_idempotency_key': clientIdempotencyKey,
      'created_at': createdAt.toUtc(),
    };
  }

  /// Safe API representation. Omits the idempotency key.
  Map<String, Object?> toPublicJson({required ObjectId currentUserId}) {
    return <String, Object?>{
      'id': id.oid,
      'conversation_id': conversationId.oid,
      'sender_user_id': senderUserId.oid,
      'sender_role': senderRole.wireValue,
      'body': body,
      'created_at': createdAt.toUtc().toIso8601String(),
      'is_mine': senderUserId == currentUserId,
    };
  }
}

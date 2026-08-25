// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Conversation participant read cursor. Admin is not a TASK 017 member.
class ConversationMember {
  /// Creates a member row.
  const ConversationMember({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.lastReadMessageId,
    this.lastReadAt,
  });

  /// Parses a MongoDB `conversation_members` document.
  factory ConversationMember.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) =>
        ConversationMemberDocumentException(message);
    final role = UserRole.fromWire(
      DocumentFields.requireString(document, 'role', error),
    );
    if (role != UserRole.customer && role != UserRole.cleaner) {
      throw const ConversationMemberDocumentException(
        'role must be customer or cleaner.',
      );
    }
    return ConversationMember(
      id: DocumentFields.requireObjectId(document, '_id', error),
      conversationId: DocumentFields.requireObjectId(
        document,
        'conversation_id',
        error,
      ),
      userId: DocumentFields.requireObjectId(document, 'user_id', error),
      role: role,
      lastReadMessageId: DocumentFields.optionalObjectId(
        document,
        'last_read_message_id',
        error,
      ),
      lastReadAt: DocumentFields.optionalUtcDateTime(
        document,
        'last_read_at',
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
    );
  }

  final ObjectId id;
  final ObjectId conversationId;
  final ObjectId userId;
  final UserRole role;
  final ObjectId? lastReadMessageId;
  final DateTime? lastReadAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// MongoDB document.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role.wireValue,
      'last_read_message_id': lastReadMessageId,
      'last_read_at': lastReadAt?.toUtc(),
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }
}

// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/conversation_member.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for conversation members.
abstract class ConversationMemberRepository {
  Future<ConversationMember> upsertMember({
    required ObjectId conversationId,
    required ObjectId userId,
    required UserRole role,
    required DateTime now,
  });

  Future<ConversationMember?> findMember({
    required ObjectId conversationId,
    required ObjectId userId,
  });

  Future<ConversationMember?> updateReadState({
    required ObjectId conversationId,
    required ObjectId userId,
    required ObjectId lastReadMessageId,
    required DateTime now,
  });
}

/// MongoDB implementation of [ConversationMemberRepository].
class MongoConversationMemberRepository
    implements ConversationMemberRepository {
  MongoConversationMemberRepository({
    required CollectionDocumentStore documents,
  }) : _documents = documents;

  factory MongoConversationMemberRepository.fromDb(Db db) {
    return MongoConversationMemberRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.conversationMembers),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<ConversationMember> upsertMember({
    required ObjectId conversationId,
    required ObjectId userId,
    required UserRole role,
    required DateTime now,
  }) async {
    final utc = now.toUtc();
    final id = ObjectId();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{
        'conversation_id': conversationId,
        'user_id': userId,
      },
      update: <String, dynamic>{
        r'$setOnInsert': <String, dynamic>{
          '_id': id,
          'conversation_id': conversationId,
          'user_id': userId,
          'role': role.wireValue,
          'created_at': utc,
        },
        r'$set': <String, dynamic>{'updated_at': utc},
      },
      upsert: true,
    );
    if (!result.isSuccess) {
      throw const ConversationMemberWriteException();
    }
    final stored = await findMember(
      conversationId: conversationId,
      userId: userId,
    );
    if (stored == null) {
      throw const ConversationMemberWriteException();
    }
    return stored;
  }

  @override
  Future<ConversationMember?> findMember({
    required ObjectId conversationId,
    required ObjectId userId,
  }) async {
    final document = await _documents.findOne(<String, dynamic>{
      'conversation_id': conversationId,
      'user_id': userId,
    });
    if (document == null) {
      return null;
    }
    return ConversationMember.fromDocument(document);
  }

  @override
  Future<ConversationMember?> updateReadState({
    required ObjectId conversationId,
    required ObjectId userId,
    required ObjectId lastReadMessageId,
    required DateTime now,
  }) async {
    final utc = now.toUtc();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{
        'conversation_id': conversationId,
        'user_id': userId,
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'last_read_message_id': lastReadMessageId,
          'last_read_at': utc,
          'updated_at': utc,
        },
      },
    );
    if (!result.matched) {
      return null;
    }
    if (!result.isSuccess) {
      throw const ConversationMemberWriteException();
    }
    return findMember(conversationId: conversationId, userId: userId);
  }
}

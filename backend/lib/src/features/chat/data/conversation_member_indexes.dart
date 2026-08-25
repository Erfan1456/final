// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique conversation + user member index.
const String conversationMembersConversationUserUniqueIndexName =
    'conversation_members_conversation_user_unique';

const String conversationMembersConversationIdField = 'conversation_id';
const String conversationMembersUserIdField = 'user_id';

typedef EnsureConversationMemberIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures `conversation_members` indexes.
///
/// `conversation_members_user_conversation` (user_id, conversation_id) is
/// omitted: conversation lists query `conversations` by participant user id,
/// and member reads always use `(conversation_id, user_id)` covered by the
/// unique index.
Future<void> ensureConversationMemberIndexes({
  required EnsureConversationMemberIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.conversationMembers,
    keys: const <String, dynamic>{
      conversationMembersConversationIdField: 1,
      conversationMembersUserIdField: 1,
    },
    unique: true,
    name: conversationMembersConversationUserUniqueIndexName,
  );
}

/// Ensures conversation-member indexes on [db].
Future<void> ensureConversationMemberIndexesOnDb(Db db) {
  return ensureConversationMemberIndexes(
    ensureIndex:
        ({
          required String collectionName,
          required Map<String, dynamic> keys,
          required bool unique,
          required String name,
        }) async {
          final collection = db.collection(collectionName);
          try {
            await collection.createIndex(
              keys: keys,
              unique: unique,
              name: name,
            );
          } catch (_) {
            final indexes = await collection.getIndexes();
            final exists = indexes.any((index) => index['name'] == name);
            if (!exists) {
              rethrow;
            }
          }
        },
  );
}

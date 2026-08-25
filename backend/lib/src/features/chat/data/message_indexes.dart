// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Conversation history keyset index.
const String messagesConversationIdDescIndexName =
    'messages_conversation_id_desc';

/// Unique sender idempotency index.
const String messagesSenderIdempotencyUniqueIndexName =
    'messages_sender_idempotency_unique';

const String messagesConversationIdField = 'conversation_id';
const String messagesSenderUserIdField = 'sender_user_id';
const String messagesClientIdempotencyKeyField = 'client_idempotency_key';

typedef EnsureMessageIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures `messages` indexes.
Future<void> ensureMessageIndexes({
  required EnsureMessageIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.messages,
    keys: const <String, dynamic>{messagesConversationIdField: 1, '_id': -1},
    unique: false,
    name: messagesConversationIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.messages,
    keys: const <String, dynamic>{
      messagesConversationIdField: 1,
      messagesSenderUserIdField: 1,
      messagesClientIdempotencyKeyField: 1,
    },
    unique: true,
    name: messagesSenderIdempotencyUniqueIndexName,
  );
}

/// Ensures message indexes on [db].
Future<void> ensureMessageIndexesOnDb(Db db) {
  return ensureMessageIndexes(
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

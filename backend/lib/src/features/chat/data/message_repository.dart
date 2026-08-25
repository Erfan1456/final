// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_message.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for immutable chat messages.
abstract class MessageRepository {
  Future<ChatMessage?> findBySenderIdempotency({
    required ObjectId conversationId,
    required ObjectId senderUserId,
    required String clientIdempotencyKey,
  });

  Future<ChatMessage> create(ChatMessage message);

  Future<List<ChatMessage>> latest({
    required ObjectId conversationId,
    required int limit,
  });

  Future<List<ChatMessage>> before({
    required ObjectId conversationId,
    required ObjectId beforeId,
    required int limit,
  });

  Future<List<ChatMessage>> after({
    required ObjectId conversationId,
    required ObjectId afterId,
    required int limit,
  });

  Future<ChatMessage?> findByIdInConversation({
    required ObjectId conversationId,
    required ObjectId messageId,
  });

  Future<int> countUnreadForMember({
    required ObjectId conversationId,
    required ObjectId currentUserId,
    ObjectId? lastReadMessageId,
  });

  Future<Map<ObjectId, ChatMessage>> latestForConversationIds(
    Iterable<ObjectId> conversationIds,
  );
}

/// MongoDB implementation of [MessageRepository].
class MongoMessageRepository implements MessageRepository {
  MongoMessageRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  factory MongoMessageRepository.fromDb(Db db) {
    return MongoMessageRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.messages),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<ChatMessage?> findBySenderIdempotency({
    required ObjectId conversationId,
    required ObjectId senderUserId,
    required String clientIdempotencyKey,
  }) {
    return _find(<String, dynamic>{
      'conversation_id': conversationId,
      'sender_user_id': senderUserId,
      'client_idempotency_key': clientIdempotencyKey,
    });
  }

  @override
  Future<ChatMessage> create(ChatMessage message) async {
    final result = await _documents.insertOne(message.toDocument());
    if (result.isDuplicateKey) {
      throw const MessageDuplicateKeyException();
    }
    if (!result.isSuccess) {
      throw const MessageWriteException();
    }
    return message;
  }

  @override
  Future<List<ChatMessage>> latest({
    required ObjectId conversationId,
    required int limit,
  }) {
    return _page(
      selector: <String, dynamic>{'conversation_id': conversationId},
      sort: const <String, int>{'_id': -1},
      limit: limit,
      chronological: true,
    );
  }

  @override
  Future<List<ChatMessage>> before({
    required ObjectId conversationId,
    required ObjectId beforeId,
    required int limit,
  }) {
    return _page(
      selector: <String, dynamic>{
        'conversation_id': conversationId,
        '_id': <String, dynamic>{r'$lt': beforeId},
      },
      sort: const <String, int>{'_id': -1},
      limit: limit,
      chronological: true,
    );
  }

  @override
  Future<List<ChatMessage>> after({
    required ObjectId conversationId,
    required ObjectId afterId,
    required int limit,
  }) {
    return _page(
      selector: <String, dynamic>{
        'conversation_id': conversationId,
        '_id': <String, dynamic>{r'$gt': afterId},
      },
      sort: const <String, int>{'_id': 1},
      limit: limit,
      chronological: false,
    );
  }

  @override
  Future<ChatMessage?> findByIdInConversation({
    required ObjectId conversationId,
    required ObjectId messageId,
  }) {
    return _find(<String, dynamic>{
      '_id': messageId,
      'conversation_id': conversationId,
    });
  }

  @override
  Future<int> countUnreadForMember({
    required ObjectId conversationId,
    required ObjectId currentUserId,
    ObjectId? lastReadMessageId,
  }) {
    final selector = <String, dynamic>{
      'conversation_id': conversationId,
      'sender_user_id': <String, dynamic>{r'$ne': currentUserId},
    };
    if (lastReadMessageId != null) {
      selector['_id'] = <String, dynamic>{r'$gt': lastReadMessageId};
    }
    return _documents.count(selector);
  }

  @override
  Future<Map<ObjectId, ChatMessage>> latestForConversationIds(
    Iterable<ObjectId> conversationIds,
  ) async {
    final result = <ObjectId, ChatMessage>{};
    for (final id in conversationIds) {
      final documents = await _documents.findMany(
        selector: <String, dynamic>{'conversation_id': id},
        sort: const <String, int>{'_id': -1},
        limit: 1,
      );
      if (documents.isNotEmpty) {
        result[id] = ChatMessage.fromDocument(documents.first);
      }
    }
    return result;
  }

  Future<List<ChatMessage>> _page({
    required Map<String, dynamic> selector,
    required Map<String, int> sort,
    required int limit,
    required bool chronological,
  }) async {
    final documents = await _documents.findMany(
      selector: selector,
      sort: sort,
      limit: limit,
    );
    final items = documents.map(ChatMessage.fromDocument).toList();
    if (chronological) {
      return items.reversed.toList();
    }
    return items;
  }

  Future<ChatMessage?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return ChatMessage.fromDocument(document);
  }
}

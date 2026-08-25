// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/conversation.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for booking conversations.
abstract class ConversationRepository {
  Future<Conversation?> findById(ObjectId id);

  Future<Conversation?> findByBookingId(ObjectId bookingId);

  Future<Conversation> createForBooking(Conversation conversation);

  Future<List<Conversation>> listForUser({
    required ObjectId userId,
    required UserRole role,
    required int limit,
  });

  Future<Conversation?> touchLastMessage({
    required ObjectId id,
    required DateTime lastMessageAt,
  });
}

/// MongoDB implementation of [ConversationRepository].
class MongoConversationRepository implements ConversationRepository {
  MongoConversationRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  factory MongoConversationRepository.fromDb(Db db) {
    return MongoConversationRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.conversations),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<Conversation?> findById(ObjectId id) {
    return _find(_idSelector(id));
  }

  Map<String, dynamic> _idSelector(ObjectId id) => <String, dynamic>{'_id': id};

  @override
  Future<Conversation?> findByBookingId(ObjectId bookingId) {
    return _find(<String, dynamic>{'booking_id': bookingId});
  }

  @override
  Future<Conversation> createForBooking(Conversation conversation) async {
    final result = await _documents.insertOne(conversation.toDocument());
    if (result.isDuplicateKey) {
      throw const ConversationDuplicateKeyException();
    }
    if (!result.isSuccess) {
      throw const ConversationWriteException();
    }
    return conversation;
  }

  @override
  Future<List<Conversation>> listForUser({
    required ObjectId userId,
    required UserRole role,
    required int limit,
  }) async {
    final field = role == UserRole.customer
        ? 'customer_user_id'
        : 'cleaner_user_id';
    final documents = await _documents.findMany(
      selector: <String, dynamic>{field: userId},
      sort: const <String, int>{'last_message_at': -1, '_id': -1},
      limit: limit,
    );
    return documents.map(Conversation.fromDocument).toList();
  }

  @override
  Future<Conversation?> touchLastMessage({
    required ObjectId id,
    required DateTime lastMessageAt,
  }) async {
    final utc = lastMessageAt.toUtc();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{'_id': id},
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'last_message_at': utc,
          'updated_at': utc,
        },
      },
    );
    if (!result.matched) {
      return null;
    }
    if (!result.isSuccess) {
      throw const ConversationWriteException();
    }
    return findById(id);
  }

  Future<Conversation?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return Conversation.fromDocument(document);
  }
}

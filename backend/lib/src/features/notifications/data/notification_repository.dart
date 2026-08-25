// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/app_notification.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// One page of notifications.
class NotificationPage {
  const NotificationPage({required this.items, required this.nextCursor});

  final List<AppNotification> items;
  final String? nextCursor;
}

/// Persistence contract for in-app notifications.
abstract class NotificationRepository {
  Future<AppNotification> create(AppNotification notification);

  Future<AppNotification?> findByUserDedupe({
    required ObjectId userId,
    required String dedupeKey,
  });

  Future<NotificationPage> listForUser({
    required ObjectId userId,
    required int limit,
    bool? unread,
    ObjectId? after,
  });

  Future<int> unreadCount(ObjectId userId);

  Future<AppNotification?> markReadOwned({
    required ObjectId id,
    required ObjectId userId,
    required DateTime now,
  });

  Future<int> markAllRead({
    required ObjectId userId,
    required DateTime now,
  });
}

/// MongoDB implementation of [NotificationRepository].
class MongoNotificationRepository implements NotificationRepository {
  MongoNotificationRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  factory MongoNotificationRepository.fromDb(Db db) {
    return MongoNotificationRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.notifications),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<AppNotification> create(AppNotification notification) async {
    final result = await _documents.insertOne(notification.toDocument());
    if (result.isDuplicateKey) {
      throw const NotificationDuplicateKeyException();
    }
    if (!result.isSuccess) {
      throw const NotificationWriteException();
    }
    return notification;
  }

  @override
  Future<AppNotification?> findByUserDedupe({
    required ObjectId userId,
    required String dedupeKey,
  }) {
    return _find(<String, dynamic>{
      'user_id': userId,
      'dedupe_key': dedupeKey,
    });
  }

  @override
  Future<NotificationPage> listForUser({
    required ObjectId userId,
    required int limit,
    bool? unread,
    ObjectId? after,
  }) async {
    final selector = <String, dynamic>{'user_id': userId};
    if (unread ?? false) {
      selector['read_at'] = null;
    }
    if (after != null) {
      selector['_id'] = <String, dynamic>{r'$lt': after};
    }
    final documents = await _documents.findMany(
      selector: selector,
      sort: const <String, int>{'_id': -1},
      limit: limit + 1,
    );
    final hasMore = documents.length > limit;
    final page = hasMore ? documents.sublist(0, limit) : documents;
    final items = page.map(AppNotification.fromDocument).toList();
    return NotificationPage(
      items: items,
      nextCursor: hasMore ? items.last.id.oid : null,
    );
  }

  @override
  Future<int> unreadCount(ObjectId userId) {
    return _documents.count(<String, dynamic>{
      'user_id': userId,
      'read_at': null,
    });
  }

  @override
  Future<AppNotification?> markReadOwned({
    required ObjectId id,
    required ObjectId userId,
    required DateTime now,
  }) async {
    final existing = await _find(<String, dynamic>{
      '_id': id,
      'user_id': userId,
    });
    if (existing == null) {
      return null;
    }
    if (existing.readAt != null) {
      return existing;
    }
    final result = await _documents.updateOne(
      selector: <String, dynamic>{
        '_id': id,
        'user_id': userId,
        'read_at': null,
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{'read_at': now.toUtc()},
      },
    );
    if (!result.matched) {
      return _find(<String, dynamic>{'_id': id, 'user_id': userId});
    }
    if (!result.isSuccess) {
      throw const NotificationWriteException();
    }
    return _find(<String, dynamic>{'_id': id, 'user_id': userId});
  }

  @override
  Future<int> markAllRead({
    required ObjectId userId,
    required DateTime now,
  }) async {
    final unread = await _documents.findMany(
      selector: <String, dynamic>{'user_id': userId, 'read_at': null},
    );
    var updated = 0;
    final utc = now.toUtc();
    for (final document in unread) {
      final id = document['_id'];
      if (id is! ObjectId) {
        continue;
      }
      final result = await _documents.updateOne(
        selector: <String, dynamic>{
          '_id': id,
          'user_id': userId,
          'read_at': null,
        },
        update: <String, dynamic>{
          r'$set': <String, dynamic>{'read_at': utc},
        },
      );
      if (result.isSuccess && result.matched) {
        updated += 1;
      }
    }
    return updated;
  }

  Future<AppNotification?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return AppNotification.fromDocument(document);
  }
}

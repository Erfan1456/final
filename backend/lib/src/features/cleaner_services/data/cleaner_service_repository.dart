import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_offering.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for cleaner service offerings.
abstract class CleanerServiceRepository {
  /// Finds the offering for [cleanerUserId] and [serviceId], if any.
  Future<CleanerServiceOffering?> findByCleanerAndService({
    required ObjectId cleanerUserId,
    required ObjectId serviceId,
  });

  /// Lists offerings owned by [cleanerUserId].
  Future<List<CleanerServiceOffering>> listForCleaner(ObjectId cleanerUserId);

  /// Upserts pricing and activation for the unique cleaner/service pair.
  Future<CleanerServiceOffering> upsertOffering({
    required ObjectId cleanerUserId,
    required ObjectId serviceId,
    required CleanerServiceWriteData data,
  });

  /// Sets `is_active` to false for the owned offering.
  Future<CleanerServiceOffering?> deactivateOffering({
    required ObjectId cleanerUserId,
    required ObjectId serviceId,
  });

  /// Returns the active offering for a cleaner and service, or `null`.
  Future<CleanerServiceOffering?> findActiveOffering({
    required ObjectId cleanerUserId,
    required ObjectId serviceId,
  });

  /// Discovery page of active offerings matching filters, `_id` ascending.
  Future<CleanerServiceDiscoveryPage> discoveryPage({
    required ObjectId serviceId,
    required int limit,
    String? currencyCode,
    int? maxRateMinor,
    ObjectId? after,
  });
}

/// MongoDB implementation of [CleanerServiceRepository].
class MongoCleanerServiceRepository implements CleanerServiceRepository {
  /// Creates a repository over [documents].
  MongoCleanerServiceRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  /// Creates a repository using the cleaner_services collection on [db].
  factory MongoCleanerServiceRepository.fromDb(Db db) {
    return MongoCleanerServiceRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.cleanerServices),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<CleanerServiceOffering?> findByCleanerAndService({
    required ObjectId cleanerUserId,
    required ObjectId serviceId,
  }) {
    return _find(<String, dynamic>{
      'cleaner_user_id': cleanerUserId,
      'service_id': serviceId,
    });
  }

  @override
  Future<List<CleanerServiceOffering>> listForCleaner(
    ObjectId cleanerUserId,
  ) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{'cleaner_user_id': cleanerUserId},
      sort: const <String, int>{'created_at': 1},
    );
    return documents.map(CleanerServiceOffering.fromDocument).toList();
  }

  @override
  Future<CleanerServiceOffering> upsertOffering({
    required ObjectId cleanerUserId,
    required ObjectId serviceId,
    required CleanerServiceWriteData data,
  }) async {
    final now = DateTime.now().toUtc();
    final id = ObjectId();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{
        'cleaner_user_id': cleanerUserId,
        'service_id': serviceId,
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'hourly_rate_minor': data.hourlyRateMinor,
          'currency_code': data.currencyCode,
          'is_active': data.isActive,
          'updated_at': now,
        },
        r'$setOnInsert': <String, dynamic>{
          '_id': id,
          'cleaner_user_id': cleanerUserId,
          'service_id': serviceId,
          'created_at': now,
        },
      },
      upsert: true,
    );
    if (!result.isSuccess && !result.upserted && !result.matched) {
      throw const CleanerServiceWriteException();
    }
    final stored = await findByCleanerAndService(
      cleanerUserId: cleanerUserId,
      serviceId: serviceId,
    );
    if (stored == null) {
      throw const CleanerServiceWriteException();
    }
    return stored;
  }

  @override
  Future<CleanerServiceOffering?> deactivateOffering({
    required ObjectId cleanerUserId,
    required ObjectId serviceId,
  }) async {
    final now = DateTime.now().toUtc();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{
        'cleaner_user_id': cleanerUserId,
        'service_id': serviceId,
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'is_active': false,
          'updated_at': now,
        },
      },
    );
    if (!result.matched) {
      return null;
    }
    if (!result.isSuccess) {
      throw const CleanerServiceWriteException();
    }
    return findByCleanerAndService(
      cleanerUserId: cleanerUserId,
      serviceId: serviceId,
    );
  }

  @override
  Future<CleanerServiceOffering?> findActiveOffering({
    required ObjectId cleanerUserId,
    required ObjectId serviceId,
  }) {
    return _find(<String, dynamic>{
      'cleaner_user_id': cleanerUserId,
      'service_id': serviceId,
      'is_active': true,
    });
  }

  @override
  Future<CleanerServiceDiscoveryPage> discoveryPage({
    required ObjectId serviceId,
    required int limit,
    String? currencyCode,
    int? maxRateMinor,
    ObjectId? after,
  }) async {
    final selector = <String, dynamic>{
      'service_id': serviceId,
      'is_active': true,
    };
    if (currencyCode != null) {
      selector['currency_code'] = currencyCode;
    }
    if (maxRateMinor != null) {
      selector['hourly_rate_minor'] = <String, dynamic>{r'$lte': maxRateMinor};
    }
    if (after != null) {
      selector['_id'] = <String, dynamic>{r'$gt': after};
    }
    final documents = await _documents.findMany(
      selector: selector,
      sort: const <String, int>{'_id': 1},
      limit: limit + 1,
    );
    final hasMore = documents.length > limit;
    final page = hasMore ? documents.sublist(0, limit) : documents;
    return CleanerServiceDiscoveryPage(
      items: page.map(CleanerServiceOffering.fromDocument).toList(),
      hasMore: hasMore,
    );
  }

  Future<CleanerServiceOffering?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return CleanerServiceOffering.fromDocument(document);
  }
}

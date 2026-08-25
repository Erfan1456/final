import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/marketplace_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for the platform service catalog.
///
/// Catalog mutation is not part of request application services.
abstract class ServiceRepository {
  /// Returns the service with [id], or `null`.
  Future<MarketplaceService?> findById(ObjectId id);

  /// Returns the service with [slug], or `null`.
  Future<MarketplaceService?> findBySlug(String slug);

  /// Lists active catalog services, slug ascending.
  Future<List<MarketplaceService>> listActive();
}

/// MongoDB implementation of [ServiceRepository].
class MongoServiceRepository implements ServiceRepository {
  /// Creates a repository over [documents].
  MongoServiceRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  /// Creates a repository using the services collection on [db].
  factory MongoServiceRepository.fromDb(Db db) {
    return MongoServiceRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.services),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<MarketplaceService?> findById(ObjectId id) {
    return _find(<String, dynamic>{'_id': id});
  }

  @override
  Future<MarketplaceService?> findBySlug(String slug) {
    return _find(<String, dynamic>{'slug': slug});
  }

  @override
  Future<List<MarketplaceService>> listActive() async {
    final documents = await _documents.findMany(
      selector: const <String, dynamic>{'active': true},
      sort: const <String, int>{'slug': 1},
    );
    return documents.map(MarketplaceService.fromDocument).toList();
  }

  Future<MarketplaceService?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return MarketplaceService.fromDocument(document);
  }
}

/// Catalog-tool-only writes. Not exposed to HTTP application services.
class ServiceCatalogStore {
  /// Creates a store over [documents].
  ServiceCatalogStore({required CollectionDocumentStore documents})
    : _documents = documents;

  /// Creates a store using the services collection on [db].
  factory ServiceCatalogStore.fromDb(Db db) {
    return ServiceCatalogStore(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.services),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  /// Inserts [service].
  Future<void> insert(MarketplaceService service) async {
    final result = await _documents.insertOne(service.toDocument());
    if (!result.isSuccess) {
      throw const ServiceWriteException();
    }
  }

  /// Replaces canonical public fields of [service] by slug.
  Future<void> updateCanonicalFields(MarketplaceService service) async {
    final result = await _documents.updateOne(
      selector: <String, dynamic>{'slug': service.slug},
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'name': service.name,
          'description': service.description,
          'billing_model': service.billingModel.wireValue,
          'active': service.active,
          'updated_at': service.updatedAt.toUtc(),
        },
      },
    );
    if (!result.isSuccess || !result.matched) {
      throw const ServiceWriteException();
    }
  }
}

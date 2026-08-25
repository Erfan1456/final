import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique slug index on `services.slug`.
const String servicesSlugUniqueIndexName = 'services_slug_unique';

/// Active-catalog listing index.
const String servicesActiveSlugIndexName = 'services_active_slug';

/// Slug field.
const String servicesSlugField = 'slug';

/// Active flag field.
const String servicesActiveField = 'active';

/// Function used to ensure a MongoDB index without coupling tests to Atlas.
typedef EnsureServiceIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures the approved `services` indexes.
Future<void> ensureServiceIndexes({
  required EnsureServiceIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.services,
    keys: const <String, dynamic>{servicesSlugField: 1},
    unique: true,
    name: servicesSlugUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.services,
    keys: const <String, dynamic>{
      servicesActiveField: 1,
      servicesSlugField: 1,
    },
    unique: false,
    name: servicesActiveSlugIndexName,
  );
}

/// Ensures approved service indexes on [db].
Future<void> ensureServiceIndexesOnDb(Db db) {
  return ensureServiceIndexes(ensureIndex: _ensureIndexOnDb(db));
}

EnsureServiceIndexFn _ensureIndexOnDb(Db db) {
  return ({
    required String collectionName,
    required Map<String, dynamic> keys,
    required bool unique,
    required String name,
  }) async {
    final collection = db.collection(collectionName);
    try {
      await collection.createIndex(keys: keys, unique: unique, name: name);
    } catch (_) {
      final indexes = await collection.getIndexes();
      final exists = indexes.any((index) => index['name'] == name);
      if (!exists) {
        rethrow;
      }
    }
  };
}

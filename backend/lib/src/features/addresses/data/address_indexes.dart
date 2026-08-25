import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Owner lookup index on `addresses.user_id`.
const String addressesUserIdIndexName = 'addresses_user_id';

/// Owner plus newest-first listing index.
const String addressesUserIdCreatedAtIndexName = 'addresses_user_id_created_at';

/// Owning user field.
const String addressesUserIdField = 'user_id';

/// Creation timestamp field.
const String addressesCreatedAtField = 'created_at';

/// Function used to ensure a MongoDB index without coupling tests to Atlas.
typedef EnsureAddressIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures the approved `addresses` indexes.
///
/// Does not run per HTTP request. Call from a controlled startup or tool.
Future<void> ensureAddressIndexes({
  required EnsureAddressIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.addresses,
    keys: const <String, dynamic>{addressesUserIdField: 1},
    unique: false,
    name: addressesUserIdIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.addresses,
    keys: const <String, dynamic>{
      addressesUserIdField: 1,
      addressesCreatedAtField: -1,
    },
    unique: false,
    name: addressesUserIdCreatedAtIndexName,
  );
}

/// Ensures approved address indexes on [db].
Future<void> ensureAddressIndexesOnDb(Db db) {
  return ensureAddressIndexes(
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

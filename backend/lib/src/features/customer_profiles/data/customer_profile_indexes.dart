import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique owner index on `customer_profiles.user_id`.
const String customerProfilesUserIdUniqueIndexName =
    'customer_profiles_user_id_unique';

/// Field indexed for one-profile-per-user lookup.
const String customerProfilesUserIdField = 'user_id';

/// Function used to ensure a MongoDB index without coupling tests to Atlas.
typedef EnsureCustomerProfileIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures the approved `customer_profiles.user_id` unique index.
///
/// Does not run per HTTP request. Call from a controlled startup or tool.
Future<void> ensureCustomerProfileIndexes({
  required EnsureCustomerProfileIndexFn ensureIndex,
}) {
  return ensureIndex(
    collectionName: CollectionNames.customerProfiles,
    keys: const <String, dynamic>{customerProfilesUserIdField: 1},
    unique: true,
    name: customerProfilesUserIdUniqueIndexName,
  );
}

/// Ensures approved customer-profile indexes on [db].
Future<void> ensureCustomerProfileIndexesOnDb(Db db) {
  return ensureCustomerProfileIndexes(
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

import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Stable name for the unique normalized-email index on `users`.
const String usersEmailNormalizedUniqueIndexName =
    'users_email_normalized_unique';

/// Field indexed for unique user email lookup.
const String usersEmailNormalizedField = 'email_normalized';

/// Stable name for the admin user listing compound index.
const String usersRoleStatusIdDescIndexName = 'users_role_status_id_desc';

/// Function used to ensure a MongoDB index without coupling tests to Atlas.
typedef EnsureIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures the approved `users.email_normalized` unique index.
///
/// Does not run per HTTP request. Call from a controlled startup or tool.
Future<void> ensureUserIndexes({required EnsureIndexFn ensureIndex}) async {
  await ensureIndex(
    collectionName: CollectionNames.users,
    keys: const <String, dynamic>{usersEmailNormalizedField: 1},
    unique: true,
    name: usersEmailNormalizedUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.users,
    keys: const <String, dynamic>{
      'role': 1,
      'account_status': 1,
      '_id': -1,
    },
    unique: false,
    name: usersRoleStatusIdDescIndexName,
  );
}

/// Ensures approved user indexes on [db].
Future<void> ensureUserIndexesOnDb(Db db) {
  return ensureUserIndexes(
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

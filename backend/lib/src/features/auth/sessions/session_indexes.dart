import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique current refresh-token hash index.
const String userSessionsRefreshTokenHashUniqueIndexName =
    'user_sessions_refresh_token_hash_unique';

/// Used-token replay lookup index.
const String userSessionsUsedRefreshTokenHashesIndexName =
    'user_sessions_used_refresh_token_hashes';

/// Per-user session lookup index.
const String userSessionsUserIdIndexName = 'user_sessions_user_id';

/// TTL cleanup index on absolute expiration.
const String userSessionsExpiresAtTtlIndexName = 'user_sessions_expires_at_ttl';

/// Current refresh-token hash field.
const String userSessionsRefreshTokenHashField = 'refresh_token_hash';

/// Consumed refresh-token hash array field.
const String userSessionsUsedRefreshTokenHashesField =
    'used_refresh_token_hashes';

/// Owning user field.
const String userSessionsUserIdField = 'user_id';

/// Absolute expiration field.
const String userSessionsExpiresAtField = 'expires_at';

/// Function used to ensure a session index without coupling tests to Atlas.
typedef EnsureSessionIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
      int? expireAfterSeconds,
    });

/// Ensures the approved `user_sessions` indexes.
///
/// Does not run per HTTP request. Call from a controlled startup or tool.
Future<void> ensureUserSessionIndexes({
  required EnsureSessionIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.userSessions,
    keys: const <String, dynamic>{userSessionsRefreshTokenHashField: 1},
    unique: true,
    name: userSessionsRefreshTokenHashUniqueIndexName,
    expireAfterSeconds: null,
  );
  await ensureIndex(
    collectionName: CollectionNames.userSessions,
    keys: const <String, dynamic>{userSessionsUsedRefreshTokenHashesField: 1},
    unique: false,
    name: userSessionsUsedRefreshTokenHashesIndexName,
    expireAfterSeconds: null,
  );
  await ensureIndex(
    collectionName: CollectionNames.userSessions,
    keys: const <String, dynamic>{userSessionsUserIdField: 1},
    unique: false,
    name: userSessionsUserIdIndexName,
    expireAfterSeconds: null,
  );
  await ensureIndex(
    collectionName: CollectionNames.userSessions,
    keys: const <String, dynamic>{userSessionsExpiresAtField: 1},
    unique: false,
    name: userSessionsExpiresAtTtlIndexName,
    expireAfterSeconds: 0,
  );
}

/// Ensures approved user-session indexes on [db].
Future<void> ensureUserSessionIndexesOnDb(Db db) {
  return ensureUserSessionIndexes(
    ensureIndex:
        ({
          required String collectionName,
          required Map<String, dynamic> keys,
          required bool unique,
          required String name,
          int? expireAfterSeconds,
        }) async {
          final collection = db.collection(collectionName);
          try {
            if (expireAfterSeconds != null) {
              await db.runCommand(<String, Object>{
                'createIndexes': collectionName,
                'indexes': <Object>[
                  <String, Object>{
                    'key': Map<String, Object>.from(keys),
                    'name': name,
                    'expireAfterSeconds': expireAfterSeconds,
                  },
                ],
              });
            } else {
              await collection.createIndex(
                keys: keys,
                unique: unique,
                name: name,
              );
            }
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

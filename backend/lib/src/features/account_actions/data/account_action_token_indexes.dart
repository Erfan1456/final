import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique SHA-256 token-hash index.
const String accountActionTokensTokenHashUniqueIndexName =
    'account_action_tokens_token_hash_unique';

/// Per-user purpose history index.
const String accountActionTokensUserPurposeCreatedIndexName =
    'account_action_tokens_user_purpose_created';

/// TTL cleanup index on absolute expiration.
const String accountActionTokensExpiresTtlIndexName =
    'account_action_tokens_expires_ttl';

/// Hashed token field.
const String accountActionTokensTokenHashField = 'token_hash';

/// Owning user field.
const String accountActionTokensUserIdField = 'user_id';

/// Purpose field.
const String accountActionTokensPurposeField = 'purpose';

/// Created-at field.
const String accountActionTokensCreatedAtField = 'created_at';

/// Absolute expiration field.
const String accountActionTokensExpiresAtField = 'expires_at';

/// Function used to ensure an account-action index without coupling tests
/// to Atlas.
typedef EnsureAccountActionIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
      int? expireAfterSeconds,
    });

/// Ensures the approved `account_action_tokens` indexes.
///
/// Does not run per HTTP request. Call from a controlled startup or tool.
Future<void> ensureAccountActionTokenIndexes({
  required EnsureAccountActionIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.accountActionTokens,
    keys: const <String, dynamic>{accountActionTokensTokenHashField: 1},
    unique: true,
    name: accountActionTokensTokenHashUniqueIndexName,
    expireAfterSeconds: null,
  );
  await ensureIndex(
    collectionName: CollectionNames.accountActionTokens,
    keys: const <String, dynamic>{
      accountActionTokensUserIdField: 1,
      accountActionTokensPurposeField: 1,
      accountActionTokensCreatedAtField: -1,
    },
    unique: false,
    name: accountActionTokensUserPurposeCreatedIndexName,
    expireAfterSeconds: null,
  );
  await ensureIndex(
    collectionName: CollectionNames.accountActionTokens,
    keys: const <String, dynamic>{accountActionTokensExpiresAtField: 1},
    unique: false,
    name: accountActionTokensExpiresTtlIndexName,
    expireAfterSeconds: 0,
  );
}

/// Ensures approved account-action token indexes on [db].
Future<void> ensureAccountActionTokenIndexesOnDb(Db db) {
  return ensureAccountActionTokenIndexes(
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

import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique owner index on `cleaner_profiles.user_id`.
const String cleanerProfilesUserIdUniqueIndexName =
    'cleaner_profiles_user_id_unique';

/// Admin queue index on status then `_id`.
const String cleanerProfilesStatusIdIndexName = 'cleaner_profiles_status_id';

/// Owning user field.
const String cleanerProfilesUserIdField = 'user_id';

/// Onboarding status field.
const String cleanerProfilesOnboardingStatusField = 'onboarding_status';

/// Function used to ensure a MongoDB index without coupling tests to Atlas.
typedef EnsureCleanerProfileIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures the approved `cleaner_profiles` indexes.
///
/// Does not run per HTTP request. Call from a controlled startup or tool.
Future<void> ensureCleanerProfileIndexes({
  required EnsureCleanerProfileIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.cleanerProfiles,
    keys: const <String, dynamic>{cleanerProfilesUserIdField: 1},
    unique: true,
    name: cleanerProfilesUserIdUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.cleanerProfiles,
    keys: const <String, dynamic>{
      cleanerProfilesOnboardingStatusField: 1,
      '_id': 1,
    },
    unique: false,
    name: cleanerProfilesStatusIdIndexName,
  );
}

/// Ensures approved cleaner-profile indexes on [db].
Future<void> ensureCleanerProfileIndexesOnDb(Db db) {
  return ensureCleanerProfileIndexes(
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

import 'package:home_cleaning_marketplace_api/src/features/users/data/user_indexes.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Deliberate database index initialization. Call once from a setup workflow,
/// not from per-request middleware.
Future<void> ensureApprovedDatabaseIndexes(Db db) {
  return ensureUserIndexesOnDb(db);
}

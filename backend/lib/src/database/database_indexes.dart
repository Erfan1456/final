import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/session_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_indexes.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Deliberate database index initialization. Call once from a setup workflow,
/// not from per-request middleware.
Future<void> ensureApprovedDatabaseIndexes(Db db) async {
  await ensureUserIndexesOnDb(db);
  await ensureUserSessionIndexesOnDb(db);
  await ensureCustomerProfileIndexesOnDb(db);
  await ensureCleanerProfileIndexesOnDb(db);
  await ensureAddressIndexesOnDb(db);
}

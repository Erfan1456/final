import 'dart:io';

import 'package:home_cleaning_marketplace_api/src/config/environment_loader.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/database/database_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/session_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_indexes.dart';

/// Ensures approved MongoDB indexes. Prints only sanitized operational status.
///
/// Does not insert, update, delete, or dump application documents.
Future<void> main() async {
  final config = ServerConfig.fromEnvironment(const EnvironmentLoader().load());
  final mongo = MongoDatabase(config: config);

  if (!mongo.isConfigured) {
    stderr.writeln('Database indexes could not be ensured.');
    exitCode = 1;
    return;
  }

  try {
    await mongo.connect();
    final db = mongo.db;
    if (db == null) {
      stderr.writeln('Database indexes could not be ensured.');
      exitCode = 1;
      return;
    }

    await ensureApprovedDatabaseIndexes(db);
    final usersIndexes = await db
        .collection(CollectionNames.users)
        .getIndexes();
    final sessionIndexes = await db
        .collection(CollectionNames.userSessions)
        .getIndexes();
    final customerIndexes = await db
        .collection(CollectionNames.customerProfiles)
        .getIndexes();
    final cleanerIndexes = await db
        .collection(CollectionNames.cleanerProfiles)
        .getIndexes();
    final addressIndexes = await db
        .collection(CollectionNames.addresses)
        .getIndexes();
    final serviceIndexes = await db
        .collection(CollectionNames.services)
        .getIndexes();
    final offeringIndexes = await db
        .collection(CollectionNames.cleanerServices)
        .getIndexes();
    final slotIndexes = await db
        .collection(CollectionNames.availabilitySlots)
        .getIndexes();

    if (!_hasNamedIndex(usersIndexes, usersEmailNormalizedUniqueIndexName) ||
        !_hasNamedIndex(
          sessionIndexes,
          userSessionsRefreshTokenHashUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          sessionIndexes,
          userSessionsUsedRefreshTokenHashesIndexName,
        ) ||
        !_hasNamedIndex(sessionIndexes, userSessionsUserIdIndexName) ||
        !_hasNamedIndex(sessionIndexes, userSessionsExpiresAtTtlIndexName) ||
        !_hasNamedIndex(
          customerIndexes,
          customerProfilesUserIdUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          cleanerIndexes,
          cleanerProfilesUserIdUniqueIndexName,
        ) ||
        !_hasNamedIndex(cleanerIndexes, cleanerProfilesStatusIdIndexName) ||
        !_hasNamedIndex(addressIndexes, addressesUserIdIndexName) ||
        !_hasNamedIndex(
          addressIndexes,
          addressesUserIdCreatedAtIndexName,
        ) ||
        !_hasNamedIndex(serviceIndexes, servicesSlugUniqueIndexName) ||
        !_hasNamedIndex(serviceIndexes, servicesActiveSlugIndexName) ||
        !_hasNamedIndex(
          offeringIndexes,
          cleanerServicesCleanerServiceUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          offeringIndexes,
          cleanerServicesServiceActiveIdIndexName,
        ) ||
        !_hasNamedIndex(
          offeringIndexes,
          cleanerServicesServiceCurrencyRateIdIndexName,
        ) ||
        !_hasNamedIndex(
          slotIndexes,
          availabilitySlotsCleanerStartUniqueIndexName,
        ) ||
        !_hasNamedIndex(slotIndexes, availabilitySlotsServiceStartIndexName) ||
        !_hasNamedIndex(
          slotIndexes,
          availabilitySlotsCleanerServiceStartIndexName,
        )) {
      stderr.writeln('Database indexes could not be ensured.');
      exitCode = 1;
      return;
    }

    stdout
      ..writeln('Database indexes ensured successfully.')
      ..writeln('$usersEmailNormalizedUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('key = $usersEmailNormalizedField ascending')
      ..writeln('$userSessionsRefreshTokenHashUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('key = $userSessionsRefreshTokenHashField ascending')
      ..writeln('$userSessionsUsedRefreshTokenHashesIndexName exists')
      ..writeln('key = $userSessionsUsedRefreshTokenHashesField ascending')
      ..writeln('$userSessionsUserIdIndexName exists')
      ..writeln('key = $userSessionsUserIdField ascending')
      ..writeln('$userSessionsExpiresAtTtlIndexName exists')
      ..writeln('key = $userSessionsExpiresAtField ascending')
      ..writeln('expireAfterSeconds = 0')
      ..writeln('$customerProfilesUserIdUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('key = $customerProfilesUserIdField ascending')
      ..writeln('$cleanerProfilesUserIdUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('key = $cleanerProfilesUserIdField ascending')
      ..writeln('$cleanerProfilesStatusIdIndexName exists')
      ..writeln(
        'key = $cleanerProfilesOnboardingStatusField ascending, _id ascending',
      )
      ..writeln('$addressesUserIdIndexName exists')
      ..writeln('key = $addressesUserIdField ascending')
      ..writeln('$addressesUserIdCreatedAtIndexName exists')
      ..writeln(
        'key = $addressesUserIdField ascending, '
        '$addressesCreatedAtField descending',
      )
      ..writeln('$servicesSlugUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('key = $servicesSlugField ascending')
      ..writeln('$servicesActiveSlugIndexName exists')
      ..writeln(
        'key = $servicesActiveField ascending, $servicesSlugField ascending',
      )
      ..writeln('$cleanerServicesCleanerServiceUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln(
        'key = $cleanerServicesCleanerUserIdField ascending, '
        '$cleanerServicesServiceIdField ascending',
      )
      ..writeln('$cleanerServicesServiceActiveIdIndexName exists')
      ..writeln('$cleanerServicesServiceCurrencyRateIdIndexName exists')
      ..writeln('$availabilitySlotsCleanerStartUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln(
        'key = $availabilitySlotsCleanerUserIdField ascending, '
        '$availabilitySlotsStartAtField ascending',
      )
      ..writeln('$availabilitySlotsServiceStartIndexName exists')
      ..writeln('$availabilitySlotsCleanerServiceStartIndexName exists');
  } catch (_) {
    stderr.writeln('Database indexes could not be ensured.');
    exitCode = 1;
  } finally {
    await mongo.close();
  }
}

bool _hasNamedIndex(List<Map<String, dynamic>> indexes, String name) {
  return indexes.any((index) => index['name'] == name);
}

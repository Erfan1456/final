import 'dart:io';

import 'package:home_cleaning_marketplace_api/src/config/environment_loader.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/application/canonical_service_catalog.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';

/// Ensures the canonical `home-cleaning` platform service.
///
/// Idempotent. Does not mutate users, profiles, sessions, offerings, or slots.
Future<void> main() async {
  final config = ServerConfig.fromEnvironment(const EnvironmentLoader().load());
  final mongo = MongoDatabase(config: config);

  if (!mongo.isConfigured) {
    stderr.writeln('Service catalog could not be ensured.');
    exitCode = 1;
    return;
  }

  try {
    await mongo.connect();
    final db = mongo.db;
    if (db == null) {
      stderr.writeln('Service catalog could not be ensured.');
      exitCode = 1;
      return;
    }

    final repository = MongoServiceRepository.fromDb(db);
    final ensure = CanonicalServiceCatalogEnsure(
      repository: repository,
      store: ServiceCatalogStore.fromDb(db),
    );
    final service = await ensure.ensureHomeCleaning();
    if (service.slug != CanonicalHomeCleaningService.slug ||
        service.name != CanonicalHomeCleaningService.name ||
        service.billingModel != CanonicalHomeCleaningService.billingModel ||
        service.active != CanonicalHomeCleaningService.active) {
      stderr.writeln('Service catalog could not be ensured.');
      exitCode = 1;
      return;
    }

    stdout
      ..writeln('Canonical service catalog ensured successfully.')
      ..writeln('slug = ${service.slug}')
      ..writeln('name = ${service.name}')
      ..writeln('billing_model = ${service.billingModel.wireValue}')
      ..writeln('active = ${service.active}');
  } catch (_) {
    stderr.writeln('Service catalog could not be ensured.');
    exitCode = 1;
  } finally {
    await mongo.close();
  }
}

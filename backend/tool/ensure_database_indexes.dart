import 'dart:io';

import 'package:home_cleaning_marketplace_api/src/config/environment_loader.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/database/database_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_indexes.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

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
    if (!await _usersEmailNormalizedUniqueIndexExists(db)) {
      stderr.writeln('Database indexes could not be ensured.');
      exitCode = 1;
      return;
    }

    stdout
      ..writeln('Database indexes ensured successfully.')
      ..writeln('$usersEmailNormalizedUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('key = $usersEmailNormalizedField ascending');
  } catch (_) {
    stderr.writeln('Database indexes could not be ensured.');
    exitCode = 1;
  } finally {
    await mongo.close();
  }
}

Future<bool> _usersEmailNormalizedUniqueIndexExists(Db db) async {
  final indexes = await db.collection(CollectionNames.users).getIndexes();
  return indexes.any(
    (index) => index['name'] == usersEmailNormalizedUniqueIndexName,
  );
}

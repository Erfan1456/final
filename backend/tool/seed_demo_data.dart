import 'dart:io';

import 'package:home_cleaning_marketplace_api/src/config/environment_loader.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';

import 'demo_seed/demo_seed_applier.dart';
import 'demo_seed/demo_seed_cli_errors.dart';
import 'demo_seed/demo_seed_constants.dart';
import 'demo_seed/demo_seed_exception.dart';
import 'demo_seed/demo_seed_plan.dart';
import 'demo_seed/demo_seed_summary.dart';
import 'demo_seed/demo_seed_uri.dart';

/// Portfolio demo MongoDB seed CLI.
///
/// Exactly one of `--dry-run`, `--apply`, or `--summary` is required.
///
/// Apply/summary use the normal configured Mongo connection and refuse to run
/// unless the URI database path is exactly
/// [DemoSeedConstants.expectedDatabaseName]. The Mongo URI is never printed.
/// Unexpected exceptions are reported with a generic message only.
Future<void> main(List<String> args) async {
  final mode = _parseMode(args);
  if (mode == null) {
    stderr.writeln(
      'Usage: dart run tool/seed_demo_data.dart '
      '--dry-run | --apply | --summary',
    );
    exitCode = 64;
    return;
  }

  switch (mode) {
    case _SeedMode.dryRun:
      await _dryRun();
    case _SeedMode.apply:
      await _apply();
    case _SeedMode.summary:
      await _summary();
  }
}

Future<void> _dryRun() async {
  final plan = buildDemoSeedPlan(
    nowUtc: DateTime.now().toUtc(),
    serviceId: DemoSeedConstants.dryRunServiceId,
    commissionBps: ServerConfig.defaultPlatformCommissionBps,
  );
  stdout
    ..writeln('Dry-run seed plan for ${DemoSeedConstants.seedKey}')
    ..writeln('Service id (placeholder): ${plan.serviceId.oid}')
    ..writeln('Commission bps: ${plan.commissionBps}');
  final counts = plan.countSummary();
  final keys = counts.keys.toList()..sort();
  for (final key in keys) {
    stdout.writeln('  $key: ${counts[key]}');
  }
  stdout
    ..writeln('Booking statuses: ${plan.bookingStatusCounts}')
    ..writeln('Role counts: ${plan.roleCounts}');
}

Future<void> _apply() async {
  final env = const EnvironmentLoader().load();
  final adminPassword = env[DemoSeedConstants.adminPasswordEnv];
  final sharedPassword = env[DemoSeedConstants.sharedPasswordEnv];
  if (adminPassword == null ||
      adminPassword.isEmpty ||
      sharedPassword == null ||
      sharedPassword.isEmpty) {
    stderr.writeln(
      'Missing ${DemoSeedConstants.adminPasswordEnv} and/or '
      '${DemoSeedConstants.sharedPasswordEnv}.',
    );
    exitCode = 1;
    return;
  }

  final config = ServerConfig.fromEnvironment(env);
  final mongo = MongoDatabase(config: config);
  if (!mongo.isConfigured) {
    stderr.writeln('MongoDB is not configured.');
    exitCode = 1;
    return;
  }

  try {
    requireMongoUriDatabase(
      config.mongoUri,
      DemoSeedConstants.expectedDatabaseName,
    );
    await mongo.connect();
    final db = mongo.db;
    if (db == null) {
      throw const DemoSeedException('MongoDB connection is not ready.');
    }
    if (db.databaseName != DemoSeedConstants.expectedDatabaseName) {
      throw const DemoSeedException(
        'Configured MongoDB database must be home_cleaning_marketplace.',
      );
    }
    stdout
      ..writeln('Database: ${db.databaseName}')
      ..writeln('Seed: ${DemoSeedConstants.seedKey}');
    await applyDemoSeed(
      db: db,
      config: config,
      adminPassword: adminPassword,
      sharedPassword: sharedPassword,
      log: stdout.writeln,
    );
  } catch (error) {
    reportSeedCliFailure(
      error,
      unexpectedMessage:
          'Seed apply failed due to an unexpected database/tool error.',
      write: stderr.writeln,
    );
    exitCode = 1;
  } finally {
    await mongo.close();
  }
}

Future<void> _summary() async {
  final config = ServerConfig.fromEnvironment(const EnvironmentLoader().load());
  final mongo = MongoDatabase(config: config);
  if (!mongo.isConfigured) {
    stderr.writeln('MongoDB is not configured.');
    exitCode = 1;
    return;
  }

  try {
    requireMongoUriDatabase(
      config.mongoUri,
      DemoSeedConstants.expectedDatabaseName,
    );
    await mongo.connect();
    final db = mongo.db;
    if (db == null) {
      throw const DemoSeedException('MongoDB connection is not ready.');
    }
    if (db.databaseName != DemoSeedConstants.expectedDatabaseName) {
      throw const DemoSeedException(
        'Configured MongoDB database must be home_cleaning_marketplace.',
      );
    }
    stdout.writeln('Database: ${db.databaseName}');
    await printDemoSeedSummary(db: db, log: stdout.writeln);
  } catch (error) {
    reportSeedCliFailure(
      error,
      unexpectedMessage:
          'Seed summary failed due to an unexpected database/tool error.',
      write: stderr.writeln,
    );
    exitCode = 1;
  } finally {
    await mongo.close();
  }
}

enum _SeedMode { dryRun, apply, summary }

_SeedMode? _parseMode(List<String> args) {
  final flags = args.where((a) => a.startsWith('--')).toSet();
  final modes = <_SeedMode>[];
  if (flags.contains('--dry-run')) {
    modes.add(_SeedMode.dryRun);
  }
  if (flags.contains('--apply')) {
    modes.add(_SeedMode.apply);
  }
  if (flags.contains('--summary')) {
    modes.add(_SeedMode.summary);
  }
  if (modes.length != 1) {
    return null;
  }
  return modes.single;
}

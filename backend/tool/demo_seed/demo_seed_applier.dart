import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/argon2id_password_hasher.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/auth_session_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/mongo_user_session_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/application/canonical_service_catalog.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/mongo_user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

import 'demo_seed_constants.dart';
import 'demo_seed_documents.dart';
import 'demo_seed_exception.dart';
import 'demo_seed_plan.dart';

/// Applies the portfolio demo seed into [db] idempotently.
Future<void> applyDemoSeed({
  required Db db,
  required ServerConfig config,
  required String adminPassword,
  required String sharedPassword,
  required void Function(String) log,
}) async {
  if (db.databaseName != DemoSeedConstants.expectedDatabaseName) {
    throw const DemoSeedException(
      'Configured MongoDB database must be home_cleaning_marketplace.',
    );
  }

  log('Ensuring canonical home-cleaning service...');
  final serviceRepository = MongoServiceRepository.fromDb(db);
  final ensure = CanonicalServiceCatalogEnsure(
    repository: serviceRepository,
    store: ServiceCatalogStore.fromDb(db),
  );
  final service = await ensure.ensureHomeCleaning();

  final previous = await _loadManifest(db);
  if (previous != null) {
    log('Cleaning previous seed documents for ${previous.seedKey}...');
    await _cleanupPreviousSeed(db: db, previous: previous, log: log);
  } else {
    log('No previous seed manifest found.');
  }

  const policy = PasswordPolicy();
  final adminValidation = policy.validate(adminPassword);
  final sharedValidation = policy.validate(sharedPassword);
  if (!adminValidation.isValid || !sharedValidation.isValid) {
    throw const DemoSeedException(
      'Seed passwords failed PasswordPolicy validation.',
    );
  }

  final hasher = Argon2idPasswordHasher();
  final adminHash = hasher.hash(adminPassword);
  final sharedHash = hasher.hash(sharedPassword);

  final nowUtc = DateTime.now().toUtc();
  final plan = buildDemoSeedPlan(
    nowUtc: nowUtc,
    serviceId: service.id,
    commissionBps: config.platformCommissionBps,
  );

  final passwordHashByEmail = <String, String>{
    for (final user in plan.users)
      user.emailNormalized: user.isTargetAdmin ? adminHash : sharedHash,
  };

  final bundle = buildDemoSeedDocuments(
    plan: plan,
    passwordHashByEmailNormalized: passwordHashByEmail,
  );

  final usersCollection = db.collection(CollectionNames.users);
  final userRepository = MongoUserRepository.fromDb(db);
  final sessions = AuthSessionService(
    sessions: MongoUserSessionRepository.fromDb(db),
  );

  final plannedAdmin = plan.targetAdmin;
  final existingAdmin = await userRepository.findByEmail(
    DemoSeedConstants.targetAdminEmail,
  );

  late final ObjectId realAdminId;
  var createdTargetAdminThisRun = false;
  if (existingAdmin != null) {
    realAdminId = existingAdmin.id;
    log('Updating existing target admin in place...');
    final updated = UserAccount(
      id: existingAdmin.id,
      role: UserRole.admin,
      email: plannedAdmin.email,
      emailNormalized: plannedAdmin.emailNormalized,
      passwordHash: adminHash,
      accountStatus: plannedAdmin.accountStatus,
      emailVerified: true,
      createdAt: existingAdmin.createdAt,
      updatedAt: nowUtc,
    );
    final result = await usersCollection.updateOne(
      where.eq('_id', existingAdmin.id),
      {
        r'$set': <String, dynamic>{
          'role': updated.role.wireValue,
          'email': updated.email,
          'email_normalized': updated.emailNormalized,
          'password_hash': updated.passwordHash,
          'account_status': updated.accountStatus.wireValue,
          'email_verified': updated.emailVerified,
          'updated_at': updated.updatedAt,
        },
      },
    );
    if (!result.isSuccess) {
      throw StateError('Failed to update target admin user');
    }
    await sessions.revokeAllForUser(existingAdmin.id);
  } else {
    realAdminId = plannedAdmin.id;
    log('Inserting target admin user...');
    final insert = await usersCollection.insertOne(
      UserAccount(
        id: plannedAdmin.id,
        role: UserRole.admin,
        email: plannedAdmin.email,
        emailNormalized: plannedAdmin.emailNormalized,
        passwordHash: adminHash,
        accountStatus: plannedAdmin.accountStatus,
        emailVerified: true,
        createdAt: nowUtc.subtract(const Duration(days: 40)),
        updatedAt: nowUtc,
      ).toDocument(),
    );
    if (!insert.isSuccess) {
      throw StateError('Failed to insert target admin user');
    }
    createdTargetAdminThisRun = true;
  }

  final remapped = _remapObjectId(
    bundle.documentsByCollection,
    from: plannedAdmin.id,
    to: realAdminId,
  );

  // Target admin already upserted; do not insert a duplicate users doc.
  final usersDocs = remapped[CollectionNames.users] ?? const [];
  remapped[CollectionNames.users] = [
    for (final doc in usersDocs)
      if ((doc['_id'] as ObjectId) != realAdminId &&
          doc['email_normalized'] !=
              DemoSeedConstants.targetAdminEmailNormalized)
        doc,
  ];

  final insertedThisRun = <String, List<ObjectId>>{};
  if (createdTargetAdminThisRun) {
    insertedThisRun[CollectionNames.users] = <ObjectId>[realAdminId];
  }
  try {
    for (final entry in remapped.entries) {
      final collectionName = entry.key;
      final docs = entry.value;
      if (docs.isEmpty) {
        continue;
      }
      log('Inserting ${docs.length} documents into $collectionName...');
      final collection = db.collection(collectionName);
      for (final doc in docs) {
        final result = await collection.insertOne(doc);
        if (!result.isSuccess) {
          throw StateError('Insert failed for collection $collectionName');
        }
        final id = doc['_id'];
        if (id is ObjectId) {
          insertedThisRun
              .putIfAbsent(collectionName, () => <ObjectId>[])
              .add(id);
        }
      }
    }

    final manifestIds = <String, List<String>>{
      for (final entry in remapped.entries)
        entry.key: [
          for (final doc in entry.value) (doc['_id'] as ObjectId).oid,
        ],
    };
    final userIds = manifestIds[CollectionNames.users] ?? <String>[];
    if (!userIds.contains(realAdminId.oid)) {
      userIds.add(realAdminId.oid);
    }
    manifestIds[CollectionNames.users] = userIds;

    final manifestCounts = <String, int>{
      for (final entry in remapped.entries) entry.key: entry.value.length,
    };
    manifestCounts[CollectionNames.users] = userIds.length;

    final manifest = DemoSeedManifestData(
      seedKey: DemoSeedConstants.seedKey,
      collectionIds: manifestIds,
      counts: manifestCounts,
      fingerprint: bundle.manifest.fingerprint,
      createdAt: nowUtc,
    );
    await _writeManifest(db, manifest);
    log('Seed apply completed for ${DemoSeedConstants.seedKey}.');
  } catch (error) {
    log('Seed apply failed; rolling back inserts from this run...');
    await _bestEffortDelete(db, insertedThisRun);
    rethrow;
  }
}

Future<DemoSeedManifestData?> _loadManifest(Db db) async {
  final collection = db.collection(DemoSeedConstants.manifestCollection);
  final doc = await collection.findOne(
    where.eq('seed_key', DemoSeedConstants.seedKey),
  );
  if (doc == null) {
    return null;
  }
  return DemoSeedManifestData.fromDocument(Map<String, dynamic>.from(doc));
}

Future<void> _writeManifest(Db db, DemoSeedManifestData manifest) async {
  final collection = db.collection(DemoSeedConstants.manifestCollection);
  await collection.deleteMany(
    where.eq('seed_key', DemoSeedConstants.seedKey),
  );
  final result = await collection.insertOne(
    manifest.toDocument(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.manifest, 1),
    ),
  );
  if (!result.isSuccess) {
    throw StateError('Failed to write demo seed manifest');
  }
}

Future<void> _cleanupPreviousSeed({
  required Db db,
  required DemoSeedManifestData previous,
  required void Function(String) log,
}) async {
  for (final entry in previous.collectionIds.entries) {
    final collectionName = entry.key;
    final ids = <ObjectId>[];
    for (final hex in entry.value) {
      try {
        ids.add(ObjectId.fromHexString(hex));
      } catch (_) {
        // Ignore malformed historic ids.
      }
    }
    if (ids.isEmpty) {
      continue;
    }

    if (collectionName == CollectionNames.users) {
      final users = db.collection(CollectionNames.users);
      final result = await users.deleteMany({
        '_id': {r'$in': ids},
        'email_normalized': {
          r'$ne': DemoSeedConstants.targetAdminEmailNormalized,
        },
      });
      log(
        'Removed ${result.nRemoved} prior seeded users '
        '(target admin retained if present).',
      );
      continue;
    }

    final collection = db.collection(collectionName);
    final result = await collection.deleteMany({
      '_id': {r'$in': ids},
    });
    log('Removed ${result.nRemoved} docs from $collectionName');
  }
}

Future<void> _bestEffortDelete(
  Db db,
  Map<String, List<ObjectId>> insertedThisRun,
) async {
  for (final entry in insertedThisRun.entries) {
    if (entry.value.isEmpty) {
      continue;
    }
    try {
      await db.collection(entry.key).deleteMany({
        '_id': {r'$in': entry.value},
      });
    } catch (_) {
      // Best-effort only.
    }
  }
}

Map<String, List<Map<String, dynamic>>> _remapObjectId(
  Map<String, List<Map<String, dynamic>>> source, {
  required ObjectId from,
  required ObjectId to,
}) {
  return {
    for (final entry in source.entries)
      entry.key: [
        for (final doc in entry.value)
          _remapMap(Map<String, dynamic>.from(doc), from: from, to: to),
      ],
  };
}

Map<String, dynamic> _remapMap(
  Map<String, dynamic> value, {
  required ObjectId from,
  required ObjectId to,
}) {
  return <String, dynamic>{
    for (final entry in value.entries)
      entry.key: _remapValue(entry.value, from: from, to: to),
  };
}

Object? _remapValue(
  Object? value, {
  required ObjectId from,
  required ObjectId to,
}) {
  if (value is ObjectId) {
    return value == from ? to : value;
  }
  if (value is Map) {
    return _remapMap(
      Map<String, dynamic>.from(value),
      from: from,
      to: to,
    );
  }
  if (value is List) {
    return [
      for (final item in value) _remapValue(item, from: from, to: to),
    ];
  }
  return value;
}

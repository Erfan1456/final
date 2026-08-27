import 'package:mongo_dart/mongo_dart.dart';

import 'demo_seed_constants.dart';
import 'demo_seed_documents.dart';

/// Prints a secret-free summary of the last applied demo seed.
Future<void> printDemoSeedSummary({
  required Db db,
  required void Function(String) log,
  bool verifyIds = true,
}) async {
  final collection = db.collection(DemoSeedConstants.manifestCollection);
  final doc = await collection.findOne(
    where.eq('seed_key', DemoSeedConstants.seedKey),
  );
  if (doc == null) {
    log('No demo seed manifest found for ${DemoSeedConstants.seedKey}.');
    return;
  }

  final manifest = DemoSeedManifestData.fromDocument(
    Map<String, dynamic>.from(doc),
  );
  log('Seed: ${manifest.seedKey}');
  log('Fingerprint: ${manifest.fingerprint}');
  log('Created at: ${manifest.createdAt.toIso8601String()}');
  log('Manifest counts:');
  final keys = manifest.counts.keys.toList()..sort();
  for (final key in keys) {
    log('  $key: ${manifest.counts[key]}');
  }

  if (!verifyIds) {
    return;
  }

  log('Verified present ids:');
  for (final entry in manifest.collectionIds.entries) {
    final ids = <ObjectId>[];
    for (final hex in entry.value) {
      try {
        ids.add(ObjectId.fromHexString(hex));
      } catch (_) {
        // Skip malformed.
      }
    }
    if (ids.isEmpty) {
      log('  ${entry.key}: 0');
      continue;
    }
    final count = await db.collection(entry.key).count({
      '_id': {r'$in': ids},
    });
    log('  ${entry.key}: $count / ${ids.length}');
  }
}

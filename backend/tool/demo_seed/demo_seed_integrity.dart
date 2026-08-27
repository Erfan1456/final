import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/commission_math.dart';

import 'demo_seed_plan.dart';

/// Integrity helpers for demo-seed tests and document builders.
abstract final class DemoSeedIntegrity {
  /// Field names that must never appear on seed documents.
  static const forbiddenSecretFieldNames = <String>{
    'password',
    'plaintext_password',
    'raw_password',
    'jwt',
    'access_token',
    'refresh_token',
    'token',
    'secret',
    'mongo_uri',
    'mongodb_uri',
  };

  /// Ensures documents contain only argon2 `password_hash` secrets.
  static void assertDocumentsSafe(
    Map<String, List<Map<String, dynamic>>> documentsByCollection,
  ) {
    for (final entry in documentsByCollection.entries) {
      for (final document in entry.value) {
        _scanMap(document, path: entry.key);
      }
    }
  }

  /// Validates earnings commission splits against [CommissionMath].
  static void assertFinancialSplits(DemoSeedPlan plan) {
    for (final earning in plan.earnings) {
      final fee = CommissionMath.platformFeeMinor(
        grossMinor: earning.grossAmountMinor,
        commissionBps: earning.commissionBps,
      );
      final net = CommissionMath.cleanerNetMinor(
        grossMinor: earning.grossAmountMinor,
        commissionBps: earning.commissionBps,
      );
      if (earning.platformFeeMinor != fee) {
        throw StateError('platform_fee_minor mismatch');
      }
      if (earning.cleanerAmountMinor != net) {
        throw StateError('cleaner_amount_minor mismatch');
      }
      if (earning.platformFeeMinor + earning.cleanerAmountMinor !=
          earning.grossAmountMinor) {
        throw StateError('earnings split does not sum to gross');
      }
    }
  }

  /// Returns true when [value] looks like an argon2 PHC hash.
  static bool looksLikeArgon2Hash(Object? value) {
    return value is String && value.startsWith(r'$argon2');
  }

  static void _scanMap(Map<Object?, Object?> map, {required String path}) {
    for (final entry in map.entries) {
      final key = entry.key;
      final keyName = key?.toString() ?? '';
      final lower = keyName.toLowerCase();
      if (forbiddenSecretFieldNames.contains(lower)) {
        throw StateError('Forbidden field "$keyName" at $path');
      }
      if (lower == 'password_hash') {
        if (!looksLikeArgon2Hash(entry.value)) {
          throw StateError('password_hash must look like argon2 at $path');
        }
        continue;
      }
      final value = entry.value;
      if (value is Map) {
        _scanMap(Map<Object?, Object?>.from(value), path: '$path.$keyName');
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          final item = value[i];
          if (item is Map) {
            _scanMap(
              Map<Object?, Object?>.from(item),
              path: '$path.$keyName[$i]',
            );
          } else {
            _rejectSecretLikeString(item, path: '$path.$keyName[$i]');
          }
        }
      } else {
        _rejectSecretLikeString(value, path: '$path.$keyName');
      }
    }
  }

  static void _rejectSecretLikeString(Object? value, {required String path}) {
    if (value is! String) {
      return;
    }
    // Never allow accidental plaintext password material in seed docs.
    if (value.contains('password=') ||
        value.contains('Bearer ') ||
        value.startsWith('eyJ')) {
      throw StateError('Secret-like string at $path');
    }
    // ObjectIds and normal text are fine; skip argon2 hashes elsewhere.
    if (value.startsWith(r'$argon2') && !path.endsWith('password_hash')) {
      throw StateError('Unexpected argon2 hash outside password_hash at $path');
    }
  }
}

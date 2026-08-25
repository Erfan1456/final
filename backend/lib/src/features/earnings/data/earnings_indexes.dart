import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique deterministic source-event key.
const String earningsLedgerSourceEventUniqueIndexName =
    'earnings_ledger_source_event_unique';

/// Cleaner + currency keyset index (`_id` descending).
const String earningsLedgerCleanerCurrencyIdDescIndexName =
    'earnings_ledger_cleaner_currency_id_desc';

/// Booking + entry-type lookup index.
const String earningsLedgerBookingTypeIndexName =
    'earnings_ledger_booking_type';

/// Created-at admin/reconciliation index.
const String earningsLedgerCreatedAtIndexName = 'earnings_ledger_created_at';

/// Source-event field.
const String earningsLedgerSourceEventKeyField = 'source_event_key';

/// Cleaner owner field.
const String earningsLedgerCleanerUserIdField = 'cleaner_user_id';

/// Currency field.
const String earningsLedgerCurrencyCodeField = 'currency_code';

/// Booking field.
const String earningsLedgerBookingIdField = 'booking_id';

/// Entry-type field.
const String earningsLedgerEntryTypeField = 'entry_type';

/// Created-at field.
const String earningsLedgerCreatedAtField = 'created_at';

/// Function used to ensure an earnings ledger index in tests.
typedef EnsureEarningsLedgerIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures the approved `earnings_ledger` indexes.
///
/// `earnings_ledger_created_at` is kept for admin date-range scans even though
/// cleaner listing uses the cleaner+currency+`_id` index. Booking+type is
/// narrower than a booking-only index for earning/refund lookup.
Future<void> ensureEarningsLedgerIndexes({
  required EnsureEarningsLedgerIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.earningsLedger,
    keys: const <String, dynamic>{earningsLedgerSourceEventKeyField: 1},
    unique: true,
    name: earningsLedgerSourceEventUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.earningsLedger,
    keys: const <String, dynamic>{
      earningsLedgerCleanerUserIdField: 1,
      earningsLedgerCurrencyCodeField: 1,
      '_id': -1,
    },
    unique: false,
    name: earningsLedgerCleanerCurrencyIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.earningsLedger,
    keys: const <String, dynamic>{
      earningsLedgerBookingIdField: 1,
      earningsLedgerEntryTypeField: 1,
    },
    unique: false,
    name: earningsLedgerBookingTypeIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.earningsLedger,
    keys: const <String, dynamic>{
      earningsLedgerCreatedAtField: -1,
      '_id': -1,
    },
    unique: false,
    name: earningsLedgerCreatedAtIndexName,
  );
}

/// Ensures approved earnings-ledger indexes on [db].
Future<void> ensureEarningsLedgerIndexesOnDb(Db db) {
  return ensureEarningsLedgerIndexes(
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

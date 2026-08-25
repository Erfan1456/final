import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_entry_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_ledger_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_summary.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for the append-only earnings ledger.
abstract class EarningsLedgerRepository {
  /// Finds an entry by deterministic source-event key.
  Future<EarningsLedgerEntry?> findBySourceEventKey(String sourceEventKey);

  /// Original service earning for [bookingId], if any.
  Future<EarningsLedgerEntry?> findServiceEarningForBooking(ObjectId bookingId);

  /// Ledger rows for [bookingId].
  Future<List<EarningsLedgerEntry>> listForBooking(ObjectId bookingId);

  /// Inserts [entry]. Duplicate unique keys are reported.
  Future<EarningsLedgerEntry> append(EarningsLedgerEntry entry);

  /// Cleaner ledger page, `_id` descending.
  Future<EarningsLedgerPage> listForCleaner({
    required ObjectId cleanerUserId,
    required int limit,
    String? currencyCode,
    EarningsEntryType? entryType,
    ObjectId? after,
  });

  /// Per-currency ledger totals for one cleaner. Does not include payouts.
  Future<Map<String, CurrencySummaryAccumulator>> aggregateCleanerLedgerTotals(
    ObjectId cleanerUserId,
  );

  /// Admin finance ledger totals in `[from, to]`, optionally one currency.
  Future<Map<String, AdminFinanceLedgerTotals>> aggregateAdminFinanceSummary({
    required DateTime from,
    required DateTime to,
    String? currencyCode,
  });
}

/// Ledger-side admin finance totals for one currency.
class AdminFinanceLedgerTotals {
  /// Creates zeroed totals.
  AdminFinanceLedgerTotals();

  /// Original service-earning gross.
  int grossServiceVolumeMinor = 0;

  /// Original service-earning platform fees.
  int platformFeeMinor = 0;

  /// Original service-earning cleaner net.
  int cleanerNetEarningsMinor = 0;

  /// Absolute refund-adjustment gross.
  int refundGrossMinor = 0;

  /// Refund-adjustment cleaner amounts (negative).
  int cleanerRefundAdjustmentsMinor = 0;
}

/// MongoDB implementation of [EarningsLedgerRepository].
///
/// Append-only: no update or delete methods.
class MongoEarningsLedgerRepository implements EarningsLedgerRepository {
  /// Creates a repository over [documents].
  MongoEarningsLedgerRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  /// Creates a repository using the earnings-ledger collection on [db].
  factory MongoEarningsLedgerRepository.fromDb(Db db) {
    return MongoEarningsLedgerRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.earningsLedger),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<EarningsLedgerEntry?> findBySourceEventKey(String sourceEventKey) {
    return _find(<String, dynamic>{'source_event_key': sourceEventKey});
  }

  @override
  Future<EarningsLedgerEntry?> findServiceEarningForBooking(
    ObjectId bookingId,
  ) {
    return _find(<String, dynamic>{
      'booking_id': bookingId,
      'entry_type': EarningsEntryType.serviceEarning.wireValue,
    });
  }

  @override
  Future<List<EarningsLedgerEntry>> listForBooking(ObjectId bookingId) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{'booking_id': bookingId},
      sort: const <String, int>{'_id': 1},
    );
    return documents.map(EarningsLedgerEntry.fromDocument).toList();
  }

  @override
  Future<EarningsLedgerEntry> append(EarningsLedgerEntry entry) async {
    final result = await _documents.insertOne(entry.toDocument());
    if (result.isDuplicateKey) {
      throw const EarningsDuplicateKeyException();
    }
    if (!result.isSuccess) {
      throw const EarningsWriteException();
    }
    return entry;
  }

  @override
  Future<EarningsLedgerPage> listForCleaner({
    required ObjectId cleanerUserId,
    required int limit,
    String? currencyCode,
    EarningsEntryType? entryType,
    ObjectId? after,
  }) async {
    final selector = <String, dynamic>{'cleaner_user_id': cleanerUserId};
    if (currencyCode != null) {
      selector['currency_code'] = currencyCode;
    }
    if (entryType != null) {
      selector['entry_type'] = entryType.wireValue;
    }
    if (after != null) {
      selector['_id'] = <String, dynamic>{r'$lt': after};
    }
    final documents = await _documents.findMany(
      selector: selector,
      sort: const <String, int>{'_id': -1},
      limit: limit + 1,
    );
    final items = documents
        .take(limit)
        .map(EarningsLedgerEntry.fromDocument)
        .toList();
    final nextCursor = documents.length > limit ? items.last.id.oid : null;
    return EarningsLedgerPage(items: items, nextCursor: nextCursor);
  }

  @override
  Future<Map<String, CurrencySummaryAccumulator>> aggregateCleanerLedgerTotals(
    ObjectId cleanerUserId,
  ) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{'cleaner_user_id': cleanerUserId},
    );
    final totals = <String, CurrencySummaryAccumulator>{};
    for (final document in documents) {
      final entry = EarningsLedgerEntry.fromDocument(document);
      final acc = totals.putIfAbsent(
        entry.currencyCode,
        () => CurrencySummaryAccumulator(entry.currencyCode),
      );
      switch (entry.entryType) {
        case EarningsEntryType.serviceEarning:
          acc
            ..netLedgerMinor += entry.cleanerAmountMinor
            ..grossEarnedMinor += entry.grossAmountMinor
            ..platformFeesMinor += entry.platformFeeMinor;
        case EarningsEntryType.refundAdjustment:
          acc
            ..netLedgerMinor += entry.cleanerAmountMinor
            ..refundsGrossMinor += -entry.grossAmountMinor
            ..cleanerRefundAdjustmentsMinor += entry.cleanerAmountMinor;
      }
    }
    return totals;
  }

  @override
  Future<Map<String, AdminFinanceLedgerTotals>> aggregateAdminFinanceSummary({
    required DateTime from,
    required DateTime to,
    String? currencyCode,
  }) async {
    final selector = <String, dynamic>{
      'created_at': <String, dynamic>{
        r'$gte': from.toUtc(),
        r'$lte': to.toUtc(),
      },
    };
    if (currencyCode != null) {
      selector['currency_code'] = currencyCode;
    }
    final documents = await _documents.findMany(selector: selector);
    final totals = <String, AdminFinanceLedgerTotals>{};
    for (final document in documents) {
      final entry = EarningsLedgerEntry.fromDocument(document);
      final acc = totals.putIfAbsent(
        entry.currencyCode,
        AdminFinanceLedgerTotals.new,
      );
      switch (entry.entryType) {
        case EarningsEntryType.serviceEarning:
          acc
            ..grossServiceVolumeMinor += entry.grossAmountMinor
            ..platformFeeMinor += entry.platformFeeMinor
            ..cleanerNetEarningsMinor += entry.cleanerAmountMinor;
        case EarningsEntryType.refundAdjustment:
          acc
            ..refundGrossMinor += -entry.grossAmountMinor
            ..cleanerRefundAdjustmentsMinor += entry.cleanerAmountMinor;
      }
    }
    return totals;
  }

  Future<EarningsLedgerEntry?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return EarningsLedgerEntry.fromDocument(document);
  }
}

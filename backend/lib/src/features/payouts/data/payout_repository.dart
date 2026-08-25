import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_request.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Per-currency payout totals used by earnings summaries.
class PayoutCurrencyTotals {
  /// Creates zeroed totals.
  PayoutCurrencyTotals();

  /// Sum of requested + processing amounts.
  int reservedMinor = 0;

  /// Sum of paid amounts.
  int paidOutMinor = 0;
}

/// Admin finance payout totals for one currency.
class AdminFinancePayoutTotals {
  /// Creates zeroed totals.
  AdminFinancePayoutTotals();

  /// Amounts currently requested.
  int requestedMinor = 0;

  /// Amounts currently processing.
  int processingMinor = 0;

  /// Amounts paid in the window.
  int paidMinor = 0;

  /// Amounts failed in the window.
  int failedMinor = 0;
}

/// Persistence contract for payout requests.
abstract class PayoutRepository {
  /// Finds a payout by id.
  Future<PayoutRequest?> findById(ObjectId id);

  /// Finds [id] only when owned by [cleanerUserId].
  Future<PayoutRequest?> findOwnedById({
    required ObjectId id,
    required ObjectId cleanerUserId,
  });

  /// Finds a payout by cleaner and client idempotency key.
  Future<PayoutRequest?> findByCleanerIdempotency({
    required ObjectId cleanerUserId,
    required String clientIdempotencyKey,
  });

  /// Active requested/processing payout for [cleanerUserId], if any.
  Future<PayoutRequest?> findActiveForCleaner(ObjectId cleanerUserId);

  /// Finds a payout by provider payout id.
  Future<PayoutRequest?> findByProviderPayoutId({
    required String provider,
    required String providerPayoutId,
  });

  /// Next 1-based attempt number for [cleanerUserId] across currencies.
  Future<int> nextAttemptNumber(ObjectId cleanerUserId);

  /// Inserts a requested payout. Duplicate unique keys are reported.
  Future<PayoutRequest> createRequested(PayoutRequest payout);

  /// Conditional requested → cancelled for the owning cleaner.
  Future<PayoutRequest?> cancelRequested({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
  });

  /// Conditional requested → processing by an administrator.
  Future<PayoutRequest?> startProcessing({
    required ObjectId id,
    required ObjectId adminUserId,
    required String provider,
    required DateTime now,
  });

  /// Persists the opaque provider payout id while still processing.
  Future<PayoutRequest?> attachProviderPayoutId({
    required ObjectId id,
    required String providerPayoutId,
    required DateTime now,
  });

  /// Conditional processing → paid from a verified webhook.
  Future<PayoutRequest?> markPaid({
    required ObjectId id,
    required DateTime now,
  });

  /// Conditional processing → failed from provider or webhook.
  Future<PayoutRequest?> markFailed({
    required ObjectId id,
    required DateTime now,
    String? failureCode,
    String? failureMessage,
  });

  /// Conditional requested → rejected by an administrator.
  Future<PayoutRequest?> rejectRequested({
    required ObjectId id,
    required ObjectId adminUserId,
    required String reason,
    required DateTime now,
  });

  /// Cleaner list page, `_id` descending.
  Future<PayoutPage> listForCleaner({
    required ObjectId cleanerUserId,
    required int limit,
    PayoutStatus? status,
    String? currencyCode,
    ObjectId? after,
  });

  /// Admin list page, `_id` descending.
  Future<PayoutPage> adminPage({
    required int limit,
    PayoutStatus? status,
    String? currencyCode,
    ObjectId? cleanerUserId,
    ObjectId? after,
  });

  /// Per-currency reserved and paid totals for one cleaner.
  Future<Map<String, PayoutCurrencyTotals>> aggregatePayoutTotals(
    ObjectId cleanerUserId,
  );

  /// Admin finance payout totals in `[from, to]`.
  Future<Map<String, AdminFinancePayoutTotals>> aggregateAdminFinanceTotals({
    required DateTime from,
    required DateTime to,
    String? currencyCode,
  });
}

/// MongoDB implementation of [PayoutRepository].
class MongoPayoutRepository implements PayoutRepository {
  /// Creates a repository over [documents].
  MongoPayoutRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  /// Creates a repository using the payout-requests collection on [db].
  factory MongoPayoutRepository.fromDb(Db db) {
    return MongoPayoutRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.payoutRequests),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<PayoutRequest?> findById(ObjectId id) {
    return _find(<String, dynamic>{'_id': id});
  }

  @override
  Future<PayoutRequest?> findOwnedById({
    required ObjectId id,
    required ObjectId cleanerUserId,
  }) {
    return _find(<String, dynamic>{
      '_id': id,
      'cleaner_user_id': cleanerUserId,
    });
  }

  @override
  Future<PayoutRequest?> findByCleanerIdempotency({
    required ObjectId cleanerUserId,
    required String clientIdempotencyKey,
  }) {
    return _find(<String, dynamic>{
      'cleaner_user_id': cleanerUserId,
      'client_idempotency_key': clientIdempotencyKey,
    });
  }

  @override
  Future<PayoutRequest?> findActiveForCleaner(ObjectId cleanerUserId) {
    return _find(<String, dynamic>{
      'cleaner_user_id': cleanerUserId,
      'payout_active': true,
    });
  }

  @override
  Future<PayoutRequest?> findByProviderPayoutId({
    required String provider,
    required String providerPayoutId,
  }) {
    return _find(<String, dynamic>{
      'provider': provider,
      'provider_payout_id': providerPayoutId,
    });
  }

  @override
  Future<int> nextAttemptNumber(ObjectId cleanerUserId) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{'cleaner_user_id': cleanerUserId},
      sort: const <String, int>{'attempt_number': -1},
      limit: 1,
    );
    if (documents.isEmpty) {
      return 1;
    }
    final current = documents.first['attempt_number'];
    if (current is int) {
      return current + 1;
    }
    return 1;
  }

  @override
  Future<PayoutRequest> createRequested(PayoutRequest payout) async {
    final result = await _documents.insertOne(payout.toDocument());
    if (result.isDuplicateKey) {
      throw const PayoutDuplicateKeyException();
    }
    if (!result.isSuccess) {
      throw const PayoutWriteException();
    }
    return payout;
  }

  @override
  Future<PayoutRequest?> cancelRequested({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    return _update(
      selector: <String, dynamic>{
        '_id': id,
        'cleaner_user_id': cleanerUserId,
        'status': PayoutStatus.requested.wireValue,
        'payout_active': true,
      },
      set: <String, dynamic>{
        'status': PayoutStatus.cancelled.wireValue,
        'payout_active': false,
        'cancelled_at': utc,
        'updated_at': utc,
      },
    );
  }

  @override
  Future<PayoutRequest?> startProcessing({
    required ObjectId id,
    required ObjectId adminUserId,
    required String provider,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    return _update(
      selector: <String, dynamic>{
        '_id': id,
        'status': PayoutStatus.requested.wireValue,
        'payout_active': true,
      },
      set: <String, dynamic>{
        'status': PayoutStatus.processing.wireValue,
        'payout_active': true,
        'provider': provider,
        'processed_by': adminUserId,
        'processing_at': utc,
        'updated_at': utc,
      },
    );
  }

  @override
  Future<PayoutRequest?> attachProviderPayoutId({
    required ObjectId id,
    required String providerPayoutId,
    required DateTime now,
  }) {
    return _update(
      selector: <String, dynamic>{
        '_id': id,
        'status': PayoutStatus.processing.wireValue,
        'payout_active': true,
      },
      set: <String, dynamic>{
        'provider_payout_id': providerPayoutId,
        'updated_at': now.toUtc(),
      },
    );
  }

  @override
  Future<PayoutRequest?> markPaid({
    required ObjectId id,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    return _update(
      selector: <String, dynamic>{
        '_id': id,
        'status': PayoutStatus.processing.wireValue,
        'payout_active': true,
      },
      set: <String, dynamic>{
        'status': PayoutStatus.paid.wireValue,
        'payout_active': false,
        'paid_at': utc,
        'updated_at': utc,
      },
    );
  }

  @override
  Future<PayoutRequest?> markFailed({
    required ObjectId id,
    required DateTime now,
    String? failureCode,
    String? failureMessage,
  }) {
    final utc = now.toUtc();
    return _update(
      selector: <String, dynamic>{
        '_id': id,
        'status': PayoutStatus.processing.wireValue,
        'payout_active': true,
      },
      set: <String, dynamic>{
        'status': PayoutStatus.failed.wireValue,
        'payout_active': false,
        'failed_at': utc,
        'failure_code': failureCode,
        'failure_message': failureMessage,
        'updated_at': utc,
      },
    );
  }

  @override
  Future<PayoutRequest?> rejectRequested({
    required ObjectId id,
    required ObjectId adminUserId,
    required String reason,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    return _update(
      selector: <String, dynamic>{
        '_id': id,
        'status': PayoutStatus.requested.wireValue,
        'payout_active': true,
      },
      set: <String, dynamic>{
        'status': PayoutStatus.rejected.wireValue,
        'payout_active': false,
        'rejected_at': utc,
        'rejection_reason': reason,
        'processed_by': adminUserId,
        'updated_at': utc,
      },
    );
  }

  @override
  Future<PayoutPage> listForCleaner({
    required ObjectId cleanerUserId,
    required int limit,
    PayoutStatus? status,
    String? currencyCode,
    ObjectId? after,
  }) {
    return _page(
      selector: <String, dynamic>{
        'cleaner_user_id': cleanerUserId,
        if (status != null) 'status': status.wireValue,
        if (currencyCode != null) 'currency_code': currencyCode,
      },
      limit: limit,
      after: after,
    );
  }

  @override
  Future<PayoutPage> adminPage({
    required int limit,
    PayoutStatus? status,
    String? currencyCode,
    ObjectId? cleanerUserId,
    ObjectId? after,
  }) {
    return _page(
      selector: <String, dynamic>{
        if (status != null) 'status': status.wireValue,
        if (currencyCode != null) 'currency_code': currencyCode,
        if (cleanerUserId != null) 'cleaner_user_id': cleanerUserId,
      },
      limit: limit,
      after: after,
    );
  }

  @override
  Future<Map<String, PayoutCurrencyTotals>> aggregatePayoutTotals(
    ObjectId cleanerUserId,
  ) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{'cleaner_user_id': cleanerUserId},
    );
    final totals = <String, PayoutCurrencyTotals>{};
    for (final document in documents) {
      final payout = PayoutRequest.fromDocument(document);
      final acc = totals.putIfAbsent(
        payout.currencyCode,
        PayoutCurrencyTotals.new,
      );
      switch (payout.status) {
        case PayoutStatus.requested:
        case PayoutStatus.processing:
          acc.reservedMinor += payout.amountMinor;
        case PayoutStatus.paid:
          acc.paidOutMinor += payout.amountMinor;
        case PayoutStatus.failed:
        case PayoutStatus.cancelled:
        case PayoutStatus.rejected:
          break;
      }
    }
    return totals;
  }

  @override
  Future<Map<String, AdminFinancePayoutTotals>> aggregateAdminFinanceTotals({
    required DateTime from,
    required DateTime to,
    String? currencyCode,
  }) async {
    final selector = <String, dynamic>{
      if (currencyCode != null) 'currency_code': currencyCode,
    };
    final documents = await _documents.findMany(selector: selector);
    final totals = <String, AdminFinancePayoutTotals>{};
    final fromUtc = from.toUtc();
    final toUtc = to.toUtc();
    for (final document in documents) {
      final payout = PayoutRequest.fromDocument(document);
      final acc = totals.putIfAbsent(
        payout.currencyCode,
        AdminFinancePayoutTotals.new,
      );
      if (_inRange(payout.requestedAt, fromUtc, toUtc) &&
          payout.status == PayoutStatus.requested) {
        acc.requestedMinor += payout.amountMinor;
      }
      if (payout.processingAt != null &&
          _inRange(payout.processingAt!, fromUtc, toUtc) &&
          payout.status == PayoutStatus.processing) {
        acc.processingMinor += payout.amountMinor;
      }
      if (payout.paidAt != null && _inRange(payout.paidAt!, fromUtc, toUtc)) {
        acc.paidMinor += payout.amountMinor;
      }
      if (payout.failedAt != null &&
          _inRange(payout.failedAt!, fromUtc, toUtc)) {
        acc.failedMinor += payout.amountMinor;
      }
    }
    return totals;
  }

  Future<PayoutPage> _page({
    required Map<String, dynamic> selector,
    required int limit,
    ObjectId? after,
  }) async {
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
        .map(PayoutRequest.fromDocument)
        .toList();
    final nextCursor = documents.length > limit ? items.last.id.oid : null;
    return PayoutPage(items: items, nextCursor: nextCursor);
  }

  Future<PayoutRequest?> _update({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> set,
  }) async {
    final result = await _documents.updateOne(
      selector: selector,
      update: <String, dynamic>{r'$set': set},
    );
    if (!result.isSuccess && result.matched) {
      throw const PayoutWriteException();
    }
    if (!result.matched) {
      return null;
    }
    return _find(<String, dynamic>{'_id': selector['_id']});
  }

  Future<PayoutRequest?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return PayoutRequest.fromDocument(document);
  }

  static bool _inRange(DateTime value, DateTime from, DateTime to) {
    final utc = value.toUtc();
    return !utc.isBefore(from) && !utc.isAfter(to);
  }
}

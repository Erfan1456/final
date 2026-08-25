import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/data/earnings_ledger_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_summary.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_request.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent cleaner earnings and payout-request operations.
class CleanerPayoutService {
  /// Creates a cleaner payout service.
  CleanerPayoutService({
    required EarningsLedgerRepository ledger,
    required PayoutRepository payouts,
    DateTime Function()? clock,
  }) : _ledger = ledger,
       _payouts = payouts,
       _clock = clock ?? DateTime.now;

  final EarningsLedgerRepository _ledger;
  final PayoutRepository _payouts;
  final DateTime Function() _clock;

  /// Per-currency earnings summaries. Currencies are never combined.
  Future<Map<String, Object?>> summary({required UserAccount user}) async {
    final summaries = await currencySummaries(user.id);
    return <String, Object?>{
      'currencies': [for (final item in summaries) item.toJson()],
    };
  }

  /// Per-currency summaries including payout reservation.
  Future<List<CleanerCurrencyEarningsSummary>> currencySummaries(
    ObjectId cleanerUserId,
  ) async {
    final ledgerTotals = await _ledger.aggregateCleanerLedgerTotals(
      cleanerUserId,
    );
    final payoutTotals = await _payouts.aggregatePayoutTotals(cleanerUserId);
    final currencies = <String>{
      ...ledgerTotals.keys,
      ...payoutTotals.keys,
    }.toList()..sort();
    return [
      for (final currency in currencies)
        _merge(currency, ledgerTotals[currency], payoutTotals[currency]),
    ];
  }

  /// One-currency summary, or a zeroed summary when unused.
  Future<CleanerCurrencyEarningsSummary> summaryForCurrency({
    required ObjectId cleanerUserId,
    required String currencyCode,
  }) async {
    final all = await currencySummaries(cleanerUserId);
    for (final item in all) {
      if (item.currencyCode == currencyCode) {
        return item;
      }
    }
    return CleanerCurrencyEarningsSummary(
      currencyCode: currencyCode,
      grossEarnedMinor: 0,
      platformFeesMinor: 0,
      refundsGrossMinor: 0,
      cleanerRefundAdjustmentsMinor: 0,
      netLedgerMinor: 0,
      reservedPayoutMinor: 0,
      paidOutMinor: 0,
      availableBalanceMinor: 0,
    );
  }

  /// Cleaner ledger page.
  Future<Map<String, Object?>> listLedger({
    required UserAccount user,
    Object? currency,
    Object? entryType,
    Object? limitRaw,
    Object? after,
  }) async {
    final page = await _ledger.listForCleaner(
      cleanerUserId: user.id,
      limit: EarningsValidation.requireLimit(limitRaw),
      currencyCode: EarningsValidation.optionalCurrency(currency),
      entryType: EarningsValidation.optionalEntryType(entryType),
      after: EarningsValidation.optionalCursor(after),
    );
    return <String, Object?>{
      'items': [for (final item in page.items) item.toPublicJson()],
      'next_cursor': page.nextCursor,
    };
  }

  /// Cleaner payout list page.
  Future<Map<String, Object?>> listPayouts({
    required UserAccount user,
    Object? status,
    Object? currency,
    Object? limitRaw,
    Object? after,
  }) async {
    final page = await _payouts.listForCleaner(
      cleanerUserId: user.id,
      limit: PayoutValidation.requireLimit(limitRaw),
      status: PayoutValidation.optionalStatus(status),
      currencyCode: PayoutValidation.optionalCurrency(currency),
      after: PayoutValidation.optionalCursor(after),
    );
    return <String, Object?>{
      'items': [for (final item in page.items) item.toCleanerJson()],
      'next_cursor': page.nextCursor,
    };
  }

  /// One owned payout.
  Future<Map<String, Object?>> getPayout({
    required UserAccount user,
    required ObjectId payoutId,
  }) async {
    final payout = await _payouts.findOwnedById(
      id: payoutId,
      cleanerUserId: user.id,
    );
    if (payout == null) {
      throw const PayoutNotFoundException();
    }
    return payout.toCleanerJson();
  }

  /// Creates a payout request or returns an identical idempotent replay.
  Future<({Map<String, Object?> payout, bool created})> requestPayout({
    required UserAccount user,
    required String? idempotencyKeyRaw,
    required Object? amountRaw,
    required Object? currencyRaw,
  }) async {
    final idempotencyKey = PayoutValidation.requireIdempotencyKey(
      idempotencyKeyRaw,
    );
    final amountMinor = PayoutValidation.requireAmountMinor(amountRaw);
    final currencyCode = PayoutValidation.requireCurrencyCode(currencyRaw);
    final fingerprint = PayoutValidation.requestFingerprint(
      cleanerUserId: user.id,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
    );

    final existingByKey = await _payouts.findByCleanerIdempotency(
      cleanerUserId: user.id,
      clientIdempotencyKey: idempotencyKey,
    );
    if (existingByKey != null) {
      return _replayOrConflict(
        existing: existingByKey,
        fingerprint: fingerprint,
      );
    }

    final summary = await summaryForCurrency(
      cleanerUserId: user.id,
      currencyCode: currencyCode,
    );
    if (summary.availableBalanceMinor < 1 ||
        amountMinor > summary.availableBalanceMinor) {
      throw const InsufficientPayoutBalanceException();
    }

    final now = _clock().toUtc();
    final payout = PayoutRequest(
      id: ObjectId(),
      cleanerUserId: user.id,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      status: PayoutStatus.requested,
      attemptNumber: await _payouts.nextAttemptNumber(user.id),
      clientIdempotencyKey: idempotencyKey,
      requestFingerprint: fingerprint,
      payoutActive: true,
      requestedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    try {
      final created = await _payouts.createRequested(payout);
      return (payout: created.toCleanerJson(), created: true);
    } on PayoutDuplicateKeyException {
      return _recoverDuplicate(
        cleanerUserId: user.id,
        idempotencyKey: idempotencyKey,
        fingerprint: fingerprint,
      );
    }
  }

  /// Cancels a requested payout owned by the cleaner.
  Future<Map<String, Object?>> cancelPayout({
    required UserAccount user,
    required ObjectId payoutId,
  }) async {
    final updated = await _payouts.cancelRequested(
      id: payoutId,
      cleanerUserId: user.id,
      now: _clock().toUtc(),
    );
    if (updated != null) {
      return updated.toCleanerJson();
    }
    final existing = await _payouts.findOwnedById(
      id: payoutId,
      cleanerUserId: user.id,
    );
    if (existing == null) {
      throw const PayoutNotFoundException();
    }
    throw const InvalidPayoutStateException();
  }

  ({Map<String, Object?> payout, bool created}) _replayOrConflict({
    required PayoutRequest existing,
    required String fingerprint,
  }) {
    if (existing.requestFingerprint != fingerprint) {
      throw const IdempotencyKeyReusedException();
    }
    return (payout: existing.toCleanerJson(), created: false);
  }

  Future<({Map<String, Object?> payout, bool created})> _recoverDuplicate({
    required ObjectId cleanerUserId,
    required String idempotencyKey,
    required String fingerprint,
  }) async {
    final existing = await _payouts.findByCleanerIdempotency(
      cleanerUserId: cleanerUserId,
      clientIdempotencyKey: idempotencyKey,
    );
    if (existing != null) {
      return _replayOrConflict(existing: existing, fingerprint: fingerprint);
    }
    final active = await _payouts.findActiveForCleaner(cleanerUserId);
    if (active != null) {
      throw const PayoutAlreadyActiveException();
    }
    throw const PayoutWriteException();
  }

  static CleanerCurrencyEarningsSummary _merge(
    String currency,
    CurrencySummaryAccumulator? ledger,
    PayoutCurrencyTotals? payouts,
  ) {
    return (ledger ?? CurrencySummaryAccumulator(currency)
          ..reservedPayoutMinor = payouts?.reservedMinor ?? 0
          ..paidOutMinor = payouts?.paidOutMinor ?? 0)
        .toSummary();
  }
}

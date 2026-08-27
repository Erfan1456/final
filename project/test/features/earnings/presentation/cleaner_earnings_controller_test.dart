import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/earnings/data/earnings_api.dart';
import 'package:home_cleaning_marketplace/features/earnings/data/earnings_models.dart';
import 'package:home_cleaning_marketplace/features/earnings/presentation/cleaner_earnings_controller.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

class _FakeApi extends CleanerEarningsApi {
  _FakeApi() : super(Dio());

  EarningsSummary summary = EarningsSummary(
    currencies: [
      testEarningsSummary(),
      testEarningsSummary(currency: 'USD'),
    ],
  );
  EarningsLedgerPage ledger = EarningsLedgerPage(
    items: [testEarningsLedgerEntry()],
    nextCursor: 'next-ledger',
  );
  CleanerPayoutPage payouts = CleanerPayoutPage(
    items: [testCleanerPayout()],
    nextCursor: 'next-payout',
  );
  ApiFailure? nextError;
  int summaryCalls = 0;
  int ledgerCalls = 0;
  int payoutCalls = 0;
  int requestCalls = 0;
  String? lastIdempotencyKey;
  String? lastCurrency;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<EarningsSummary> getSummary() async {
    summaryCalls += 1;
    _throwIfNeeded();
    return summary;
  }

  @override
  Future<EarningsLedgerPage> getLedger({
    String? currency,
    String? entryType,
    int? limit,
    String? after,
  }) async {
    ledgerCalls += 1;
    lastCurrency = currency;
    _throwIfNeeded();
    return ledger;
  }

  @override
  Future<CleanerPayoutPage> listPayouts({
    String? status,
    String? currency,
    int? limit,
    String? after,
  }) async {
    payoutCalls += 1;
    _throwIfNeeded();
    return payouts;
  }

  @override
  Future<CleanerPayout> requestPayout({
    required int amountMinor,
    required String currencyCode,
    required String idempotencyKey,
  }) async {
    requestCalls += 1;
    lastIdempotencyKey = idempotencyKey;
    _throwIfNeeded();
    return testCleanerPayout();
  }

  @override
  Future<CleanerPayout> cancelPayout(String payoutId) async {
    _throwIfNeeded();
    return testCleanerPayout(status: 'cancelled');
  }
}

void main() {
  test('load summary, select currency, and paginate ledger', () async {
    final api = _FakeApi();
    final container = ProviderContainer(
      overrides: [
        ...authenticatedAuthOverrides(),
        cleanerEarningsApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      cleanerEarningsControllerProvider.notifier,
    );
    await controller.load();
    expect(
      container.read(cleanerEarningsControllerProvider).selectedCurrency,
      equals('BDT'),
    );
    await controller.selectCurrency('USD');
    expect(api.lastCurrency, equals('USD'));
    await controller.loadMoreLedger();
    expect(
      container.read(cleanerEarningsControllerProvider).ledger,
      hasLength(2),
    );
  });

  test(
    'request payout keeps one idempotency key and guards duplicates',
    () async {
      final api = _FakeApi();
      final container = ProviderContainer(
        overrides: [
          ...authenticatedAuthOverrides(),
          cleanerEarningsApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        cleanerEarningsControllerProvider.notifier,
      );
      controller.beginPayoutRequest(keyFactory: () => 'same-payout-key-16xx');
      await controller.requestPayout(amountMinor: 10000, currencyCode: 'BDT');
      expect(api.lastIdempotencyKey, equals('same-payout-key-16xx'));
      controller.state = controller.state.copyWith(saving: true);
      expect(
        await controller.requestPayout(amountMinor: 10000, currencyCode: 'BDT'),
        isFalse,
      );
      expect(api.requestCalls, equals(1));
    },
  );

  test('maps insufficient balance safely', () async {
    final api = _FakeApi()
      ..nextError = const ApiFailure(
        code: 'insufficient_payout_balance',
        message: 'Available payout balance is insufficient.',
      );
    final container = ProviderContainer(
      overrides: [
        ...authenticatedAuthOverrides(),
        cleanerEarningsApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      cleanerEarningsControllerProvider.notifier,
    );
    controller.beginPayoutRequest(keyFactory: () => 'same-payout-key-16xx');
    final ok = await controller.requestPayout(
      amountMinor: 10000,
      currencyCode: 'BDT',
    );
    expect(ok, isFalse);
    expect(
      container.read(cleanerEarningsControllerProvider).errorMessage,
      contains('insufficient'),
    );
  });
}

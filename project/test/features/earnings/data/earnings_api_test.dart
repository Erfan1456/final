import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/earnings/data/earnings_api.dart';
import 'package:home_cleaning_marketplace/features/earnings/data/earnings_models.dart';

import '../../../helpers/feature_test_fakes.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  Future<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

void main() {
  test('parses known enums and unknown values safely', () {
    expect(
      EarningsEntryType.fromWire('service_earning'),
      equals(EarningsEntryType.serviceEarning),
    );
    expect(
      EarningsEntryType.fromWire('refund_adjustment'),
      equals(EarningsEntryType.refundAdjustment),
    );
    expect(
      EarningsEntryType.fromWire('manual'),
      equals(EarningsEntryType.unknown),
    );
    expect(PayoutStatus.fromWire('requested'), equals(PayoutStatus.requested));
    expect(PayoutStatus.fromWire('stripe'), equals(PayoutStatus.unknown));
  });

  test('summary keeps currencies separate and allows negative balance', () {
    final summary = EarningsSummary.fromJson(<String, dynamic>{
      'currencies': [
        earningsCurrencyJson(),
        earningsCurrencyJson(currency: 'USD', available: -5000),
      ],
    });
    expect(summary.currencies, hasLength(2));
    expect(summary.currencies.first.currencyCode, equals('BDT'));
    expect(summary.currencies.last.availableBalanceMinor, equals(-5000));
    expect(
      jsonEncode(earningsCurrencyJson()),
      isNot(contains('source_event_key')),
    );
  });

  test('ledger parses refund adjustments as negative', () {
    final entry = EarningsLedgerEntry.fromJson(
      earningsLedgerJson(type: 'refund_adjustment', cleanerAmount: -17000),
    );
    expect(entry.entryType, equals(EarningsEntryType.refundAdjustment));
    expect(entry.isNegativeAdjustment, isTrue);
    expect(entry.cleanerAmountMinor, equals(-17000));
  });

  test('request payout sends Idempotency-Key and integer amount', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    final adapter = _Adapter((options) async {
      return jsonBody(<String, dynamic>{
        'data': <String, dynamic>{'payout': cleanerPayoutJson()},
      }, 201);
    });
    dio.httpClientAdapter = adapter;
    final api = CleanerEarningsApi(dio);
    final payout = await api.requestPayout(
      amountMinor: 10000,
      currencyCode: 'BDT',
      idempotencyKey: 'payout-idempotency-key1',
    );
    expect(payout.status, equals(PayoutStatus.requested));
    expect(
      adapter.requests.single.headers['Idempotency-Key'],
      equals('payout-idempotency-key1'),
    );
    expect(adapter.requests.single.data['amount_minor'], equals(10000));
  });

  test('maps insufficient balance without leaking Dio text', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    dio.httpClientAdapter = _Adapter((options) async {
      return jsonBody(<String, dynamic>{
        'error': <String, String>{'code': 'insufficient_payout_balance'},
      }, 409);
    });
    final api = CleanerEarningsApi(dio);
    try {
      await api.requestPayout(
        amountMinor: 10000,
        currencyCode: 'BDT',
        idempotencyKey: 'payout-idempotency-key1',
      );
      fail('expected ApiFailure');
    } on ApiFailure catch (error) {
      expect(error.code, equals('insufficient_payout_balance'));
      expect(error.message, contains('insufficient'));
      expect(error.toString(), isNot(contains('DioException')));
    }
  });
}

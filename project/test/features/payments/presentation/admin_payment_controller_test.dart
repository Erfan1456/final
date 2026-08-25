import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_api.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/admin_payment_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeAdminPaymentApi extends AdminPaymentApi {
  _FakeAdminPaymentApi() : super(Dio());

  AdminPaymentPage page = AdminPaymentPage(
    items: [testAdminPaymentSummary()],
    nextCursor: 'cursor-1',
  );
  AdminPaymentDetail detail = testAdminPaymentDetail();
  List<PaymentWebhookEventSummary> eventItems = [
    PaymentWebhookEventSummary.fromJson(webhookEventJson()),
  ];
  ApiFailure? nextError;
  int listCalls = 0;
  int detailCalls = 0;
  int eventCalls = 0;
  int refundCalls = 0;
  String? lastStatus;
  String? lastProvider;
  String? lastCurrency;
  String? lastAfter;
  String? lastIdempotencyKey;
  String? lastReason;
  int? lastAmount;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<AdminPaymentPage> list({
    String? status,
    String? provider,
    String? currency,
    String? bookingId,
    String? customerUserId,
    int? limit,
    String? after,
  }) async {
    listCalls += 1;
    lastStatus = status;
    lastProvider = provider;
    lastCurrency = currency;
    lastAfter = after;
    _throwIfNeeded();
    return page;
  }

  @override
  Future<AdminPaymentDetail> get(String paymentId) async {
    detailCalls += 1;
    _throwIfNeeded();
    return detail;
  }

  @override
  Future<List<PaymentWebhookEventSummary>> events(String paymentId) async {
    eventCalls += 1;
    _throwIfNeeded();
    return eventItems;
  }

  @override
  Future<AdminPaymentDetail> refund({
    required String paymentId,
    required String idempotencyKey,
    required String reason,
    int? amountMinor,
  }) async {
    refundCalls += 1;
    lastIdempotencyKey = idempotencyKey;
    lastReason = reason;
    lastAmount = amountMinor;
    _throwIfNeeded();
    return detail;
  }
}

void main() {
  late _FakeAdminPaymentApi api;
  late ProviderContainer container;

  setUp(() {
    api = _FakeAdminPaymentApi();
    container = ProviderContainer(
      overrides: [adminPaymentApiProvider.overrideWithValue(api)],
    );
  });

  tearDown(() => container.dispose());

  Future<AdminPaymentState> settle() async {
    container.listen(adminPaymentControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container.read(adminPaymentControllerProvider);
  }

  test('load returns the first page', () async {
    final state = await settle();
    expect(state.items, hasLength(1));
    expect(api.listCalls, equals(1));
  });

  test('filters and pagination pass query values', () async {
    await settle();
    await container
        .read(adminPaymentControllerProvider.notifier)
        .applyFilters(
          const AdminPaymentFilters(
            status: 'paid',
            provider: 'sandbox',
            currency: 'BDT',
          ),
        );
    expect(api.lastStatus, equals('paid'));
    expect(api.lastProvider, equals('sandbox'));
    expect(api.lastCurrency, equals('BDT'));
    await container.read(adminPaymentControllerProvider.notifier).loadMore();
    expect(api.lastAfter, equals('cursor-1'));
  });

  test('detail and events load together', () async {
    await settle();
    await container
        .read(adminPaymentControllerProvider.notifier)
        .loadDetail('507f1f77bcf86cd7994390d1');
    expect(api.detailCalls, equals(1));
    expect(api.eventCalls, equals(1));
    expect(
      container.read(adminPaymentControllerProvider).detail?.bookingId,
      equals('507f1f77bcf86cd799439091'),
    );
    expect(container.read(adminPaymentControllerProvider).events, hasLength(1));
  });

  test('refund reuses one idempotency key', () async {
    await settle();
    final notifier = container.read(adminPaymentControllerProvider.notifier);
    notifier.beginRefundAttempt(keyFactory: () => 'fixed-refund-key-16');
    final first = await notifier.refund(
      paymentId: '507f1f77bcf86cd7994390d1',
      reason: 'Customer requested a refund.',
      amountMinor: 100000,
    );
    expect(first, isTrue);
    expect(api.lastIdempotencyKey, equals('fixed-refund-key-16'));
    expect(api.lastAmount, equals(100000));
    expect(api.refundCalls, equals(1));
  });

  test('safe error is stored without raw exception text', () async {
    await settle();
    api.nextError = ApiFailure(
      code: 'invalid_refund_reason',
      message: messageForApiCode('invalid_refund_reason'),
    );
    final ok = await container
        .read(adminPaymentControllerProvider.notifier)
        .refund(paymentId: '507f1f77bcf86cd7994390d1', reason: 'no');
    expect(ok, isFalse);
    expect(
      container.read(adminPaymentControllerProvider).errorMessage,
      equals('Refund reason must be between 5 and 500 characters.'),
    );
    expect(
      container.read(adminPaymentControllerProvider).errorMessage,
      isNot(contains('Mongo')),
    );
  });
}

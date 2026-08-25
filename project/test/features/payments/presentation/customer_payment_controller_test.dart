import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_api.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeCustomerPaymentApi extends CustomerPaymentApi {
  _FakeCustomerPaymentApi() : super(Dio());

  PaymentHistory history = PaymentHistory(
    current: testPaymentAttempt(),
    attempts: [testPaymentAttempt()],
  );
  ApiFailure? nextError;
  Completer<void>? startGate;
  int getCalls = 0;
  int startCalls = 0;
  int cancelCalls = 0;
  String? lastIdempotencyKey;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<PaymentHistory> getPayment(String bookingId) async {
    getCalls += 1;
    _throwIfNeeded();
    return history;
  }

  @override
  Future<PaymentAttempt> startPayment({
    required String bookingId,
    required String idempotencyKey,
  }) async {
    startCalls += 1;
    lastIdempotencyKey = idempotencyKey;
    final gate = startGate;
    if (gate != null) {
      await gate.future;
    }
    _throwIfNeeded();
    return history.current ?? testPaymentAttempt();
  }

  @override
  Future<PaymentAttempt> cancelPayment(String bookingId) async {
    cancelCalls += 1;
    _throwIfNeeded();
    return testPaymentAttempt(status: 'cancelled');
  }
}

class _FakeSandboxApi extends SandboxPaymentApi {
  _FakeSandboxApi() : super(Dio());

  int successCalls = 0;
  int failureCalls = 0;
  ApiFailure? nextError;

  @override
  Future<PaymentAttempt> simulateSuccess(String paymentId) async {
    successCalls += 1;
    if (nextError != null) {
      throw nextError!;
    }
    return testPaymentAttempt(
      status: 'paid',
      paidAt: '2026-08-25T12:05:00.000Z',
    );
  }

  @override
  Future<PaymentAttempt> simulateFailure(String paymentId) async {
    failureCalls += 1;
    if (nextError != null) {
      throw nextError!;
    }
    return testPaymentAttempt(status: 'failed');
  }
}

void main() {
  late _FakeCustomerPaymentApi api;
  late _FakeSandboxApi sandbox;
  late ProviderContainer container;

  setUp(() {
    api = _FakeCustomerPaymentApi();
    sandbox = _FakeSandboxApi();
    container = ProviderContainer(
      overrides: [
        customerPaymentApiProvider.overrideWithValue(api),
        sandboxPaymentApiProvider.overrideWithValue(sandbox),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('load stores history', () async {
    await container
        .read(customerPaymentControllerProvider.notifier)
        .load('507f1f77bcf86cd799439091');
    expect(
      container.read(customerPaymentControllerProvider).current?.status,
      equals(PaymentStatus.pending),
    );
    expect(api.getCalls, equals(1));
  });

  test('start reuses one key and ignores duplicate presses', () async {
    api.startGate = Completer<void>();
    final notifier = container.read(customerPaymentControllerProvider.notifier);
    notifier.beginAttempt(keyFactory: () => 'fixed-payment-key-1');
    final first = notifier.startPayment('507f1f77bcf86cd799439091');
    await pumpEventQueue();
    final second = notifier.startPayment('507f1f77bcf86cd799439091');
    api.startGate!.complete();
    await Future.wait<PaymentAttempt?>([first, second]);
    expect(api.startCalls, equals(1));
    expect(api.lastIdempotencyKey, equals('fixed-payment-key-1'));
  });

  test('retry generates a new key', () async {
    final notifier = container.read(customerPaymentControllerProvider.notifier);
    notifier.beginAttempt(keyFactory: () => 'first-payment-key-1');
    await notifier.startPayment('507f1f77bcf86cd799439091');
    await notifier.retryPayment('507f1f77bcf86cd799439091');
    expect(api.startCalls, equals(2));
    expect(api.lastIdempotencyKey, isNot(equals('first-payment-key-1')));
  });

  test('cancel pending reloads history', () async {
    await container
        .read(customerPaymentControllerProvider.notifier)
        .cancelPayment('507f1f77bcf86cd799439091');
    expect(api.cancelCalls, equals(1));
    expect(api.getCalls, equals(1));
  });

  test('sandbox success and failure refresh history', () async {
    final notifier = container.read(customerPaymentControllerProvider.notifier);
    await notifier.simulateSuccess(
      '507f1f77bcf86cd799439091',
      '507f1f77bcf86cd7994390d1',
    );
    expect(sandbox.successCalls, equals(1));
    await notifier.simulateFailure(
      '507f1f77bcf86cd799439091',
      '507f1f77bcf86cd7994390d1',
    );
    expect(sandbox.failureCalls, equals(1));
    expect(api.getCalls, equals(2));
  });

  test('safe error is stored without raw exception text', () async {
    api.nextError = ApiFailure(
      code: 'booking_not_payable',
      message: messageForApiCode('booking_not_payable'),
    );
    container
        .read(customerPaymentControllerProvider.notifier)
        .beginAttempt(keyFactory: () => 'fixed-payment-key-1');
    final created = await container
        .read(customerPaymentControllerProvider.notifier)
        .startPayment('507f1f77bcf86cd799439091');
    expect(created, isNull);
    expect(
      container.read(customerPaymentControllerProvider).errorMessage,
      equals('This booking cannot be paid until it is confirmed.'),
    );
    expect(
      container.read(customerPaymentControllerProvider).errorMessage,
      isNot(contains('Mongo')),
    );
  });
}

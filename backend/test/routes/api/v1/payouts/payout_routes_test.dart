import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/finance/application/admin_finance_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/admin_payout_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/cleaner_payout_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/payout_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/sandbox_payout_simulation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_event_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/security/sandbox_payout_webhook_hmac.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../../routes/api/v1/admin/finance/summary.dart'
    as admin_finance;
import '../../../../../routes/api/v1/admin/payouts/index.dart' as admin_list;
import '../../../../../routes/api/v1/cleaner/earnings/summary.dart'
    as cleaner_summary;
import '../../../../../routes/api/v1/cleaner/payouts/index.dart'
    as cleaner_payouts;
import '../../../../../routes/api/v1/dev/payouts/[payoutId]/simulate.dart'
    as simulate_route;
import '../../../../../routes/api/v1/payouts/webhooks/sandbox.dart'
    as webhook_route;
import '../../../../helpers/account_route_test_utils.dart';
import '../../../../helpers/marketplace_test_fixtures.dart';
import '../../../../helpers/payment_test_fixtures.dart';
import '../../../../src/features/earnings/earnings_payout_test.dart';

class _MockContext extends Mock implements RequestContext {}

void main() {
  late FinanceTestStack stack;
  late AuthenticatedUserContext cleanerScoped;
  late AuthenticatedUserContext adminScoped;
  late ObjectId customerId;
  late ObjectId cleanerId;
  late ObjectId bookingId;

  setUp(() {
    stack = FinanceTestStack();
    customerId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
    cleanerId = ObjectId.fromHexString('507f1f77bcf86cd799439022');
    bookingId = ObjectId.fromHexString('507f1f77bcf86cd7994390b1');
    cleanerScoped = AuthenticatedUserContext(
      principal: fakePrincipal(role: UserRole.cleaner),
      currentUser: testUserAccount(id: cleanerId),
    );
    adminScoped = AuthenticatedUserContext(
      principal: fakePrincipal(role: UserRole.admin),
      currentUser: testUserAccount(role: UserRole.admin),
    );
  });

  Future<void> seedEarning() async {
    stack.bookings.documents.add(
      testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
        status: BookingStatus.completed,
        quotedTotalMinor: 100000,
      ).toDocument(),
    );
    stack.payments.documents.add(
      testPayment(
        bookingId: bookingId,
        customerId: customerId,
        cleanerId: cleanerId,
        status: PaymentStatus.paid,
        amountMinor: 100000,
      ).toDocument(),
    );
    await stack.earnings.ensureBookingEarning(bookingId);
  }

  RequestContext cleanerCtx(Request request) {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(
      () => context.read<AuthenticatedUserContext>(),
    ).thenReturn(cleanerScoped);
    when(
      () => context.read<CleanerPayoutService>(),
    ).thenReturn(stack.cleanerPayouts);
    return context;
  }

  RequestContext adminCtx(Request request) {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(
      () => context.read<AuthenticatedUserContext>(),
    ).thenReturn(adminScoped);
    when(
      () => context.read<AdminPayoutService>(),
    ).thenReturn(stack.adminPayouts);
    when(
      () => context.read<AdminFinanceService>(),
    ).thenReturn(stack.finance);
    return context;
  }

  test('GET cleaner earnings summary omits source_event_key', () async {
    await seedEarning();
    final response = await cleaner_summary.onRequest(
      cleanerCtx(
        Request(
          'GET',
          Uri.parse('http://localhost/api/v1/cleaner/earnings/summary'),
        ),
      ),
    );
    expect(response.statusCode, equals(HttpStatus.ok));
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    expect(jsonEncode(body), isNot(contains('source_event_key')));
    expect(jsonEncode(body), isNot(contains('profit')));
  });

  test('POST cleaner payout returns 201 then 200 on replay', () async {
    await seedEarning();
    final created = await cleaner_payouts.onRequest(
      cleanerCtx(
        Request(
          'POST',
          Uri.parse('http://localhost/api/v1/cleaner/payouts'),
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
            'Idempotency-Key': 'payout-idempotency1',
          },
          body: jsonEncode(<String, Object?>{
            'amount_minor': 10000,
            'currency_code': 'BDT',
          }),
        ),
      ),
    );
    expect(created.statusCode, equals(HttpStatus.created));
    final replay = await cleaner_payouts.onRequest(
      cleanerCtx(
        Request(
          'POST',
          Uri.parse('http://localhost/api/v1/cleaner/payouts'),
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
            'Idempotency-Key': 'payout-idempotency1',
          },
          body: jsonEncode(<String, Object?>{
            'amount_minor': 10000,
            'currency_code': 'BDT',
          }),
        ),
      ),
    );
    expect(replay.statusCode, equals(HttpStatus.ok));
    final body = jsonDecode(await created.body()) as Map<String, dynamic>;
    expect(jsonEncode(body), isNot(contains('client_idempotency_key')));
    expect(jsonEncode(body), isNot(contains('request_fingerprint')));
    expect(jsonEncode(body), isNot(contains(testSandboxPayoutWebhookSecret)));
  });

  test('sandbox payout webhook accepts a valid signature', () async {
    await seedEarning();
    final created = await stack.cleanerPayouts.requestPayout(
      user: testUserAccount(id: cleanerId),
      idempotencyKeyRaw: 'payout-idempotency1',
      amountRaw: 10000,
      currencyRaw: 'BDT',
    );
    final payoutId = ObjectId.fromHexString(created.payout['id']! as String);
    await stack.adminPayouts.process(
      admin: testUserAccount(role: UserRole.admin),
      payoutId: payoutId,
    );
    final payout = (await stack.payoutRepo.findById(payoutId))!;
    final dispatch = stack.sandbox.signEvent(
      eventId: 'evt_route_ok',
      eventType: PayoutWebhookEventType.payoutPaid,
      providerPayoutId: payout.providerPayoutId!,
      amountMinor: payout.amountMinor,
      currencyCode: payout.currencyCode,
    );
    final context = _MockContext();
    when(() => context.request).thenReturn(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/payouts/webhooks/sandbox'),
        headers: <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json',
          SandboxPayoutWebhookHmac.signatureHeaderName: dispatch.signature,
        },
        body: dispatch.rawBody,
      ),
    );
    when(
      () => context.read<PayoutWebhookService>(),
    ).thenReturn(stack.webhooks);
    final response = await webhook_route.onRequest(context);
    expect(response.statusCode, equals(HttpStatus.ok));
  });

  test('sandbox payout webhook rejects an invalid signature', () async {
    final context = _MockContext();
    when(() => context.request).thenReturn(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/payouts/webhooks/sandbox'),
        headers: <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json',
          SandboxPayoutWebhookHmac.signatureHeaderName: '00' * 32,
        },
        body: '{"event_id":"x"}',
      ),
    );
    when(
      () => context.read<PayoutWebhookService>(),
    ).thenReturn(stack.webhooks);
    final response = await webhook_route.onRequest(context);
    expect(response.statusCode, equals(HttpStatus.unauthorized));
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    expect(
      (body['error'] as Map)['code'],
      equals('invalid_payout_webhook_signature'),
    );
  });

  test('admin payout list defaults to requested and omits secrets', () async {
    await seedEarning();
    await stack.cleanerPayouts.requestPayout(
      user: testUserAccount(id: cleanerId),
      idempotencyKeyRaw: 'payout-idempotency1',
      amountRaw: 10000,
      currencyRaw: 'BDT',
    );
    final response = await admin_list.onRequest(
      adminCtx(
        Request('GET', Uri.parse('http://localhost/api/v1/admin/payouts')),
      ),
    );
    expect(response.statusCode, equals(HttpStatus.ok));
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    expect(jsonEncode(body), isNot(contains('client_idempotency_key')));
    expect(jsonEncode(body), isNot(contains(testSandboxPayoutWebhookSecret)));
    expect(
      (((body['data'] as Map)['items'] as List).first as Map)['status'],
      equals('requested'),
    );
  });

  test('admin finance summary uses platform_fee_minor not profit', () async {
    await seedEarning();
    final response = await admin_finance.onRequest(
      adminCtx(
        Request(
          'GET',
          Uri.parse('http://localhost/api/v1/admin/finance/summary'),
        ),
      ),
    );
    expect(response.statusCode, equals(HttpStatus.ok));
    final encoded = jsonEncode(jsonDecode(await response.body()));
    expect(encoded, contains('platform_fee_minor'));
    expect(encoded, isNot(contains('profit')));
  });

  test('dev simulate success goes through the webhook path', () async {
    final dev = FinanceTestStack(environment: 'development');
    dev.bookings.documents.add(
      testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
        status: BookingStatus.completed,
        quotedTotalMinor: 100000,
      ).toDocument(),
    );
    dev.payments.documents.add(
      testPayment(
        bookingId: bookingId,
        customerId: customerId,
        cleanerId: cleanerId,
        status: PaymentStatus.paid,
        amountMinor: 100000,
      ).toDocument(),
    );
    await dev.earnings.ensureBookingEarning(bookingId);
    final created = await dev.cleanerPayouts.requestPayout(
      user: testUserAccount(id: cleanerId),
      idempotencyKeyRaw: 'payout-idempotency1',
      amountRaw: 10000,
      currencyRaw: 'BDT',
    );
    final payoutId = created.payout['id']! as String;
    await dev.adminPayouts.process(
      admin: testUserAccount(role: UserRole.admin),
      payoutId: ObjectId.fromHexString(payoutId),
    );
    final context = _MockContext();
    when(() => context.request).thenReturn(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/dev/payouts/$payoutId/simulate'),
        headers: <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode(<String, String>{'result': 'success'}),
      ),
    );
    when(
      () => context.read<SandboxPayoutSimulationService>(),
    ).thenReturn(dev.simulation);
    final response = await simulate_route.onRequest(context, payoutId);
    expect(response.statusCode, equals(HttpStatus.ok));
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    expect(((body['data'] as Map)['payout'] as Map)['status'], equals('paid'));
    expect(dev.payoutEvents.documents, isNotEmpty);
  });
}

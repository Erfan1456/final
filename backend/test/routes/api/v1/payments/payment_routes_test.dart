import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/admin_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/customer_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/payment_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/sandbox_payment_simulation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_event_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/security/sandbox_webhook_hmac.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../../routes/api/v1/admin/payments/index.dart' as admin_list;
import '../../../../../routes/api/v1/customer/bookings/[bookingId]/payment/index.dart'
    as customer_payment;
import '../../../../../routes/api/v1/dev/payments/[paymentId]/simulate.dart'
    as simulate_route;
import '../../../../../routes/api/v1/payments/webhooks/sandbox.dart'
    as webhook_route;
import '../../../../helpers/account_route_test_utils.dart';
import '../../../../helpers/auth_route_test_utils.dart';
import '../../../../helpers/marketplace_test_fixtures.dart';
import '../../../../helpers/payment_test_fixtures.dart';

class _MockContext extends Mock implements RequestContext {}

void main() {
  late PaymentTestStack stack;
  late AuthenticatedUserContext customerScoped;
  late AuthenticatedUserContext adminScoped;
  late ObjectId customerId;
  late ObjectId cleanerId;
  late ObjectId bookingId;

  setUp(() {
    stack = PaymentTestStack();
    final customer = fakeAuthResult().user;
    customerId = customer.id;
    cleanerId = ObjectId.fromHexString('507f1f77bcf86cd799439022');
    bookingId = ObjectId.fromHexString('507f1f77bcf86cd7994390b1');
    stack.bookings.documents.add(
      testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
      ).toDocument(),
    );
    customerScoped = AuthenticatedUserContext(
      principal: fakePrincipal(),
      currentUser: customer,
    );
    adminScoped = AuthenticatedUserContext(
      principal: fakePrincipal(role: UserRole.admin),
      currentUser: testUserAccount(role: UserRole.admin),
    );
  });

  RequestContext customerCtx(Request request) {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(
      () => context.read<AuthenticatedUserContext>(),
    ).thenReturn(customerScoped);
    when(
      () => context.read<CustomerPaymentService>(),
    ).thenReturn(stack.customerPayments);
    return context;
  }

  test('POST customer payment returns 201 then 200 on replay', () async {
    final created = await customer_payment.onRequest(
      customerCtx(
        Request(
          'POST',
          Uri.parse(
            'http://localhost/api/v1/customer/bookings/${bookingId.oid}/payment',
          ),
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
            'Idempotency-Key': 'payment-idempotency-1',
          },
          body: '{}',
        ),
      ),
      bookingId.oid,
    );
    expect(created.statusCode, equals(HttpStatus.created));
    final replay = await customer_payment.onRequest(
      customerCtx(
        Request(
          'POST',
          Uri.parse(
            'http://localhost/api/v1/customer/bookings/${bookingId.oid}/payment',
          ),
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
            'Idempotency-Key': 'payment-idempotency-1',
          },
          body: '{}',
        ),
      ),
      bookingId.oid,
    );
    expect(replay.statusCode, equals(HttpStatus.ok));
    final body = jsonDecode(await created.body()) as Map<String, dynamic>;
    expect(jsonEncode(body), isNot(contains('client_idempotency_key')));
    expect(jsonEncode(body), isNot(contains(testSandboxWebhookSecret)));
  });

  test('sandbox webhook accepts a valid signature', () async {
    final started = await stack.customerPayments.startPayment(
      user: fakeAuthResult().user,
      bookingId: bookingId,
      idempotencyKeyRaw: 'payment-idempotency-1',
    );
    final payment = await stack.paymentRepo.findById(
      ObjectId.fromHexString(started.payment['id']! as String),
    );
    final dispatch = stack.sandbox.signEvent(
      eventId: 'evt_route_ok',
      eventType: PaymentWebhookEventType.paymentSucceeded,
      providerPaymentId: payment!.providerPaymentId!,
      amountMinor: payment.amountMinor,
      currencyCode: payment.currencyCode,
    );
    final context = _MockContext();
    when(() => context.request).thenReturn(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/payments/webhooks/sandbox'),
        headers: <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json',
          SandboxWebhookHmac.signatureHeaderName: dispatch.signature,
        },
        body: dispatch.rawBody,
      ),
    );
    when(
      () => context.read<PaymentWebhookService>(),
    ).thenReturn(stack.webhooks);
    final response = await webhook_route.onRequest(context);
    expect(response.statusCode, equals(HttpStatus.ok));
  });

  test('sandbox webhook rejects an invalid signature', () async {
    final context = _MockContext();
    when(() => context.request).thenReturn(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/payments/webhooks/sandbox'),
        headers: <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json',
          SandboxWebhookHmac.signatureHeaderName: '00' * 32,
        },
        body: '{"event_id":"x"}',
      ),
    );
    when(
      () => context.read<PaymentWebhookService>(),
    ).thenReturn(stack.webhooks);
    final response = await webhook_route.onRequest(context);
    expect(response.statusCode, equals(HttpStatus.unauthorized));
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    expect((body['error'] as Map)['code'], equals('invalid_webhook_signature'));
  });

  test('dev simulate success goes through the webhook path', () async {
    final started = await stack.customerPayments.startPayment(
      user: fakeAuthResult().user,
      bookingId: bookingId,
      idempotencyKeyRaw: 'payment-idempotency-1',
    );
    final paymentId = started.payment['id']! as String;
    final context = _MockContext();
    when(() => context.request).thenReturn(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/dev/payments/$paymentId/simulate'),
        headers: <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode(<String, String>{'result': 'success'}),
      ),
    );
    when(
      () => context.read<SandboxPaymentSimulationService>(),
    ).thenReturn(stack.simulation);
    final response = await simulate_route.onRequest(context, paymentId);
    expect(response.statusCode, equals(HttpStatus.ok));
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    expect(((body['data'] as Map)['payment'] as Map)['status'], equals('paid'));
  });

  test('admin payment list omits secrets', () async {
    await stack.customerPayments.startPayment(
      user: fakeAuthResult().user,
      bookingId: bookingId,
      idempotencyKeyRaw: 'payment-idempotency-1',
    );
    final context = _MockContext();
    when(() => context.request).thenReturn(
      Request(
        'GET',
        Uri.parse('http://localhost/api/v1/admin/payments'),
      ),
    );
    when(
      () => context.read<AuthenticatedUserContext>(),
    ).thenReturn(adminScoped);
    when(
      () => context.read<AdminPaymentService>(),
    ).thenReturn(stack.adminPayments);
    final response = await admin_list.onRequest(context);
    expect(response.statusCode, equals(HttpStatus.ok));
    final body = await response.body();
    expect(body, isNot(contains('client_idempotency_key')));
    expect(body, isNot(contains(testSandboxWebhookSecret)));
  });
}

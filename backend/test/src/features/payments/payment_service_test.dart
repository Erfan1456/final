import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/database/document_write_results.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/cleaner_booking_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/customer_booking_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/booking_cancellation_orchestrator.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/customer_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_event_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_processing_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../helpers/auth_route_test_utils.dart';
import '../../../helpers/marketplace_test_fixtures.dart';
import '../../../helpers/memory_collection_store.dart';
import '../../../helpers/payment_test_fixtures.dart';
import '../../../helpers/recording_notification_sink.dart';

void main() {
  late PaymentTestStack stack;
  late ObjectId customerId;
  late ObjectId cleanerId;
  late ObjectId bookingId;

  setUp(() {
    stack = PaymentTestStack();
    customerId = fakeAuthResult().user.id;
    cleanerId = ObjectId.fromHexString('507f1f77bcf86cd799439022');
    bookingId = ObjectId.fromHexString('507f1f77bcf86cd7994390b1');
    stack.bookings.documents.add(
      testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
      ).toDocument(),
    );
  });

  group('payment initialization', () {
    test('confirmed booking starts payment from quote amount', () async {
      final result = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      expect(result.created, isTrue);
      expect(result.payment['status'], equals('pending'));
      expect(result.payment['amount_minor'], equals(500000));
      expect(result.payment['currency_code'], equals('BDT'));
      expect(result.payment['attempt_number'], equals(1));
      expect(result.payment.containsKey('client_idempotency_key'), isFalse);
      final session =
          result.payment['sandbox_session']! as Map<String, Object?>;
      expect(session['simulation_available'], isTrue);
    });

    test('pending booking is not payable', () async {
      stack.bookings.documents
        ..clear()
        ..add(
          testConfirmedBooking(
            customerId: customerId,
            cleanerId: cleanerId,
            id: bookingId,
            status: BookingStatus.pending,
          ).toDocument(),
        );
      expect(
        () => stack.customerPayments.startPayment(
          user: fakeAuthResult().user,
          bookingId: bookingId,
          idempotencyKeyRaw: 'payment-idempotency-1',
        ),
        throwsA(isA<BookingNotPayableException>()),
      );
    });

    test('cancelled and completed bookings are not payable', () async {
      for (final status in [BookingStatus.cancelled, BookingStatus.completed]) {
        stack.bookings.documents
          ..clear()
          ..add(
            testConfirmedBooking(
              customerId: customerId,
              cleanerId: cleanerId,
              id: bookingId,
              status: status,
            ).toDocument(),
          );
        expect(
          () => stack.customerPayments.startPayment(
            user: fakeAuthResult().user,
            bookingId: bookingId,
            idempotencyKeyRaw: 'payment-idempotency-1',
          ),
          throwsA(isA<BookingNotPayableException>()),
        );
      }
    });

    test('foreign booking is hidden', () async {
      expect(
        () => stack.customerPayments.startPayment(
          user: testUserAccount(
            id: ObjectId.fromHexString('507f1f77bcf86cd799439099'),
            role: UserRole.customer,
          ),
          bookingId: bookingId,
          idempotencyKeyRaw: 'payment-idempotency-1',
        ),
        throwsA(isA<BookingNotFoundException>()),
      );
    });

    test('same idempotency key replays', () async {
      final first = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final second = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      expect(second.created, isFalse);
      expect(second.payment['id'], equals(first.payment['id']));
    });

    test('same key for a different booking conflicts', () async {
      await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final other = ObjectId.fromHexString('507f1f77bcf86cd7994390b2');
      stack.bookings.documents.add(
        testConfirmedBooking(
          customerId: customerId,
          cleanerId: cleanerId,
          id: other,
        ).toDocument(),
      );
      expect(
        () => stack.customerPayments.startPayment(
          user: fakeAuthResult().user,
          bookingId: other,
          idempotencyKeyRaw: 'payment-idempotency-1',
        ),
        throwsA(isA<IdempotencyKeyReusedException>()),
      );
    });

    test('duplicate insert race replays identical intent', () async {
      stack.payments.insertResult = const DocumentInsertResult.duplicate();
      stack.payments.documents.add(
        testPayment(
          bookingId: bookingId,
          customerId: customerId,
          cleanerId: cleanerId,
          fingerprint: 'will-be-wrong',
        ).toDocument(),
      );
      // Stored fingerprint will not match the computed fingerprint.
      expect(
        () => stack.customerPayments.startPayment(
          user: fakeAuthResult().user,
          bookingId: bookingId,
          idempotencyKeyRaw: 'payment-idempotency-1',
        ),
        throwsA(isA<IdempotencyKeyReusedException>()),
      );
    });

    test('active payment blocks a new attempt', () async {
      await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      expect(
        () => stack.customerPayments.startPayment(
          user: fakeAuthResult().user,
          bookingId: bookingId,
          idempotencyKeyRaw: 'payment-idempotency-2',
        ),
        throwsA(isA<PaymentAlreadyActiveException>()),
      );
    });

    test('already paid blocks another charge', () async {
      stack.payments.documents.add(
        testPayment(
          bookingId: bookingId,
          customerId: customerId,
          cleanerId: cleanerId,
          status: PaymentStatus.paid,
        ).toDocument(),
      );
      expect(
        () => stack.customerPayments.startPayment(
          user: fakeAuthResult().user,
          bookingId: bookingId,
          idempotencyKeyRaw: 'payment-idempotency-9',
        ),
        throwsA(isA<PaymentAlreadyPaidException>()),
      );
    });

    test('retry after failure increments attempt number', () async {
      stack.payments.documents.add(
        testPayment(
          bookingId: bookingId,
          customerId: customerId,
          cleanerId: cleanerId,
          status: PaymentStatus.failed,
        ).toDocument(),
      );
      final retry = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-2',
      );
      expect(retry.created, isTrue);
      expect(retry.payment['attempt_number'], equals(2));
    });

    test('sandbox is forbidden in production', () async {
      final production = PaymentTestStack(environment: 'production');
      production.bookings.documents.add(
        testConfirmedBooking(
          customerId: customerId,
          cleanerId: cleanerId,
          id: bookingId,
        ).toDocument(),
      );
      final unavailable = CustomerPaymentService(
        bookings: production.bookingRepo,
        payments: production.paymentRepo,
        provider: null,
        config: testPaymentConfig(environment: 'production'),
      );
      expect(
        () => unavailable.startPayment(
          user: fakeAuthResult().user,
          bookingId: bookingId,
          idempotencyKeyRaw: 'payment-idempotency-1',
        ),
        throwsA(isA<PaymentProviderUnavailableException>()),
      );
    });
  });

  group('webhooks', () {
    test('success event marks paid', () async {
      final started = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final stored = stack.paymentRepo.findById(
        ObjectId.fromHexString(started.payment['id']! as String),
      );
      final payment = await stored;
      final dispatch = stack.sandbox.signEvent(
        eventId: 'evt_success_1',
        eventType: PaymentWebhookEventType.paymentSucceeded,
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      final updated = await stack.paymentRepo.findById(payment.id);
      expect(updated!.status, equals(PaymentStatus.paid));
      expect(updated.paidAt, isNotNull);
    });

    test('failed event marks failed', () async {
      final started = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final payment = await stack.paymentRepo.findById(
        ObjectId.fromHexString(started.payment['id']! as String),
      );
      final dispatch = stack.sandbox.signEvent(
        eventId: 'evt_fail_1',
        eventType: PaymentWebhookEventType.paymentFailed,
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
        failureCode: 'sandbox_failure',
        failureMessage: 'declined',
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      expect(
        (await stack.paymentRepo.findById(payment.id))!.status,
        equals(PaymentStatus.failed),
      );
    });

    test('paid webhook notifies once; invalid signature does not', () async {
      final sink = RecordingNotificationSink();
      stack = PaymentTestStack(notifications: sink);
      stack.bookings.documents.add(
        testConfirmedBooking(
          customerId: customerId,
          cleanerId: cleanerId,
          id: bookingId,
        ).toDocument(),
      );
      expect(
        () => stack.webhooks.process(
          rawBodyBytes: utf8.encode('{"event_id":"x"}'),
          signatureHeader: '00' * 32,
        ),
        throwsA(isA<InvalidWebhookSignatureException>()),
      );
      expect(sink.created, isEmpty);
      final started = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final payment = await stack.paymentRepo.findById(
        ObjectId.fromHexString(started.payment['id']! as String),
      );
      final dispatch = stack.sandbox.signEvent(
        eventId: 'evt_notify_paid',
        eventType: PaymentWebhookEventType.paymentSucceeded,
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      expect(
        sink.created.where(
          (row) => row['type'] == NotificationType.paymentPaid,
        ),
        hasLength(1),
      );
      expect(sink.created.single['user_id'], customerId);
    });

    test('invalid signature is rejected', () async {
      expect(
        () => stack.webhooks.process(
          rawBodyBytes: utf8.encode('{"event_id":"x"}'),
          signatureHeader: '00' * 32,
        ),
        throwsA(isA<InvalidWebhookSignatureException>()),
      );
    });

    test('missing signature is rejected', () async {
      expect(
        () => stack.webhooks.process(
          rawBodyBytes: utf8.encode('{"event_id":"x"}'),
          signatureHeader: null,
        ),
        throwsA(isA<InvalidWebhookSignatureException>()),
      );
    });

    test('amount mismatch is rejected without updating payment', () async {
      final started = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final payment = await stack.paymentRepo.findById(
        ObjectId.fromHexString(started.payment['id']! as String),
      );
      final dispatch = stack.sandbox.signEvent(
        eventId: 'evt_mismatch',
        eventType: PaymentWebhookEventType.paymentSucceeded,
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: 1,
        currencyCode: payment.currencyCode,
      );
      expect(
        () => stack.webhooks.process(
          rawBodyBytes: utf8.encode(dispatch.rawBody),
          signatureHeader: dispatch.signature,
        ),
        throwsA(isA<PaymentIntegrityMismatchException>()),
      );
      expect(
        (await stack.paymentRepo.findById(payment.id))!.status,
        equals(PaymentStatus.pending),
      );
    });

    test('currency mismatch is rejected', () async {
      final started = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final payment = await stack.paymentRepo.findById(
        ObjectId.fromHexString(started.payment['id']! as String),
      );
      final dispatch = stack.sandbox.signEvent(
        eventId: 'evt_currency',
        eventType: PaymentWebhookEventType.paymentSucceeded,
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: 'USD',
      );
      expect(
        () => stack.webhooks.process(
          rawBodyBytes: utf8.encode(dispatch.rawBody),
          signatureHeader: dispatch.signature,
        ),
        throwsA(isA<PaymentIntegrityMismatchException>()),
      );
    });

    test('duplicate event is idempotent', () async {
      final started = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final payment = await stack.paymentRepo.findById(
        ObjectId.fromHexString(started.payment['id']! as String),
      );
      final dispatch = stack.sandbox.signEvent(
        eventId: 'evt_dup',
        eventType: PaymentWebhookEventType.paymentSucceeded,
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      expect(stack.events.documents, hasLength(1));
      expect(
        (await stack.paymentRepo.findById(payment.id))!.status,
        equals(PaymentStatus.paid),
      );
    });

    test('same event id with different payload conflicts', () async {
      final started = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final payment = await stack.paymentRepo.findById(
        ObjectId.fromHexString(started.payment['id']! as String),
      );
      final first = stack.sandbox.signEvent(
        eventId: 'evt_conflict',
        eventType: PaymentWebhookEventType.paymentSucceeded,
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(first.rawBody),
        signatureHeader: first.signature,
      );
      final second = stack.sandbox.signEvent(
        eventId: 'evt_conflict',
        eventType: PaymentWebhookEventType.paymentFailed,
        providerPaymentId: payment.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
      );
      expect(
        () => stack.webhooks.process(
          rawBodyBytes: utf8.encode(second.rawBody),
          signatureHeader: second.signature,
        ),
        throwsA(isA<WebhookEventConflictException>()),
      );
    });

    test('stale failure after paid does not downgrade', () async {
      final started = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final payment = await stack.paymentRepo.findById(
        ObjectId.fromHexString(started.payment['id']! as String),
      );
      final success = stack.sandbox.signEvent(
        eventId: 'evt_paid',
        eventType: PaymentWebhookEventType.paymentSucceeded,
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(success.rawBody),
        signatureHeader: success.signature,
      );
      final failed = stack.sandbox.signEvent(
        eventId: 'evt_stale_fail',
        eventType: PaymentWebhookEventType.paymentFailed,
        providerPaymentId: payment.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(failed.rawBody),
        signatureHeader: failed.signature,
      );
      expect(
        (await stack.paymentRepo.findById(payment.id))!.status,
        equals(PaymentStatus.paid),
      );
    });

    test('unknown payment is ignored safely', () async {
      final dispatch = stack.sandbox.signEvent(
        eventId: 'evt_unknown',
        eventType: PaymentWebhookEventType.paymentSucceeded,
        providerPaymentId: 'sandbox_missing',
        amountMinor: 500000,
        currencyCode: 'BDT',
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      final stored = await stack.eventRepo.findByProviderEventId(
        provider: stack.sandbox.type,
        providerEventId: 'evt_unknown',
      );
      expect(
        stored!.processingStatus,
        equals(PaymentWebhookProcessingStatus.ignored),
      );
      expect(jsonEncode(stored.toAdminJson()), isNot(contains('signature')));
    });

    test('raw signature is not persisted', () async {
      final started = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final payment = await stack.paymentRepo.findById(
        ObjectId.fromHexString(started.payment['id']! as String),
      );
      final dispatch = stack.sandbox.signEvent(
        eventId: 'evt_nosig',
        eventType: PaymentWebhookEventType.paymentSucceeded,
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      final stored = stack.events.documents.first;
      expect(stored.containsKey('signature'), isFalse);
      expect(stored.containsKey('raw_signature'), isFalse);
      expect(
        stored.values.map((value) => value.toString()).join('|'),
        isNot(contains(dispatch.signature)),
      );
      expect(
        stored.values.map((value) => value.toString()).join('|'),
        isNot(contains(testSandboxWebhookSecret)),
      );
    });
  });

  group('refunds', () {
    Future<ObjectId> paidPayment() async {
      final started = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final payment = await stack.paymentRepo.findById(
        ObjectId.fromHexString(started.payment['id']! as String),
      );
      final dispatch = stack.sandbox.signEvent(
        eventId: 'evt_pay',
        eventType: PaymentWebhookEventType.paymentSucceeded,
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      return payment.id;
    }

    test('full refund', () async {
      final id = await paidPayment();
      final admin = testUserAccount(role: UserRole.admin);
      await stack.adminPayments.refund(
        user: admin,
        paymentId: id,
        idempotencyKeyRaw: 'refund-idempotency-01',
        amountRaw: null,
        reasonRaw: 'Customer requested a full refund.',
      );
      expect(
        (await stack.paymentRepo.findById(id))!.status,
        equals(PaymentStatus.refunded),
      );
    });

    test('partial then remaining refund', () async {
      final id = await paidPayment();
      final admin = testUserAccount(role: UserRole.admin);
      await stack.adminPayments.refund(
        user: admin,
        paymentId: id,
        idempotencyKeyRaw: 'refund-idempotency-01',
        amountRaw: 100000,
        reasonRaw: 'Partial refund for delay.',
      );
      expect(
        (await stack.paymentRepo.findById(id))!.status,
        equals(PaymentStatus.partiallyRefunded),
      );
      await stack.adminPayments.refund(
        user: admin,
        paymentId: id,
        idempotencyKeyRaw: 'refund-idempotency-02',
        amountRaw: 400000,
        reasonRaw: 'Remaining refund after complaint.',
      );
      expect(
        (await stack.paymentRepo.findById(id))!.status,
        equals(PaymentStatus.refunded),
      );
    });

    test('too-large, zero, and invalid status are rejected', () async {
      final id = await paidPayment();
      final admin = testUserAccount(role: UserRole.admin);
      expect(
        () => stack.adminPayments.refund(
          user: admin,
          paymentId: id,
          idempotencyKeyRaw: 'refund-idempotency-01',
          amountRaw: 9999999,
          reasonRaw: 'Too large refund request here.',
        ),
        throwsA(isA<InvalidRefundAmountException>()),
      );
      expect(
        () => stack.adminPayments.refund(
          user: admin,
          paymentId: id,
          idempotencyKeyRaw: 'refund-idempotency-02',
          amountRaw: 0,
          reasonRaw: 'Zero refund request is invalid.',
        ),
        throwsA(isA<InvalidRefundAmountException>()),
      );
      expect(
        () => stack.adminPayments.refund(
          user: admin,
          paymentId: id,
          idempotencyKeyRaw: 'refund-idempotency-03',
          amountRaw: null,
          reasonRaw: 'ab',
        ),
        throwsA(isA<InvalidRefundReasonException>()),
      );
    });

    test('refund idempotent replay and conflict', () async {
      final id = await paidPayment();
      final admin = testUserAccount(role: UserRole.admin);
      final first = await stack.adminPayments.refund(
        user: admin,
        paymentId: id,
        idempotencyKeyRaw: 'refund-idempotency-01',
        amountRaw: null,
        reasonRaw: 'Customer requested a full refund.',
      );
      final replay = await stack.adminPayments.refund(
        user: admin,
        paymentId: id,
        idempotencyKeyRaw: 'refund-idempotency-01',
        amountRaw: null,
        reasonRaw: 'Customer requested a full refund.',
      );
      expect(replay.created, isFalse);
      expect(
        () => stack.adminPayments.refund(
          user: admin,
          paymentId: id,
          idempotencyKeyRaw: 'refund-idempotency-01',
          amountRaw: 100000,
          reasonRaw: 'Different refund intent text.',
        ),
        throwsA(isA<IdempotencyKeyReusedException>()),
      );
      expect(first.created, isTrue);
    });

    test('duplicate refund webhook is harmless', () async {
      final id = await paidPayment();
      final payment = await stack.paymentRepo.findById(id);
      final dispatch = await stack.sandbox.refund(
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
        cumulativeRefundedAmountMinor: payment.amountMinor,
        fullRefund: true,
        reason: 'dup',
        eventId: 'evt_refund_dup',
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      expect(
        (await stack.paymentRepo.findById(id))!.status,
        equals(PaymentStatus.refunded),
      );
    });
  });

  group('booking cancellation integration', () {
    test('confirmed unpaid booking cancels normally', () async {
      final updated = await stack.cancellation.cancelByCustomer(
        user: fakeAuthResult().user,
        bookingId: bookingId,
      );
      expect(updated.status, equals(BookingStatus.cancelled));
    });

    test('pending payment is cancelled before booking cancellation', () async {
      await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final updated = await stack.cancellation.cancelByCustomer(
        user: fakeAuthResult().user,
        bookingId: bookingId,
      );
      expect(updated.status, equals(BookingStatus.cancelled));
      expect(
        (await stack.paymentRepo.listForBooking(bookingId)).first.status,
        equals(PaymentStatus.cancelled),
      );
    });

    test('paid payment refunds then booking cancels', () async {
      final started = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final payment = await stack.paymentRepo.findById(
        ObjectId.fromHexString(started.payment['id']! as String),
      );
      final dispatch = stack.sandbox.signEvent(
        eventId: 'evt_paid_cancel',
        eventType: PaymentWebhookEventType.paymentSucceeded,
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      final updated = await stack.cancellation.cancelByCustomer(
        user: fakeAuthResult().user,
        bookingId: bookingId,
      );
      expect(updated.status, equals(BookingStatus.cancelled));
      expect(
        (await stack.paymentRepo.findById(payment.id))!.status,
        equals(PaymentStatus.refunded),
      );
    });

    test('failed refund leaves booking confirmed', () async {
      final started = await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final payment = await stack.paymentRepo.findById(
        ObjectId.fromHexString(started.payment['id']! as String),
      );
      final dispatch = stack.sandbox.signEvent(
        eventId: 'evt_paid_fail_refund',
        eventType: PaymentWebhookEventType.paymentSucceeded,
        providerPaymentId: payment!.providerPaymentId!,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      final broken = PaymentTestStack();
      broken.bookings.documents.addAll(stack.bookings.documents);
      broken.payments.documents.addAll(stack.payments.documents);
      final failing = BookingCancellationOrchestrator(
        bookings: broken.bookingRepo,
        payments: broken.paymentRepo,
        webhooks: broken.webhooks,
        provider: null,
        clock: marketplaceTestNow,
      );
      expect(
        () => failing.cancelByCustomer(
          user: fakeAuthResult().user,
          bookingId: bookingId,
        ),
        throwsA(isA<PaymentRefundFailedException>()),
      );
      expect(
        (await broken.bookingRepo.findById(bookingId))!.status,
        equals(BookingStatus.confirmed),
      );
    });
  });

  group('admin payments', () {
    test('list filters and detail omit secrets', () async {
      await stack.customerPayments.startPayment(
        user: fakeAuthResult().user,
        bookingId: bookingId,
        idempotencyKeyRaw: 'payment-idempotency-1',
      );
      final list = await stack.adminPayments.list(status: 'pending');
      final items = list['items']! as List<Object?>;
      expect(items, hasLength(1));
      final encoded = jsonEncode(list);
      expect(encoded, isNot(contains('client_idempotency_key')));
      expect(encoded, isNot(contains('request_fingerprint')));
      expect(encoded, isNot(contains(testSandboxWebhookSecret)));
      final first = items.first! as Map<String, Object?>;
      final id = ObjectId.fromHexString(first['id']! as String);
      final detail = await stack.adminPayments.detail(id);
      expect(detail['payment'], isA<Map<String, Object?>>());
      expect(jsonEncode(detail), isNot(contains('client_idempotency_key')));
    });
  });

  group('customer/cleaner booking services with orchestrator', () {
    test('customer cancel of unpaid confirmed remains available', () async {
      final profiles = MemoryCollectionDocumentStore()
        ..documents.add(
          CustomerProfile(
            id: ObjectId(),
            userId: customerId,
            fullName: 'Pat Customer',
            createdAt: marketplaceTestNow(),
            updatedAt: marketplaceTestNow(),
          ).toDocument(),
        );
      final customerBookings = CustomerBookingService(
        addresses: MongoAddressRepository(
          documents: MemoryCollectionDocumentStore(),
        ),
        slots: MongoAvailabilityRepository(
          documents: MemoryCollectionDocumentStore(),
        ),
        users: MemoryUserRepository(),
        cleanerProfiles: MongoCleanerProfileRepository(
          documents: MemoryCollectionDocumentStore()
            ..documents.add(
              testCleanerProfileRecord(userId: cleanerId).toDocument(),
            ),
        ),
        services: MongoServiceRepository(
          documents: MemoryCollectionDocumentStore(),
        ),
        offerings: MongoCleanerServiceRepository(
          documents: MemoryCollectionDocumentStore(),
        ),
        bookings: stack.bookingRepo,
        cancellation: stack.cancellation,
      );
      final json = await customerBookings.cancelBooking(
        user: fakeAuthResult().user,
        bookingId: bookingId,
      );
      expect(json['status'], equals('cancelled'));
      final cleanerBookings = CleanerBookingService(
        bookings: stack.bookingRepo,
        customerProfiles: MongoCustomerProfileRepository(documents: profiles),
        cancellation: stack.cancellation,
      );
      expect(cleanerBookings, isNotNull);
    });
  });
}

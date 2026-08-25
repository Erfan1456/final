import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/application/earnings_settlement_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/data/earnings_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/data/earnings_ledger_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_entry_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_ledger_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/finance/application/admin_finance_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/admin_payout_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/cleaner_payout_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/payout_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/sandbox_payout_simulation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_provider_event_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_provider_event_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_event_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/provider/payout_provider_resolver.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/provider/sandbox_payout_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/security/sandbox_payout_webhook_hmac.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/mongo_user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../helpers/marketplace_test_fixtures.dart';
import '../../../helpers/memory_collection_store.dart';
import '../../../helpers/payment_test_fixtures.dart';
import '../../../helpers/recording_audit_sink.dart';
import '../../../helpers/recording_notification_sink.dart';

const String testSandboxPayoutWebhookSecret =
    'test-sandbox-payout-webhook-32b!!';

class MemoryPayoutTestUsers implements UserDocumentStore {
  final documents = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector) async {
    for (final document in documents) {
      if (document['_id'] == selector['_id']) {
        return Map<String, dynamic>.from(document);
      }
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> findMany(
    Map<String, dynamic> selector, {
    Map<String, int>? sort,
    int? limit,
  }) async {
    return [
      for (final document in documents) Map<String, dynamic>.from(document),
    ];
  }

  @override
  Future<UserInsertResult> insertOne(Map<String, dynamic> document) async {
    documents.add(document);
    return const UserInsertResult.success();
  }

  @override
  Future<UserUpdateResult> updateOne({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> update,
  }) async {
    return const UserUpdateResult.failed();
  }
}

class FinanceTestStack {
  FinanceTestStack({
    String environment = 'test',
    int commissionBps = 1500,
    DateTime Function()? clock,
    List<int> Function(int length)? randomBytesFn,
  }) : bookings = MemoryCollectionDocumentStore(),
       payments = MemoryCollectionDocumentStore(),
       ledger = MemoryCollectionDocumentStore(),
       payouts = MemoryCollectionDocumentStore(),
       payoutEvents = MemoryCollectionDocumentStore(),
       cleanerProfiles = MemoryCollectionDocumentStore(),
       users = MemoryPayoutTestUsers(),
       notifications = RecordingNotificationSink(),
       audit = RecordingAuditSink(),
       config = ServerConfig(
         environment: environment,
         allowedOrigins: const <String>[],
         sandboxPayoutWebhookSecret: testSandboxPayoutWebhookSecret,
         platformCommissionBps: commissionBps,
         hasExplicitPlatformCommissionBps: true,
       ) {
    final tick = clock ?? marketplaceTestNow;
    ledger.uniqueIndexes.add(const MemoryUniqueIndex(['source_event_key']));
    payouts.uniqueIndexes.addAll(const [
      MemoryUniqueIndex(['cleaner_user_id', 'client_idempotency_key']),
      MemoryUniqueIndex(
        ['cleaner_user_id'],
        partialEquals: <String, Object?>{'payout_active': true},
      ),
    ]);
    payoutEvents.uniqueIndexes.add(
      const MemoryUniqueIndex(['provider', 'provider_event_id']),
    );
    sandbox = SandboxPayoutProvider(
      webhookSecret: testSandboxPayoutWebhookSecret,
      randomBytesFn: randomBytesFn ?? _incrementingBytes,
      clock: tick,
    );
    bookingRepo = MongoBookingRepository(documents: bookings);
    paymentRepo = MongoPaymentRepository(documents: payments);
    ledgerRepo = MongoEarningsLedgerRepository(documents: ledger);
    payoutRepo = MongoPayoutRepository(documents: payouts);
    eventRepo = MongoPayoutProviderEventRepository(documents: payoutEvents);
    earnings = EarningsSettlementService(
      config: config,
      bookings: bookingRepo,
      payments: paymentRepo,
      ledger: ledgerRepo,
      clock: tick,
    );
    cleanerPayouts = CleanerPayoutService(
      ledger: ledgerRepo,
      payouts: payoutRepo,
      clock: tick,
    );
    webhooks = PayoutWebhookService(
      provider: sandbox,
      payouts: payoutRepo,
      events: eventRepo,
      notifications: notifications,
      clock: tick,
    );
    adminPayouts = AdminPayoutService(
      payouts: payoutRepo,
      events: eventRepo,
      cleanerPayouts: cleanerPayouts,
      cleanerProfiles: MongoCleanerProfileRepository(
        documents: cleanerProfiles,
      ),
      provider: sandbox,
      notifications: notifications,
      audit: audit,
      clock: tick,
    );
    simulation = SandboxPayoutSimulationService(
      config: config,
      payouts: payoutRepo,
      webhooks: webhooks,
      sandbox: sandbox,
      audit: audit,
    );
    finance = AdminFinanceService(
      ledger: ledgerRepo,
      payouts: payoutRepo,
      bookings: bookingRepo,
      payments: paymentRepo,
      cleanerPayouts: cleanerPayouts,
      cleanerProfiles: MongoCleanerProfileRepository(
        documents: cleanerProfiles,
      ),
      users: MongoUserRepository(documents: users),
      clock: tick,
    );
  }

  final MemoryCollectionDocumentStore bookings;
  final MemoryCollectionDocumentStore payments;
  final MemoryCollectionDocumentStore ledger;
  final MemoryCollectionDocumentStore payouts;
  final MemoryCollectionDocumentStore payoutEvents;
  final MemoryCollectionDocumentStore cleanerProfiles;
  final MemoryPayoutTestUsers users;
  final RecordingNotificationSink notifications;
  final RecordingAuditSink audit;
  final ServerConfig config;
  late final SandboxPayoutProvider sandbox;
  late final MongoBookingRepository bookingRepo;
  late final MongoPaymentRepository paymentRepo;
  late final MongoEarningsLedgerRepository ledgerRepo;
  late final MongoPayoutRepository payoutRepo;
  late final MongoPayoutProviderEventRepository eventRepo;
  late final EarningsSettlementService earnings;
  late final CleanerPayoutService cleanerPayouts;
  late final PayoutWebhookService webhooks;
  late final AdminPayoutService adminPayouts;
  late final SandboxPayoutSimulationService simulation;
  late final AdminFinanceService finance;

  int _nonce = 1;

  List<int> _incrementingBytes(int length) {
    _nonce += 17;
    return List<int>.generate(length, (index) => (_nonce + index) % 256);
  }
}

Payment paymentWithRefund(Payment payment, int refundedAmountMinor) {
  return Payment(
    id: payment.id,
    bookingId: payment.bookingId,
    customerUserId: payment.customerUserId,
    cleanerUserId: payment.cleanerUserId,
    provider: payment.provider,
    status: refundedAmountMinor >= payment.amountMinor
        ? PaymentStatus.refunded
        : PaymentStatus.partiallyRefunded,
    amountMinor: payment.amountMinor,
    currencyCode: payment.currencyCode,
    providerPaymentId: payment.providerPaymentId,
    attemptNumber: payment.attemptNumber,
    clientIdempotencyKey: payment.clientIdempotencyKey,
    requestFingerprint: payment.requestFingerprint,
    paymentActive: payment.paymentActive,
    settlementRecorded: payment.settlementRecorded,
    refundedAmountMinor: refundedAmountMinor,
    createdAt: payment.createdAt,
    updatedAt: payment.updatedAt,
  );
}

void main() {
  late FinanceTestStack stack;
  late ObjectId customerId;
  late ObjectId cleanerId;
  late ObjectId bookingId;

  setUp(() {
    stack = FinanceTestStack();
    customerId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
    cleanerId = ObjectId.fromHexString('507f1f77bcf86cd799439022');
    bookingId = ObjectId.fromHexString('507f1f77bcf86cd7994390b1');
  });

  Future<void> seedCompletedPaid({
    BookingStatus bookingStatus = BookingStatus.completed,
    PaymentStatus paymentStatus = PaymentStatus.paid,
    int amountMinor = 100000,
    String currencyCode = 'BDT',
    int refundedAmountMinor = 0,
  }) async {
    stack.bookings.documents.add(
      testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
        status: bookingStatus,
        quotedTotalMinor: amountMinor,
        currencyCode: currencyCode,
      ).toDocument(),
    );
    stack.payments.documents.add(
      testPayment(
        bookingId: bookingId,
        customerId: customerId,
        cleanerId: cleanerId,
        status: paymentStatus,
        amountMinor: amountMinor,
        refundedAmountMinor: refundedAmountMinor,
      ).toDocument(),
    );
  }

  group('earnings settlement', () {
    test('completed + paid creates one earning', () async {
      await seedCompletedPaid();
      await stack.earnings.ensureBookingEarning(bookingId);
      await stack.earnings.ensureBookingEarning(bookingId);
      expect(stack.ledger.documents, hasLength(1));
      final entry = await stack.ledgerRepo.findServiceEarningForBooking(
        bookingId,
      );
      expect(entry!.grossAmountMinor, equals(100000));
      expect(entry.commissionBps, equals(1500));
      expect(entry.platformFeeMinor, equals(15000));
      expect(entry.cleanerAmountMinor, equals(85000));
      expect(entry.toPublicJson().containsKey('source_event_key'), isFalse);
    });

    test('completed without payment is a no-op', () async {
      stack.bookings.documents.add(
        testConfirmedBooking(
          customerId: customerId,
          cleanerId: cleanerId,
          id: bookingId,
          status: BookingStatus.completed,
        ).toDocument(),
      );
      await stack.earnings.ensureBookingEarning(bookingId);
      expect(stack.ledger.documents, isEmpty);
    });

    test('paid without completed booking is a no-op', () async {
      await seedCompletedPaid(bookingStatus: BookingStatus.confirmed);
      await stack.earnings.ensureBookingEarning(bookingId);
      expect(stack.ledger.documents, isEmpty);
    });

    test('refund before earning is represented after creation', () async {
      await seedCompletedPaid(
        paymentStatus: PaymentStatus.partiallyRefunded,
        refundedAmountMinor: 20000,
      );
      await stack.earnings.ensureBookingEarning(bookingId);
      expect(stack.ledger.documents, hasLength(2));
      final rows = await stack.ledgerRepo.listForBooking(bookingId);
      final refund = rows.firstWhere(
        (row) => row.entryType == EarningsEntryType.refundAdjustment,
      );
      expect(refund.grossAmountMinor, equals(-20000));
      expect(refund.commissionBps, equals(1500));
      expect(refund.cleanerAmountMinor, equals(-17000));
    });
  });

  group('payout request and lifecycle', () {
    test('valid request reserves balance and replays the same key', () async {
      await seedCompletedPaid();
      await stack.earnings.ensureBookingEarning(bookingId);
      final cleaner = testUserAccount(id: cleanerId);
      final first = await stack.cleanerPayouts.requestPayout(
        user: cleaner,
        idempotencyKeyRaw: 'payout-idempotency1',
        amountRaw: 10000,
        currencyRaw: 'bdt',
      );
      expect(first.created, isTrue);
      final replay = await stack.cleanerPayouts.requestPayout(
        user: cleaner,
        idempotencyKeyRaw: 'payout-idempotency1',
        amountRaw: 10000,
        currencyRaw: 'BDT',
      );
      expect(replay.created, isFalse);
      final summary = await stack.cleanerPayouts.summaryForCurrency(
        cleanerUserId: cleanerId,
        currencyCode: 'BDT',
      );
      expect(summary.reservedPayoutMinor, equals(10000));
      expect(summary.availableBalanceMinor, equals(75000));
    });

    test('rejects invalid amounts and over-available requests', () async {
      await seedCompletedPaid();
      await stack.earnings.ensureBookingEarning(bookingId);
      final cleaner = testUserAccount(id: cleanerId);
      expect(
        () => stack.cleanerPayouts.requestPayout(
          user: cleaner,
          idempotencyKeyRaw: 'payout-idempotency1',
          amountRaw: '10000',
          currencyRaw: 'BDT',
        ),
        throwsA(isA<InvalidPayoutAmountException>()),
      );
      expect(
        () => stack.cleanerPayouts.requestPayout(
          user: cleaner,
          idempotencyKeyRaw: 'payout-idempotency1',
          amountRaw: 0,
          currencyRaw: 'BDT',
        ),
        throwsA(isA<InvalidPayoutAmountException>()),
      );
      expect(
        () => stack.cleanerPayouts.requestPayout(
          user: cleaner,
          idempotencyKeyRaw: 'payout-idempotency1',
          amountRaw: 85001,
          currencyRaw: 'BDT',
        ),
        throwsA(isA<InsufficientPayoutBalanceException>()),
      );
    });

    test('same key conflict and one active payout', () async {
      await seedCompletedPaid();
      await stack.earnings.ensureBookingEarning(bookingId);
      final cleaner = testUserAccount(id: cleanerId);
      await stack.cleanerPayouts.requestPayout(
        user: cleaner,
        idempotencyKeyRaw: 'payout-idempotency1',
        amountRaw: 10000,
        currencyRaw: 'BDT',
      );
      expect(
        () => stack.cleanerPayouts.requestPayout(
          user: cleaner,
          idempotencyKeyRaw: 'payout-idempotency1',
          amountRaw: 20000,
          currencyRaw: 'BDT',
        ),
        throwsA(isA<IdempotencyKeyReusedException>()),
      );
      expect(
        () => stack.cleanerPayouts.requestPayout(
          user: cleaner,
          idempotencyKeyRaw: 'payout-idempotency2',
          amountRaw: 10000,
          currencyRaw: 'BDT',
        ),
        throwsA(isA<PayoutAlreadyActiveException>()),
      );
    });

    test('cancel requested, hide foreign, processing cannot cancel', () async {
      await seedCompletedPaid();
      await stack.earnings.ensureBookingEarning(bookingId);
      final cleaner = testUserAccount(id: cleanerId);
      final created = await stack.cleanerPayouts.requestPayout(
        user: cleaner,
        idempotencyKeyRaw: 'payout-idempotency1',
        amountRaw: 10000,
        currencyRaw: 'BDT',
      );
      final payoutId = ObjectId.fromHexString(created.payout['id']! as String);
      final cancelled = await stack.cleanerPayouts.cancelPayout(
        user: cleaner,
        payoutId: payoutId,
      );
      expect(cancelled['status'], equals('cancelled'));
      expect(
        () => stack.cleanerPayouts.cancelPayout(
          user: testUserAccount(id: ObjectId()),
          payoutId: payoutId,
        ),
        throwsA(isA<PayoutNotFoundException>()),
      );
      final again = await stack.cleanerPayouts.requestPayout(
        user: cleaner,
        idempotencyKeyRaw: 'payout-idempotency2',
        amountRaw: 10000,
        currencyRaw: 'BDT',
      );
      final processingId = ObjectId.fromHexString(
        again.payout['id']! as String,
      );
      await stack.adminPayouts.process(
        admin: testUserAccount(role: UserRole.admin),
        payoutId: processingId,
      );
      expect(
        () => stack.cleanerPayouts.cancelPayout(
          user: cleaner,
          payoutId: processingId,
        ),
        throwsA(isA<InvalidPayoutStateException>()),
      );
    });
  });

  group('payout webhook', () {
    test('valid signature pays; missing signature rejected', () async {
      await seedCompletedPaid();
      await stack.earnings.ensureBookingEarning(bookingId);
      final cleaner = testUserAccount(id: cleanerId);
      final created = await stack.cleanerPayouts.requestPayout(
        user: cleaner,
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
        eventId: 'evt_paid_1',
        eventType: PayoutWebhookEventType.payoutPaid,
        providerPayoutId: payout.providerPayoutId!,
        amountMinor: payout.amountMinor,
        currencyCode: payout.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
      expect(
        (await stack.payoutRepo.findById(payoutId))!.status,
        equals(PayoutStatus.paid),
      );
      expect(
        () => stack.webhooks.process(
          rawBodyBytes: utf8.encode('{}'),
          signatureHeader: null,
        ),
        throwsA(isA<InvalidPayoutWebhookSignatureException>()),
      );
      expect(
        SandboxPayoutWebhookHmac.verify(
          secret: testSandboxPayoutWebhookSecret,
          bodyBytes: utf8.encode(dispatch.rawBody),
          providedHex: dispatch.signature,
        ),
        isTrue,
      );
    });

    test('stale paid after failed cannot resurrect', () async {
      await seedCompletedPaid();
      await stack.earnings.ensureBookingEarning(bookingId);
      final cleaner = testUserAccount(id: cleanerId);
      final created = await stack.cleanerPayouts.requestPayout(
        user: cleaner,
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
      final failed = stack.sandbox.signEvent(
        eventId: 'evt_failed',
        eventType: PayoutWebhookEventType.payoutFailed,
        providerPayoutId: payout.providerPayoutId!,
        amountMinor: payout.amountMinor,
        currencyCode: payout.currencyCode,
        failureCode: 'sandbox_failure',
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(failed.rawBody),
        signatureHeader: failed.signature,
      );
      final paid = stack.sandbox.signEvent(
        eventId: 'evt_paid_late',
        eventType: PayoutWebhookEventType.payoutPaid,
        providerPayoutId: payout.providerPayoutId!,
        amountMinor: payout.amountMinor,
        currencyCode: payout.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(paid.rawBody),
        signatureHeader: paid.signature,
      );
      expect(
        (await stack.payoutRepo.findById(payoutId))!.status,
        equals(PayoutStatus.failed),
      );
    });

    test('production resolver never returns sandbox', () {
      expect(
        const PayoutProviderResolver().resolve(
          const ServerConfig(
            environment: 'production',
            allowedOrigins: <String>[],
            sandboxPayoutWebhookSecret: testSandboxPayoutWebhookSecret,
          ),
        ),
        isNull,
      );
    });
  });

  group('reconciliation and indexes', () {
    test('detects missing earning and refund mismatch', () async {
      await seedCompletedPaid();
      var result = await stack.finance.reconciliation();
      var items = result['items']! as List<dynamic>;
      expect(
        (items.first as Map)['issue_type'],
        equals('missing_service_earning'),
      );
      await stack.earnings.ensureBookingEarning(bookingId);
      result = await stack.finance.reconciliation();
      items = result['items']! as List<dynamic>;
      expect(items, isEmpty);
      stack.payments.documents[0]['refunded_amount_minor'] = 10000;
      stack.payments.documents[0]['status'] = 'partially_refunded';
      result = await stack.finance.reconciliation();
      items = result['items']! as List<dynamic>;
      expect(
        (items.first as Map)['issue_type'],
        equals('refund_adjustment_mismatch'),
      );
    });

    test('cleaner finance rejects unknown users', () {
      expect(
        () => stack.finance.cleanerFinance(ObjectId()),
        throwsA(isA<UserNotFoundException>()),
      );
    });

    test('approved unique indexes are requested', () async {
      final names = <String>[];
      await ensureEarningsLedgerIndexes(
        ensureIndex:
            ({
              required String collectionName,
              required Map<String, dynamic> keys,
              required bool unique,
              required String name,
            }) async {
              names.add(name);
            },
      );
      expect(names, contains(earningsLedgerSourceEventUniqueIndexName));
      Map<String, dynamic>? activePartial;
      await ensurePayoutIndexes(
        ensureIndex:
            ({
              required String collectionName,
              required Map<String, dynamic> keys,
              required bool unique,
              required String name,
              Map<String, dynamic>? partialFilterExpression,
            }) async {
              if (name == payoutRequestsCleanerActiveUniqueIndexName) {
                activePartial = partialFilterExpression;
              }
            },
      );
      expect(
        activePartial,
        equals(const <String, dynamic>{'payout_active': true}),
      );
      final eventNames = <String>[];
      await ensurePayoutProviderEventIndexes(
        ensureIndex:
            ({
              required String collectionName,
              required Map<String, dynamic> keys,
              required bool unique,
              required String name,
            }) async {
              eventNames.add(name);
            },
      );
      expect(eventNames, contains(payoutEventsProviderEventUniqueIndexName));
    });
  });

  group('refund adjustments and balances', () {
    test('incremental refunds use original commission', () async {
      await seedCompletedPaid();
      await stack.earnings.ensureBookingEarning(bookingId);
      final payment = testPayment(
        bookingId: bookingId,
        customerId: customerId,
        cleanerId: cleanerId,
        status: PaymentStatus.partiallyRefunded,
        amountMinor: 100000,
        refundedAmountMinor: 20000,
      );
      await stack.earnings.applyRefundAdjustment(
        bookingId: bookingId,
        payment: payment,
        refundDeltaMinor: 20000,
        sourceEventKey: 'refund:sandbox:evt1',
      );
      await stack.earnings.applyRefundAdjustment(
        bookingId: bookingId,
        payment: paymentWithRefund(payment, 50000),
        refundDeltaMinor: 30000,
        sourceEventKey: 'refund:sandbox:evt2',
      );
      await stack.earnings.applyRefundAdjustment(
        bookingId: bookingId,
        payment: paymentWithRefund(payment, 100000),
        refundDeltaMinor: 50000,
        sourceEventKey: 'refund:sandbox:evt3',
      );
      await stack.earnings.applyRefundAdjustment(
        bookingId: bookingId,
        payment: paymentWithRefund(payment, 100000),
        refundDeltaMinor: 50000,
        sourceEventKey: 'refund:sandbox:evt3',
      );
      final rows = await stack.ledgerRepo.listForBooking(bookingId);
      final refunds = rows
          .where((row) => row.entryType == EarningsEntryType.refundAdjustment)
          .toList();
      expect(refunds, hasLength(3));
      expect(refunds.every((row) => row.commissionBps == 1500), isTrue);
      expect(
        refunds.fold<int>(0, (sum, row) => sum + row.grossAmountMinor),
        equals(-100000),
      );
      final summary = await stack.cleanerPayouts.summaryForCurrency(
        cleanerUserId: cleanerId,
        currencyCode: 'BDT',
      );
      expect(summary.netLedgerMinor, equals(0));
      expect(summary.availableBalanceMinor, equals(0));
    });

    test(
      'paid payout then refund yields a negative available balance',
      () async {
        await seedCompletedPaid();
        await stack.earnings.ensureBookingEarning(bookingId);
        final cleaner = testUserAccount(id: cleanerId);
        final created = await stack.cleanerPayouts.requestPayout(
          user: cleaner,
          idempotencyKeyRaw: 'payout-idempotency1',
          amountRaw: 85000,
          currencyRaw: 'BDT',
        );
        final payoutId = ObjectId.fromHexString(
          created.payout['id']! as String,
        );
        await stack.adminPayouts.process(
          admin: testUserAccount(role: UserRole.admin),
          payoutId: payoutId,
        );
        final payout = (await stack.payoutRepo.findById(payoutId))!;
        final paid = stack.sandbox.signEvent(
          eventId: 'evt_paid_full',
          eventType: PayoutWebhookEventType.payoutPaid,
          providerPayoutId: payout.providerPayoutId!,
          amountMinor: payout.amountMinor,
          currencyCode: payout.currencyCode,
        );
        await stack.webhooks.process(
          rawBodyBytes: utf8.encode(paid.rawBody),
          signatureHeader: paid.signature,
        );
        await stack.earnings.applyRefundAdjustment(
          bookingId: bookingId,
          payment: paymentWithRefund(
            testPayment(
              bookingId: bookingId,
              customerId: customerId,
              cleanerId: cleanerId,
              status: PaymentStatus.paid,
              amountMinor: 100000,
            ),
            100000,
          ),
          refundDeltaMinor: 100000,
          sourceEventKey: 'refund:sandbox:after_payout',
        );
        final summary = await stack.cleanerPayouts.summaryForCurrency(
          cleanerUserId: cleanerId,
          currencyCode: 'BDT',
        );
        expect(summary.availableBalanceMinor, equals(-85000));
        expect(
          () => stack.cleanerPayouts.requestPayout(
            user: cleaner,
            idempotencyKeyRaw: 'payout-idempotency9',
            amountRaw: 1,
            currencyRaw: 'BDT',
          ),
          throwsA(isA<InsufficientPayoutBalanceException>()),
        );
      },
    );

    test(
      'failed cancelled and rejected payouts release reserved balance',
      () async {
        await seedCompletedPaid();
        await stack.earnings.ensureBookingEarning(bookingId);
        final cleaner = testUserAccount(id: cleanerId);
        final admin = testUserAccount(role: UserRole.admin);
        final first = await stack.cleanerPayouts.requestPayout(
          user: cleaner,
          idempotencyKeyRaw: 'payout-idempotency1',
          amountRaw: 10000,
          currencyRaw: 'BDT',
        );
        await stack.cleanerPayouts.cancelPayout(
          user: cleaner,
          payoutId: ObjectId.fromHexString(first.payout['id']! as String),
        );
        var summary = await stack.cleanerPayouts.summaryForCurrency(
          cleanerUserId: cleanerId,
          currencyCode: 'BDT',
        );
        expect(summary.reservedPayoutMinor, equals(0));
        expect(summary.availableBalanceMinor, equals(85000));
        final second = await stack.cleanerPayouts.requestPayout(
          user: cleaner,
          idempotencyKeyRaw: 'payout-idempotency2',
          amountRaw: 10000,
          currencyRaw: 'BDT',
        );
        await stack.adminPayouts.reject(
          admin: admin,
          payoutId: ObjectId.fromHexString(second.payout['id']! as String),
          reasonRaw: 'Incomplete documentation for review.',
        );
        summary = await stack.cleanerPayouts.summaryForCurrency(
          cleanerUserId: cleanerId,
          currencyCode: 'BDT',
        );
        expect(summary.reservedPayoutMinor, equals(0));
        final third = await stack.cleanerPayouts.requestPayout(
          user: cleaner,
          idempotencyKeyRaw: 'payout-idempotency3',
          amountRaw: 10000,
          currencyRaw: 'BDT',
        );
        final processingId = ObjectId.fromHexString(
          third.payout['id']! as String,
        );
        await stack.adminPayouts.process(admin: admin, payoutId: processingId);
        final payout = (await stack.payoutRepo.findById(processingId))!;
        final failed = stack.sandbox.signEvent(
          eventId: 'evt_fail_release',
          eventType: PayoutWebhookEventType.payoutFailed,
          providerPayoutId: payout.providerPayoutId!,
          amountMinor: payout.amountMinor,
          currencyCode: payout.currencyCode,
          failureCode: 'sandbox_failure',
        );
        await stack.webhooks.process(
          rawBodyBytes: utf8.encode(failed.rawBody),
          signatureHeader: failed.signature,
        );
        summary = await stack.cleanerPayouts.summaryForCurrency(
          cleanerUserId: cleanerId,
          currencyCode: 'BDT',
        );
        expect(summary.reservedPayoutMinor, equals(0));
        expect(summary.paidOutMinor, equals(0));
        expect(summary.availableBalanceMinor, equals(85000));
      },
    );

    test('duplicate source event race still yields one earning', () async {
      await seedCompletedPaid();
      await stack.earnings.ensureBookingEarning(bookingId);
      final existing = (await stack.ledgerRepo.findServiceEarningForBooking(
        bookingId,
      ))!;
      expect(
        () => stack.ledgerRepo.append(
          EarningsLedgerEntry(
            id: ObjectId(),
            cleanerUserId: existing.cleanerUserId,
            bookingId: existing.bookingId,
            paymentId: existing.paymentId,
            entryType: existing.entryType,
            grossAmountMinor: existing.grossAmountMinor,
            commissionBps: existing.commissionBps,
            platformFeeMinor: existing.platformFeeMinor,
            cleanerAmountMinor: existing.cleanerAmountMinor,
            currencyCode: existing.currencyCode,
            sourceEventKey: existing.sourceEventKey,
            createdAt: existing.createdAt,
          ),
        ),
        throwsA(isA<EarningsDuplicateKeyException>()),
      );
      expect(stack.ledger.documents, hasLength(1));
    });
  });

  group('payout webhook integrity', () {
    Future<ObjectId> processingPayout() async {
      await seedCompletedPaid();
      await stack.earnings.ensureBookingEarning(bookingId);
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
      return payoutId;
    }

    test('invalid signature, amount mismatch, and duplicate events', () async {
      final payoutId = await processingPayout();
      final payout = (await stack.payoutRepo.findById(payoutId))!;
      expect(
        () => stack.webhooks.process(
          rawBodyBytes: utf8.encode('{"event_id":"x"}'),
          signatureHeader: '00' * 32,
        ),
        throwsA(isA<InvalidPayoutWebhookSignatureException>()),
      );
      final mismatch = stack.sandbox.signEvent(
        eventId: 'evt_mismatch',
        eventType: PayoutWebhookEventType.payoutPaid,
        providerPayoutId: payout.providerPayoutId!,
        amountMinor: payout.amountMinor + 1,
        currencyCode: payout.currencyCode,
      );
      expect(
        () => stack.webhooks.process(
          rawBodyBytes: utf8.encode(mismatch.rawBody),
          signatureHeader: mismatch.signature,
        ),
        throwsA(isA<PayoutIntegrityMismatchException>()),
      );
      final currency = stack.sandbox.signEvent(
        eventId: 'evt_currency',
        eventType: PayoutWebhookEventType.payoutPaid,
        providerPayoutId: payout.providerPayoutId!,
        amountMinor: payout.amountMinor,
        currencyCode: 'USD',
      );
      expect(
        () => stack.webhooks.process(
          rawBodyBytes: utf8.encode(currency.rawBody),
          signatureHeader: currency.signature,
        ),
        throwsA(isA<PayoutIntegrityMismatchException>()),
      );
      final paid = stack.sandbox.signEvent(
        eventId: 'evt_paid_ok',
        eventType: PayoutWebhookEventType.payoutPaid,
        providerPayoutId: payout.providerPayoutId!,
        amountMinor: payout.amountMinor,
        currencyCode: payout.currencyCode,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(paid.rawBody),
        signatureHeader: paid.signature,
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(paid.rawBody),
        signatureHeader: paid.signature,
      );
      expect(stack.payoutEvents.documents, hasLength(3));
      final conflict = stack.sandbox.signEvent(
        eventId: 'evt_paid_ok',
        eventType: PayoutWebhookEventType.payoutFailed,
        providerPayoutId: payout.providerPayoutId!,
        amountMinor: payout.amountMinor,
        currencyCode: payout.currencyCode,
        failureCode: 'sandbox_failure',
      );
      expect(
        () => stack.webhooks.process(
          rawBodyBytes: utf8.encode(conflict.rawBody),
          signatureHeader: conflict.signature,
        ),
        throwsA(isA<PayoutWebhookEventConflictException>()),
      );
      final stored = stack.payoutEvents.documents.toString();
      expect(stored, isNot(contains(testSandboxPayoutWebhookSecret)));
      expect(stored, isNot(contains('X-Sandbox-Payout-Signature')));
      final staleFailed = stack.sandbox.signEvent(
        eventId: 'evt_stale_failed',
        eventType: PayoutWebhookEventType.payoutFailed,
        providerPayoutId: payout.providerPayoutId!,
        amountMinor: payout.amountMinor,
        currencyCode: payout.currencyCode,
        failureCode: 'sandbox_failure',
      );
      await stack.webhooks.process(
        rawBodyBytes: utf8.encode(staleFailed.rawBody),
        signatureHeader: staleFailed.signature,
      );
      expect(
        (await stack.payoutRepo.findById(payoutId))!.status,
        equals(PayoutStatus.paid),
      );
    });

    test('development simulation uses the signed webhook path', () async {
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
      final payoutId = ObjectId.fromHexString(created.payout['id']! as String);
      await dev.adminPayouts.process(
        admin: testUserAccount(role: UserRole.admin),
        payoutId: payoutId,
      );
      expect(dev.simulation.isAvailable, isTrue);
      await dev.simulation.simulate(
        payoutId: payoutId,
        resultRaw: 'success',
        admin: testUserAccount(role: UserRole.admin),
      );
      expect(
        (await dev.payoutRepo.findById(payoutId))!.status,
        equals(PayoutStatus.paid),
      );
      expect(dev.payoutEvents.documents, isNotEmpty);
    });
  });
}

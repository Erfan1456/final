import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_address_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_service_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status_history_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/admin_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/booking_cancellation_orchestrator.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/customer_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/payment_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/sandbox_payment_simulation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_refund_request_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_webhook_event_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/sandbox_payment_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

import '../helpers/marketplace_test_fixtures.dart';
import '../helpers/memory_collection_store.dart';

/// Fake sandbox webhook secret used only in tests. Not a production secret.
const String testSandboxWebhookSecret = 'test-sandbox-webhook-secret-32b!!';

ServerConfig testPaymentConfig({
  String environment = 'test',
  String sandboxSecret = testSandboxWebhookSecret,
}) {
  return ServerConfig(
    environment: environment,
    allowedOrigins: const <String>[],
    sandboxPaymentWebhookSecret: sandboxSecret,
  );
}

Booking testConfirmedBooking({
  required ObjectId customerId,
  required ObjectId cleanerId,
  ObjectId? id,
  BookingStatus status = BookingStatus.confirmed,
  int quotedTotalMinor = 500000,
  String currencyCode = 'BDT',
}) {
  final now = marketplaceTestNow();
  return Booking(
    id: id ?? ObjectId.fromHexString('507f1f77bcf86cd7994390b1'),
    customerUserId: customerId,
    cleanerUserId: cleanerId,
    availabilitySlotId: ObjectId.fromHexString('507f1f77bcf86cd7994390c3'),
    serviceId: testHomeCleaningService().id,
    status: status,
    reservationActive: status.reservationActive,
    durationMinutes: 120,
    hourlyRateMinor: 250000,
    quotedTotalMinor: quotedTotalMinor,
    currencyCode: currencyCode,
    serviceSnapshot: BookingServiceSnapshot.fromService(
      testHomeCleaningService(),
    ),
    addressSnapshot: BookingAddressSnapshot.fromAddress(
      testAddress(userId: customerId),
    ),
    idempotencyKey: 'idempotency-key-16',
    requestFingerprint: 'a' * 64,
    startAt: DateTime.utc(2026, 9, 1, 3),
    endAt: DateTime.utc(2026, 9, 1, 5),
    statusHistory: [
      BookingStatusHistoryEntry(
        toStatus: status,
        actorUserId: customerId,
        actorRole: UserRole.customer,
        createdAt: now,
      ),
    ],
    createdAt: now,
    updatedAt: now,
  );
}

Payment testPayment({
  required ObjectId bookingId,
  required ObjectId customerId,
  required ObjectId cleanerId,
  ObjectId? id,
  PaymentStatus status = PaymentStatus.pending,
  int attemptNumber = 1,
  String idempotencyKey = 'payment-idempotency-1',
  String fingerprint =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  String? providerPaymentId = 'sandbox_abc',
  int amountMinor = 500000,
  int refundedAmountMinor = 0,
}) {
  final now = marketplaceTestNow();
  return Payment(
    id: id ?? ObjectId.fromHexString('507f1f77bcf86cd7994390d1'),
    bookingId: bookingId,
    customerUserId: customerId,
    cleanerUserId: cleanerId,
    provider: PaymentProviderType.sandbox,
    status: status,
    amountMinor: amountMinor,
    currencyCode: 'BDT',
    providerPaymentId: providerPaymentId,
    attemptNumber: attemptNumber,
    clientIdempotencyKey: idempotencyKey,
    requestFingerprint: fingerprint,
    paymentActive: status.paymentActive,
    settlementRecorded: status.settlementRecorded,
    refundedAmountMinor: refundedAmountMinor,
    createdAt: now,
    updatedAt: now,
  );
}

class PaymentTestStack {
  PaymentTestStack({
    String environment = 'test',
    DateTime Function()? clock,
    List<int> Function(int length)? randomBytesFn,
  }) : bookings = MemoryCollectionDocumentStore(),
       payments = MemoryCollectionDocumentStore(),
       events = MemoryCollectionDocumentStore(),
       refunds = MemoryCollectionDocumentStore(),
       config = testPaymentConfig(environment: environment) {
    final tick = clock ?? marketplaceTestNow;
    sandbox = SandboxPaymentProvider(
      webhookSecret: testSandboxWebhookSecret,
      randomBytesFn: randomBytesFn ?? _incrementingBytes,
      clock: tick,
    );
    paymentRepo = MongoPaymentRepository(documents: payments);
    eventRepo = MongoPaymentWebhookEventRepository(documents: events);
    refundRepo = MongoPaymentRefundRequestRepository(documents: refunds);
    bookingRepo = MongoBookingRepository(documents: bookings);
    webhooks = PaymentWebhookService(
      provider: sandbox,
      payments: paymentRepo,
      events: eventRepo,
      clock: tick,
    );
    customerPayments = CustomerPaymentService(
      bookings: bookingRepo,
      payments: paymentRepo,
      provider: sandbox,
      config: config,
      clock: tick,
    );
    adminPayments = AdminPaymentService(
      payments: paymentRepo,
      events: eventRepo,
      refundRequests: refundRepo,
      bookings: bookingRepo,
      webhooks: webhooks,
      provider: sandbox,
      clock: tick,
    );
    cancellation = BookingCancellationOrchestrator(
      bookings: bookingRepo,
      payments: paymentRepo,
      webhooks: webhooks,
      provider: sandbox,
      clock: tick,
    );
    simulation = SandboxPaymentSimulationService(
      config: config,
      payments: paymentRepo,
      webhooks: webhooks,
      sandbox: sandbox,
    );
  }

  final MemoryCollectionDocumentStore bookings;
  final MemoryCollectionDocumentStore payments;
  final MemoryCollectionDocumentStore events;
  final MemoryCollectionDocumentStore refunds;
  final ServerConfig config;
  late final SandboxPaymentProvider sandbox;
  late final MongoPaymentRepository paymentRepo;
  late final MongoPaymentWebhookEventRepository eventRepo;
  late final MongoPaymentRefundRequestRepository refundRepo;
  late final MongoBookingRepository bookingRepo;
  late final PaymentWebhookService webhooks;
  late final CustomerPaymentService customerPayments;
  late final AdminPaymentService adminPayments;
  late final BookingCancellationOrchestrator cancellation;
  late final SandboxPaymentSimulationService simulation;

  int _nonce = 1;

  List<int> _incrementingBytes(int length) {
    _nonce += 17;
    return List<int>.generate(length, (index) => (_nonce + index) % 256);
  }
}

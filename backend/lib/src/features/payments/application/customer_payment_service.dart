import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/payment_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/sandbox_payment_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent customer payment operations.
class CustomerPaymentService {
  /// Creates a customer payment service.
  CustomerPaymentService({
    required BookingRepository bookings,
    required PaymentRepository payments,
    required PaymentProvider? provider,
    required ServerConfig config,
    DateTime Function()? clock,
  }) : _bookings = bookings,
       _payments = payments,
       _provider = provider,
       _config = config,
       _clock = clock ?? DateTime.now;

  final BookingRepository _bookings;
  final PaymentRepository _payments;
  final PaymentProvider? _provider;
  final ServerConfig _config;
  final DateTime Function() _clock;

  /// Payment history for an owned booking.
  Future<Map<String, Object?>> getPayment({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    final booking = await _requireOwnedBooking(
      user: user,
      bookingId: bookingId,
    );
    final attempts = await _payments.listForBooking(booking.id);
    final current = _currentAttempt(attempts);
    return <String, Object?>{
      'current': current == null ? null : _toCustomerJson(current),
      'attempts': [for (final item in attempts) _toCustomerJson(item)],
    };
  }

  /// Starts a payment or returns an identical idempotent replay.
  Future<({Map<String, Object?> payment, bool created})> startPayment({
    required UserAccount user,
    required ObjectId bookingId,
    required String? idempotencyKeyRaw,
  }) async {
    final idempotencyKey = PaymentValidation.requireIdempotencyKey(
      idempotencyKeyRaw,
    );
    final booking = await _requireOwnedBooking(
      user: user,
      bookingId: bookingId,
    );
    if (booking.status != BookingStatus.confirmed) {
      throw const BookingNotPayableException();
    }
    final fingerprint = PaymentValidation.requestFingerprint(
      customerUserId: user.id,
      bookingId: booking.id,
    );

    final existingByKey = await _payments.findByCustomerIdempotency(
      customerUserId: user.id,
      clientIdempotencyKey: idempotencyKey,
    );
    if (existingByKey != null) {
      return _replayOrConflict(
        existing: existingByKey,
        fingerprint: fingerprint,
      );
    }

    final successful = await _payments.findSuccessfulForBooking(booking.id);
    if (successful != null) {
      throw const PaymentAlreadyPaidException();
    }
    final active = await _payments.findActiveForBooking(booking.id);
    if (active != null) {
      throw const PaymentAlreadyActiveException();
    }

    final provider = _provider;
    if (provider == null) {
      throw const PaymentProviderUnavailableException();
    }

    final now = _clock().toUtc();
    final paymentId = ObjectId();
    final session = await provider.createPayment(
      paymentId: paymentId,
      amountMinor: booking.quotedTotalMinor,
      currencyCode: booking.currencyCode,
    );
    final attemptNumber = await _payments.nextAttemptNumber(booking.id);
    final payment = Payment(
      id: paymentId,
      bookingId: booking.id,
      customerUserId: booking.customerUserId,
      cleanerUserId: booking.cleanerUserId,
      provider: provider.type,
      status: PaymentStatus.pending,
      amountMinor: booking.quotedTotalMinor,
      currencyCode: booking.currencyCode,
      providerPaymentId: session.providerPaymentId,
      providerReference: session.providerReference,
      attemptNumber: attemptNumber,
      clientIdempotencyKey: idempotencyKey,
      requestFingerprint: fingerprint,
      paymentActive: true,
      settlementRecorded: false,
      refundedAmountMinor: 0,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final created = await _payments.create(payment);
      return (payment: _toCustomerJson(created), created: true);
    } on PaymentDuplicateKeyException {
      return _recoverDuplicate(
        customerUserId: user.id,
        idempotencyKey: idempotencyKey,
        fingerprint: fingerprint,
        bookingId: booking.id,
      );
    }
  }

  /// Cancels a pending payment attempt. Does not cancel the booking.
  Future<Map<String, Object?>> cancelPayment({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    await _requireOwnedBooking(user: user, bookingId: bookingId);
    final active = await _payments.findActiveForBooking(bookingId);
    if (active == null || active.status != PaymentStatus.pending) {
      final attempts = await _payments.listForBooking(bookingId);
      if (attempts.isEmpty) {
        throw const PaymentNotFoundException();
      }
      throw const InvalidPaymentStateException();
    }
    final updated = await _payments.cancelPending(
      id: active.id,
      customerUserId: user.id,
      now: _clock().toUtc(),
    );
    if (updated == null) {
      throw const InvalidPaymentStateException();
    }
    return _toCustomerJson(updated);
  }

  Map<String, Object?> _toCustomerJson(Payment payment) {
    return payment.toPublicJson(
      sandboxSession: _sandboxSession(payment),
    );
  }

  Map<String, Object?>? _sandboxSession(Payment payment) {
    if (!_config.allowsSandboxPayments) {
      return null;
    }
    if (payment.provider.wireValue != 'sandbox') {
      return null;
    }
    if (payment.status != PaymentStatus.pending) {
      return null;
    }
    if (_provider is! SandboxPaymentProvider) {
      return null;
    }
    return <String, Object?>{
      'payment_id': payment.id.oid,
      'simulation_available': true,
    };
  }

  Payment? _currentAttempt(List<Payment> attempts) {
    for (final item in attempts) {
      if (item.paymentActive) {
        return item;
      }
    }
    return attempts.isEmpty ? null : attempts.first;
  }

  Future<Booking> _requireOwnedBooking({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    final booking = await _bookings.findCustomerBookingById(
      id: bookingId,
      customerUserId: user.id,
    );
    if (booking == null) {
      throw const BookingNotFoundException();
    }
    return booking;
  }

  ({Map<String, Object?> payment, bool created}) _replayOrConflict({
    required Payment existing,
    required String fingerprint,
  }) {
    if (existing.requestFingerprint != fingerprint) {
      throw const IdempotencyKeyReusedException();
    }
    return (payment: _toCustomerJson(existing), created: false);
  }

  Future<({Map<String, Object?> payment, bool created})> _recoverDuplicate({
    required ObjectId customerUserId,
    required String idempotencyKey,
    required String fingerprint,
    required ObjectId bookingId,
  }) async {
    final existing = await _payments.findByCustomerIdempotency(
      customerUserId: customerUserId,
      clientIdempotencyKey: idempotencyKey,
    );
    if (existing != null) {
      return _replayOrConflict(existing: existing, fingerprint: fingerprint);
    }
    if (await _payments.findSuccessfulForBooking(bookingId) != null) {
      throw const PaymentAlreadyPaidException();
    }
    if (await _payments.findActiveForBooking(bookingId) != null) {
      throw const PaymentAlreadyActiveException();
    }
    throw const PaymentWriteException();
  }
}

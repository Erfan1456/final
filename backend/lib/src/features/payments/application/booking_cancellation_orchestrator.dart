import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/payment_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/payment_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Coordinates payment settlement before confirmed-booking cancellation.
///
/// Payments remain the source of truth. Booking cancellation is not marked
/// until pending attempts are cancelled or successful payments are refunded.
class BookingCancellationOrchestrator {
  /// Creates an orchestrator.
  BookingCancellationOrchestrator({
    required BookingRepository bookings,
    required PaymentRepository payments,
    required PaymentWebhookService webhooks,
    required PaymentProvider? provider,
    DateTime Function()? clock,
  }) : _bookings = bookings,
       _payments = payments,
       _webhooks = webhooks,
       _provider = provider,
       _clock = clock ?? DateTime.now;

  final BookingRepository _bookings;
  final PaymentRepository _payments;
  final PaymentWebhookService _webhooks;
  final PaymentProvider? _provider;
  final DateTime Function() _clock;

  /// Settles payment state for a confirmed booking before cancellation.
  Future<void> prepareConfirmedCancellation(Booking booking) async {
    if (booking.status != BookingStatus.confirmed) {
      return;
    }

    final active = await _payments.findActiveForBooking(booking.id);
    if (active != null && active.paymentActive) {
      final cancelled = await _payments.cancelPending(
        id: active.id,
        customerUserId: booking.customerUserId,
        now: _clock().toUtc(),
      );
      if (cancelled == null && active.status == PaymentStatus.pending) {
        throw const InvalidPaymentStateException();
      }
    }

    final successful = await _payments.findSuccessfulForBooking(booking.id);
    if (successful == null) {
      return;
    }
    if (successful.status == PaymentStatus.refunded) {
      return;
    }
    if (!successful.status.allowsRefund) {
      throw const PaymentRefundFailedException();
    }

    await _refundRemaining(successful);
    final latest = await _payments.findById(successful.id);
    if (latest == null || latest.status != PaymentStatus.refunded) {
      throw const PaymentRefundFailedException();
    }
  }

  /// Customer cancel after payment-aware preparation.
  Future<Booking> cancelByCustomer({
    required UserAccount user,
    required ObjectId bookingId,
    String? reason,
  }) async {
    final booking = await _bookings.findCustomerBookingById(
      id: bookingId,
      customerUserId: user.id,
    );
    if (booking == null) {
      throw const BookingNotFoundException();
    }
    if (booking.status == BookingStatus.confirmed) {
      await prepareConfirmedCancellation(booking);
    }
    final updated = await _bookings.cancelByCustomer(
      id: bookingId,
      customerUserId: user.id,
      now: _clock().toUtc(),
      reason: reason,
    );
    if (updated != null) {
      return updated;
    }
    final existing = await _bookings.findCustomerBookingById(
      id: bookingId,
      customerUserId: user.id,
    );
    if (existing == null) {
      throw const BookingNotFoundException();
    }
    throw const InvalidBookingStateException();
  }

  /// Cleaner cancel after payment-aware preparation.
  Future<Booking> cancelByCleaner({
    required UserAccount user,
    required ObjectId bookingId,
    required String reason,
  }) async {
    final booking = await _bookings.findCleanerBookingById(
      id: bookingId,
      cleanerUserId: user.id,
    );
    if (booking == null) {
      throw const BookingNotFoundException();
    }
    if (booking.status == BookingStatus.confirmed) {
      await prepareConfirmedCancellation(booking);
    }
    final updated = await _bookings.cancelByCleaner(
      id: bookingId,
      cleanerUserId: user.id,
      now: _clock().toUtc(),
      reason: reason,
    );
    if (updated != null) {
      return updated;
    }
    final existing = await _bookings.findCleanerBookingById(
      id: bookingId,
      cleanerUserId: user.id,
    );
    if (existing == null) {
      throw const BookingNotFoundException();
    }
    throw const InvalidBookingStateException();
  }

  /// Administrator cancel after payment-aware confirmed-booking preparation.
  Future<Booking> cancelByAdmin({
    required UserAccount admin,
    required ObjectId bookingId,
    required String reason,
  }) async {
    final booking = await _bookings.findById(bookingId);
    if (booking == null) {
      throw const BookingNotFoundException();
    }
    if (booking.status != BookingStatus.pending &&
        booking.status != BookingStatus.confirmed) {
      throw const AdminBookingNotCancellableException();
    }
    if (booking.status == BookingStatus.confirmed) {
      await prepareConfirmedCancellation(booking);
    }
    final updated = await _bookings.cancelByAdmin(
      id: bookingId,
      adminUserId: admin.id,
      now: _clock().toUtc(),
      reason: reason,
    );
    if (updated != null) {
      return updated;
    }
    throw const InvalidBookingStateException();
  }

  Future<void> _refundRemaining(Payment payment) async {
    final remaining = payment.remainingRefundableMinor;
    if (remaining < 1) {
      return;
    }
    final provider = _provider;
    final providerPaymentId = payment.providerPaymentId;
    if (provider == null || providerPaymentId == null) {
      throw const PaymentRefundFailedException();
    }
    try {
      final dispatch = await provider.refund(
        providerPaymentId: providerPaymentId,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
        cumulativeRefundedAmountMinor: payment.amountMinor,
        fullRefund: true,
        reason: 'Booking cancellation refund',
        eventId: 'sandbox_cancel_refund_$providerPaymentId',
      );
      await _webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
    } on Exception {
      throw const PaymentRefundFailedException();
    }
  }
}

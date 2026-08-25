import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/payment_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_refund_request_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_webhook_event_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_refund_request.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/refund_request_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/payment_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent admin payment inspection and refunds.
class AdminPaymentService {
  /// Creates an admin payment service.
  AdminPaymentService({
    required PaymentRepository payments,
    required PaymentWebhookEventRepository events,
    required PaymentRefundRequestRepository refundRequests,
    required BookingRepository bookings,
    required PaymentWebhookService webhooks,
    required PaymentProvider? provider,
    DateTime Function()? clock,
  }) : _payments = payments,
       _events = events,
       _refundRequests = refundRequests,
       _bookings = bookings,
       _webhooks = webhooks,
       _provider = provider,
       _clock = clock ?? DateTime.now;

  final PaymentRepository _payments;
  final PaymentWebhookEventRepository _events;
  final PaymentRefundRequestRepository _refundRequests;
  final BookingRepository _bookings;
  final PaymentWebhookService _webhooks;
  final PaymentProvider? _provider;
  final DateTime Function() _clock;

  /// Admin payment list with keyset pagination.
  Future<Map<String, Object?>> list({
    Object? status,
    Object? provider,
    Object? currency,
    Object? bookingId,
    Object? customerUserId,
    Object? limitRaw,
    Object? after,
  }) async {
    final query = PaymentAdminListQuery.parse(
      status: status,
      provider: provider,
      currency: currency,
      bookingId: bookingId,
      customerUserId: customerUserId,
      limitRaw: limitRaw,
      after: after,
    );
    final page = await _payments.adminPage(
      limit: query.limit,
      status: query.status,
      provider: query.provider,
      currencyCode: query.currencyCode,
      bookingId: query.bookingId,
      customerUserId: query.customerUserId,
      after: query.after,
    );
    return <String, Object?>{
      'items': [for (final item in page.items) item.toAdminJson()],
      'next_cursor': page.nextCursor,
    };
  }

  /// Admin payment detail with booking and event summaries.
  Future<Map<String, Object?>> detail(ObjectId paymentId) async {
    final payment = await _requirePayment(paymentId);
    return _detailJson(payment);
  }

  /// Admin webhook event summaries for a payment.
  Future<Map<String, Object?>> events(ObjectId paymentId) async {
    final payment = await _requirePayment(paymentId);
    final providerPaymentId = payment.providerPaymentId;
    final items = providerPaymentId == null
        ? const <Map<String, Object?>>[]
        : [
            for (final event in await _events.listForProviderPaymentId(
              providerPaymentId,
            ))
              event.toAdminJson(),
          ];
    return <String, Object?>{'items': items};
  }

  /// Issues an idempotent refund and processes it through the webhook path.
  Future<({Map<String, Object?> payment, bool created})> refund({
    required UserAccount user,
    required ObjectId paymentId,
    required String? idempotencyKeyRaw,
    required Object? amountRaw,
    required Object? reasonRaw,
  }) async {
    final idempotencyKey = PaymentValidation.requireIdempotencyKey(
      idempotencyKeyRaw,
    );
    final reason = PaymentValidation.requireRefundReason(reasonRaw);
    final payment = await _requirePayment(paymentId);
    final existing = await _refundRequests.findByAdminIdempotency(
      adminUserId: user.id,
      idempotencyKey: idempotencyKey,
    );
    if (existing != null) {
      final replayAmount = amountRaw == null
          ? existing.amountMinor
          : PaymentValidation.parseProvidedRefundAmount(amountRaw);
      return _replayRefund(
        existing: existing,
        fingerprint: PaymentValidation.refundRequestFingerprint(
          paymentId: payment.id,
          amountMinor: replayAmount,
          reason: reason,
        ),
      );
    }
    if (!payment.status.allowsRefund) {
      throw const InvalidPaymentStateException();
    }
    final amountMinor = PaymentValidation.requireRefundAmount(
      payment: payment,
      amountRaw: amountRaw,
    );
    final fingerprint = PaymentValidation.refundRequestFingerprint(
      paymentId: payment.id,
      amountMinor: amountMinor,
      reason: reason,
    );

    final provider = _provider;
    if (provider == null) {
      throw const PaymentProviderUnavailableException();
    }
    final providerPaymentId = payment.providerPaymentId;
    if (providerPaymentId == null) {
      throw const PaymentProviderUnavailableException();
    }

    final now = _clock().toUtc();
    final request = PaymentRefundRequest(
      id: ObjectId(),
      paymentId: payment.id,
      adminUserId: user.id,
      idempotencyKey: idempotencyKey,
      amountMinor: amountMinor,
      reason: reason,
      requestFingerprint: fingerprint,
      status: RefundRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    PaymentRefundRequest stored;
    try {
      stored = await _refundRequests.create(request);
    } on PaymentDuplicateKeyException {
      final raced = await _refundRequests.findByAdminIdempotency(
        adminUserId: user.id,
        idempotencyKey: idempotencyKey,
      );
      if (raced == null) {
        throw const PaymentWriteException();
      }
      return _replayRefund(existing: raced, fingerprint: fingerprint);
    }

    final cumulative = payment.refundedAmountMinor + amountMinor;
    final fullRefund = cumulative >= payment.amountMinor;
    try {
      final dispatch = await provider.refund(
        providerPaymentId: providerPaymentId,
        amountMinor: payment.amountMinor,
        currencyCode: payment.currencyCode,
        cumulativeRefundedAmountMinor: cumulative,
        fullRefund: fullRefund,
        reason: reason,
        eventId: 'sandbox_refund_${stored.id.oid}',
      );
      await _webhooks.process(
        rawBodyBytes: utf8.encode(dispatch.rawBody),
        signatureHeader: dispatch.signature,
      );
    } on Exception {
      await _refundRequests.markFailed(id: stored.id, now: _clock().toUtc());
      throw const PaymentRefundFailedException();
    }

    await _refundRequests.markSucceeded(id: stored.id, now: _clock().toUtc());
    final updated = await _payments.findById(payment.id);
    if (updated == null) {
      throw const PaymentNotFoundException();
    }
    return (payment: await _detailJson(updated), created: true);
  }

  Future<Map<String, Object?>> _detailJson(Payment payment) async {
    final booking = await _bookings.findById(payment.bookingId);
    final providerPaymentId = payment.providerPaymentId;
    final events = providerPaymentId == null
        ? const <Map<String, Object?>>[]
        : [
            for (final event in await _events.listForProviderPaymentId(
              providerPaymentId,
            ))
              event.toAdminJson(),
          ];
    return <String, Object?>{
      'payment': payment.toAdminJson(
        bookingStatus: booking?.status.wireValue,
        serviceName: booking?.serviceSnapshot.name,
      ),
      'events': events,
    };
  }

  Future<Payment> _requirePayment(ObjectId paymentId) async {
    final payment = await _payments.findById(paymentId);
    if (payment == null) {
      throw const PaymentNotFoundException();
    }
    return payment;
  }

  Future<({Map<String, Object?> payment, bool created})> _replayRefund({
    required PaymentRefundRequest existing,
    required String fingerprint,
  }) async {
    if (existing.requestFingerprint != fingerprint) {
      throw const IdempotencyKeyReusedException();
    }
    final payment = await _requirePayment(existing.paymentId);
    return (payment: await _detailJson(payment), created: false);
  }
}

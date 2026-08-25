import 'package:home_cleaning_marketplace_api/src/features/earnings/application/earnings_settlement_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_sink.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_webhook_event_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_event.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_event_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_processing_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/payment_provider.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent webhook verification, idempotency, and state application.
class PaymentWebhookService {
  /// Creates a webhook service.
  PaymentWebhookService({
    required PaymentProvider? provider,
    required PaymentRepository payments,
    required PaymentWebhookEventRepository events,
    NotificationSink? notifications,
    EarningsSettlementService? earnings,
    DateTime Function()? clock,
  }) : _provider = provider,
       _payments = payments,
       _events = events,
       _notifications = notifications ?? const NoOpNotificationSink(),
       _earnings = earnings,
       _clock = clock ?? DateTime.now;

  final PaymentProvider? _provider;
  final PaymentRepository _payments;
  final PaymentWebhookEventRepository _events;
  final NotificationSink _notifications;
  final EarningsSettlementService? _earnings;
  final DateTime Function() _clock;

  /// Verifies, records, and applies a provider webhook.
  Future<void> process({
    required List<int> rawBodyBytes,
    required String? signatureHeader,
  }) async {
    final provider = _provider;
    if (provider == null) {
      throw const PaymentProviderUnavailableException();
    }

    final verified = provider.parseAndVerifyWebhook(
      rawBodyBytes: rawBodyBytes,
      signatureHeader: signatureHeader,
    );
    final payloadHash = PaymentValidation.payloadSha256(rawBodyBytes);
    final now = _clock().toUtc();

    final existing = await _events.findByProviderEventId(
      provider: verified.provider,
      providerEventId: verified.eventId,
    );
    if (existing != null) {
      if (existing.payloadSha256 != payloadHash) {
        throw const WebhookEventConflictException();
      }
      if (existing.processingStatus ==
              PaymentWebhookProcessingStatus.processed ||
          existing.processingStatus == PaymentWebhookProcessingStatus.ignored) {
        return;
      }
    }

    PaymentWebhookEvent event;
    try {
      event =
          existing ??
          await _events.createReceived(
            PaymentWebhookEvent(
              id: ObjectId(),
              provider: verified.provider,
              providerEventId: verified.eventId,
              eventType: verified.eventType.wireValue,
              providerPaymentId: verified.providerPaymentId,
              payloadSha256: payloadHash,
              processingStatus: PaymentWebhookProcessingStatus.received,
              createdAt: now,
            ),
          );
    } on PaymentDuplicateKeyException {
      final existing = await _events.findByProviderEventId(
        provider: verified.provider,
        providerEventId: verified.eventId,
      );
      if (existing == null) {
        throw const PaymentWriteException();
      }
      if (existing.payloadSha256 != payloadHash) {
        throw const WebhookEventConflictException();
      }
      if (existing.processingStatus ==
              PaymentWebhookProcessingStatus.processed ||
          existing.processingStatus == PaymentWebhookProcessingStatus.ignored) {
        return;
      }
      event = existing;
    }

    try {
      await _apply(verified: verified, event: event, now: now);
    } on PaymentIntegrityMismatchException {
      await _events.markFailed(id: event.id, now: now);
      rethrow;
    } on Exception {
      await _events.markFailed(id: event.id, now: now);
      rethrow;
    }
  }

  Future<void> _apply({
    required VerifiedWebhookEvent verified,
    required PaymentWebhookEvent event,
    required DateTime now,
  }) async {
    final payment = await _payments.findByProviderPaymentId(
      provider: verified.provider,
      providerPaymentId: verified.providerPaymentId,
    );
    if (payment == null) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }

    if (!_integrityMatches(payment, verified)) {
      throw const PaymentIntegrityMismatchException();
    }

    switch (verified.eventType) {
      case PaymentWebhookEventType.paymentSucceeded:
        await _applySucceeded(payment: payment, event: event, now: now);
      case PaymentWebhookEventType.paymentFailed:
        await _applyFailed(
          payment: payment,
          event: event,
          now: now,
          failureCode: verified.failureCode,
          failureMessage: verified.failureMessage,
        );
      case PaymentWebhookEventType.paymentRefunded:
        await _applyRefund(
          payment: payment,
          event: event,
          now: now,
          refundedAmountMinor: payment.amountMinor,
          fullRefund: true,
        );
      case PaymentWebhookEventType.paymentPartiallyRefunded:
        final cumulative =
            verified.refundedAmountMinor ?? payment.refundedAmountMinor;
        await _applyRefund(
          payment: payment,
          event: event,
          now: now,
          refundedAmountMinor: cumulative,
          fullRefund: cumulative >= payment.amountMinor,
        );
    }
  }

  Future<void> _applySucceeded({
    required Payment payment,
    required PaymentWebhookEvent event,
    required DateTime now,
  }) async {
    if (payment.status == PaymentStatus.paid ||
        payment.status == PaymentStatus.partiallyRefunded ||
        payment.status == PaymentStatus.refunded) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    if (payment.status == PaymentStatus.failed ||
        payment.status == PaymentStatus.cancelled) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    final updated = await _payments.markPaidFromWebhook(
      id: payment.id,
      now: now,
    );
    if (updated == null) {
      final latest = await _payments.findById(payment.id);
      if (latest != null && latest.status.settlementRecorded) {
        await _events.markIgnored(id: event.id, now: now);
        return;
      }
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    await _events.markProcessed(id: event.id, now: now);
    await _notifyCustomer(
      payment: updated,
      eventId: event.providerEventId,
      type: NotificationType.paymentPaid,
      title: 'Payment completed',
      body: 'Payment completed.',
    );
    await _earnings?.tryEnsureBookingEarning(updated.bookingId);
  }

  Future<void> _applyFailed({
    required Payment payment,
    required PaymentWebhookEvent event,
    required DateTime now,
    String? failureCode,
    String? failureMessage,
  }) async {
    if (payment.status.settlementRecorded ||
        payment.status == PaymentStatus.failed ||
        payment.status == PaymentStatus.cancelled) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    final updated = await _payments.markFailedFromWebhook(
      id: payment.id,
      now: now,
      failureCode: failureCode,
      failureMessage: failureMessage,
    );
    if (updated == null) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    await _events.markProcessed(id: event.id, now: now);
    await _notifyCustomer(
      payment: updated,
      eventId: event.providerEventId,
      type: NotificationType.paymentFailed,
      title: 'Payment failed',
      body: 'Payment could not be completed.',
    );
  }

  Future<void> _applyRefund({
    required Payment payment,
    required PaymentWebhookEvent event,
    required DateTime now,
    required int refundedAmountMinor,
    required bool fullRefund,
  }) async {
    if (payment.status == PaymentStatus.refunded) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    if (!payment.status.allowsRefund &&
        payment.status != PaymentStatus.refunded) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    final updated = await _payments.applyRefundFromWebhook(
      id: payment.id,
      refundedAmountMinor: refundedAmountMinor,
      fullRefund: fullRefund,
      now: now,
    );
    if (updated == null) {
      final latest = await _payments.findById(payment.id);
      if (latest != null && latest.status == PaymentStatus.refunded) {
        await _events.markIgnored(id: event.id, now: now);
        return;
      }
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    await _events.markProcessed(id: event.id, now: now);
    await _notifyCustomer(
      payment: updated,
      eventId: event.providerEventId,
      type: NotificationType.paymentRefunded,
      title: 'Payment refunded',
      body: fullRefund
          ? 'Your payment was refunded.'
          : 'A partial refund was issued.',
    );
    final delta = updated.refundedAmountMinor - payment.refundedAmountMinor;
    await _earnings?.tryApplyRefundAdjustment(
      bookingId: updated.bookingId,
      payment: updated,
      refundDeltaMinor: delta,
      sourceEventKey: EarningsValidation.refundEventSourceEventKey(
        provider: updated.provider.wireValue,
        providerEventId: event.providerEventId,
      ),
    );
  }

  Future<void> _notifyCustomer({
    required Payment payment,
    required String eventId,
    required NotificationType type,
    required String title,
    required String body,
  }) {
    return _notifications.notifyBestEffort(
      userId: payment.customerUserId,
      type: type,
      title: title,
      body: body,
      dedupeKey: 'payment-event:$eventId',
      resourceType: 'booking',
      resourceId: payment.bookingId,
    );
  }

  bool _integrityMatches(Payment payment, VerifiedWebhookEvent verified) {
    if (verified.amountMinor != null &&
        verified.amountMinor != payment.amountMinor) {
      return false;
    }
    if (verified.currencyCode != null &&
        verified.currencyCode != payment.currencyCode) {
      return false;
    }
    if (verified.provider != payment.provider) {
      return false;
    }
    return true;
  }
}

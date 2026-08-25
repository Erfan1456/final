import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_sink.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_provider_event_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_request.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_event.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_event_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_processing_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/provider/payout_provider.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent payout webhook verification, idempotency, and settlement.
class PayoutWebhookService {
  /// Creates a webhook service.
  PayoutWebhookService({
    required PayoutProvider? provider,
    required PayoutRepository payouts,
    required PayoutProviderEventRepository events,
    NotificationSink? notifications,
    DateTime Function()? clock,
  }) : _provider = provider,
       _payouts = payouts,
       _events = events,
       _notifications = notifications ?? const NoOpNotificationSink(),
       _clock = clock ?? DateTime.now;

  final PayoutProvider? _provider;
  final PayoutRepository _payouts;
  final PayoutProviderEventRepository _events;
  final NotificationSink _notifications;
  final DateTime Function() _clock;

  /// Verifies, records, and applies a provider webhook.
  Future<void> process({
    required List<int> rawBodyBytes,
    required String? signatureHeader,
  }) async {
    final provider = _provider;
    if (provider == null) {
      throw const PayoutProviderUnavailableException();
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
        throw const PayoutWebhookEventConflictException();
      }
      if (existing.processingStatus ==
              PayoutWebhookProcessingStatus.processed ||
          existing.processingStatus == PayoutWebhookProcessingStatus.ignored) {
        return;
      }
    }

    PayoutProviderEvent event;
    try {
      event =
          existing ??
          await _events.createReceived(
            PayoutProviderEvent(
              id: ObjectId(),
              provider: verified.provider,
              providerEventId: verified.eventId,
              eventType: verified.eventType.wireValue,
              providerPayoutId: verified.providerPayoutId,
              payloadSha256: payloadHash,
              processingStatus: PayoutWebhookProcessingStatus.received,
              createdAt: now,
            ),
          );
    } on PayoutDuplicateKeyException {
      final raced = await _events.findByProviderEventId(
        provider: verified.provider,
        providerEventId: verified.eventId,
      );
      if (raced == null) {
        throw const PayoutWriteException();
      }
      if (raced.payloadSha256 != payloadHash) {
        throw const PayoutWebhookEventConflictException();
      }
      if (raced.processingStatus == PayoutWebhookProcessingStatus.processed ||
          raced.processingStatus == PayoutWebhookProcessingStatus.ignored) {
        return;
      }
      event = raced;
    }

    try {
      await _apply(verified: verified, event: event, now: now);
    } on PayoutIntegrityMismatchException {
      await _events.markFailed(id: event.id, now: now);
      rethrow;
    } on Exception {
      await _events.markFailed(id: event.id, now: now);
      rethrow;
    }
  }

  Future<void> _apply({
    required VerifiedPayoutWebhookEvent verified,
    required PayoutProviderEvent event,
    required DateTime now,
  }) async {
    final payout = await _payouts.findByProviderPayoutId(
      provider: verified.provider.wireValue,
      providerPayoutId: verified.providerPayoutId,
    );
    if (payout == null) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }

    if (verified.amountMinor != payout.amountMinor ||
        verified.currencyCode != payout.currencyCode) {
      throw const PayoutIntegrityMismatchException();
    }

    switch (verified.eventType) {
      case PayoutWebhookEventType.payoutPaid:
        await _applyPaid(payout: payout, event: event, now: now);
      case PayoutWebhookEventType.payoutFailed:
        await _applyFailed(
          payout: payout,
          event: event,
          now: now,
          failureCode: verified.failureCode,
          failureMessage: verified.failureMessage,
        );
    }
  }

  Future<void> _applyPaid({
    required PayoutRequest payout,
    required PayoutProviderEvent event,
    required DateTime now,
  }) async {
    if (payout.status == PayoutStatus.paid) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    if (payout.status != PayoutStatus.processing) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    final updated = await _payouts.markPaid(id: payout.id, now: now);
    if (updated == null) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    await _events.markProcessed(id: event.id, now: now);
    await _notify(
      payout: updated,
      eventId: event.providerEventId,
      type: NotificationType.payoutPaid,
      title: 'Payout paid',
      body: 'Your payout request completed in the development sandbox.',
    );
  }

  Future<void> _applyFailed({
    required PayoutRequest payout,
    required PayoutProviderEvent event,
    required DateTime now,
    String? failureCode,
    String? failureMessage,
  }) async {
    if (payout.status == PayoutStatus.failed) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    if (payout.status != PayoutStatus.processing) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    final updated = await _payouts.markFailed(
      id: payout.id,
      now: now,
      failureCode: failureCode,
      failureMessage: failureMessage,
    );
    if (updated == null) {
      await _events.markIgnored(id: event.id, now: now);
      return;
    }
    await _events.markProcessed(id: event.id, now: now);
    await _notify(
      payout: updated,
      eventId: event.providerEventId,
      type: NotificationType.payoutFailed,
      title: 'Payout failed',
      body: 'Your payout request could not be completed.',
    );
  }

  Future<void> _notify({
    required PayoutRequest payout,
    required String eventId,
    required NotificationType type,
    required String title,
    required String body,
  }) {
    return _notifications.notifyBestEffort(
      userId: payout.cleanerUserId,
      type: type,
      title: title,
      body: body,
      dedupeKey: 'payout-event:$eventId',
      resourceType: 'payout',
      resourceId: payout.id,
    );
  }
}

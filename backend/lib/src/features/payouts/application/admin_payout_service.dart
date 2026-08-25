import 'package:home_cleaning_marketplace_api/src/features/audit/application/audit_log_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_sink.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/cleaner_payout_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_provider_event_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_request.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/provider/payout_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/provider/sandbox_payout_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent administrator payout review and processing.
class AdminPayoutService {
  /// Creates an admin payout service.
  AdminPayoutService({
    required PayoutRepository payouts,
    required PayoutProviderEventRepository events,
    required CleanerPayoutService cleanerPayouts,
    required CleanerProfileRepository cleanerProfiles,
    required PayoutProvider? provider,
    NotificationSink? notifications,
    AuditSink? audit,
    DateTime Function()? clock,
  }) : _payouts = payouts,
       _events = events,
       _cleanerPayouts = cleanerPayouts,
       _cleanerProfiles = cleanerProfiles,
       _provider = provider,
       _notifications = notifications ?? const NoOpNotificationSink(),
       _audit = audit ?? const NoOpAuditSink(),
       _clock = clock ?? DateTime.now;

  final PayoutRepository _payouts;
  final PayoutProviderEventRepository _events;
  final CleanerPayoutService _cleanerPayouts;
  final CleanerProfileRepository _cleanerProfiles;
  final PayoutProvider? _provider;
  final NotificationSink _notifications;
  final AuditSink _audit;
  final DateTime Function() _clock;

  /// Whether development sandbox simulation is available.
  bool get simulationAvailable => _provider is SandboxPayoutProvider;

  /// Admin payout queue. Defaults to requested.
  Future<Map<String, Object?>> list({
    Object? status,
    Object? currency,
    Object? cleanerUserId,
    Object? limitRaw,
    Object? after,
  }) async {
    final page = await _payouts.adminPage(
      limit: PayoutValidation.requireLimit(limitRaw),
      status: PayoutValidation.defaultAdminStatus(status),
      currencyCode: PayoutValidation.optionalCurrency(currency),
      cleanerUserId: PayoutValidation.optionalObjectId(
        cleanerUserId,
        field: 'cleaner_user_id',
      ),
      after: PayoutValidation.optionalCursor(after),
    );
    final names = await _cleanerNames(
      page.items.map((item) => item.cleanerUserId),
    );
    return <String, Object?>{
      'items': [
        for (final item in page.items)
          item.toAdminJson(
            cleanerDisplayName: names[item.cleanerUserId.oid] ?? 'Cleaner',
          ),
      ],
      'next_cursor': page.nextCursor,
    };
  }

  /// Admin payout detail with financial and provider-event summaries.
  Future<Map<String, Object?>> detail(ObjectId payoutId) async {
    final payout = await _payouts.findById(payoutId);
    if (payout == null) {
      throw const PayoutNotFoundException();
    }
    final names = await _cleanerNames([payout.cleanerUserId]);
    final summary = await _cleanerPayouts.summaryForCurrency(
      cleanerUserId: payout.cleanerUserId,
      currencyCode: payout.currencyCode,
    );
    final events = payout.providerPayoutId == null
        ? const <Map<String, Object?>>[]
        : [
            for (final event in await _events.listForProviderPayoutId(
              payout.providerPayoutId!,
            ))
              event.toAdminJson(),
          ];
    return <String, Object?>{
      'payout': payout.toAdminJson(
        cleanerDisplayName: names[payout.cleanerUserId.oid] ?? 'Cleaner',
        simulationAvailable: simulationAvailable,
      ),
      'earnings_summary': summary.toJson(),
      'provider_events': events,
    };
  }

  /// Transitions requested → processing and invokes the payout provider.
  ///
  /// Provider-call failure transitions processing → failed and releases the
  /// active reservation when the conditional update succeeds. A crash between
  /// the provider call and persistence is a documented cross-system gap
  /// surfaced by reconciliation, not silently repaired.
  Future<Map<String, Object?>> process({
    required UserAccount admin,
    required ObjectId payoutId,
  }) async {
    final provider = _provider;
    if (provider == null) {
      throw const PayoutProviderUnavailableException();
    }
    final existing = await _payouts.findById(payoutId);
    if (existing == null) {
      throw const PayoutNotFoundException();
    }
    final processing = await _payouts.startProcessing(
      id: payoutId,
      adminUserId: admin.id,
      provider: provider.type.wireValue,
      now: _clock().toUtc(),
    );
    if (processing == null) {
      final latest = await _payouts.findById(payoutId);
      if (latest == null) {
        throw const PayoutNotFoundException();
      }
      throw const InvalidPayoutStateException();
    }
    await _audit.appendBestEffort(
      actorUserId: admin.id,
      actorRole: UserRole.admin,
      action: AuditAction.payoutProcessingStarted,
      targetType: AuditTargetType.payout,
      targetId: payoutId,
      metadata: <String, Object?>{
        'amount_minor': processing.amountMinor,
        'currency_code': processing.currencyCode,
      },
    );
    await _notifyCleaner(
      payout: processing,
      type: NotificationType.payoutProcessing,
      title: 'Payout processing',
      body: 'Your payout request is being processed.',
      suffix: 'processing',
    );

    try {
      final created = await provider.createPayout(
        payoutId: processing.id,
        amountMinor: processing.amountMinor,
        currencyCode: processing.currencyCode,
      );
      final attached = await _payouts.attachProviderPayoutId(
        id: processing.id,
        providerPayoutId: created.providerPayoutId,
        now: _clock().toUtc(),
      );
      return (attached ?? processing).toAdminJson(
        simulationAvailable: simulationAvailable,
      );
    } on Exception {
      final failed = await _payouts.markFailed(
        id: processing.id,
        now: _clock().toUtc(),
        failureCode: 'provider_error',
        failureMessage: 'Payout provider request failed.',
      );
      if (failed != null) {
        await _notifyCleaner(
          payout: failed,
          type: NotificationType.payoutFailed,
          title: 'Payout failed',
          body: 'Your payout request could not be completed.',
          suffix: 'failed',
        );
        return failed.toAdminJson(simulationAvailable: simulationAvailable);
      }
      throw const PayoutWriteException();
    }
  }

  /// Rejects a requested payout.
  Future<Map<String, Object?>> reject({
    required UserAccount admin,
    required ObjectId payoutId,
    required Object? reasonRaw,
  }) async {
    final reason = PayoutValidation.requireRejectionReason(reasonRaw);
    final existing = await _payouts.findById(payoutId);
    if (existing == null) {
      throw const PayoutNotFoundException();
    }
    final rejected = await _payouts.rejectRequested(
      id: payoutId,
      adminUserId: admin.id,
      reason: reason,
      now: _clock().toUtc(),
    );
    if (rejected == null) {
      throw const InvalidPayoutStateException();
    }
    await _audit.appendBestEffort(
      actorUserId: admin.id,
      actorRole: UserRole.admin,
      action: AuditAction.payoutRejected,
      targetType: AuditTargetType.payout,
      targetId: payoutId,
      reason: reason,
    );
    await _notifyCleaner(
      payout: rejected,
      type: NotificationType.payoutRejected,
      title: 'Payout rejected',
      body: 'Your payout request was rejected.',
      suffix: 'rejected',
    );
    return rejected.toAdminJson(simulationAvailable: simulationAvailable);
  }

  Future<Map<String, String>> _cleanerNames(Iterable<ObjectId> ids) async {
    final profiles = await _cleanerProfiles.findByUserIds(ids);
    return <String, String>{
      for (final profile in profiles) profile.userId.oid: profile.fullName,
    };
  }

  Future<void> _notifyCleaner({
    required PayoutRequest payout,
    required NotificationType type,
    required String title,
    required String body,
    required String suffix,
  }) {
    return _notifications.notifyBestEffort(
      userId: payout.cleanerUserId,
      type: type,
      title: title,
      body: body,
      dedupeKey: 'payout:${payout.id.oid}:$suffix',
      resourceType: 'payout',
      resourceId: payout.id,
    );
  }
}

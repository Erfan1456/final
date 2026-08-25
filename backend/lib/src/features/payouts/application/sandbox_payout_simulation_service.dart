import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/application/audit_log_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/payout_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_event_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/provider/sandbox_payout_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Development-only sandbox payout simulator.
///
/// Always dispatches through the signed webhook processing path.
class SandboxPayoutSimulationService {
  /// Creates a simulator.
  SandboxPayoutSimulationService({
    required ServerConfig config,
    required PayoutRepository payouts,
    required PayoutWebhookService webhooks,
    required SandboxPayoutProvider? sandbox,
    AuditSink? audit,
  }) : _config = config,
       _payouts = payouts,
       _webhooks = webhooks,
       _sandbox = sandbox,
       _audit = audit ?? const NoOpAuditSink();

  final ServerConfig _config;
  final PayoutRepository _payouts;
  final PayoutWebhookService _webhooks;
  final SandboxPayoutProvider? _sandbox;
  final AuditSink _audit;

  /// Whether this process may expose the simulator.
  bool get isAvailable =>
      _config.isDevelopment && _config.allowsSandboxPayouts && _sandbox != null;

  /// Simulates provider completion by signing a webhook and processing it.
  Future<Map<String, Object?>> simulate({
    required ObjectId payoutId,
    required Object? resultRaw,
    UserAccount? admin,
  }) async {
    if (!isAvailable) {
      throw const PayoutProviderUnavailableException();
    }
    final sandbox = _sandbox;
    if (sandbox == null) {
      throw const PayoutProviderUnavailableException();
    }
    final result = _requireResult(resultRaw);
    final payout = await _payouts.findById(payoutId);
    if (payout == null) {
      throw const PayoutNotFoundException();
    }
    if (payout.status != PayoutStatus.processing) {
      throw const InvalidPayoutStateException();
    }
    final providerPayoutId = payout.providerPayoutId;
    if (providerPayoutId == null) {
      throw const InvalidPayoutStateException();
    }

    final success = result == 'success';
    final dispatch = sandbox.signEvent(
      eventId: sandbox.nextEventId(),
      eventType: success
          ? PayoutWebhookEventType.payoutPaid
          : PayoutWebhookEventType.payoutFailed,
      providerPayoutId: providerPayoutId,
      amountMinor: payout.amountMinor,
      currencyCode: payout.currencyCode,
      failureCode: success ? null : 'sandbox_failure',
      failureMessage: success ? null : 'Sandbox simulation reported failure.',
    );
    await _webhooks.process(
      rawBodyBytes: utf8.encode(dispatch.rawBody),
      signatureHeader: dispatch.signature,
    );
    if (admin != null) {
      await _audit.appendBestEffort(
        actorUserId: admin.id,
        actorRole: UserRole.admin,
        action: AuditAction.payoutSandboxSimulated,
        targetType: AuditTargetType.payout,
        targetId: payoutId,
        metadata: <String, Object?>{'result': result},
      );
    }
    final updated = await _payouts.findById(payoutId);
    if (updated == null) {
      throw const PayoutNotFoundException();
    }
    return updated.toAdminJson(simulationAvailable: true);
  }

  String _requireResult(Object? raw) {
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'result must be success or failure.',
      );
    }
    final value = raw.trim();
    if (value != 'success' && value != 'failure') {
      throw const ProfileValidationException(
        message: 'result must be success or failure.',
      );
    }
    return value;
  }
}

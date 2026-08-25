import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/payment_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_event_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/sandbox_payment_provider.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Development-only sandbox simulator. Always dispatches through webhooks.
class SandboxPaymentSimulationService {
  /// Creates a simulator.
  SandboxPaymentSimulationService({
    required ServerConfig config,
    required PaymentRepository payments,
    required PaymentWebhookService webhooks,
    required SandboxPaymentProvider? sandbox,
  }) : _config = config,
       _payments = payments,
       _webhooks = webhooks,
       _sandbox = sandbox;

  final ServerConfig _config;
  final PaymentRepository _payments;
  final PaymentWebhookService _webhooks;
  final SandboxPaymentProvider? _sandbox;

  /// Whether this process may expose the simulator.
  bool get isAvailable => _config.allowsSandboxPayments && _sandbox != null;

  /// Simulates provider completion by signing a webhook and processing it.
  Future<Map<String, Object?>> simulate({
    required ObjectId paymentId,
    required Object? resultRaw,
  }) async {
    if (!isAvailable) {
      throw const PaymentProviderUnavailableException();
    }
    final sandbox = _sandbox;
    if (sandbox == null) {
      throw const PaymentProviderUnavailableException();
    }
    final result = _requireResult(resultRaw);
    final payment = await _payments.findById(paymentId);
    if (payment == null) {
      throw const PaymentNotFoundException();
    }
    if (payment.status != PaymentStatus.pending &&
        payment.status != PaymentStatus.authorized) {
      throw const InvalidPaymentStateException();
    }
    final providerPaymentId = payment.providerPaymentId;
    if (providerPaymentId == null) {
      throw const InvalidPaymentStateException();
    }

    final success = result == 'success';
    final dispatch = sandbox.signEvent(
      eventId: sandbox.nextEventId(),
      eventType: success
          ? PaymentWebhookEventType.paymentSucceeded
          : PaymentWebhookEventType.paymentFailed,
      providerPaymentId: providerPaymentId,
      amountMinor: payment.amountMinor,
      currencyCode: payment.currencyCode,
      failureCode: success ? null : 'sandbox_failure',
      failureMessage: success ? null : 'Sandbox simulation reported failure.',
    );
    await _webhooks.process(
      rawBodyBytes: utf8.encode(dispatch.rawBody),
      signatureHeader: dispatch.signature,
    );
    final updated = await _payments.findById(paymentId);
    if (updated == null) {
      throw const PaymentNotFoundException();
    }
    return updated.toPublicJson();
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

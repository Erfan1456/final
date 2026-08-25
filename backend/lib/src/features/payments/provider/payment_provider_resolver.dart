import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/payment_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/sandbox_payment_provider.dart';

/// Resolves the TASK 016 payment provider.
///
/// Production never falls back to sandbox.
class PaymentProviderResolver {
  /// Creates a resolver.
  const PaymentProviderResolver();

  /// Returns the sandbox provider in development/test when the secret is valid.
  ///
  /// Returns `null` when sandbox is forbidden or the webhook secret is missing.
  PaymentProvider? resolve(
    ServerConfig config, {
    List<int> Function(int length)? randomBytesFn,
    DateTime Function()? clock,
  }) {
    if (!config.allowsSandboxPayments) {
      return null;
    }
    if (!config.hasValidSandboxWebhookSecret) {
      return null;
    }
    return SandboxPaymentProvider(
      webhookSecret: config.sandboxPaymentWebhookSecret,
      randomBytesFn: randomBytesFn,
      clock: clock,
    );
  }
}

/// Whether [secret] meets the sandbox webhook secret minimum.
bool isValidSandboxWebhookSecret(String secret) {
  return utf8.encode(secret).length >=
      PaymentValidation.sandboxWebhookSecretMinBytes;
}

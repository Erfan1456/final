import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/provider/payout_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/provider/sandbox_payout_provider.dart';

/// Resolves the TASK 019 payout provider.
///
/// Production never falls back to sandbox.
class PayoutProviderResolver {
  /// Creates a resolver.
  const PayoutProviderResolver();

  /// Returns the sandbox provider in development/test when the secret is valid.
  PayoutProvider? resolve(
    ServerConfig config, {
    List<int> Function(int length)? randomBytesFn,
    DateTime Function()? clock,
  }) {
    if (!config.allowsSandboxPayouts) {
      return null;
    }
    if (!config.hasValidSandboxPayoutWebhookSecret) {
      return null;
    }
    return SandboxPayoutProvider(
      webhookSecret: config.sandboxPayoutWebhookSecret,
      randomBytesFn: randomBytesFn,
      clock: clock,
    );
  }
}

/// Whether [secret] meets the sandbox payout webhook secret minimum.
bool isValidSandboxPayoutWebhookSecret(String secret) {
  return utf8.encode(secret).length >=
      PayoutValidation.sandboxPayoutWebhookSecretMinBytes;
}

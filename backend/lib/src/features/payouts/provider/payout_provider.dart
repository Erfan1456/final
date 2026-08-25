import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_event_type.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Provider-neutral result of creating a payout.
class CreatedPayout {
  /// Creates a result without vendor payload leakage.
  const CreatedPayout({required this.providerPayoutId});

  /// Opaque provider payout identifier.
  final String providerPayoutId;
}

/// Signed webhook body that must be processed through the webhook service.
class SignedPayoutWebhookDispatch {
  /// Creates a dispatch envelope. [rawBody] is the exact bytes to verify.
  const SignedPayoutWebhookDispatch({
    required this.rawBody,
    required this.signature,
  });

  /// Exact UTF-8 JSON body that was signed.
  final String rawBody;

  /// Lowercase hex HMAC-SHA256 of [rawBody].
  final String signature;
}

/// Verified, provider-normalized payout webhook event.
class VerifiedPayoutWebhookEvent {
  /// Creates a verified event. Does not include raw vendor documents.
  const VerifiedPayoutWebhookEvent({
    required this.provider,
    required this.eventId,
    required this.eventType,
    required this.providerPayoutId,
    required this.amountMinor,
    required this.currencyCode,
    required this.createdAt,
    this.failureCode,
    this.failureMessage,
  });

  /// Provider that produced the event.
  final PayoutProviderType provider;

  /// Provider-unique event identifier.
  final String eventId;

  /// Normalized event type.
  final PayoutWebhookEventType eventType;

  /// Provider payout identifier.
  final String providerPayoutId;

  /// Amount from the event. Required for integrity checks.
  final int amountMinor;

  /// Currency from the event. Required for integrity checks.
  final String currencyCode;

  /// Safe provider failure code.
  final String? failureCode;

  /// Safe provider failure message.
  final String? failureMessage;

  /// Event creation time in UTC.
  final DateTime createdAt;
}

/// Narrow payout adapter. Application services must not import vendor SDKs.
abstract class PayoutProvider {
  /// Provider type implemented by this adapter.
  PayoutProviderType get type;

  /// Creates an opaque provider payout.
  Future<CreatedPayout> createPayout({
    required ObjectId payoutId,
    required int amountMinor,
    required String currencyCode,
  });

  /// Parses and HMAC-verifies a webhook body. Throws on invalid signatures.
  VerifiedPayoutWebhookEvent parseAndVerifyWebhook({
    required List<int> rawBodyBytes,
    required String? signatureHeader,
  });
}

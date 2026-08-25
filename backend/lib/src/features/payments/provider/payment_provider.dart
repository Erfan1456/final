import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_event_type.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Provider-neutral result of creating a payment session.
class CreatedPaymentSession {
  /// Creates a session result without vendor payload leakage.
  const CreatedPaymentSession({
    required this.providerPaymentId,
    this.providerReference,
  });

  /// Opaque provider payment identifier.
  final String providerPaymentId;

  /// Optional opaque provider reference.
  final String? providerReference;
}

/// Signed webhook body that must be processed through the webhook service.
class SignedWebhookDispatch {
  /// Creates a dispatch envelope. [rawBody] is the exact bytes to verify.
  const SignedWebhookDispatch({
    required this.rawBody,
    required this.signature,
  });

  /// Exact UTF-8 JSON body that was signed.
  final String rawBody;

  /// Lowercase hex HMAC-SHA256 of [rawBody].
  final String signature;
}

/// Verified, provider-normalized webhook event.
class VerifiedWebhookEvent {
  /// Creates a verified event. Does not include raw vendor documents.
  const VerifiedWebhookEvent({
    required this.provider,
    required this.eventId,
    required this.eventType,
    required this.providerPaymentId,
    required this.createdAt,
    this.amountMinor,
    this.currencyCode,
    this.refundedAmountMinor,
    this.failureCode,
    this.failureMessage,
  });

  /// Provider that produced the event.
  final PaymentProviderType provider;

  /// Provider-unique event identifier.
  final String eventId;

  /// Normalized event type.
  final PaymentWebhookEventType eventType;

  /// Provider payment identifier.
  final String providerPaymentId;

  /// Amount from the event when present.
  final int? amountMinor;

  /// Currency from the event when present.
  final String? currencyCode;

  /// Cumulative refunded amount when present on refund events.
  final int? refundedAmountMinor;

  /// Safe provider failure code.
  final String? failureCode;

  /// Safe provider failure message.
  final String? failureMessage;

  /// Event creation time in UTC.
  final DateTime createdAt;
}

/// Narrow provider adapter. Application services must not import vendor SDKs.
abstract class PaymentProvider {
  /// Provider type implemented by this adapter.
  PaymentProviderType get type;

  /// Creates an opaque pending provider payment session.
  Future<CreatedPaymentSession> createPayment({
    required ObjectId paymentId,
    required int amountMinor,
    required String currencyCode,
  });

  /// Parses and HMAC-verifies a webhook body. Throws on invalid signatures.
  VerifiedWebhookEvent parseAndVerifyWebhook({
    required List<int> rawBodyBytes,
    required String? signatureHeader,
  });

  /// Requests a refund and returns a signed webhook for shared processing.
  Future<SignedWebhookDispatch> refund({
    required String providerPaymentId,
    required int amountMinor,
    required String currencyCode,
    required int cumulativeRefundedAmountMinor,
    required bool fullRefund,
    required String reason,
    required String eventId,
  });
}

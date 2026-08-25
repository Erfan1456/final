import 'dart:convert';

import 'package:hashlib/random.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_event_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/payment_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/security/sandbox_webhook_hmac.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Development/test sandbox processor. Not a production payment gateway.
///
/// Does not collect or store card numbers. Completes only through signed
/// webhooks processed by the shared webhook application service.
class SandboxPaymentProvider implements PaymentProvider {
  /// Creates a sandbox adapter.
  ///
  /// [randomBytesFn] is a test-only injection seam.
  SandboxPaymentProvider({
    required String webhookSecret,
    List<int> Function(int length)? randomBytesFn,
    DateTime Function()? clock,
  }) : _webhookSecret = webhookSecret,
       _randomBytes = randomBytesFn ?? randomBytes,
       _clock = clock ?? DateTime.now;

  final String _webhookSecret;
  final List<int> Function(int length) _randomBytes;
  final DateTime Function() _clock;

  @override
  PaymentProviderType get type => PaymentProviderType.sandbox;

  @override
  Future<CreatedPaymentSession> createPayment({
    required ObjectId paymentId,
    required int amountMinor,
    required String currencyCode,
  }) async {
    return CreatedPaymentSession(
      providerPaymentId: 'sandbox_${_opaqueToken()}',
    );
  }

  @override
  VerifiedWebhookEvent parseAndVerifyWebhook({
    required List<int> rawBodyBytes,
    required String? signatureHeader,
  }) {
    final valid = SandboxWebhookHmac.verify(
      secret: _webhookSecret,
      bodyBytes: rawBodyBytes,
      providedHex: signatureHeader,
    );
    if (!valid) {
      throw const InvalidWebhookSignatureException();
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(rawBodyBytes));
    } on FormatException {
      throw const MalformedWebhookException();
    }
    if (decoded is! Map) {
      throw const MalformedWebhookException();
    }
    final map = Map<String, dynamic>.from(decoded);

    final eventId = map['event_id'];
    final eventTypeRaw = map['event_type'];
    final providerPaymentId = map['provider_payment_id'];
    if (eventId is! String ||
        eventId.trim().isEmpty ||
        eventTypeRaw is! String ||
        providerPaymentId is! String ||
        providerPaymentId.trim().isEmpty) {
      throw const MalformedWebhookException();
    }

    final PaymentWebhookEventType eventType;
    try {
      eventType = PaymentWebhookEventType.fromWire(eventTypeRaw.trim());
    } on FormatException {
      throw const MalformedWebhookException();
    }

    DateTime createdAt;
    try {
      final rawCreated = map['created_at'];
      if (rawCreated is! String) {
        throw const FormatException('created_at');
      }
      createdAt = DateTime.parse(rawCreated).toUtc();
    } on FormatException {
      throw const MalformedWebhookException();
    }

    return VerifiedWebhookEvent(
      provider: PaymentProviderType.sandbox,
      eventId: eventId.trim(),
      eventType: eventType,
      providerPaymentId: providerPaymentId.trim(),
      amountMinor: _optionalInt(map['amount_minor']),
      currencyCode: map['currency_code'] is String
          ? (map['currency_code'] as String).trim()
          : null,
      refundedAmountMinor: _optionalInt(map['refunded_amount_minor']),
      failureCode: map['failure_code'] is String
          ? (map['failure_code'] as String).trim()
          : null,
      failureMessage: map['failure_message'] is String
          ? (map['failure_message'] as String).trim()
          : null,
      createdAt: createdAt,
    );
  }

  @override
  Future<SignedWebhookDispatch> refund({
    required String providerPaymentId,
    required int amountMinor,
    required String currencyCode,
    required int cumulativeRefundedAmountMinor,
    required bool fullRefund,
    required String reason,
    required String eventId,
  }) async {
    final eventType = fullRefund
        ? PaymentWebhookEventType.paymentRefunded
        : PaymentWebhookEventType.paymentPartiallyRefunded;
    return signEvent(
      eventId: eventId,
      eventType: eventType,
      providerPaymentId: providerPaymentId,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      refundedAmountMinor: cumulativeRefundedAmountMinor,
    );
  }

  /// Builds a signed sandbox completion/failure webhook for the simulator.
  SignedWebhookDispatch signEvent({
    required String eventId,
    required PaymentWebhookEventType eventType,
    required String providerPaymentId,
    required int amountMinor,
    required String currencyCode,
    int? refundedAmountMinor,
    String? failureCode,
    String? failureMessage,
  }) {
    final payload = <String, Object?>{
      'event_id': eventId,
      'event_type': eventType.wireValue,
      'provider_payment_id': providerPaymentId,
      'amount_minor': amountMinor,
      'currency_code': currencyCode,
      'created_at': _clock().toUtc().toIso8601String(),
      if (refundedAmountMinor != null)
        'refunded_amount_minor': refundedAmountMinor,
      if (failureCode != null) 'failure_code': failureCode,
      if (failureMessage != null) 'failure_message': failureMessage,
    };
    final rawBody = jsonEncode(payload);
    return SignedWebhookDispatch(
      rawBody: rawBody,
      signature: SandboxWebhookHmac.sign(
        secret: _webhookSecret,
        bodyBytes: utf8.encode(rawBody),
      ),
    );
  }

  /// Opaque non-sequential identifier fragment.
  String nextEventId() => 'sandbox_evt_${_opaqueToken()}';

  String _opaqueToken() {
    return base64Url.encode(_randomBytes(18)).replaceAll('=', '');
  }

  static int? _optionalInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    return null;
  }
}

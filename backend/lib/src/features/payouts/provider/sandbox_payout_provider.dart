import 'dart:convert';

import 'package:hashlib/random.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_event_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/provider/payout_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/security/sandbox_payout_webhook_hmac.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Development/test sandbox payout adapter. Not a production bank transfer.
class SandboxPayoutProvider implements PayoutProvider {
  /// Creates a sandbox adapter.
  SandboxPayoutProvider({
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
  PayoutProviderType get type => PayoutProviderType.sandbox;

  @override
  Future<CreatedPayout> createPayout({
    required ObjectId payoutId,
    required int amountMinor,
    required String currencyCode,
  }) async {
    return CreatedPayout(providerPayoutId: 'sandbox_payout_${_opaqueToken()}');
  }

  @override
  VerifiedPayoutWebhookEvent parseAndVerifyWebhook({
    required List<int> rawBodyBytes,
    required String? signatureHeader,
  }) {
    final valid = SandboxPayoutWebhookHmac.verify(
      secret: _webhookSecret,
      bodyBytes: rawBodyBytes,
      providedHex: signatureHeader,
    );
    if (!valid) {
      throw const InvalidPayoutWebhookSignatureException();
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(rawBodyBytes));
    } on FormatException {
      throw const MalformedPayoutWebhookException();
    }
    if (decoded is! Map) {
      throw const MalformedPayoutWebhookException();
    }
    final map = Map<String, dynamic>.from(decoded);

    final eventId = map['event_id'];
    final eventTypeRaw = map['event_type'];
    final providerPayoutId = map['provider_payout_id'];
    final amountMinor = map['amount_minor'];
    final currencyCode = map['currency_code'];
    if (eventId is! String ||
        eventId.trim().isEmpty ||
        eventTypeRaw is! String ||
        providerPayoutId is! String ||
        providerPayoutId.trim().isEmpty ||
        amountMinor is! int ||
        currencyCode is! String) {
      throw const MalformedPayoutWebhookException();
    }

    final PayoutWebhookEventType eventType;
    try {
      eventType = PayoutWebhookEventType.fromWire(eventTypeRaw.trim());
    } on FormatException {
      throw const MalformedPayoutWebhookException();
    }

    DateTime createdAt;
    try {
      final rawCreated = map['created_at'];
      if (rawCreated is! String) {
        throw const FormatException('created_at');
      }
      createdAt = DateTime.parse(rawCreated).toUtc();
    } on FormatException {
      throw const MalformedPayoutWebhookException();
    }

    return VerifiedPayoutWebhookEvent(
      provider: PayoutProviderType.sandbox,
      eventId: eventId.trim(),
      eventType: eventType,
      providerPayoutId: providerPayoutId.trim(),
      amountMinor: amountMinor,
      currencyCode: currencyCode.trim().toUpperCase(),
      createdAt: createdAt,
      failureCode: map['failure_code'] is String
          ? (map['failure_code'] as String).trim()
          : null,
      failureMessage: map['failure_message'] is String
          ? (map['failure_message'] as String).trim()
          : null,
    );
  }

  /// Builds a signed sandbox payout webhook for the simulator.
  SignedPayoutWebhookDispatch signEvent({
    required String eventId,
    required PayoutWebhookEventType eventType,
    required String providerPayoutId,
    required int amountMinor,
    required String currencyCode,
    String? failureCode,
    String? failureMessage,
  }) {
    final payload = <String, Object?>{
      'event_id': eventId,
      'event_type': eventType.wireValue,
      'provider_payout_id': providerPayoutId,
      'amount_minor': amountMinor,
      'currency_code': currencyCode,
      'created_at': _clock().toUtc().toIso8601String(),
      if (failureCode != null) 'failure_code': failureCode,
      if (failureMessage != null) 'failure_message': failureMessage,
    };
    final rawBody = jsonEncode(payload);
    return SignedPayoutWebhookDispatch(
      rawBody: rawBody,
      signature: SandboxPayoutWebhookHmac.sign(
        secret: _webhookSecret,
        bodyBytes: utf8.encode(rawBody),
      ),
    );
  }

  /// Opaque non-sequential identifier fragment.
  String nextEventId() => 'sandbox_payout_evt_${_opaqueToken()}';

  String _opaqueToken() {
    return base64Url.encode(_randomBytes(18)).replaceAll('=', '');
  }
}

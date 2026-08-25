import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/features/payouts/security/sandbox_payout_webhook_hmac.dart';
import 'package:test/test.dart';

/// Fake sandbox payout webhook secret used only in tests.
const String testSandboxPayoutWebhookSecret =
    'test-sandbox-payout-webhook-32b!!';

void main() {
  const body = '{"event_id":"evt_payout_1"}';
  final bodyBytes = utf8.encode(body);

  group('SandboxPayoutWebhookHmac', () {
    test('signs lowercase hex HMAC-SHA256 of the raw body', () {
      final signature = SandboxPayoutWebhookHmac.sign(
        secret: testSandboxPayoutWebhookSecret,
        bodyBytes: bodyBytes,
      );
      expect(signature, equals(signature.toLowerCase()));
      expect(signature.length, equals(64));
      expect(
        SandboxPayoutWebhookHmac.verify(
          secret: testSandboxPayoutWebhookSecret,
          bodyBytes: bodyBytes,
          providedHex: signature,
        ),
        isTrue,
      );
    });

    test('rejects missing and invalid signatures', () {
      expect(
        SandboxPayoutWebhookHmac.verify(
          secret: testSandboxPayoutWebhookSecret,
          bodyBytes: bodyBytes,
          providedHex: null,
        ),
        isFalse,
      );
      expect(
        SandboxPayoutWebhookHmac.verify(
          secret: testSandboxPayoutWebhookSecret,
          bodyBytes: bodyBytes,
          providedHex: 'deadbeef',
        ),
        isFalse,
      );
    });

    test('constant-time hex helper matches equal values', () {
      const left = 'aabbccddeeff00112233445566778899';
      expect(
        SandboxPayoutWebhookHmac.constantTimeHexEquals(left, left),
        isTrue,
      );
      expect(
        SandboxPayoutWebhookHmac.constantTimeHexEquals(
          left,
          'aabbccddeeff0011223344556677889a',
        ),
        isFalse,
      );
      expect(
        SandboxPayoutWebhookHmac.constantTimeHexEquals(left, 'aa'),
        isFalse,
      );
      expect(
        SandboxPayoutWebhookHmac.constantTimeHexEquals('not-hex', 'not-hex!'),
        isFalse,
      );
    });
  });
}

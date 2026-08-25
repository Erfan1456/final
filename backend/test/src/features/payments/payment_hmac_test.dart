import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/features/payments/security/sandbox_webhook_hmac.dart';
import 'package:test/test.dart';

import '../../../helpers/payment_test_fixtures.dart';

void main() {
  const body = '{"event_id":"evt_1"}';
  final bodyBytes = utf8.encode(body);

  group('SandboxWebhookHmac', () {
    test('signs lowercase hex HMAC-SHA256 of the raw body', () {
      final signature = SandboxWebhookHmac.sign(
        secret: testSandboxWebhookSecret,
        bodyBytes: bodyBytes,
      );
      expect(signature, equals(signature.toLowerCase()));
      expect(signature.length, equals(64));
      expect(
        SandboxWebhookHmac.verify(
          secret: testSandboxWebhookSecret,
          bodyBytes: bodyBytes,
          providedHex: signature,
        ),
        isTrue,
      );
    });

    test('rejects missing and invalid signatures', () {
      expect(
        SandboxWebhookHmac.verify(
          secret: testSandboxWebhookSecret,
          bodyBytes: bodyBytes,
          providedHex: null,
        ),
        isFalse,
      );
      expect(
        SandboxWebhookHmac.verify(
          secret: testSandboxWebhookSecret,
          bodyBytes: bodyBytes,
          providedHex: 'deadbeef',
        ),
        isFalse,
      );
    });

    test('constant-time hex helper matches equal values', () {
      const left = 'aabbccddeeff00112233445566778899';
      expect(SandboxWebhookHmac.constantTimeHexEquals(left, left), isTrue);
      expect(
        SandboxWebhookHmac.constantTimeHexEquals(
          left,
          'aabbccddeeff0011223344556677889a',
        ),
        isFalse,
      );
      expect(SandboxWebhookHmac.constantTimeHexEquals(left, 'aa'), isFalse);
      expect(
        SandboxWebhookHmac.constantTimeHexEquals('not-hex', 'not-hex!'),
        isFalse,
      );
    });
  });
}

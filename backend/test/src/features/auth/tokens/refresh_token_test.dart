import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/refresh_token.dart';
import 'package:test/test.dart';

void main() {
  List<int> decodeRaw(String raw) {
    var padded = raw;
    final remainder = padded.length % 4;
    if (remainder != 0) {
      padded = padded.padRight(padded.length + (4 - remainder), '=');
    }
    return base64Url.decode(padded);
  }

  group('RefreshTokenGenerator', () {
    final generator = RefreshTokenGenerator();

    test('generates a 32-byte opaque base64url token', () {
      final raw = generator.generate();

      expect(raw, isNotEmpty);
      expect(raw.contains('='), isFalse);
      expect(decodeRaw(raw), hasLength(refreshTokenLengthBytes));
      expect(raw.contains('{'), isFalse);
      expect(raw.contains('user'), isFalse);
      expect(raw.contains('session'), isFalse);
      expect(raw.contains('@'), isFalse);
    });

    test('generates distinct tokens', () {
      final first = generator.generate();
      final second = generator.generate();

      expect(first, isNot(equals(second)));
    });
  });

  group('RefreshTokenHasher', () {
    const hasher = RefreshTokenHasher();

    test('hashes the same raw token identically as lowercase hex SHA-256', () {
      const raw = 'fake-refresh-token-value';
      final first = hasher.hashToken(raw);
      final second = hasher.hashToken(raw);

      expect(first, equals(second));
      expect(first.length, equals(64));
      expect(first, matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(first, isNot(equals(raw)));
    });

    test('hashes different raw tokens differently', () {
      const hasher = RefreshTokenHasher();

      expect(
        hasher.hashToken('fake-refresh-token-a'),
        isNot(equals(hasher.hashToken('fake-refresh-token-b'))),
      );
    });
  });
}

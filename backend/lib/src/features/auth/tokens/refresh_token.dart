import 'dart:convert';

import 'package:hashlib/hashlib.dart';
import 'package:hashlib/random.dart';

/// Opaque refresh-token entropy in bytes (256 bits).
const int refreshTokenLengthBytes = 32;

/// Generates opaque refresh tokens. Output carries no structured metadata.
class RefreshTokenGenerator {
  /// Creates a generator.
  ///
  /// [randomBytesFn] is a test-only injection seam. Production omits it.
  RefreshTokenGenerator({
    List<int> Function(int length)? randomBytesFn,
  }) : _randomBytes = randomBytesFn ?? randomBytes;

  final List<int> Function(int length) _randomBytes;

  /// Returns a base64url string without padding.
  String generate() {
    return base64Url
        .encode(_randomBytes(refreshTokenLengthBytes))
        .replaceAll(
          '=',
          '',
        );
  }
}

/// Deterministic SHA-256 lookup hash for refresh tokens.
class RefreshTokenHasher {
  /// Creates a hasher.
  const RefreshTokenHasher();

  /// SHA-256 of [rawToken] as lowercase hexadecimal (64 characters).
  String hashToken(String rawToken) {
    return sha256.string(rawToken, utf8).hex();
  }
}

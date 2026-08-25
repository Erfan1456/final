import 'dart:convert';

import 'package:hashlib/hashlib.dart';

/// HMAC-SHA256 helpers for sandbox payout webhook authenticity.
abstract final class SandboxPayoutWebhookHmac {
  /// Header carrying the lowercase hex HMAC-SHA256 of the raw body.
  static const String signatureHeaderName = 'X-Sandbox-Payout-Signature';

  /// Canonical lowercase header name used by Dart Frog.
  static const String signatureHeaderNameLower = 'x-sandbox-payout-signature';

  /// Signs [bodyBytes] with [secret] as lowercase hexadecimal HMAC-SHA256.
  static String sign({
    required String secret,
    required List<int> bodyBytes,
  }) {
    return hmac_sha256
        .by(utf8.encode(secret))
        .convert(bodyBytes)
        .hex()
        .toLowerCase();
  }

  /// Constant-time verification of [providedHex] against HMAC-SHA256(body).
  static bool verify({
    required String secret,
    required List<int> bodyBytes,
    required String? providedHex,
  }) {
    if (providedHex == null) {
      return false;
    }
    final trimmed = providedHex.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return false;
    }
    final digest = hmac_sha256.by(utf8.encode(secret)).convert(bodyBytes);
    return digest.isEqual(trimmed);
  }

  /// Constant-time equality of two hexadecimal strings.
  static bool constantTimeHexEquals(String left, String right) {
    final a = _tryDecodeHex(left);
    final b = _tryDecodeHex(right);
    if (a == null || b == null) {
      return false;
    }
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static List<int>? _tryDecodeHex(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty || value.length.isOdd) {
      return null;
    }
    final bytes = <int>[];
    for (var i = 0; i < value.length; i += 2) {
      final parsed = int.tryParse(value.substring(i, i + 2), radix: 16);
      if (parsed == null) {
        return null;
      }
      bytes.add(parsed);
    }
    return bytes;
  }
}

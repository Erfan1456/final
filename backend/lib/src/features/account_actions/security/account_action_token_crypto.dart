import 'dart:convert';
import 'dart:math';

import 'package:hashlib/hashlib.dart';

import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_policy.dart';

/// Generates opaque base64url account-action tokens.
class AccountActionTokenGenerator {
  /// Creates a generator. Tests may inject [randomBytes].
  AccountActionTokenGenerator({
    List<int> Function(int length)? randomBytes,
  }) : _randomBytes = randomBytes ?? _secureRandomBytes;

  final List<int> Function(int length) _randomBytes;

  /// 32 CSPRNG bytes encoded as unpadded base64url.
  String generate() {
    final bytes = _randomBytes(AccountActionPolicy.tokenLengthBytes);
    if (bytes.length != AccountActionPolicy.tokenLengthBytes) {
      throw StateError('Account-action token entropy length is invalid.');
    }
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static List<int> _secureRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}

/// SHA-256 lowercase hex hasher for raw account-action tokens.
class AccountActionTokenHasher {
  /// Hashes [rawToken]. Never log [rawToken].
  String hash(String rawToken) {
    return sha256.string(rawToken, utf8).hex();
  }
}

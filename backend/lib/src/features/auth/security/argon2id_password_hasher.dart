import 'dart:convert';

import 'package:hashlib/hashlib.dart';
import 'package:hashlib/random.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_hasher.dart';

/// Approved Argon2id memory parameter in KiB.
const int argon2idMemoryKib = 19456;

/// Approved Argon2id iteration count.
const int argon2idIterations = 2;

/// Approved Argon2id parallelism.
const int argon2idParallelism = 1;

/// Approved derived-hash length in bytes.
const int argon2idHashLengthBytes = 32;

/// Approved salt length in bytes.
const int argon2idSaltLengthBytes = 16;

/// Argon2id hasher using hashlib's encoded PHC output.
class Argon2idPasswordHasher implements PasswordHasher {
  /// Creates a hasher.
  ///
  /// [saltBytes] is a test-only injection seam. Production omits it and uses
  /// hashlib `randomBytes` with a secure generator.
  Argon2idPasswordHasher({
    List<int> Function(int length)? saltBytes,
  }) : _saltBytes = saltBytes ?? _secureSalt;

  static const Argon2Security _security = Argon2Security(
    'approved',
    m: argon2idMemoryKib,
    t: argon2idIterations,
    p: argon2idParallelism,
  );

  final List<int> Function(int length) _saltBytes;

  static List<int> _secureSalt(int length) => randomBytes(length);

  @override
  String hash(String password) {
    final salt = _saltBytes(argon2idSaltLengthBytes);
    final digest = argon2id(
      utf8.encode(password),
      salt,
      hashLength: argon2idHashLengthBytes,
      security: _security,
    );
    return digest.encoded();
  }

  @override
  bool verify({
    required String password,
    required String encodedHash,
  }) {
    try {
      return argon2Verify(encodedHash, utf8.encode(password));
    } on FormatException {
      return false;
    } catch (error) {
      if (error is ArgumentError) {
        return false;
      }
      rethrow;
    }
  }

  @override
  bool needsRehash(String encodedHash) {
    final parsed = _EncodedArgon2id.tryParse(encodedHash);
    if (parsed == null) {
      return true;
    }
    return parsed.memoryKib != argon2idMemoryKib ||
        parsed.iterations != argon2idIterations ||
        parsed.parallelism != argon2idParallelism ||
        parsed.hashLengthBytes != argon2idHashLengthBytes;
  }
}

/// Minimal PHC Argon2id parameter reader for rehash detection.
class _EncodedArgon2id {
  const _EncodedArgon2id({
    required this.memoryKib,
    required this.iterations,
    required this.parallelism,
    required this.hashLengthBytes,
  });

  final int memoryKib;
  final int iterations;
  final int parallelism;
  final int hashLengthBytes;

  static final _pattern = RegExp(
    r'^\$argon2id\$v=19\$m=(\d+),t=(\d+),p=(\d+)\$[^\$]+\$([^\$]+)$',
  );

  static _EncodedArgon2id? tryParse(String encoded) {
    final match = _pattern.firstMatch(encoded);
    if (match == null) {
      return null;
    }
    final memory = int.tryParse(match.group(1)!);
    final iterations = int.tryParse(match.group(2)!);
    final parallelism = int.tryParse(match.group(3)!);
    final hashBytes = _decodePhcBase64(match.group(4)!);
    if (memory == null ||
        iterations == null ||
        parallelism == null ||
        hashBytes == null) {
      return null;
    }
    return _EncodedArgon2id(
      memoryKib: memory,
      iterations: iterations,
      parallelism: parallelism,
      hashLengthBytes: hashBytes.length,
    );
  }

  static List<int>? _decodePhcBase64(String value) {
    try {
      var padded = value.replaceAll('-', '+').replaceAll('_', '/');
      final remainder = padded.length % 4;
      if (remainder != 0) {
        padded = padded.padRight(padded.length + (4 - remainder), '=');
      }
      return base64Decode(padded);
    } on FormatException {
      return null;
    }
  }
}

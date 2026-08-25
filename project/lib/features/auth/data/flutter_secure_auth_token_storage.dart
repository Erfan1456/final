import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_storage.dart';

/// Reads and writes a single opaque string in platform secure storage.
typedef SecureStringReader = Future<String?> Function(String key);
typedef SecureStringWriter = Future<void> Function(String key, String value);
typedef SecureStringDeleter = Future<void> Function(String key);

/// [AuthTokenStorage] backed by FlutterSecureStorage.
///
/// Stores one JSON document under [storageKey]. Corrupt values are cleared
/// and treated as no session.
class FlutterSecureAuthTokenStorage implements AuthTokenStorage {
  /// Creates storage with injected read/write/delete seams.
  FlutterSecureAuthTokenStorage({
    required this.readRaw,
    required this.writeRaw,
    required this.deleteRaw,
  });

  /// Uses the default [FlutterSecureStorage] plugin.
  factory FlutterSecureAuthTokenStorage.platform() {
    const storage = FlutterSecureStorage();
    return FlutterSecureAuthTokenStorage(
      readRaw: (key) => storage.read(key: key),
      writeRaw: (key, value) => storage.write(key: key, value: value),
      deleteRaw: (key) => storage.delete(key: key),
    );
  }

  /// Single stable secure-storage key for the token pair JSON.
  static const String storageKey = 'auth.token_pair';

  final SecureStringReader readRaw;
  final SecureStringWriter writeRaw;
  final SecureStringDeleter deleteRaw;

  @override
  Future<AuthTokenPair?> read() async {
    final raw = await readRaw(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await clear();
        return null;
      }
      return AuthTokenPair.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      await clear();
      return null;
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthTokenPair pair) {
    return writeRaw(storageKey, jsonEncode(pair.toJson()));
  }

  @override
  Future<void> clear() {
    return deleteRaw(storageKey);
  }
}

/// Process-scoped secure token storage.
final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return FlutterSecureAuthTokenStorage.platform();
});

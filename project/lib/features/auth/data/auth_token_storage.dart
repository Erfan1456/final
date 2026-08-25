import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';

/// Secure persistence for the access/refresh token pair only.
abstract class AuthTokenStorage {
  /// Returns the stored pair, or `null` when absent or unreadable.
  Future<AuthTokenPair?> read();

  /// Atomically replaces the stored pair.
  Future<void> write(AuthTokenPair pair);

  /// Deletes any stored credentials.
  Future<void> clear();
}

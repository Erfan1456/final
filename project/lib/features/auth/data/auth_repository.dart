import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_api.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_storage.dart';
import 'package:home_cleaning_marketplace/features/auth/data/flutter_secure_auth_token_storage.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_user.dart';

/// Authentication use cases over [AuthApi] and secure token storage.
class AuthRepository {
  /// Creates a repository.
  AuthRepository({required this.api, required this.storage});

  final AuthApi api;
  final AuthTokenStorage storage;

  /// Registers a customer or cleaner and stores the returned token pair.
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    final result = await api.signUp(
      email: email,
      password: password,
      role: role,
    );
    await storage.write(result.tokens);
    return result.user;
  }

  /// Authenticates and stores the returned token pair.
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final result = await api.login(email: email, password: password);
    await storage.write(result.tokens);
    return result.user;
  }

  /// Restores a session from secure storage and GET /account/me.
  ///
  /// Missing tokens yield `null`. Irrecoverable auth failures clear storage
  /// and yield `null`.
  Future<AuthUser?> restoreSession() async {
    final pair = await storage.read();
    if (pair == null) {
      return null;
    }
    try {
      return await api.me();
    } on AuthFailure catch (error) {
      if (error.isSessionInvalid ||
          error.code == 'account_unavailable' ||
          error.code == 'invalid_credentials') {
        await storage.clear();
        return null;
      }
      rethrow;
    }
  }

  /// Loads the current account through the authenticated client.
  Future<AuthUser> getCurrentUser() {
    return api.me();
  }

  /// Logs out this device. Local tokens are always cleared.
  Future<void> logout() async {
    try {
      final pair = await storage.read();
      if (pair != null && pair.refreshToken.isNotEmpty) {
        await api.logout(pair.refreshToken);
      }
    } catch (_) {
      // Local logout still proceeds.
    } finally {
      await storage.clear();
    }
  }

  /// Revokes all refresh sessions, then clears local tokens.
  Future<void> logoutAll() async {
    try {
      await api.revokeAllSessions();
    } catch (_) {
      // Local logout still proceeds.
    } finally {
      await storage.clear();
    }
  }
}

/// Process-scoped authentication repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    storage: ref.watch(authTokenStorageProvider),
  );
});

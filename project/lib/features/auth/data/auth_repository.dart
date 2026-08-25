import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/auth/data/account_session.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_api.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_storage.dart';
import 'package:home_cleaning_marketplace/features/auth/data/flutter_secure_auth_token_storage.dart';
import 'package:home_cleaning_marketplace/features/auth/data/signup_result.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_user.dart';

/// Authentication use cases over [AuthApi] and secure token storage.
class AuthRepository {
  /// Creates a repository.
  AuthRepository({required this.api, required this.storage});

  final AuthApi api;
  final AuthTokenStorage storage;

  /// Registers a customer or cleaner without storing tokens.
  Future<SignupResult> signUp({
    required String email,
    required String password,
    required String role,
  }) {
    return api.signUp(email: email, password: password, role: role);
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

  /// Public verification resend.
  Future<AccountActionRequestResult> requestEmailVerification(String email) {
    return api.requestEmailVerification(email);
  }

  /// Public verification consume.
  Future<void> verifyEmail(String token) {
    return api.verifyEmail(token);
  }

  /// Public password-reset request.
  Future<AccountActionRequestResult> requestPasswordReset(String email) {
    return api.requestPasswordReset(email);
  }

  /// Public password-reset confirmation.
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) {
    return api.confirmPasswordReset(token: token, newPassword: newPassword);
  }

  /// Authenticated password change. Clears local tokens afterward.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await storage.clear();
  }

  /// Lists active sessions for the signed-in account.
  Future<List<AccountSession>> listSessions() {
    return api.listSessions();
  }

  /// Revokes one owned session. Returns whether the current session was revoked.
  Future<bool> revokeSession(String sessionId) {
    return api.revokeSession(sessionId);
  }

  /// Revokes every session except when clearing locally via [logoutAll].
  Future<void> revokeAllSessions() {
    return api.revokeAllSessions();
  }
}

/// Process-scoped authentication repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    storage: ref.watch(authTokenStorageProvider),
  );
});

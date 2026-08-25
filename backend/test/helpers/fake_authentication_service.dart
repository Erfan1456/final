import 'package:home_cleaning_marketplace_api/src/features/auth/application/authentication_result.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/authentication_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';

/// Test double for auth route tests. Never contacts MongoDB Atlas.
class FakeAuthenticationService implements AuthenticationService {
  /// Creates a fake with optional canned results or errors.
  FakeAuthenticationService();

  /// Result returned by login when [nextError] is null.
  AuthenticationResult? nextAuthResult;

  /// Result returned by signup when [nextError] is null.
  SignupResult? nextSignupResult;

  /// Result returned by refresh when [nextError] is null.
  RefreshedTokens? nextRefreshResult;

  /// When set, the next use-case throws this exception.
  Exception? nextError;

  int signUpCalls = 0;
  int loginCalls = 0;
  int refreshCalls = 0;
  int logoutCalls = 0;
  String? lastEmail;
  String? lastPassword;
  UserRole? lastRole;
  String? lastRefreshToken;

  @override
  Future<SignupResult> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    signUpCalls += 1;
    lastEmail = email;
    lastPassword = password;
    lastRole = role;
    _throwIfNeeded();
    return nextSignupResult!;
  }

  @override
  Future<AuthenticationResult> login({
    required String email,
    required String password,
  }) async {
    loginCalls += 1;
    lastEmail = email;
    lastPassword = password;
    _throwIfNeeded();
    return nextAuthResult!;
  }

  @override
  Future<RefreshedTokens> refresh(String rawRefreshToken) async {
    refreshCalls += 1;
    lastRefreshToken = rawRefreshToken;
    _throwIfNeeded();
    return nextRefreshResult!;
  }

  @override
  Future<void> logout(String rawRefreshToken) async {
    logoutCalls += 1;
    lastRefreshToken = rawRefreshToken;
    _throwIfNeeded();
  }

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }
}

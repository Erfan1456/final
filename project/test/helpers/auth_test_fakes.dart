import 'dart:async';

import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_storage.dart';
import 'package:home_cleaning_marketplace/features/auth/data/development_account_action.dart';
import 'package:home_cleaning_marketplace/features/auth/data/signup_result.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_user.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';

class SeededAuthController extends AuthController {
  SeededAuthController(this._seed);

  final AuthState _seed;
  int loginCalls = 0;
  int logoutCalls = 0;
  int logoutAllCalls = 0;
  Completer<void>? submitGate;
  String? nextError;
  String? nextErrorCode;
  AuthUser? nextAuthenticatedUser;

  @override
  AuthState build() => _seed;

  @override
  Future<void> login({required String email, required String password}) async {
    loginCalls += 1;
    state = state.copyWith(isSubmitting: true, clearError: true);
    if (submitGate != null) {
      await submitGate!.future;
    }
    if (nextError != null) {
      state = AuthState.unauthenticated(
        errorMessage: nextError,
        errorCode: nextErrorCode,
      );
      return;
    }
    state = AuthState.authenticated(nextAuthenticatedUser ?? testUser());
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
    state = const AuthState.unauthenticated();
  }

  @override
  Future<void> logoutAll() async {
    logoutAllCalls += 1;
    state = const AuthState.unauthenticated();
  }

  @override
  void clearAuthenticatedSession() {
    state = const AuthState.unauthenticated();
  }

  /// Test stand-in for current-session revoke / remote session invalidation.
  void expireSession() {
    clearAuthenticatedSession();
  }
}

AuthUser testUser({
  String id = '507f1f77bcf86cd799439011',
  String role = 'customer',
  String email = 'person@example.com',
  bool emailVerified = true,
}) {
  final created = DateTime.utc(2026, 8, 25, 12);
  return AuthUser(
    id: id,
    role: role,
    email: email,
    accountStatus: 'active',
    emailVerified: emailVerified,
    createdAt: created,
    updatedAt: created,
  );
}

/// Overrides [authControllerProvider] with an authenticated seeded session.
List<dynamic> authenticatedAuthOverrides([AuthUser? user]) {
  return [
    authControllerProvider.overrideWith(
      () => SeededAuthController(AuthState.authenticated(user ?? testUser())),
    ),
  ];
}

SignupResult testSignupResult({
  String role = 'customer',
  String email = 'person@example.com',
  String? developmentToken,
}) {
  return SignupResult(
    user: testUser(role: role, email: email, emailVerified: false),
    verificationRequired: true,
    developmentAction: developmentToken == null
        ? null
        : DevelopmentAccountAction(
            purpose: 'email_verification',
            token: developmentToken,
          ),
  );
}

Map<String, dynamic> userJson(AuthUser user) {
  return <String, dynamic>{
    'id': user.id,
    'role': user.role,
    'email': user.email,
    'account_status': user.accountStatus,
    'email_verified': user.emailVerified,
    'created_at': user.createdAt.toIso8601String(),
    'updated_at': user.updatedAt.toIso8601String(),
  };
}

Map<String, dynamic> signupDataJson(
  AuthUser user, {
  bool verificationRequired = true,
  DevelopmentAccountAction? developmentAction,
}) {
  final data = <String, dynamic>{
    'user': userJson(user),
    'verification_required': verificationRequired,
  };
  if (developmentAction != null) {
    data['development_action'] = <String, String>{
      'purpose': developmentAction.purpose,
      'token': developmentAction.token,
    };
  }
  return data;
}

Map<String, dynamic> successEnvelope(Object data) {
  return <String, dynamic>{'success': true, 'data': data};
}

Map<String, dynamic> errorEnvelope({
  required String code,
  required String message,
}) {
  return <String, dynamic>{
    'success': false,
    'error': <String, String>{'code': code, 'message': message},
  };
}

class InMemoryAuthTokenStorage implements AuthTokenStorage {
  AuthTokenPair? value;
  int writeCount = 0;
  int clearCount = 0;
  int readCount = 0;

  @override
  Future<AuthTokenPair?> read() async {
    readCount += 1;
    return value;
  }

  @override
  Future<void> write(AuthTokenPair pair) async {
    writeCount += 1;
    value = pair;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    value = null;
  }
}

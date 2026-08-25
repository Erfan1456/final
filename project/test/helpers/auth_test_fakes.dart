import 'dart:async';

import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_storage.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_user.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';

class SeededAuthController extends AuthController {
  SeededAuthController(this._seed);

  final AuthState _seed;
  int loginCalls = 0;
  int signupCalls = 0;
  int logoutCalls = 0;
  int logoutAllCalls = 0;
  Completer<void>? submitGate;
  String? nextError;

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
      state = AuthState.unauthenticated(errorMessage: nextError);
      return;
    }
    state = AuthState.authenticated(testUser());
  }

  @override
  Future<void> signup({
    required String email,
    required String password,
    required String role,
  }) async {
    signupCalls += 1;
    state = state.copyWith(isSubmitting: true, clearError: true);
    if (submitGate != null) {
      await submitGate!.future;
    }
    if (nextError != null) {
      state = AuthState.unauthenticated(errorMessage: nextError);
      return;
    }
    state = AuthState.authenticated(testUser(role: role));
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
}

AuthUser testUser({
  String role = 'customer',
  String email = 'person@example.com',
}) {
  final created = DateTime.utc(2026, 8, 25, 12);
  return AuthUser(
    id: '507f1f77bcf86cd799439011',
    role: role,
    email: email,
    accountStatus: 'active',
    emailVerified: false,
    createdAt: created,
    updatedAt: created,
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

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_api.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_repository.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_user.dart';

import '../../../helpers/auth_test_fakes.dart';

class _FakeApi extends AuthApi {
  _FakeApi() : super(plain: Dio(), authenticated: Dio());

  ({AuthUser user, AuthTokenPair tokens})? nextAuth;
  AuthUser? nextUser;
  Exception? nextError;
  int signupCalls = 0;
  int loginCalls = 0;
  int meCalls = 0;
  int logoutCalls = 0;
  int revokeCalls = 0;
  String? lastRefreshToken;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<({AuthUser user, AuthTokenPair tokens})> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    signupCalls += 1;
    _throwIfNeeded();
    return nextAuth!;
  }

  @override
  Future<({AuthUser user, AuthTokenPair tokens})> login({
    required String email,
    required String password,
  }) async {
    loginCalls += 1;
    _throwIfNeeded();
    return nextAuth!;
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalls += 1;
    lastRefreshToken = refreshToken;
    _throwIfNeeded();
  }

  @override
  Future<AuthUser> me() async {
    meCalls += 1;
    _throwIfNeeded();
    return nextUser!;
  }

  @override
  Future<void> revokeAllSessions() async {
    revokeCalls += 1;
    _throwIfNeeded();
  }
}

void main() {
  late _FakeApi api;
  late InMemoryAuthTokenStorage storage;
  late AuthRepository repository;
  const pair = AuthTokenPair(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
  );

  setUp(() {
    api = _FakeApi()
      ..nextAuth = (user: testUser(), tokens: pair)
      ..nextUser = testUser();
    storage = InMemoryAuthTokenStorage();
    repository = AuthRepository(api: api, storage: storage);
  });

  test('signup stores the returned pair and returns the user', () async {
    final user = await repository.signUp(
      email: 'person@example.com',
      password: 'fifteenCharsPass',
      role: 'customer',
    );
    expect(user.email, equals('person@example.com'));
    expect(storage.value?.accessToken, equals('access-token'));
    expect(api.signupCalls, equals(1));
  });

  test('login stores the returned pair and returns the user', () async {
    final user = await repository.login(
      email: 'person@example.com',
      password: 'password',
    );
    expect(user.id, equals('507f1f77bcf86cd799439011'));
    expect(storage.value?.refreshToken, equals('refresh-token'));
  });

  test('restore with no tokens is unauthenticated', () async {
    expect(await repository.restoreSession(), isNull);
    expect(api.meCalls, equals(0));
  });

  test('restore with tokens and me success is authenticated', () async {
    storage.value = pair;
    final user = await repository.restoreSession();
    expect(user?.email, equals('person@example.com'));
    expect(api.meCalls, equals(1));
  });

  test(
    'restore treats invalid tokens as unauthenticated and clears storage',
    () async {
      storage.value = pair;
      api.nextError = const AuthFailure(
        code: 'invalid_refresh_token',
        message: 'Your session has expired. Please sign in again.',
      );
      expect(await repository.restoreSession(), isNull);
      expect(storage.value, isNull);
    },
  );

  test('logout clears storage after backend success', () async {
    storage.value = pair;
    await repository.logout();
    expect(api.logoutCalls, equals(1));
    expect(api.lastRefreshToken, equals('refresh-token'));
    expect(storage.value, isNull);
  });

  test('logout clears storage when the backend is unavailable', () async {
    storage.value = pair;
    api.nextError = const AuthFailure(
      code: 'network',
      message: 'Unable to reach the server. Check your connection.',
    );
    await repository.logout();
    expect(storage.value, isNull);
  });

  test('logoutAll revokes remotely and clears local storage', () async {
    storage.value = pair;
    await repository.logoutAll();
    expect(api.revokeCalls, equals(1));
    expect(storage.value, isNull);
  });
}

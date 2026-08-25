import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/auth_session_events.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_api.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_repository.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/data/flutter_secure_auth_token_storage.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_user.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';

import '../../../helpers/auth_test_fakes.dart';

class _FakeApi extends AuthApi {
  _FakeApi() : super(plain: Dio(), authenticated: Dio());

  ({AuthUser user, AuthTokenPair tokens})? nextAuth;
  AuthUser? nextUser;
  Exception? nextError;
  Completer<void>? loginGate;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<({AuthUser user, AuthTokenPair tokens})> login({
    required String email,
    required String password,
  }) async {
    if (loginGate != null) {
      await loginGate!.future;
    }
    _throwIfNeeded();
    return nextAuth!;
  }

  @override
  Future<AuthUser> me() async {
    _throwIfNeeded();
    return nextUser!;
  }

  @override
  Future<void> logout(String refreshToken) async {}

  @override
  Future<void> revokeAllSessions() async {}
}

void main() {
  late _FakeApi api;
  late InMemoryAuthTokenStorage storage;
  late AuthSessionEventBus events;
  const pair = AuthTokenPair(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
  );

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        authTokenStorageProvider.overrideWithValue(storage),
        authSessionEventsProvider.overrideWithValue(events),
        authRepositoryProvider.overrideWithValue(
          AuthRepository(api: api, storage: storage),
        ),
      ],
    );
  }

  setUp(() {
    api = _FakeApi()
      ..nextAuth = (user: testUser(), tokens: pair)
      ..nextUser = testUser();
    storage = InMemoryAuthTokenStorage();
    events = AuthSessionEventBus();
  });

  tearDown(() {
    events.dispose();
  });

  test(
    'startup restoration authenticates when tokens and me succeed',
    () async {
      storage.value = pair;
      final container = createContainer();
      addTearDown(container.dispose);

      expect(
        container.read(authControllerProvider).status,
        AuthStatus.restoring,
      );
      await container.read(authControllerProvider.notifier).restoreSession();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.email, 'person@example.com');
    },
  );

  test('unauthenticated startup when storage is empty', () async {
    final container = createContainer();
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
  });

  test('login success becomes authenticated', () async {
    final container = createContainer();
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();
    await container
        .read(authControllerProvider.notifier)
        .login(email: 'person@example.com', password: 'password');
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.authenticated,
    );
  });

  test('login error stays unauthenticated with a safe message', () async {
    api.nextError = const AuthFailure(
      code: 'invalid_credentials',
      message: 'Invalid email or password.',
    );
    final container = createContainer();
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();
    await container
        .read(authControllerProvider.notifier)
        .login(email: 'person@example.com', password: 'wrong');
    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.errorMessage, 'Invalid email or password.');
  });

  test('login email_not_verified exposes error code', () async {
    api.nextError = const AuthFailure(
      code: 'email_not_verified',
      message: 'Verify your email before signing in.',
    );
    final container = createContainer();
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();
    await container
        .read(authControllerProvider.notifier)
        .login(email: 'person@example.com', password: 'password');
    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.errorCode, 'email_not_verified');
    expect(state.errorMessage, 'Verify your email before signing in.');
  });

  test('logout becomes unauthenticated', () async {
    storage.value = pair;
    final container = createContainer();
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();
    await container.read(authControllerProvider.notifier).logout();
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(storage.value, isNull);
  });

  test('logout-all becomes unauthenticated', () async {
    storage.value = pair;
    final container = createContainer();
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();
    await container.read(authControllerProvider.notifier).logoutAll();
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(storage.value, isNull);
  });

  test('session-expired event becomes unauthenticated', () async {
    storage.value = pair;
    final container = createContainer();
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.authenticated,
    );

    events.emitExpired();
    await pumpEventQueue();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
  });

  test('login sets a loading state while the request is active', () async {
    api.loginGate = Completer<void>();
    final container = createContainer();
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();
    final pending = container
        .read(authControllerProvider.notifier)
        .login(email: 'person@example.com', password: 'password');
    await pumpEventQueue();
    expect(container.read(authControllerProvider).isSubmitting, isTrue);
    api.loginGate!.complete();
    await pending;
    expect(container.read(authControllerProvider).isSubmitting, isFalse);
  });
}

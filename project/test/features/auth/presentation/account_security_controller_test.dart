import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_api.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_repository.dart';
import 'package:home_cleaning_marketplace/features/auth/data/flutter_secure_auth_token_storage.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/account_security_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';

import '../../../helpers/auth_test_fakes.dart';

class _FakeApi extends AuthApi {
  _FakeApi() : super(plain: Dio(), authenticated: Dio());

  Completer<void>? changePasswordGate;
  int changePasswordCalls = 0;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls += 1;
    if (changePasswordGate != null) {
      await changePasswordGate!.future;
    }
  }
}

void main() {
  test('changePassword ignores duplicate presses while in flight', () async {
    final api = _FakeApi()..changePasswordGate = Completer<void>();
    final storage = InMemoryAuthTokenStorage();
    final auth = SeededAuthController(AuthState.authenticated(testUser()));
    final container = ProviderContainer(
      overrides: [
        authTokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(
          AuthRepository(api: api, storage: storage),
        ),
        authControllerProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(accountSecurityControllerProvider.notifier);
    final first = notifier.changePassword(
      currentPassword: 'old-password',
      newPassword: 'new-password-1',
    );
    await pumpEventQueue();
    expect(
      container.read(accountSecurityControllerProvider).isSubmitting,
      isTrue,
    );
    final second = notifier.changePassword(
      currentPassword: 'old-password',
      newPassword: 'new-password-2',
    );
    api.changePasswordGate!.complete();
    final results = await Future.wait<bool>([first, second]);
    expect(results, equals([true, false]));
    expect(api.changePasswordCalls, equals(1));
  });
}

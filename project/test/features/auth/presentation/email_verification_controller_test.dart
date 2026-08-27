import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_api.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_repository.dart';
import 'package:home_cleaning_marketplace/features/auth/data/development_account_action.dart';
import 'package:home_cleaning_marketplace/features/auth/data/flutter_secure_auth_token_storage.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/email_verification_controller.dart';

import '../../../helpers/auth_test_fakes.dart';

class _FakeApi extends AuthApi {
  _FakeApi() : super(plain: Dio(), authenticated: Dio());

  Exception? nextError;

  @override
  Future<AccountActionRequestResult> requestEmailVerification(
    String email,
  ) async {
    if (nextError != null) {
      throw nextError!;
    }
    return const AccountActionRequestResult(
      message: 'If an account exists, a verification email was sent.',
      developmentAction: DevelopmentAccountAction(
        purpose: 'email_verification',
        token: 'verify-token',
      ),
    );
  }

  @override
  Future<void> verifyEmail(String token) async {
    if (nextError != null) {
      throw nextError!;
    }
  }
}

void main() {
  late _FakeApi api;
  late InMemoryAuthTokenStorage storage;

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        authTokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(
          AuthRepository(api: api, storage: storage),
        ),
      ],
    );
  }

  setUp(() {
    api = _FakeApi();
    storage = InMemoryAuthTokenStorage();
  });

  test('requestVerification stores success and development token', () async {
    final container = createContainer();
    addTearDown(container.dispose);
    await container
        .read(emailVerificationControllerProvider.notifier)
        .requestVerification('person@example.com');
    final state = container.read(emailVerificationControllerProvider);
    expect(state.successMessage, contains('verification'));
    expect(state.developmentAction?.token, equals('verify-token'));
  });

  test('verify returns true on success', () async {
    final container = createContainer();
    addTearDown(container.dispose);
    final ok = await container
        .read(emailVerificationControllerProvider.notifier)
        .verify('verify-token');
    expect(ok, isTrue);
    expect(
      container.read(emailVerificationControllerProvider).successMessage,
      contains('verified'),
    );
  });

  test('verify surfaces safe errors', () async {
    api.nextError = const AuthFailure(
      code: 'invalid_or_expired_account_action_token',
      message: 'This link has expired or is invalid. Request a new one.',
    );
    final container = createContainer();
    addTearDown(container.dispose);
    final ok = await container
        .read(emailVerificationControllerProvider.notifier)
        .verify('bad-token');
    expect(ok, isFalse);
    expect(
      container.read(emailVerificationControllerProvider).errorMessage,
      contains('expired'),
    );
  });
}

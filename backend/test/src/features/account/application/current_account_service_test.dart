import 'package:home_cleaning_marketplace_api/src/features/account/application/current_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/auth_session_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

class _MockUsers extends Mock implements UserRepository {}

class _MockSessions extends Mock implements AuthSessionService {}

void main() {
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
  final createdAt = DateTime.utc(2026, 8, 25, 12);

  UserAccount account({
    AccountStatus status = AccountStatus.active,
    UserRole role = UserRole.customer,
  }) {
    return UserAccount(
      id: userId,
      role: role,
      email: 'Person@example.com',
      emailNormalized: 'person@example.com',
      passwordHash: 'hashed-password-must-not-appear',
      accountStatus: status,
      emailVerified: false,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  late _MockUsers users;
  late _MockSessions sessions;
  late CurrentAccountServiceImpl service;

  setUpAll(() {
    registerFallbackValue(ObjectId());
  });

  setUp(() {
    users = _MockUsers();
    sessions = _MockSessions();
    service = CurrentAccountServiceImpl(users: users, sessions: sessions);
  });

  group('CurrentAccountService.getCurrentUser', () {
    test('returns the persisted active account', () async {
      when(() => users.findById(userId)).thenAnswer((_) async => account());

      final user = await service.getCurrentUser(userId);

      expect(user.id, equals(userId));
      expect(user.role, equals(UserRole.customer));
      expect(user.accountStatus, equals(AccountStatus.active));
    });

    test(
      'returns the persisted role rather than a caller-supplied role',
      () async {
        when(
          () => users.findById(userId),
        ).thenAnswer((_) async => account(role: UserRole.cleaner));

        final user = await service.getCurrentUser(userId);

        expect(user.role, equals(UserRole.cleaner));
      },
    );

    test('missing user is an authentication failure', () async {
      when(() => users.findById(userId)).thenAnswer((_) async => null);

      expect(
        () => service.getCurrentUser(userId),
        throwsA(isA<InvalidAccessTokenException>()),
      );
    });

    test('suspended accounts are unavailable', () async {
      when(
        () => users.findById(userId),
      ).thenAnswer((_) async => account(status: AccountStatus.suspended));

      expect(
        () => service.getCurrentUser(userId),
        throwsA(isA<AccountUnavailableException>()),
      );
    });

    test('deactivated accounts are unavailable', () async {
      when(
        () => users.findById(userId),
      ).thenAnswer((_) async => account(status: AccountStatus.deactivated));

      expect(
        () => service.getCurrentUser(userId),
        throwsA(isA<AccountUnavailableException>()),
      );
    });
  });

  group('CurrentAccountService.revokeAllSessions', () {
    test('revokes all sessions for the user', () async {
      when(() => sessions.revokeAllForUser(userId)).thenAnswer((_) async => 3);

      await service.revokeAllSessions(userId);

      verify(() => sessions.revokeAllForUser(userId)).called(1);
    });
  });

  group('UnconfiguredCurrentAccountService', () {
    test('fails getCurrentUser with a configuration exception', () async {
      const unconfigured = UnconfiguredCurrentAccountService();
      expect(
        () => unconfigured.getCurrentUser(userId),
        throwsA(isA<AuthenticationConfigurationException>()),
      );
    });

    test('fails revokeAllSessions with a configuration exception', () async {
      const unconfigured = UnconfiguredCurrentAccountService();
      expect(
        () => unconfigured.revokeAllSessions(userId),
        throwsA(isA<AuthenticationConfigurationException>()),
      );
    });
  });
}

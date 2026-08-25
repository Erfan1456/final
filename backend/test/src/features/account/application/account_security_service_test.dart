import 'package:home_cleaning_marketplace_api/src/features/account/application/account_security_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_delivery_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/development_account_action_delivery_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/data/account_action_token_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_purpose.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/security/account_action_token_crypto.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_hasher.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/auth_session_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../helpers/memory_account_action_documents.dart';

class _MockUsers extends Mock implements UserRepository {}

class _MockSessions extends Mock implements AuthSessionService {}

class _RecordingHasher implements PasswordHasher {
  @override
  String hash(String password) => 'hashed:$password';

  @override
  bool needsRehash(String encodedHash) => false;

  @override
  bool verify({required String password, required String encodedHash}) {
    return encodedHash == 'hashed:$password';
  }
}

void main() {
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
  final sessionId = ObjectId.fromHexString('507f1f77bcf86cd799439012');
  final now = DateTime.utc(2026, 8, 25, 12);

  UserAccount activeUser({
    bool emailVerified = false,
    AccountStatus status = AccountStatus.active,
    String passwordHash = 'hashed:current-password',
  }) {
    return UserAccount(
      id: userId,
      role: UserRole.customer,
      email: 'person@example.com',
      emailNormalized: 'person@example.com',
      passwordHash: passwordHash,
      accountStatus: status,
      emailVerified: emailVerified,
      createdAt: now,
      updatedAt: now,
    );
  }

  late _MockUsers users;
  late _MockSessions sessions;
  late AccountActionTokenService actions;
  late AccountSecurityServiceImpl service;

  setUpAll(() {
    registerFallbackValue(ObjectId());
    registerFallbackValue(DateTime.utc(2026));
  });

  setUp(() {
    users = _MockUsers();
    sessions = _MockSessions();
    var counter = 0;
    actions = AccountActionTokenService(
      tokens: MongoAccountActionTokenRepository(
        documents: MemoryAccountActionDocuments(),
      ),
      generator: AccountActionTokenGenerator(
        randomBytes: (length) => List<int>.generate(
          length,
          (index) => counter++,
        ),
      ),
      clock: () => now,
    );
    service = AccountSecurityServiceImpl(
      users: users,
      actions: actions,
      delivery: const DevelopmentAccountActionDeliveryProvider(),
      passwordPolicy: const PasswordPolicy(),
      passwordHasher: _RecordingHasher(),
      sessions: sessions,
      exposeDevelopmentAction: true,
      clock: () => now,
    );
  });

  group('AccountSecurityService.requestEmailVerification', () {
    test('returns generic result for unknown email', () async {
      when(() => users.findByEmail(any())).thenAnswer((_) async => null);
      final result = await service.requestEmailVerification('missing@example.com');
      expect(result.developmentAction, isNull);
    });

    test('issues development action for unverified user', () async {
      when(
        () => users.findByEmail(any()),
      ).thenAnswer((_) async => activeUser());
      final result = await service.requestEmailVerification('person@example.com');
      expect(result.developmentAction, isNotNull);
      expect(
        result.developmentAction!.purpose,
        equals(AccountActionPurpose.emailVerification),
      );
    });
  });

  group('AccountSecurityService.verifyEmail', () {
    test('marks email verified after valid token', () async {
      when(
        () => users.findByEmail(any()),
      ).thenAnswer((_) async => activeUser());
      final issued = await service.requestEmailVerification('person@example.com');
      when(
        () => users.markEmailVerified(
          userId: userId,
          updatedAt: any(named: 'updatedAt'),
        ),
      ).thenAnswer((_) async => activeUser(emailVerified: true));

      await service.verifyEmail(issued.developmentAction!.token);
      verify(
        () => users.markEmailVerified(userId: userId, updatedAt: now),
      ).called(1);
    });
  });

  group('AccountSecurityService.confirmPasswordReset', () {
    test('rejects password reuse before claim', () async {
      when(
        () => users.findByEmail(any()),
      ).thenAnswer((_) async => activeUser(emailVerified: true));
      final request = await service.requestPasswordReset('person@example.com');
      when(() => users.findById(userId)).thenAnswer(
        (_) async => activeUser(emailVerified: true),
      );

      await expectLater(
        service.confirmPasswordReset(
          rawToken: request.developmentAction!.token,
          newPassword: 'current-password',
        ),
        throwsA(isA<PasswordReuseNotAllowedException>()),
      );
    });

    test('revokes all sessions after successful reset', () async {
      when(
        () => users.findByEmail(any()),
      ).thenAnswer((_) async => activeUser(emailVerified: true));
      final request = await service.requestPasswordReset('person@example.com');
      when(() => users.findById(userId)).thenAnswer(
        (_) async => activeUser(emailVerified: true),
      );
      when(
        () => users.updatePasswordHash(
          userId: any(named: 'userId'),
          passwordHash: any(named: 'passwordHash'),
          updatedAt: any(named: 'updatedAt'),
        ),
      ).thenAnswer((_) async {});
      when(() => sessions.revokeAllForUser(userId)).thenAnswer((_) async => 1);

      await service.confirmPasswordReset(
        rawToken: request.developmentAction!.token,
        newPassword: 'brand-new-password',
      );
      verify(() => sessions.revokeAllForUser(userId)).called(1);
    });
  });

  group('AccountSecurityService.changePassword', () {
    test('rejects wrong current password', () async {
      when(() => users.findById(userId)).thenAnswer(
        (_) async => activeUser(emailVerified: true),
      );
      await expectLater(
        service.changePassword(
          userId: userId,
          currentPassword: 'wrong-password',
          newPassword: 'brand-new-password',
        ),
        throwsA(isA<InvalidCurrentPasswordException>()),
      );
    });

    test('revokes all sessions after success', () async {
      when(() => users.findById(userId)).thenAnswer(
        (_) async => activeUser(emailVerified: true),
      );
      when(
        () => users.updatePasswordHash(
          userId: any(named: 'userId'),
          passwordHash: any(named: 'passwordHash'),
          updatedAt: any(named: 'updatedAt'),
        ),
      ).thenAnswer((_) async {});
      when(() => sessions.revokeAllForUser(userId)).thenAnswer((_) async => 2);

      await service.changePassword(
        userId: userId,
        currentPassword: 'current-password',
        newPassword: 'brand-new-password',
      );
      verify(() => sessions.revokeAllForUser(userId)).called(1);
    });
  });

  group('AccountSecurityService.listSessions', () {
    test('marks current session from principal', () async {
      when(() => users.findById(userId)).thenAnswer(
        (_) async => activeUser(emailVerified: true),
      );
      when(() => sessions.listActiveForUser(userId)).thenAnswer((_) async {
        return <UserSession>[
          UserSession(
            id: sessionId,
            userId: userId,
            refreshTokenHash: 'hash-a',
            usedRefreshTokenHashes: const <String>[],
            expiresAt: now.add(const Duration(days: 30)),
            createdAt: now,
            lastRotatedAt: now,
          ),
        ];
      });

      final listed = await service.listSessions(
        userId: userId,
        currentSessionId: sessionId,
      );
      expect(listed.single.isCurrent, isTrue);
    });
  });
}

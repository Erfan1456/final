import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_delivery_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/development_account_action_delivery_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_purpose.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_token.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/authentication_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_hasher.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/auth_session_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/create_user_account_data.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

class _MockUsers extends Mock implements UserRepository {}

class _MockSessions extends Mock implements AuthSessionService {}

class _MockTokens extends Mock implements AccessTokenService {}

class _MockAccountActions extends Mock implements AccountActionTokenService {}

class _RecordingHasher implements PasswordHasher {
  _RecordingHasher();

  static const dummyHash = 'dummy-encoded-hash';

  final hashCalls = <String>[];
  final verifyCalls = <({String password, String encodedHash})>[];
  final needsRehashCalls = <String>[];
  bool Function(String encodedHash)? needsRehashImpl;

  @override
  String hash(String password) {
    hashCalls.add(password);
    return 'hashed:$password';
  }

  @override
  bool verify({
    required String password,
    required String encodedHash,
  }) {
    verifyCalls.add((password: password, encodedHash: encodedHash));
    if (encodedHash == dummyHash) {
      return false;
    }
    return encodedHash == 'hashed:$password';
  }

  @override
  bool needsRehash(String encodedHash) {
    needsRehashCalls.add(encodedHash);
    return needsRehashImpl?.call(encodedHash) ?? false;
  }
}

void main() {
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
  final sessionId = ObjectId.fromHexString('507f1f77bcf86cd799439012');
  final createdAt = DateTime.utc(2026, 8, 25, 12);
  const signupPassword = 'fifteenCharsPass';
  const loginPassword = 'correct-password';
  const dummyHash = _RecordingHasher.dummyHash;

  UserAccount account({
    UserRole role = UserRole.customer,
    AccountStatus status = AccountStatus.active,
    String passwordHash = 'hashed:correct-password',
    String email = 'Person@example.com',
    bool emailVerified = true,
  }) {
    return UserAccount(
      id: userId,
      role: role,
      email: email,
      emailNormalized: 'person@example.com',
      passwordHash: passwordHash,
      accountStatus: status,
      emailVerified: emailVerified,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  UserSession session({ObjectId? owner}) {
    return UserSession(
      id: sessionId,
      userId: owner ?? userId,
      refreshTokenHash: 'session-refresh-hash',
      usedRefreshTokenHashes: const <String>[],
      expiresAt: DateTime.utc(2026, 9, 24, 12),
      createdAt: createdAt,
      lastRotatedAt: createdAt,
    );
  }

  IssuedRefreshSession issued({String raw = 'new-refresh-token'}) {
    return IssuedRefreshSession(session: session(), rawRefreshToken: raw);
  }

  late _MockUsers users;
  late _MockSessions sessions;
  late _MockTokens tokens;
  late _MockAccountActions accountActions;
  late AccountActionDeliveryProvider delivery;
  late _RecordingHasher hasher;
  late AuthenticationServiceImpl service;

  AccountActionToken verificationToken() {
    return AccountActionToken(
      id: ObjectId.fromHexString('507f1f77bcf86cd799439099'),
      userId: userId,
      purpose: AccountActionPurpose.emailVerification,
      tokenHash: 'fake-hash',
      expiresAt: DateTime.utc(2026, 8, 26, 16),
      createdAt: DateTime.utc(2026, 8, 25, 16),
    );
  }

  IssuedAccountAction issuedVerification() {
    return IssuedAccountAction(
      rawToken: 'dev-verification-token',
      token: verificationToken(),
    );
  }

  setUpAll(() {
    registerFallbackValue(ObjectId());
    registerFallbackValue(UserRole.customer);
    registerFallbackValue(
      const CreateUserAccountData(
        role: UserRole.customer,
        email: 'fallback@example.com',
        passwordHash: 'fallback-hash',
      ),
    );
    registerFallbackValue(AccountActionPurpose.emailVerification);
  });

  setUp(() {
    users = _MockUsers();
    sessions = _MockSessions();
    tokens = _MockTokens();
    accountActions = _MockAccountActions();
    delivery = const DevelopmentAccountActionDeliveryProvider();
    hasher = _RecordingHasher();
    service = AuthenticationServiceImpl(
      users: users,
      passwordPolicy: const PasswordPolicy(),
      passwordHasher: hasher,
      accessTokens: tokens,
      sessions: sessions,
      accountActions: accountActions,
      delivery: delivery,
      dummyPasswordHash: dummyHash,
      exposeDevelopmentAction: true,
      clock: () => DateTime.utc(2026, 8, 25, 16),
    );

    when(
      () => accountActions.issue(
        userId: any(named: 'userId'),
        purpose: any(named: 'purpose'),
      ),
    ).thenAnswer((_) async => issuedVerification());

    when(tokens.ensureConfigured).thenReturn(null);
    when(
      () => tokens.issue(
        userId: any(named: 'userId'),
        sessionId: any(named: 'sessionId'),
        role: any(named: 'role'),
      ),
    ).thenReturn('fake-access-token');
    when(() => sessions.createSession(any())).thenAnswer((_) async => issued());
    when(
      () => sessions.rotateRefreshToken(any()),
    ).thenAnswer((_) async => issued(raw: 'rotated-refresh-token'));
    when(() => sessions.revokeById(any())).thenAnswer((_) async {});
    when(() => sessions.revokeSession(any())).thenAnswer((_) async {});
    when(() => users.create(any())).thenAnswer((invocation) async {
      final data =
          invocation.positionalArguments.first as CreateUserAccountData;
      return account(
        role: data.role,
        email: data.email,
        passwordHash: data.passwordHash,
        status: data.accountStatus,
        emailVerified: data.emailVerified,
      );
    });
    when(
      () => users.updatePasswordHash(
        userId: any(named: 'userId'),
        passwordHash: any(named: 'passwordHash'),
        updatedAt: any(named: 'updatedAt'),
      ),
    ).thenAnswer((_) async {});
  });

  group('AuthenticationService.signUp', () {
    test(
      'creates an active unverified customer without issuing tokens',
      () async {
        final result = await service.signUp(
          email: '  Person@example.com  ',
          password: signupPassword,
          role: UserRole.customer,
        );

        final data =
            verify(() => users.create(captureAny())).captured.single
                as CreateUserAccountData;
        expect(data.role, equals(UserRole.customer));
        expect(data.email, equals('Person@example.com'));
        expect(data.passwordHash, equals('hashed:$signupPassword'));
        expect(data.accountStatus, equals(AccountStatus.active));
        expect(data.emailVerified, isFalse);
        expect(hasher.hashCalls, equals(<String>[signupPassword]));
        verifyNever(() => sessions.createSession(any()));
        verifyNever(
          () => tokens.issue(
            userId: any(named: 'userId'),
            sessionId: any(named: 'sessionId'),
            role: any(named: 'role'),
          ),
        );
        verify(
          () => accountActions.issue(
            userId: userId,
            purpose: AccountActionPurpose.emailVerification,
          ),
        ).called(1);
        expect(result.user.role, equals(UserRole.customer));
        expect(result.verificationRequired, isTrue);
        expect(result.developmentAction, isNotNull);
      },
    );

    test('creates a cleaner account pending verification', () async {
      final result = await service.signUp(
        email: 'cleaner@example.com',
        password: signupPassword,
        role: UserRole.cleaner,
      );

      expect(result.user.role, equals(UserRole.cleaner));
      verifyNever(() => sessions.createSession(any()));
    });

    test('rejects admin signup before persistence', () async {
      await expectLater(
        service.signUp(
          email: 'admin@example.com',
          password: signupPassword,
          role: UserRole.admin,
        ),
        throwsA(isA<InvalidAuthInputException>()),
      );
      verifyNever(() => users.create(any()));
      verifyNever(() => sessions.createSession(any()));
    });

    test('rejects passwords that fail policy without hashing', () async {
      await expectLater(
        service.signUp(
          email: 'person@example.com',
          password: 'too-short',
          role: UserRole.customer,
        ),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(hasher.hashCalls, isEmpty);
      verifyNever(() => users.create(any()));
    });

    test('does not transform the password before hashing', () async {
      const password = '  fifteenChars!!  ';
      await service.signUp(
        email: 'person@example.com',
        password: password,
        role: UserRole.customer,
      );
      expect(hasher.hashCalls, equals(<String>[password]));
    });

    test('maps duplicate emails without creating a session', () async {
      when(() => users.create(any())).thenThrow(
        const DuplicateUserEmailException(),
      );

      await expectLater(
        service.signUp(
          email: 'person@example.com',
          password: signupPassword,
          role: UserRole.customer,
        ),
        throwsA(isA<DuplicateUserEmailException>()),
      );
      verifyNever(() => sessions.createSession(any()));
    });

    test('returns delivery unavailable when provider is unavailable', () async {
      service = AuthenticationServiceImpl(
        users: users,
        passwordPolicy: const PasswordPolicy(),
        passwordHasher: hasher,
        accessTokens: tokens,
        sessions: sessions,
        accountActions: accountActions,
        delivery: const _UnavailableDelivery(),
        dummyPasswordHash: dummyHash,
        exposeDevelopmentAction: false,
        clock: () => DateTime.utc(2026, 8, 25, 16),
      );
      when(
        () => accountActions.issue(
          userId: any(named: 'userId'),
          purpose: any(named: 'purpose'),
        ),
      ).thenAnswer((_) async => issuedVerification());

      await expectLater(
        service.signUp(
          email: 'person@example.com',
          password: signupPassword,
          role: UserRole.customer,
        ),
        throwsA(isA<AccountActionDeliveryUnavailableException>()),
      );
      verify(() => users.create(any())).called(1);
      verifyNever(() => sessions.createSession(any()));
    });
  });

  group('AuthenticationService.login', () {
    test('succeeds for a matching active account', () async {
      when(() => users.findByEmail(any())).thenAnswer((_) async => account());

      final result = await service.login(
        email: '  Person@example.com  ',
        password: loginPassword,
      );

      verify(() => users.findByEmail('Person@example.com')).called(1);
      expect(hasher.verifyCalls, hasLength(1));
      expect(
        hasher.verifyCalls.single.encodedHash,
        equals('hashed:$loginPassword'),
      );
      verifyNever(
        () => users.updatePasswordHash(
          userId: any(named: 'userId'),
          passwordHash: any(named: 'passwordHash'),
          updatedAt: any(named: 'updatedAt'),
        ),
      );
      verify(() => sessions.createSession(userId)).called(1);
      expect(result.accessToken, equals('fake-access-token'));
      expect(result.refreshToken, equals('new-refresh-token'));
    });

    test('unknown email still verifies the dummy hash', () async {
      when(() => users.findByEmail(any())).thenAnswer((_) async => null);

      await expectLater(
        service.login(
          email: 'missing@example.com',
          password: loginPassword,
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );
      expect(hasher.verifyCalls, hasLength(1));
      expect(hasher.verifyCalls.single.encodedHash, equals(dummyHash));
      expect(hasher.verifyCalls.single.password, equals(loginPassword));
      verifyNever(() => sessions.createSession(any()));
      verifyNever(
        () => users.updatePasswordHash(
          userId: any(named: 'userId'),
          passwordHash: any(named: 'passwordHash'),
          updatedAt: any(named: 'updatedAt'),
        ),
      );
    });

    test('wrong password and unknown email use the same exception', () async {
      when(() => users.findByEmail(any())).thenAnswer((_) async => account());
      Object? wrongPasswordError;
      try {
        await service.login(
          email: 'person@example.com',
          password: 'wrong-password',
        );
      } catch (error) {
        wrongPasswordError = error;
      }

      when(() => users.findByEmail(any())).thenAnswer((_) async => null);
      Object? missingUserError;
      try {
        await service.login(
          email: 'missing@example.com',
          password: loginPassword,
        );
      } catch (error) {
        missingUserError = error;
      }

      expect(wrongPasswordError, isA<InvalidCredentialsException>());
      expect(missingUserError, isA<InvalidCredentialsException>());
      expect(
        wrongPasswordError.runtimeType,
        equals(missingUserError.runtimeType),
      );
      verifyNever(() => sessions.createSession(any()));
    });

    test('does not apply signup minimum length before verification', () async {
      when(() => users.findByEmail(any())).thenAnswer((_) async => account());

      await expectLater(
        service.login(email: 'person@example.com', password: 'short'),
        throwsA(isA<InvalidCredentialsException>()),
      );
      expect(hasher.verifyCalls, hasLength(1));
    });

    test(
      'rejects suspended and deactivated accounts after a valid password',
      () async {
        when(() => users.findByEmail(any())).thenAnswer(
          (_) async => account(status: AccountStatus.suspended),
        );
        await expectLater(
          service.login(email: 'person@example.com', password: loginPassword),
          throwsA(isA<AccountUnavailableException>()),
        );

        when(() => users.findByEmail(any())).thenAnswer(
          (_) async => account(status: AccountStatus.deactivated),
        );
        await expectLater(
          service.login(email: 'person@example.com', password: loginPassword),
          throwsA(isA<AccountUnavailableException>()),
        );
        verifyNever(() => sessions.createSession(any()));
      },
    );

    test('rejects unverified accounts after a valid password', () async {
      when(() => users.findByEmail(any())).thenAnswer(
        (_) async => account(emailVerified: false),
      );

      await expectLater(
        service.login(
          email: 'person@example.com',
          password: loginPassword,
        ),
        throwsA(isA<EmailNotVerifiedException>()),
      );
      verifyNever(() => sessions.createSession(any()));
    });

    test('rehashes an outdated hash after successful authentication', () async {
      hasher.needsRehashImpl = (_) => true;
      when(() => users.findByEmail(any())).thenAnswer((_) async => account());

      await service.login(
        email: 'person@example.com',
        password: loginPassword,
      );

      verify(
        () => users.updatePasswordHash(
          userId: userId,
          passwordHash: 'hashed:$loginPassword',
          updatedAt: DateTime.utc(2026, 8, 25, 16),
        ),
      ).called(1);
      verify(() => sessions.createSession(userId)).called(1);
    });

    test('does not rehash a current hash', () async {
      hasher.needsRehashImpl = (_) => false;
      when(() => users.findByEmail(any())).thenAnswer((_) async => account());

      await service.login(
        email: 'person@example.com',
        password: loginPassword,
      );

      verifyNever(
        () => users.updatePasswordHash(
          userId: any(named: 'userId'),
          passwordHash: any(named: 'passwordHash'),
          updatedAt: any(named: 'updatedAt'),
        ),
      );
    });

    test('does not rehash a wrong password', () async {
      hasher.needsRehashImpl = (_) => true;
      when(() => users.findByEmail(any())).thenAnswer((_) async => account());

      await expectLater(
        service.login(email: 'person@example.com', password: 'wrong-password'),
        throwsA(isA<InvalidCredentialsException>()),
      );
      verifyNever(
        () => users.updatePasswordHash(
          userId: any(named: 'userId'),
          passwordHash: any(named: 'passwordHash'),
          updatedAt: any(named: 'updatedAt'),
        ),
      );
    });
  });

  group('AuthenticationService.refresh', () {
    test('returns a new refresh token and current role', () async {
      when(() => users.findById(userId)).thenAnswer(
        (_) async => account(role: UserRole.cleaner),
      );

      final result = await service.refresh('old-refresh-token');

      expect(result.refreshToken, equals('rotated-refresh-token'));
      expect(result.refreshToken, isNot(equals('old-refresh-token')));
      expect(result.accessToken, equals('fake-access-token'));
      expect(result.expiresInSeconds, equals(900));
      verify(
        () => tokens.issue(
          userId: userId,
          sessionId: sessionId,
          role: UserRole.cleaner,
        ),
      ).called(1);
      verifyNever(() => sessions.revokeById(any()));
    });

    test('revokes the session when the user is missing', () async {
      when(() => users.findById(userId)).thenAnswer((_) async => null);

      await expectLater(
        service.refresh('old-refresh-token'),
        throwsA(isA<InvalidRefreshCredentialsException>()),
      );
      verify(() => sessions.revokeById(sessionId)).called(1);
    });

    test('revokes the session for suspended and deactivated users', () async {
      when(() => users.findById(userId)).thenAnswer(
        (_) async => account(status: AccountStatus.suspended),
      );
      await expectLater(
        service.refresh('old-refresh-token'),
        throwsA(isA<InvalidRefreshCredentialsException>()),
      );

      when(() => users.findById(userId)).thenAnswer(
        (_) async => account(status: AccountStatus.deactivated),
      );
      await expectLater(
        service.refresh('old-refresh-token'),
        throwsA(isA<InvalidRefreshCredentialsException>()),
      );
      verify(() => sessions.revokeById(sessionId)).called(2);
    });

    test('maps replay and invalid refresh failures generically', () async {
      when(() => sessions.rotateRefreshToken(any())).thenThrow(
        const RefreshTokenReuseDetectedException(),
      );
      await expectLater(
        service.refresh('old-refresh-token'),
        throwsA(isA<InvalidRefreshCredentialsException>()),
      );

      when(() => sessions.rotateRefreshToken(any())).thenThrow(
        const InvalidRefreshTokenException(),
      );
      await expectLater(
        service.refresh('old-refresh-token'),
        throwsA(isA<InvalidRefreshCredentialsException>()),
      );
      verifyNever(() => users.findById(any()));
    });
  });

  group('AuthenticationService.logout', () {
    test('delegates revocation for a valid token', () async {
      await service.logout('raw-refresh-token');
      verify(() => sessions.revokeSession('raw-refresh-token')).called(1);
    });

    test('treats unknown tokens as successful', () async {
      when(() => sessions.revokeSession(any())).thenThrow(
        const InvalidRefreshTokenException(),
      );

      await service.logout('unknown-refresh-token');
    });
  });

  group('UnconfiguredAuthenticationService', () {
    test('fails signup before any persistence concern', () async {
      const unconfigured = UnconfiguredAuthenticationService();
      await expectLater(
        unconfigured.signUp(
          email: 'person@example.com',
          password: signupPassword,
          role: UserRole.customer,
        ),
        throwsA(isA<AuthenticationConfigurationException>()),
      );
    });
  });
}

class _UnavailableDelivery implements AccountActionDeliveryProvider {
  const _UnavailableDelivery();

  @override
  bool get isAvailable => false;

  @override
  Future<DevelopmentAccountAction?> deliverEmailVerification({
    required String recipientEmail,
    required String rawToken,
    required DateTime expiresAt,
  }) async {
    return null;
  }

  @override
  Future<DevelopmentAccountAction?> deliverPasswordReset({
    required String recipientEmail,
    required String rawToken,
    required DateTime expiresAt,
  }) async {
    return null;
  }
}

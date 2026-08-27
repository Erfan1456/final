import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_delivery_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_purpose.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/authentication_result.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/email_input.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_hasher.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/auth_session_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/create_user_account_data.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';

/// Authentication use-case boundary used by HTTP routes.
///
/// Implementations must not depend on Dart Frog request or response types.
abstract interface class AuthenticationService {
  /// Creates a customer or cleaner account without issuing a session.
  Future<SignupResult> signUp({
    required String email,
    required String password,
    required UserRole role,
  });

  /// Authenticates an existing verified account and issues tokens.
  Future<AuthenticationResult> login({
    required String email,
    required String password,
  });

  /// Rotates a refresh token and issues a new access token.
  Future<RefreshedTokens> refresh(String rawRefreshToken);

  /// Revokes the session for [rawRefreshToken]. Idempotent for unknown tokens.
  Future<void> logout(String rawRefreshToken);
}

/// Production authentication use cases.
class AuthenticationServiceImpl implements AuthenticationService {
  /// Creates a service over existing persistence and security primitives.
  ///
  /// [dummyPasswordHash] must be a process-scoped encoded Argon2id hash, not
  /// a real credential, and must not be regenerated on every login.
  AuthenticationServiceImpl({
    required UserRepository users,
    required PasswordPolicy passwordPolicy,
    required PasswordHasher passwordHasher,
    required AccessTokenService accessTokens,
    required AuthSessionService sessions,
    required AccountActionTokenService accountActions,
    required AccountActionDeliveryProvider delivery,
    required String dummyPasswordHash,
    required bool exposeDevelopmentAction,
    DateTime Function()? clock,
  }) : _users = users,
       _passwordPolicy = passwordPolicy,
       _passwordHasher = passwordHasher,
       _accessTokens = accessTokens,
       _sessions = sessions,
       _accountActions = accountActions,
       _delivery = delivery,
       _dummyPasswordHash = dummyPasswordHash,
       _exposeDevelopmentAction = exposeDevelopmentAction,
       _clock = clock ?? _utcNow;

  final UserRepository _users;
  final PasswordPolicy _passwordPolicy;
  final PasswordHasher _passwordHasher;
  final AccessTokenService _accessTokens;
  final AuthSessionService _sessions;
  final AccountActionTokenService _accountActions;
  final AccountActionDeliveryProvider _delivery;
  final String _dummyPasswordHash;
  final bool _exposeDevelopmentAction;
  final DateTime Function() _clock;

  static DateTime _utcNow() => DateTime.now().toUtc();

  @override
  Future<SignupResult> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (role != UserRole.customer && role != UserRole.cleaner) {
      throw const InvalidAuthInputException(
        code: 'invalid_role',
        message: 'Public signup allows only customer or cleaner roles.',
      );
    }

    final trimmedEmail = EmailInput.parse(email);
    final policy = _passwordPolicy.validate(password);
    if (!policy.isValid) {
      throw const InvalidAuthInputException(
        code: 'invalid_password',
        message: 'Password does not meet the length requirements.',
      );
    }

    final passwordHash = _passwordHasher.hash(password);
    final user = await _users.create(
      CreateUserAccountData(
        role: role,
        email: trimmedEmail,
        passwordHash: passwordHash,
      ),
    );
    final issued = await _accountActions.issue(
      userId: user.id,
      purpose: AccountActionPurpose.emailVerification,
    );
    if (!_delivery.isAvailable) {
      throw const AccountActionDeliveryUnavailableException();
    }
    final delivered = await _delivery.deliverEmailVerification(
      recipientEmail: user.email,
      rawToken: issued.rawToken,
      expiresAt: issued.token.expiresAt,
    );
    if (_exposeDevelopmentAction) {
      return SignupResult(
        user: user,
        developmentAction: delivered,
      );
    }
    return SignupResult(user: user);
  }

  @override
  Future<AuthenticationResult> login({
    required String email,
    required String password,
  }) async {
    _ensureTokensConfigured();
    final trimmedEmail = EmailInput.parse(email);
    _rejectUnreasonableLoginPassword(password);

    final user = await _users.findByEmail(trimmedEmail);
    if (user == null) {
      _passwordHasher.verify(
        password: password,
        encodedHash: _dummyPasswordHash,
      );
      throw const InvalidCredentialsException();
    }

    final matches = _passwordHasher.verify(
      password: password,
      encodedHash: user.passwordHash,
    );
    if (!matches) {
      throw const InvalidCredentialsException();
    }

    if (user.accountStatus != AccountStatus.active) {
      throw const AccountUnavailableException();
    }

    if (!user.emailVerified) {
      throw const EmailNotVerifiedException();
    }

    if (_passwordHasher.needsRehash(user.passwordHash)) {
      final replacement = _passwordHasher.hash(password);
      await _users.updatePasswordHash(
        userId: user.id,
        passwordHash: replacement,
        updatedAt: _clock().toUtc(),
      );
    }

    return _issueFor(user);
  }

  @override
  Future<RefreshedTokens> refresh(String rawRefreshToken) async {
    _ensureTokensConfigured();
    if (rawRefreshToken.isEmpty) {
      throw const InvalidAuthInputException(
        code: 'invalid_input',
        message: 'refresh_token is required.',
      );
    }

    final rotated = await _rotateOrFail(rawRefreshToken);
    try {
      final user = await _users.findById(rotated.session.userId);
      if (user == null || user.accountStatus != AccountStatus.active) {
        await _sessions.revokeById(rotated.session.id);
        throw const InvalidRefreshCredentialsException();
      }

      final accessToken = _accessTokens.issue(
        userId: user.id,
        sessionId: rotated.session.id,
        role: user.role,
      );
      return RefreshedTokens(
        accessToken: accessToken,
        refreshToken: rotated.rawRefreshToken,
        expiresInSeconds: accessTokenExpiresInSeconds,
      );
    } on InvalidRefreshCredentialsException {
      rethrow;
    } catch (error) {
      await _sessions.revokeById(rotated.session.id);
      if (error is AccessTokenConfigurationException) {
        throw const AuthenticationConfigurationException();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout(String rawRefreshToken) async {
    if (rawRefreshToken.isEmpty) {
      return;
    }
    try {
      await _sessions.revokeSession(rawRefreshToken);
    } on InvalidRefreshTokenException {
      // Unknown, expired, or already revoked tokens remain successful.
    }
  }

  Future<IssuedRefreshSession> _rotateOrFail(String rawRefreshToken) async {
    try {
      return await _sessions.rotateRefreshToken(rawRefreshToken);
    } on RefreshTokenReuseDetectedException {
      throw const InvalidRefreshCredentialsException();
    } on InvalidRefreshTokenException {
      throw const InvalidRefreshCredentialsException();
    }
  }

  Future<AuthenticationResult> _issueFor(UserAccount user) async {
    final issued = await _sessions.createSession(user.id);
    final accessToken = _accessTokens.issue(
      userId: user.id,
      sessionId: issued.session.id,
      role: user.role,
    );
    return AuthenticationResult(
      user: user,
      accessToken: accessToken,
      refreshToken: issued.rawRefreshToken,
      expiresInSeconds: accessTokenExpiresInSeconds,
    );
  }

  void _ensureTokensConfigured() {
    try {
      _accessTokens.ensureConfigured();
    } on AccessTokenConfigurationException {
      throw const AuthenticationConfigurationException();
    }
  }

  void _rejectUnreasonableLoginPassword(String password) {
    if (password.isEmpty ||
        password.runes.length > PasswordPolicy.maximumLength) {
      throw const InvalidAuthInputException(
        code: 'invalid_password',
        message: 'Password is missing or exceeds the supported length.',
      );
    }
  }
}

/// Authentication service used when MongoDB or token configuration is unusable.
class UnconfiguredAuthenticationService implements AuthenticationService {
  /// Creates a service that fails every use case before persistence.
  const UnconfiguredAuthenticationService();

  @override
  Future<SignupResult> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    throw const AuthenticationConfigurationException();
  }

  @override
  Future<AuthenticationResult> login({
    required String email,
    required String password,
  }) async {
    throw const AuthenticationConfigurationException();
  }

  @override
  Future<RefreshedTokens> refresh(String rawRefreshToken) async {
    throw const AuthenticationConfigurationException();
  }

  @override
  Future<void> logout(String rawRefreshToken) async {
    throw const AuthenticationConfigurationException();
  }
}

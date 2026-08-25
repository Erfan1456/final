import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_delivery_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_purpose.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/email_input.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_hasher.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/auth_session_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Generic public recovery/verification request result.
class AccountActionRequestResult {
  /// Creates a generic request result.
  const AccountActionRequestResult({this.developmentAction});

  /// Present only when development/test delivery produced an action.
  final DevelopmentAccountAction? developmentAction;
}

/// Safe listed session metadata. Never includes refresh-token hashes.
class AccountSessionSummary {
  /// Creates a session summary.
  const AccountSessionSummary({
    required this.id,
    required this.createdAt,
    required this.expiresAt,
    required this.lastRotatedAt,
    required this.isCurrent,
  });

  /// Session `_id`.
  final ObjectId id;

  /// UTC creation time.
  final DateTime createdAt;

  /// UTC expiry.
  final DateTime expiresAt;

  /// UTC last rotation time.
  final DateTime lastRotatedAt;

  /// Whether this session matches the verified access-token principal.
  final bool isCurrent;
}

/// Result of revoking one owned session.
class OwnedSessionRevocation {
  /// Creates a revocation result.
  const OwnedSessionRevocation({required this.currentSessionRevoked});

  /// True when the revoked session is the caller's current session.
  final bool currentSessionRevoked;
}

/// HTTP-independent account recovery, verification, password, and session
/// security use cases.
abstract interface class AccountSecurityService {
  /// Enumeration-resistant verification request.
  Future<AccountActionRequestResult> requestEmailVerification(String email);

  /// Consumes a verification token. Does not issue a session.
  Future<void> verifyEmail(String rawToken);

  /// Enumeration-resistant password-reset request.
  Future<AccountActionRequestResult> requestPasswordReset(String email);

  /// Consumes a reset token, updates the password, and revokes sessions.
  Future<void> confirmPasswordReset({
    required String rawToken,
    required String newPassword,
  });

  /// Authenticated password change. Revokes all sessions.
  Future<void> changePassword({
    required ObjectId userId,
    required String currentPassword,
    required String newPassword,
  });

  /// Lists active owned sessions, newest first, capped at 50.
  Future<List<AccountSessionSummary>> listSessions({
    required ObjectId userId,
    required ObjectId currentSessionId,
  });

  /// Revokes one owned session. Foreign/unknown sessions are not found.
  Future<OwnedSessionRevocation> revokeSession({
    required ObjectId userId,
    required ObjectId sessionId,
    required ObjectId currentSessionId,
  });
}

/// Production account-security use cases.
class AccountSecurityServiceImpl implements AccountSecurityService {
  /// Creates a service over existing persistence and security primitives.
  AccountSecurityServiceImpl({
    required UserRepository users,
    required AccountActionTokenService actions,
    required AccountActionDeliveryProvider delivery,
    required PasswordPolicy passwordPolicy,
    required PasswordHasher passwordHasher,
    required AuthSessionService sessions,
    required bool exposeDevelopmentAction,
    DateTime Function()? clock,
  }) : _users = users,
       _actions = actions,
       _delivery = delivery,
       _passwordPolicy = passwordPolicy,
       _passwordHasher = passwordHasher,
       _sessions = sessions,
       _exposeDevelopmentAction = exposeDevelopmentAction,
       _clock = clock ?? _utcNow;

  final UserRepository _users;
  final AccountActionTokenService _actions;
  final AccountActionDeliveryProvider _delivery;
  final PasswordPolicy _passwordPolicy;
  final PasswordHasher _passwordHasher;
  final AuthSessionService _sessions;
  final bool _exposeDevelopmentAction;
  final DateTime Function() _clock;

  static DateTime _utcNow() => DateTime.now().toUtc();

  /// Generic public message for verification requests.
  static const String verificationRequestMessage =
      'If verification is required for that account, instructions are '
      'available.';

  /// Generic public message for password-reset requests.
  static const String passwordResetRequestMessage =
      'If an eligible account exists, password reset instructions are '
      'available.';

  @override
  Future<AccountActionRequestResult> requestEmailVerification(
    String email,
  ) async {
    _ensureDeliveryAvailable();
    final trimmed = EmailInput.parse(email);
    final user = await _users.findByEmail(trimmed);
    if (user == null || user.emailVerified) {
      return const AccountActionRequestResult();
    }
    return _issueAndDeliver(
      user: user,
      purpose: AccountActionPurpose.emailVerification,
    );
  }

  @override
  Future<void> verifyEmail(String rawToken) async {
    final claimed = await _actions.claim(
      rawToken: rawToken,
      purpose: AccountActionPurpose.emailVerification,
    );
    await _users.markEmailVerified(
      userId: claimed.userId,
      updatedAt: _clock().toUtc(),
    );
  }

  @override
  Future<AccountActionRequestResult> requestPasswordReset(String email) async {
    _ensureDeliveryAvailable();
    final trimmed = EmailInput.parse(email);
    final user = await _users.findByEmail(trimmed);
    if (user == null || user.accountStatus == AccountStatus.deactivated) {
      return const AccountActionRequestResult();
    }
    return _issueAndDeliver(
      user: user,
      purpose: AccountActionPurpose.passwordReset,
    );
  }

  @override
  Future<void> confirmPasswordReset({
    required String rawToken,
    required String newPassword,
  }) async {
    _validateNewPassword(newPassword);
    final live = await _actions.findLive(
      rawToken: rawToken,
      purpose: AccountActionPurpose.passwordReset,
    );
    if (live == null) {
      throw const InvalidAccountActionTokenException();
    }
    final user = await _users.findById(live.userId);
    if (user == null) {
      throw const InvalidAccountActionTokenException();
    }
    if (user.accountStatus == AccountStatus.deactivated) {
      throw const AccountUnavailableException();
    }
    if (_passwordHasher.verify(
      password: newPassword,
      encodedHash: user.passwordHash,
    )) {
      throw const PasswordReuseNotAllowedException();
    }
    await _actions.claim(
      rawToken: rawToken,
      purpose: AccountActionPurpose.passwordReset,
    );
    await _users.updatePasswordHash(
      userId: user.id,
      passwordHash: _passwordHasher.hash(newPassword),
      updatedAt: _clock().toUtc(),
    );
    await _sessions.revokeAllForUser(user.id);
  }

  @override
  Future<void> changePassword({
    required ObjectId userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await _requireActiveUser(userId);
    if (currentPassword.isEmpty ||
        currentPassword.runes.length > PasswordPolicy.maximumLength) {
      throw const InvalidCurrentPasswordException();
    }
    final matches = _passwordHasher.verify(
      password: currentPassword,
      encodedHash: user.passwordHash,
    );
    if (!matches) {
      throw const InvalidCurrentPasswordException();
    }
    _validateNewPassword(newPassword);
    if (_passwordHasher.verify(
      password: newPassword,
      encodedHash: user.passwordHash,
    )) {
      throw const PasswordReuseNotAllowedException();
    }
    await _users.updatePasswordHash(
      userId: user.id,
      passwordHash: _passwordHasher.hash(newPassword),
      updatedAt: _clock().toUtc(),
    );
    await _sessions.revokeAllForUser(user.id);
  }

  @override
  Future<List<AccountSessionSummary>> listSessions({
    required ObjectId userId,
    required ObjectId currentSessionId,
  }) async {
    await _requireActiveUser(userId);
    final sessions = await _sessions.listActiveForUser(userId);
    return [
      for (final session in sessions) _summary(session, currentSessionId),
    ];
  }

  @override
  Future<OwnedSessionRevocation> revokeSession({
    required ObjectId userId,
    required ObjectId sessionId,
    required ObjectId currentSessionId,
  }) async {
    await _requireActiveUser(userId);
    final revoked = await _sessions.revokeOwnedSession(
      userId: userId,
      sessionId: sessionId,
    );
    if (revoked == null) {
      throw const SessionNotFoundException();
    }
    return OwnedSessionRevocation(
      currentSessionRevoked: sessionId == currentSessionId,
    );
  }

  Future<AccountActionRequestResult> _issueAndDeliver({
    required UserAccount user,
    required AccountActionPurpose purpose,
  }) async {
    final issued = await _actions.issue(
      userId: user.id,
      purpose: purpose,
    );
    final delivered = purpose == AccountActionPurpose.emailVerification
        ? await _delivery.deliverEmailVerification(
            recipientEmail: user.email,
            rawToken: issued.rawToken,
            expiresAt: issued.token.expiresAt,
          )
        : await _delivery.deliverPasswordReset(
            recipientEmail: user.email,
            rawToken: issued.rawToken,
            expiresAt: issued.token.expiresAt,
          );
    return AccountActionRequestResult(
      developmentAction: _exposeDevelopmentAction ? delivered : null,
    );
  }

  void _ensureDeliveryAvailable() {
    if (!_delivery.isAvailable) {
      throw const AccountActionDeliveryUnavailableException();
    }
  }

  void _validateNewPassword(String password) {
    final policy = _passwordPolicy.validate(password);
    if (!policy.isValid) {
      throw const InvalidAuthInputException(
        code: 'invalid_password',
        message: 'Password does not meet the length requirements.',
      );
    }
  }

  Future<UserAccount> _requireActiveUser(ObjectId userId) async {
    final user = await _users.findById(userId);
    if (user == null) {
      throw const InvalidAccessTokenException();
    }
    if (user.accountStatus != AccountStatus.active) {
      throw const AccountUnavailableException();
    }
    return user;
  }

  AccountSessionSummary _summary(
    UserSession session,
    ObjectId currentSessionId,
  ) {
    return AccountSessionSummary(
      id: session.id,
      createdAt: session.createdAt,
      expiresAt: session.expiresAt,
      lastRotatedAt: session.lastRotatedAt,
      isCurrent: session.id == currentSessionId,
    );
  }
}

/// Account-security service used when MongoDB is unconfigured.
class UnconfiguredAccountSecurityService implements AccountSecurityService {
  /// Creates a service that fails every use case before persistence.
  const UnconfiguredAccountSecurityService();

  @override
  Future<AccountActionRequestResult> requestEmailVerification(String email) {
    throw const AuthenticationConfigurationException();
  }

  @override
  Future<void> verifyEmail(String rawToken) {
    throw const AuthenticationConfigurationException();
  }

  @override
  Future<AccountActionRequestResult> requestPasswordReset(String email) {
    throw const AuthenticationConfigurationException();
  }

  @override
  Future<void> confirmPasswordReset({
    required String rawToken,
    required String newPassword,
  }) {
    throw const AuthenticationConfigurationException();
  }

  @override
  Future<void> changePassword({
    required ObjectId userId,
    required String currentPassword,
    required String newPassword,
  }) {
    throw const AuthenticationConfigurationException();
  }

  @override
  Future<List<AccountSessionSummary>> listSessions({
    required ObjectId userId,
    required ObjectId currentSessionId,
  }) {
    throw const AuthenticationConfigurationException();
  }

  @override
  Future<OwnedSessionRevocation> revokeSession({
    required ObjectId userId,
    required ObjectId sessionId,
    required ObjectId currentSessionId,
  }) {
    throw const AuthenticationConfigurationException();
  }
}

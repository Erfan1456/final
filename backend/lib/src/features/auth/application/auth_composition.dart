import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/account_security_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_delivery_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/development_account_action_delivery_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/data/account_action_token_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/authentication_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/argon2id_password_hasher.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_hasher.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/auth_session_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/mongo_user_session_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/jwt_access_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/mongo_user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Fixed fake password used only to produce a process-scoped dummy hash.
///
/// This is not a real credential and is not a signing secret.
const String dummyTimingPassword = 'not-a-real-user-password';

/// Access-token service that fails configuration checks without a secret.
class UnavailableAccessTokenService implements AccessTokenService {
  /// Creates an unavailable token service.
  const UnavailableAccessTokenService();

  @override
  void ensureConfigured() {
    throw const AccessTokenConfigurationException();
  }

  @override
  String issue({
    required ObjectId userId,
    required ObjectId sessionId,
    required UserRole role,
  }) {
    throw const AccessTokenConfigurationException();
  }

  @override
  Never verify(String token) {
    throw const AccessTokenConfigurationException();
  }
}

/// Process-scoped authentication composition for Dart Frog auth routes.
///
/// Dummy Argon2 hashing and Mongo repositories are created once per process
/// after a successful first composition, not on every request.
class AuthComposition {
  AuthComposition._();

  static final PasswordHasher _hasher = Argon2idPasswordHasher();
  static AuthenticationService? _cached;
  static AccountSecurityService? _cachedSecurity;
  static String? _dummyPasswordHash;
  static Future<void>? _inFlight;

  /// Returns a shared [AuthenticationService] for the current process.
  static Future<AuthenticationService> resolve({
    required ServerConfig config,
    required MongoDatabase mongo,
  }) async {
    await _ensureComposed(config: config, mongo: mongo);
    return _cached!;
  }

  /// Returns a shared [AccountSecurityService] for the current process.
  static Future<AccountSecurityService> resolveSecurity({
    required ServerConfig config,
    required MongoDatabase mongo,
  }) async {
    await _ensureComposed(config: config, mongo: mongo);
    return _cachedSecurity!;
  }

  static Future<void> _ensureComposed({
    required ServerConfig config,
    required MongoDatabase mongo,
  }) {
    if (_cached != null && _cachedSecurity != null) {
      return Future<void>.value();
    }
    return _inFlight ??= _compose(config: config, mongo: mongo).whenComplete(
      () {
        _inFlight = null;
      },
    );
  }

  static Future<void> _compose({
    required ServerConfig config,
    required MongoDatabase mongo,
  }) async {
    AccessTokenService tokens;
    try {
      tokens = JwtAccessTokenService.fromConfig(config);
    } on AccessTokenConfigurationException {
      tokens = const UnavailableAccessTokenService();
    }

    if (!mongo.isConfigured) {
      _cached = const UnconfiguredAuthenticationService();
      _cachedSecurity = const UnconfiguredAccountSecurityService();
      return;
    }

    try {
      await mongo.connect();
    } catch (_) {
      _cached = const UnconfiguredAuthenticationService();
      _cachedSecurity = const UnconfiguredAccountSecurityService();
      return;
    }
    final db = mongo.db;
    if (db == null) {
      _cached = const UnconfiguredAuthenticationService();
      _cachedSecurity = const UnconfiguredAccountSecurityService();
      return;
    }

    _dummyPasswordHash ??= _hasher.hash(dummyTimingPassword);
    final users = MongoUserRepository.fromDb(db);
    final sessions = AuthSessionService(
      sessions: MongoUserSessionRepository.fromDb(db),
    );
    final actions = AccountActionTokenService(
      tokens: MongoAccountActionTokenRepository.fromDb(db),
    );
    final delivery = _deliveryProvider(config);
    final exposeDevelopmentAction = config.allowsDevelopmentAccountActions;
    _cached = AuthenticationServiceImpl(
      users: users,
      passwordPolicy: const PasswordPolicy(),
      passwordHasher: _hasher,
      accessTokens: tokens,
      sessions: sessions,
      accountActions: actions,
      delivery: delivery,
      dummyPasswordHash: _dummyPasswordHash!,
      exposeDevelopmentAction: exposeDevelopmentAction,
    );
    _cachedSecurity = AccountSecurityServiceImpl(
      users: users,
      actions: actions,
      delivery: delivery,
      passwordPolicy: const PasswordPolicy(),
      passwordHasher: _hasher,
      sessions: sessions,
      exposeDevelopmentAction: exposeDevelopmentAction,
    );
  }

  static AccountActionDeliveryProvider _deliveryProvider(ServerConfig config) {
    if (config.allowsDevelopmentAccountActions) {
      return const DevelopmentAccountActionDeliveryProvider();
    }
    return const UnavailableAccountActionDeliveryProvider();
  }
}

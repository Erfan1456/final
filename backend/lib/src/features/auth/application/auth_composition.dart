import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
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
  static String? _dummyPasswordHash;
  static Future<AuthenticationService>? _inFlight;

  /// Returns a shared [AuthenticationService] for the current process.
  static Future<AuthenticationService> resolve({
    required ServerConfig config,
    required MongoDatabase mongo,
  }) {
    final cached = _cached;
    if (cached != null) {
      return Future<AuthenticationService>.value(cached);
    }
    return _inFlight ??= _compose(config: config, mongo: mongo).whenComplete(
      () {
        _inFlight = null;
      },
    );
  }

  static Future<AuthenticationService> _compose({
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
      return _cached = const UnconfiguredAuthenticationService();
    }

    try {
      await mongo.connect();
    } catch (_) {
      return const UnconfiguredAuthenticationService();
    }
    final db = mongo.db;
    if (db == null) {
      return const UnconfiguredAuthenticationService();
    }

    _dummyPasswordHash ??= _hasher.hash(dummyTimingPassword);
    return _cached = AuthenticationServiceImpl(
      users: MongoUserRepository.fromDb(db),
      passwordPolicy: const PasswordPolicy(),
      passwordHasher: _hasher,
      accessTokens: tokens,
      sessions: AuthSessionService(
        sessions: MongoUserSessionRepository.fromDb(db),
      ),
      dummyPasswordHash: _dummyPasswordHash!,
    );
  }
}

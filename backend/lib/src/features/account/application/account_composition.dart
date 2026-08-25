import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/current_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/auth_session_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/mongo_user_session_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/jwt_access_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/mongo_user_repository.dart';

/// Process-scoped composition for protected account routes.
class AccountComposition {
  AccountComposition._();

  static CurrentAccountService? _cached;
  static Future<CurrentAccountService>? _inFlight;

  /// Returns an [AccessTokenService] for the current process configuration.
  ///
  /// Does not connect MongoDB. Missing or short secrets yield
  /// [UnavailableAccessTokenService].
  static AccessTokenService accessTokens(ServerConfig config) {
    try {
      return JwtAccessTokenService.fromConfig(config);
    } on AccessTokenConfigurationException {
      return const UnavailableAccessTokenService();
    }
  }

  /// Returns a shared [CurrentAccountService] for the current process.
  static Future<CurrentAccountService> resolve({
    required MongoDatabase mongo,
  }) {
    final cached = _cached;
    if (cached != null) {
      return Future<CurrentAccountService>.value(cached);
    }
    return _inFlight ??= _compose(mongo: mongo).whenComplete(() {
      _inFlight = null;
    });
  }

  static Future<CurrentAccountService> _compose({
    required MongoDatabase mongo,
  }) async {
    if (!mongo.isConfigured) {
      return _cached = const UnconfiguredCurrentAccountService();
    }

    try {
      await mongo.connect();
    } catch (_) {
      return const UnconfiguredCurrentAccountService();
    }
    final db = mongo.db;
    if (db == null) {
      return const UnconfiguredCurrentAccountService();
    }

    return _cached = CurrentAccountServiceImpl(
      users: MongoUserRepository.fromDb(db),
      sessions: AuthSessionService(
        sessions: MongoUserSessionRepository.fromDb(db),
      ),
    );
  }
}

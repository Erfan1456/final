import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/account_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/access_authenticator.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/current_authenticated_user_resolver.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/role_request_authorizer.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/cleaner_onboarding_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/application/customer_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/mongo_user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Process-scoped composition for role-authorized feature routes.
class RoleScopedComposition {
  RoleScopedComposition._();

  static CustomerAccountService? _customer;
  static CleanerOnboardingService? _cleaner;
  static AdminCleanerReviewService? _admin;
  static CurrentAuthenticatedUserResolver? _resolver;
  static UserRepository? _users;

  /// Builds a [RoleRequestAuthorizer] from request providers.
  ///
  /// Tests may provide [AccessAuthenticator] and
  /// [CurrentAuthenticatedUserResolver] on the context.
  static Future<RoleRequestAuthorizer> authorizer(
    RequestContext context,
  ) async {
    final authenticator =
        _tryRead<AccessAuthenticator>(context) ??
        AccessAuthenticator(
          tokens: AccountComposition.accessTokens(context.read<ServerConfig>()),
        );
    final resolver =
        _tryRead<CurrentAuthenticatedUserResolver>(context) ??
        await _userResolver(context.read<MongoDatabase>());
    return RoleRequestAuthorizer(
      authenticator: authenticator,
      resolver: resolver,
    );
  }

  /// Shared customer profile/address service.
  static Future<CustomerAccountService> customer({
    required MongoDatabase mongo,
  }) async {
    final cached = _customer;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _customer = CustomerAccountService(
      profiles: MongoCustomerProfileRepository.fromDb(db),
      addresses: MongoAddressRepository.fromDb(db),
    );
  }

  /// Shared cleaner onboarding service.
  static Future<CleanerOnboardingService> cleaner({
    required MongoDatabase mongo,
  }) async {
    final cached = _cleaner;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _cleaner = CleanerOnboardingService(
      profiles: MongoCleanerProfileRepository.fromDb(db),
    );
  }

  /// Shared admin cleaner-review service.
  static Future<AdminCleanerReviewService> admin({
    required MongoDatabase mongo,
  }) async {
    final cached = _admin;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _admin = AdminCleanerReviewService(
      profiles: MongoCleanerProfileRepository.fromDb(db),
      users: MongoUserRepository.fromDb(db),
    );
  }

  static Future<CurrentAuthenticatedUserResolver> _userResolver(
    MongoDatabase mongo,
  ) async {
    final cached = _resolver;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _resolver = CurrentAuthenticatedUserResolver(
      users: _users ??= MongoUserRepository.fromDb(db),
    );
  }

  static Future<Db> _requireDb(MongoDatabase mongo) async {
    if (!mongo.isConfigured) {
      throw const AuthenticationConfigurationException();
    }
    try {
      await mongo.connect();
    } catch (_) {
      throw const AuthenticationConfigurationException();
    }
    final db = mongo.db;
    if (db == null) {
      throw const AuthenticationConfigurationException();
    }
    return db;
  }

  static T? _tryRead<T>(RequestContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }
}

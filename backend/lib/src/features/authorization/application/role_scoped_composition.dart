import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/account_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/access_authenticator.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/approved_cleaner_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/current_authenticated_user_resolver.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/role_request_authorizer.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/application/cleaner_availability_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/cleaner_booking_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/customer_booking_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/cleaner_onboarding_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/application/cleaner_service_management_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/application/customer_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/discovery/application/cleaner_discovery_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
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
  static ServiceRepository? _services;
  static CleanerServiceManagementService? _serviceManagement;
  static CleanerAvailabilityService? _availability;
  static CleanerDiscoveryService? _discovery;
  static CustomerBookingService? _customerBookings;
  static CleanerBookingService? _cleanerBookings;

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

  /// Shared platform catalog repository.
  static Future<ServiceRepository> services({
    required MongoDatabase mongo,
  }) async {
    final cached = _services;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _services = MongoServiceRepository.fromDb(db);
  }

  /// Shared cleaner offering management.
  static Future<CleanerServiceManagementService> cleanerServices({
    required MongoDatabase mongo,
  }) async {
    final cached = _serviceManagement;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    final profiles = MongoCleanerProfileRepository.fromDb(db);
    return _serviceManagement = CleanerServiceManagementService(
      policy: ApprovedCleanerPolicy(profiles: profiles),
      services: await services(mongo: mongo),
      offerings: MongoCleanerServiceRepository.fromDb(db),
    );
  }

  /// Shared cleaner availability management.
  static Future<CleanerAvailabilityService> cleanerAvailability({
    required MongoDatabase mongo,
  }) async {
    final cached = _availability;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    final profiles = MongoCleanerProfileRepository.fromDb(db);
    return _availability = CleanerAvailabilityService(
      policy: ApprovedCleanerPolicy(profiles: profiles),
      services: await services(mongo: mongo),
      offerings: MongoCleanerServiceRepository.fromDb(db),
      slots: MongoAvailabilityRepository.fromDb(db),
      bookings: MongoBookingRepository.fromDb(db),
    );
  }

  /// Shared customer discovery.
  static Future<CleanerDiscoveryService> discovery({
    required MongoDatabase mongo,
  }) async {
    final cached = _discovery;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _discovery = CleanerDiscoveryService(
      services: await services(mongo: mongo),
      offerings: MongoCleanerServiceRepository.fromDb(db),
      profiles: MongoCleanerProfileRepository.fromDb(db),
      users: _users ??= MongoUserRepository.fromDb(db),
      slots: MongoAvailabilityRepository.fromDb(db),
      bookings: MongoBookingRepository.fromDb(db),
    );
  }

  /// Shared customer booking service.
  static Future<CustomerBookingService> customerBookings({
    required MongoDatabase mongo,
  }) async {
    final cached = _customerBookings;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _customerBookings = CustomerBookingService(
      addresses: MongoAddressRepository.fromDb(db),
      slots: MongoAvailabilityRepository.fromDb(db),
      users: _users ??= MongoUserRepository.fromDb(db),
      cleanerProfiles: MongoCleanerProfileRepository.fromDb(db),
      services: await services(mongo: mongo),
      offerings: MongoCleanerServiceRepository.fromDb(db),
      bookings: MongoBookingRepository.fromDb(db),
    );
  }

  /// Shared cleaner booking/job service.
  static Future<CleanerBookingService> cleanerBookings({
    required MongoDatabase mongo,
  }) async {
    final cached = _cleanerBookings;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _cleanerBookings = CleanerBookingService(
      bookings: MongoBookingRepository.fromDb(db),
      customerProfiles: MongoCustomerProfileRepository.fromDb(db),
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

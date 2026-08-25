import 'package:home_cleaning_marketplace_api/src/features/authorization/approved_cleaner_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_offering.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/marketplace_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent cleaner offering management.
class CleanerServiceManagementService {
  /// Creates a service over repositories and [policy].
  CleanerServiceManagementService({
    required ApprovedCleanerPolicy policy,
    required ServiceRepository services,
    required CleanerServiceRepository offerings,
  }) : _policy = policy,
       _services = services,
       _offerings = offerings;

  final ApprovedCleanerPolicy _policy;
  final ServiceRepository _services;
  final CleanerServiceRepository _offerings;

  /// Lists the cleaner's offerings joined with safe catalog fields.
  Future<List<Map<String, Object?>>> list(UserAccount user) async {
    await _policy.requireApproved(user);
    final offerings = await _offerings.listForCleaner(user.id);
    final result = <Map<String, Object?>>[];
    for (final offering in offerings) {
      final service = await _services.findById(offering.serviceId);
      if (service == null) {
        continue;
      }
      result.add(_offeringJson(offering, service));
    }
    return result;
  }

  /// Upserts pricing and activation for [serviceId].
  Future<Map<String, Object?>> upsert({
    required UserAccount user,
    required ObjectId serviceId,
    required Object? hourlyRateMinor,
    required Object? currencyCode,
    required Object? isActive,
  }) async {
    await _policy.requireApproved(user);
    final service = await _requireActiveService(serviceId);
    final data = CleanerServiceWriteData(
      hourlyRateMinor: CleanerServiceValidation.requireHourlyRateMinor(
        hourlyRateMinor,
      ),
      currencyCode: CleanerServiceValidation.requireCurrencyCode(currencyCode),
      isActive: CleanerServiceValidation.requireActive(isActive),
    );
    final offering = await _offerings.upsertOffering(
      cleanerUserId: user.id,
      serviceId: serviceId,
      data: data,
    );
    return _offeringJson(offering, service);
  }

  /// Logically deactivates the offering for [serviceId].
  Future<Map<String, Object?>> deactivate({
    required UserAccount user,
    required ObjectId serviceId,
  }) async {
    await _policy.requireApproved(user);
    final service = await _services.findById(serviceId);
    if (service == null) {
      throw const ServiceNotFoundException();
    }
    final offering = await _offerings.deactivateOffering(
      cleanerUserId: user.id,
      serviceId: serviceId,
    );
    if (offering == null) {
      throw const CleanerServiceNotFoundException();
    }
    return _offeringJson(offering, service);
  }

  Future<MarketplaceService> _requireActiveService(ObjectId serviceId) async {
    final service = await _services.findById(serviceId);
    if (service == null || !service.active) {
      throw const ServiceNotFoundException();
    }
    return service;
  }

  Map<String, Object?> _offeringJson(
    CleanerServiceOffering offering,
    MarketplaceService service,
  ) {
    return <String, Object?>{
      'id': offering.id.oid,
      'service': service.toPublicJson(),
      'hourly_rate_minor': offering.hourlyRateMinor,
      'currency_code': offering.currencyCode,
      'is_active': offering.isActive,
      'created_at': offering.createdAt.toUtc().toIso8601String(),
      'updated_at': offering.updatedAt.toUtc().toIso8601String(),
    };
  }
}

import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/marketplace_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_billing_model.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_validation.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Canonical Home Cleaning platform service. Clients cannot mutate the catalog.
abstract final class CanonicalHomeCleaningService {
  /// Stable slug.
  static const String slug = 'home-cleaning';

  /// Display name.
  static const String name = 'Home Cleaning';

  /// Plain-text catalog description.
  static const String description =
      'Hourly professional cleaning for occupied homes, including living '
      'spaces, kitchens, bathrooms, and bedrooms.';

  /// Billing model wire value.
  static const ServiceBillingModel billingModel = ServiceBillingModel.hourly;

  /// Catalog is active for offerings and discovery.
  static const bool active = true;
}

/// Idempotent ensure of the canonical `home-cleaning` catalog document.
///
/// Does not run per HTTP request and does not mutate users, profiles,
/// sessions, cleaner offerings, or availability.
class CanonicalServiceCatalogEnsure {
  /// Creates an ensure workflow over [repository] and [store].
  CanonicalServiceCatalogEnsure({
    required ServiceRepository repository,
    required ServiceCatalogStore store,
    DateTime Function()? clock,
  }) : _repository = repository,
       _store = store,
       _clock = clock ?? DateTime.now;

  final ServiceRepository _repository;
  final ServiceCatalogStore _store;
  final DateTime Function() _clock;

  /// Creates or updates only the canonical Home Cleaning service.
  Future<MarketplaceService> ensureHomeCleaning() async {
    final slug = ServiceValidation.requireSlug(
      CanonicalHomeCleaningService.slug,
    );
    final name = ServiceValidation.requireName(
      CanonicalHomeCleaningService.name,
    );
    final description = ServiceValidation.requireDescription(
      CanonicalHomeCleaningService.description,
    );
    final now = _clock().toUtc();
    final existing = await _repository.findBySlug(slug);
    if (existing == null) {
      final created = MarketplaceService(
        id: ObjectId(),
        slug: slug,
        name: name,
        description: description,
        billingModel: CanonicalHomeCleaningService.billingModel,
        active: CanonicalHomeCleaningService.active,
        createdAt: now,
        updatedAt: now,
      );
      await _store.insert(created);
      return created;
    }
    final updated = MarketplaceService(
      id: existing.id,
      slug: existing.slug,
      name: name,
      description: description,
      billingModel: CanonicalHomeCleaningService.billingModel,
      active: CanonicalHomeCleaningService.active,
      createdAt: existing.createdAt,
      updatedAt: now,
    );
    await _store.updateCanonicalFields(updated);
    return updated;
  }
}

import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_slot.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_offering.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/marketplace_service.dart';

/// Customer-safe discovery list item. Never includes contact or review fields.
class CleanerDiscoverySummary {
  /// Creates a customer-facing summary.
  const CleanerDiscoverySummary({
    required this.cleanerUserId,
    required this.fullName,
    required this.bioExcerpt,
    required this.yearsExperience,
    required this.serviceArea,
    required this.service,
    required this.hourlyRateMinor,
    required this.currencyCode,
    required this.offeringId,
    this.nextAvailableAt,
  });

  /// Builds a summary from joined records.
  factory CleanerDiscoverySummary.fromJoined({
    required CleanerServiceOffering offering,
    required MarketplaceService service,
    required String fullName,
    required String bio,
    required int yearsExperience,
    required String serviceArea,
    required DateTime? nextAvailableAt,
  }) {
    return CleanerDiscoverySummary(
      offeringId: offering.id.oid,
      cleanerUserId: offering.cleanerUserId.oid,
      fullName: fullName,
      bioExcerpt: bio,
      yearsExperience: yearsExperience,
      serviceArea: serviceArea,
      service: service,
      hourlyRateMinor: offering.hourlyRateMinor,
      currencyCode: offering.currencyCode,
      nextAvailableAt: nextAvailableAt,
    );
  }

  /// Offering `_id` used as the pagination cursor.
  final String offeringId;

  /// Cleaner `users._id`.
  final String cleanerUserId;

  /// Public display name.
  final String fullName;

  /// Bio excerpt. May be the full bio.
  final String bioExcerpt;

  /// Years of experience.
  final int yearsExperience;

  /// Display-only service area text.
  final String serviceArea;

  /// Safe catalog fields for the requested service.
  final MarketplaceService service;

  /// Integer minor-unit hourly rate.
  final int hourlyRateMinor;

  /// Uppercase currency code.
  final String currencyCode;

  /// Next future slot start, if any.
  final DateTime? nextAvailableAt;

  /// Customer JSON. Must not include email, phone, or review metadata.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'cleaner_user_id': cleanerUserId,
      'full_name': fullName,
      'bio_excerpt': bioExcerpt,
      'years_experience': yearsExperience,
      'service_area': serviceArea,
      'service': <String, Object?>{
        'id': service.id.oid,
        'slug': service.slug,
        'name': service.name,
      },
      'hourly_rate_minor': hourlyRateMinor,
      'currency_code': currencyCode,
      'next_available_at': nextAvailableAt?.toUtc().toIso8601String(),
    };
  }
}

/// Customer-safe cleaner detail. Never includes contact or review fields.
class CleanerDiscoveryDetail {
  /// Creates a customer-facing detail payload.
  const CleanerDiscoveryDetail({
    required this.cleanerUserId,
    required this.fullName,
    required this.bio,
    required this.yearsExperience,
    required this.serviceArea,
    required this.service,
    required this.hourlyRateMinor,
    required this.currencyCode,
    required this.availability,
  });

  /// Public cleaner user id.
  final String cleanerUserId;

  /// Public display name.
  final String fullName;

  /// Full bio text.
  final String bio;

  /// Years of experience.
  final int yearsExperience;

  /// Display-only service area text.
  final String serviceArea;

  /// Requested catalog service.
  final MarketplaceService service;

  /// Integer minor-unit hourly rate.
  final int hourlyRateMinor;

  /// Uppercase currency code.
  final String currencyCode;

  /// Future slots for the requested service.
  final List<AvailabilitySlot> availability;

  /// Customer JSON. Must not include email, phone, or review metadata.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'cleaner_user_id': cleanerUserId,
      'full_name': fullName,
      'bio': bio,
      'years_experience': yearsExperience,
      'service_area': serviceArea,
      'service': <String, Object?>{
        'id': service.id.oid,
        'slug': service.slug,
        'name': service.name,
        'billing_model': service.billingModel.wireValue,
      },
      'hourly_rate_minor': hourlyRateMinor,
      'currency_code': currencyCode,
      'availability': [
        for (final slot in availability)
          <String, Object?>{
            'id': slot.id.oid,
            'service_id': slot.serviceId.oid,
            'start_at': slot.startAt.toUtc().toIso8601String(),
            'end_at': slot.endAt.toUtc().toIso8601String(),
          },
      ],
    };
  }
}

/// One page of discovery summaries.
class CleanerDiscoveryPage {
  /// Creates a page with an optional [nextCursor] offering id.
  const CleanerDiscoveryPage({
    required this.items,
    required this.nextCursor,
  });

  /// Page items.
  final List<CleanerDiscoverySummary> items;

  /// Offering `_id` cursor for the next page, or `null`.
  final String? nextCursor;

  /// Customer JSON envelope data.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'items': [for (final item in items) item.toJson()],
      'next_cursor': nextCursor,
    };
  }
}

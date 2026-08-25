import 'package:home_cleaning_marketplace/features/availability/data/availability_slot.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';

/// Customer-safe discovery list item.
class CleanerDiscoverySummary {
  const CleanerDiscoverySummary({
    required this.cleanerUserId,
    required this.fullName,
    required this.bioExcerpt,
    required this.yearsExperience,
    required this.serviceArea,
    required this.service,
    required this.hourlyRateMinor,
    required this.currencyCode,
    this.nextAvailableAt,
  });

  factory CleanerDiscoverySummary.fromJson(Map<String, dynamic> json) {
    final cleanerUserId = json['cleaner_user_id'];
    final fullName = json['full_name'];
    final bio = json['bio_excerpt'];
    final years = json['years_experience'];
    final serviceArea = json['service_area'];
    final service = json['service'];
    final rate = json['hourly_rate_minor'];
    final currency = json['currency_code'];
    final next = json['next_available_at'];
    if (cleanerUserId is! String ||
        fullName is! String ||
        bio is! String ||
        years is! int ||
        serviceArea is! String ||
        service is! Map ||
        rate is! int ||
        currency is! String) {
      throw const FormatException('Discovery summary JSON is invalid.');
    }
    return CleanerDiscoverySummary(
      cleanerUserId: cleanerUserId,
      fullName: fullName,
      bioExcerpt: bio,
      yearsExperience: years,
      serviceArea: serviceArea,
      service: MarketplaceService.fromJson(
        Map<String, dynamic>.from({
          ...service,
          'description': service['description'] ?? '',
          'billing_model': service['billing_model'] ?? 'hourly',
        }),
      ),
      hourlyRateMinor: rate,
      currencyCode: currency,
      nextAvailableAt: next is String ? DateTime.parse(next).toUtc() : null,
    );
  }

  final String cleanerUserId;
  final String fullName;
  final String bioExcerpt;
  final int yearsExperience;
  final String serviceArea;
  final MarketplaceService service;
  final int hourlyRateMinor;
  final String currencyCode;
  final DateTime? nextAvailableAt;
}

/// Customer-safe discovery detail.
class CleanerDiscoveryDetail {
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

  factory CleanerDiscoveryDetail.fromJson(Map<String, dynamic> json) {
    final cleanerUserId = json['cleaner_user_id'];
    final fullName = json['full_name'];
    final bio = json['bio'];
    final years = json['years_experience'];
    final serviceArea = json['service_area'];
    final service = json['service'];
    final rate = json['hourly_rate_minor'];
    final currency = json['currency_code'];
    final availability = json['availability'];
    if (cleanerUserId is! String ||
        fullName is! String ||
        bio is! String ||
        years is! int ||
        serviceArea is! String ||
        service is! Map ||
        rate is! int ||
        currency is! String ||
        availability is! List) {
      throw const FormatException('Discovery detail JSON is invalid.');
    }
    return CleanerDiscoveryDetail(
      cleanerUserId: cleanerUserId,
      fullName: fullName,
      bio: bio,
      yearsExperience: years,
      serviceArea: serviceArea,
      service: MarketplaceService.fromJson(
        Map<String, dynamic>.from({
          ...service,
          'description': service['description'] ?? '',
        }),
      ),
      hourlyRateMinor: rate,
      currencyCode: currency,
      availability: [
        for (final item in availability)
          if (item is Map)
            AvailabilitySlot.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }

  final String cleanerUserId;
  final String fullName;
  final String bio;
  final int yearsExperience;
  final String serviceArea;
  final MarketplaceService service;
  final int hourlyRateMinor;
  final String currencyCode;
  final List<AvailabilitySlot> availability;
}

/// One discovery page.
class CleanerDiscoveryPage {
  const CleanerDiscoveryPage({required this.items, this.nextCursor});

  factory CleanerDiscoveryPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final next = json['next_cursor'];
    if (items is! List) {
      throw const FormatException('Discovery page JSON is invalid.');
    }
    return CleanerDiscoveryPage(
      items: [
        for (final item in items)
          if (item is Map)
            CleanerDiscoverySummary.fromJson(Map<String, dynamic>.from(item)),
      ],
      nextCursor: next is String ? next : null,
    );
  }

  final List<CleanerDiscoverySummary> items;
  final String? nextCursor;
}

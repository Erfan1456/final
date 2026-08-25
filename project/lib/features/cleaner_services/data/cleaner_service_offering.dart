import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';

/// Cleaner's offering of one platform service.
class CleanerServiceOffering {
  const CleanerServiceOffering({
    required this.id,
    required this.service,
    required this.hourlyRateMinor,
    required this.currencyCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CleanerServiceOffering.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final service = json['service'];
    final rate = json['hourly_rate_minor'];
    final currency = json['currency_code'];
    final isActive = json['is_active'];
    final createdAt = json['created_at'];
    final updatedAt = json['updated_at'];
    if (id is! String ||
        service is! Map ||
        rate is! int ||
        currency is! String ||
        isActive is! bool ||
        createdAt is! String ||
        updatedAt is! String) {
      throw const FormatException('Cleaner service offering JSON is invalid.');
    }
    return CleanerServiceOffering(
      id: id,
      service: MarketplaceService.fromJson(Map<String, dynamic>.from(service)),
      hourlyRateMinor: rate,
      currencyCode: currency,
      isActive: isActive,
      createdAt: DateTime.parse(createdAt).toUtc(),
      updatedAt: DateTime.parse(updatedAt).toUtc(),
    );
  }

  final String id;
  final MarketplaceService service;
  final int hourlyRateMinor;
  final String currencyCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}

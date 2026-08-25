/// Platform billing model. Unknown server values map to [unknown].
enum BillingModel {
  hourly,
  unknown;

  static BillingModel fromWire(String value) {
    switch (value) {
      case 'hourly':
        return BillingModel.hourly;
      default:
        return BillingModel.unknown;
    }
  }

  String get wireValue {
    switch (this) {
      case BillingModel.hourly:
        return 'hourly';
      case BillingModel.unknown:
        return 'unknown';
    }
  }
}

/// Public marketplace service catalog entry.
class MarketplaceService {
  const MarketplaceService({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.billingModel,
  });

  factory MarketplaceService.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final slug = json['slug'];
    final name = json['name'];
    final description = json['description'];
    final billing = json['billing_model'];
    if (id is! String ||
        slug is! String ||
        name is! String ||
        description is! String ||
        billing is! String) {
      throw const FormatException('Marketplace service JSON is invalid.');
    }
    return MarketplaceService(
      id: id,
      slug: slug,
      name: name,
      description: description,
      billingModel: BillingModel.fromWire(billing),
    );
  }

  final String id;
  final String slug;
  final String name;
  final String description;
  final BillingModel billingModel;
}

/// Integer minor-unit hourly price label. Does not assume decimal places.
String formatMinorHourlyRate(int hourlyRateMinor, String currencyCode) {
  return '$currencyCode $hourlyRateMinor minor units / hour';
}

/// Safe customer service address. [isDefault] is computed by the backend.
class Address {
  /// Creates an address.
  const Address({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.countryCode,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.line2,
  });

  /// Parses a safe address JSON object.
  factory Address.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final label = json['label'];
    final line1 = json['line1'];
    final line2 = json['line2'];
    final city = json['city'];
    final region = json['region'];
    final postalCode = json['postal_code'];
    final countryCode = json['country_code'];
    final isDefault = json['is_default'];
    final createdAt = json['created_at'];
    final updatedAt = json['updated_at'];
    if (id is! String ||
        label is! String ||
        line1 is! String ||
        city is! String ||
        region is! String ||
        postalCode is! String ||
        countryCode is! String ||
        isDefault is! bool ||
        createdAt is! String ||
        updatedAt is! String) {
      throw const FormatException('Address JSON is invalid.');
    }
    return Address(
      id: id,
      label: label,
      line1: line1,
      line2: line2 is String ? line2 : null,
      city: city,
      region: region,
      postalCode: postalCode,
      countryCode: countryCode,
      isDefault: isDefault,
      createdAt: DateTime.parse(createdAt).toUtc(),
      updatedAt: DateTime.parse(updatedAt).toUtc(),
    );
  }

  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String region;
  final String postalCode;
  final String countryCode;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  String toString() => 'Address(id: $id, label: $label)';
}

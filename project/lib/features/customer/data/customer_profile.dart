/// Safe customer profile from the backend.
class CustomerProfile {
  /// Creates a profile. Backend IDs remain strings.
  const CustomerProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.createdAt,
    required this.updatedAt,
    this.phoneE164,
    this.defaultAddressId,
  });

  /// Parses a safe profile JSON object.
  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final userId = json['user_id'];
    final fullName = json['full_name'];
    final phone = json['phone_e164'];
    final defaultAddressId = json['default_address_id'];
    final createdAt = json['created_at'];
    final updatedAt = json['updated_at'];
    if (id is! String ||
        userId is! String ||
        fullName is! String ||
        createdAt is! String ||
        updatedAt is! String) {
      throw const FormatException('Customer profile JSON is invalid.');
    }
    return CustomerProfile(
      id: id,
      userId: userId,
      fullName: fullName,
      phoneE164: phone is String ? phone : null,
      defaultAddressId: defaultAddressId is String ? defaultAddressId : null,
      createdAt: DateTime.parse(createdAt).toUtc(),
      updatedAt: DateTime.parse(updatedAt).toUtc(),
    );
  }

  final String id;
  final String userId;
  final String fullName;
  final String? phoneE164;
  final String? defaultAddressId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  String toString() => 'CustomerProfile(id: $id, userId: $userId)';
}

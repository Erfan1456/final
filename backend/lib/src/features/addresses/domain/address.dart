import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persisted customer service address. Ownership is always [userId].
class Address {
  /// Creates an address. [id] is the MongoDB `_id`.
  const Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.line1,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.countryCode,
    required this.createdAt,
    required this.updatedAt,
    this.line2,
  });

  /// Parses a MongoDB `addresses` document.
  factory Address.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => AddressDocumentException(message);
    return Address(
      id: DocumentFields.requireObjectId(document, '_id', error),
      userId: DocumentFields.requireObjectId(document, 'user_id', error),
      label: DocumentFields.requireString(document, 'label', error),
      line1: DocumentFields.requireString(document, 'line1', error),
      line2: DocumentFields.optionalString(document, 'line2', error),
      city: DocumentFields.requireString(document, 'city', error),
      region: DocumentFields.requireString(document, 'region', error),
      postalCode: DocumentFields.requireString(document, 'postal_code', error),
      countryCode: DocumentFields.requireString(
        document,
        'country_code',
        error,
      ),
      createdAt: DocumentFields.requireUtcDateTime(
        document,
        'created_at',
        error,
      ),
      updatedAt: DocumentFields.requireUtcDateTime(
        document,
        'updated_at',
        error,
      ),
    );
  }

  /// MongoDB `_id`.
  final ObjectId id;

  /// Owning `users._id`. Never taken from an HTTP body.
  final ObjectId userId;

  /// Short label such as Home or Office.
  final String label;

  /// Primary street line.
  final String line1;

  /// Optional second street line.
  final String? line2;

  /// City / locality.
  final String city;

  /// Region / state / division.
  final String region;

  /// Postal code. Not internationally validated.
  final String postalCode;

  /// ISO 3166-1 alpha-2 country code, stored uppercase.
  final String countryCode;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last-update timestamp.
  final DateTime updatedAt;

  /// MongoDB document representation. Does not persist `is_default`.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'user_id': userId,
      'label': label,
      'line1': line1,
      'line2': line2,
      'city': city,
      'region': region,
      'postal_code': postalCode,
      'country_code': countryCode,
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  /// Safe public JSON. [isDefault] is computed from the customer profile.
  Map<String, Object?> toPublicJson({required bool isDefault}) {
    return <String, Object?>{
      'id': id.oid,
      'label': label,
      'line1': line1,
      'line2': line2,
      'city': city,
      'region': region,
      'postal_code': postalCode,
      'country_code': countryCode,
      'is_default': isDefault,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() => 'Address(id: ${id.oid}, userId: ${userId.oid})';
}

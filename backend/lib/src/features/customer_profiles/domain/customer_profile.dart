import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persisted customer marketplace profile. One document per customer user.
class CustomerProfile {
  /// Creates a customer profile. [id] is the MongoDB `_id`.
  const CustomerProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.createdAt,
    required this.updatedAt,
    this.phoneE164,
    this.defaultAddressId,
  });

  /// Parses a MongoDB `customer_profiles` document.
  factory CustomerProfile.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => ProfileDocumentException(message);
    return CustomerProfile(
      id: DocumentFields.requireObjectId(document, '_id', error),
      userId: DocumentFields.requireObjectId(document, 'user_id', error),
      fullName: DocumentFields.requireString(document, 'full_name', error),
      phoneE164: DocumentFields.optionalString(document, 'phone_e164', error),
      defaultAddressId: DocumentFields.optionalObjectId(
        document,
        'default_address_id',
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

  /// Trimmed human-readable name.
  final String fullName;

  /// Optional simplified E.164 phone. Ownership is not verified.
  final String? phoneE164;

  /// Authoritative default service-address pointer, or `null`.
  final ObjectId? defaultAddressId;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last-update timestamp.
  final DateTime updatedAt;

  /// MongoDB document representation.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone_e164': phoneE164,
      'default_address_id': defaultAddressId,
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  /// Safe public JSON. Omits password, tokens, and Mongo internals.
  Map<String, Object?> toPublicJson() {
    return <String, Object?>{
      'id': id.oid,
      'user_id': userId.oid,
      'full_name': fullName,
      'phone_e164': phoneE164,
      'default_address_id': defaultAddressId?.oid,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() => 'CustomerProfile(id: ${id.oid}, userId: ${userId.oid})';
}

/// Thrown when a customer profile document cannot be parsed.
class ProfileDocumentException implements Exception {
  /// Creates a parse failure. [message] must not include field values.
  const ProfileDocumentException(this.message);

  /// Sanitized description of the missing or invalid field.
  final String message;

  @override
  String toString() => 'ProfileDocumentException: $message';
}

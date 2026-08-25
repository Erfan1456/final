import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_billing_model.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Platform-owned marketplace service definition.
class MarketplaceService {
  /// Creates a catalog service. [id] is the MongoDB `_id`.
  const MarketplaceService({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.billingModel,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parses a MongoDB `services` document.
  factory MarketplaceService.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => ServiceDocumentException(message);
    return MarketplaceService(
      id: DocumentFields.requireObjectId(document, '_id', error),
      slug: DocumentFields.requireString(document, 'slug', error),
      name: DocumentFields.requireString(document, 'name', error),
      description: DocumentFields.requireString(document, 'description', error),
      billingModel: ServiceBillingModel.fromWire(
        DocumentFields.requireString(document, 'billing_model', error),
      ),
      active: DocumentFields.requireBool(document, 'active', error),
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

  /// URL-safe unique slug.
  final String slug;

  /// Human-readable name.
  final String name;

  /// Plain-text description.
  final String description;

  /// Billing model. Currently only hourly.
  final ServiceBillingModel billingModel;

  /// Whether the catalog entry is active for offerings and discovery.
  final bool active;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last-update timestamp.
  final DateTime updatedAt;

  /// MongoDB document representation.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'slug': slug,
      'name': name,
      'description': description,
      'billing_model': billingModel.wireValue,
      'active': active,
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  /// Public catalog JSON. Inactive services must not be serialized this way.
  Map<String, Object?> toPublicJson() {
    return <String, Object?>{
      'id': id.oid,
      'slug': slug,
      'name': name,
      'description': description,
      'billing_model': billingModel.wireValue,
    };
  }

  @override
  String toString() => 'MarketplaceService(id: ${id.oid}, slug: $slug)';
}

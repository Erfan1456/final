import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// One cleaner offering of one platform service.
class CleanerServiceOffering {
  /// Creates an offering. [id] is the MongoDB `_id`.
  const CleanerServiceOffering({
    required this.id,
    required this.cleanerUserId,
    required this.serviceId,
    required this.hourlyRateMinor,
    required this.currencyCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parses a MongoDB `cleaner_services` document.
  factory CleanerServiceOffering.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => CleanerServiceDocumentException(message);
    return CleanerServiceOffering(
      id: DocumentFields.requireObjectId(document, '_id', error),
      cleanerUserId: DocumentFields.requireObjectId(
        document,
        'cleaner_user_id',
        error,
      ),
      serviceId: DocumentFields.requireObjectId(document, 'service_id', error),
      hourlyRateMinor: DocumentFields.requireInt(
        document,
        'hourly_rate_minor',
        error,
      ),
      currencyCode: DocumentFields.requireString(
        document,
        'currency_code',
        error,
      ),
      isActive: DocumentFields.requireBool(document, 'is_active', error),
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

  /// Owning cleaner `users._id`. Never taken from an HTTP body.
  final ObjectId cleanerUserId;

  /// Platform `services._id`.
  final ObjectId serviceId;

  /// Hourly price in the currency's minor unit. Integer only.
  final int hourlyRateMinor;

  /// ISO-like three-letter currency code, stored uppercase.
  final String currencyCode;

  /// Whether the offering is active for discovery and availability.
  final bool isActive;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last-update timestamp.
  final DateTime updatedAt;

  /// MongoDB document representation.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'cleaner_user_id': cleanerUserId,
      'service_id': serviceId,
      'hourly_rate_minor': hourlyRateMinor,
      'currency_code': currencyCode,
      'is_active': isActive,
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  @override
  String toString() =>
      'CleanerServiceOffering(id: ${id.oid}, cleaner: ${cleanerUserId.oid})';
}

/// Validated offering fields after HTTP parsing.
class CleanerServiceWriteData {
  /// Creates validated offering fields.
  const CleanerServiceWriteData({
    required this.hourlyRateMinor,
    required this.currencyCode,
    required this.isActive,
  });

  /// Integer minor-unit hourly rate.
  final int hourlyRateMinor;

  /// Uppercase three-letter currency code.
  final String currencyCode;

  /// Whether the offering should be active.
  final bool isActive;
}

/// One page of discovery offerings ordered by `_id` ascending.
class CleanerServiceDiscoveryPage {
  /// Creates a page of [items].
  const CleanerServiceDiscoveryPage({
    required this.items,
    required this.hasMore,
  });

  /// Page items, at most the requested limit.
  final List<CleanerServiceOffering> items;

  /// Whether another page exists after [items].
  final bool hasMore;
}

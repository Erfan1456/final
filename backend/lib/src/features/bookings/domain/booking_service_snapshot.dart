import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/marketplace_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_billing_model.dart';

/// Immutable catalog fields copied into a booking at creation.
class BookingServiceSnapshot {
  /// Creates a service snapshot.
  const BookingServiceSnapshot({
    required this.slug,
    required this.name,
    required this.billingModel,
  });

  /// Copies public catalog fields from [service].
  factory BookingServiceSnapshot.fromService(MarketplaceService service) {
    return BookingServiceSnapshot(
      slug: service.slug,
      name: service.name,
      billingModel: service.billingModel,
    );
  }

  /// Parses an embedded `service_snapshot` map.
  factory BookingServiceSnapshot.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => BookingDocumentException(message);
    return BookingServiceSnapshot(
      slug: DocumentFields.requireString(document, 'slug', error),
      name: DocumentFields.requireString(document, 'name', error),
      billingModel: ServiceBillingModel.fromWire(
        DocumentFields.requireString(document, 'billing_model', error),
      ),
    );
  }

  /// Catalog slug at booking time.
  final String slug;

  /// Catalog name at booking time.
  final String name;

  /// Billing model at booking time.
  final ServiceBillingModel billingModel;

  /// BSON nested document.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      'slug': slug,
      'name': name,
      'billing_model': billingModel.wireValue,
    };
  }

  /// Public JSON. Does not include catalog ids beyond the snapshot fields.
  Map<String, Object?> toPublicJson() {
    return <String, Object?>{
      'slug': slug,
      'name': name,
      'billing_model': billingModel.wireValue,
    };
  }
}

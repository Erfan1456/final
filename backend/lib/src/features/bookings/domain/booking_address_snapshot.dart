import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';

/// Immutable customer service address copied into a booking at creation.
class BookingAddressSnapshot {
  /// Creates an address snapshot.
  const BookingAddressSnapshot({
    required this.label,
    required this.line1,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.countryCode,
    this.line2,
  });

  /// Copies fields from an owned [address].
  factory BookingAddressSnapshot.fromAddress(Address address) {
    return BookingAddressSnapshot(
      label: address.label,
      line1: address.line1,
      line2: address.line2,
      city: address.city,
      region: address.region,
      postalCode: address.postalCode,
      countryCode: address.countryCode,
    );
  }

  /// Parses an embedded `address_snapshot` map.
  factory BookingAddressSnapshot.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => BookingDocumentException(message);
    return BookingAddressSnapshot(
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
    );
  }

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

  /// Postal code.
  final String postalCode;

  /// ISO 3166-1 alpha-2 country code.
  final String countryCode;

  /// BSON nested document. Full address is always stored.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      'label': label,
      'line1': line1,
      'line2': line2,
      'city': city,
      'region': region,
      'postal_code': postalCode,
      'country_code': countryCode,
    };
  }

  /// Full address JSON for the owning customer or an accepted cleaner.
  Map<String, Object?> toFullJson() {
    return <String, Object?>{
      'label': label,
      'line1': line1,
      'line2': line2,
      'city': city,
      'region': region,
      'postal_code': postalCode,
      'country_code': countryCode,
    };
  }

  /// Coarse location for pending/declined/cancelled cleaner views.
  Map<String, Object?> toCoarseJson() {
    return <String, Object?>{
      'city': city,
      'region': region,
      'country_code': countryCode,
    };
  }
}

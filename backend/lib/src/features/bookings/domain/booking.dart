import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_address_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_service_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status_history_entry.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persisted booking of one complete availability slot.
///
/// Snapshots preserve agreement terms. Security identity is not stored.
class Booking {
  /// Creates a booking. [id] is the MongoDB `_id`.
  const Booking({
    required this.id,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.availabilitySlotId,
    required this.serviceId,
    required this.status,
    required this.reservationActive,
    required this.durationMinutes,
    required this.hourlyRateMinor,
    required this.quotedTotalMinor,
    required this.currencyCode,
    required this.serviceSnapshot,
    required this.addressSnapshot,
    required this.idempotencyKey,
    required this.requestFingerprint,
    required this.startAt,
    required this.endAt,
    required this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
    this.customerNotes,
    this.acceptedAt,
    this.declinedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });

  /// Parses a MongoDB `bookings` document.
  factory Booking.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => BookingDocumentException(message);
    final historyRaw = DocumentFields.requireList(
      document,
      'status_history',
      error,
    );
    return Booking(
      id: DocumentFields.requireObjectId(document, '_id', error),
      customerUserId: DocumentFields.requireObjectId(
        document,
        'customer_user_id',
        error,
      ),
      cleanerUserId: DocumentFields.requireObjectId(
        document,
        'cleaner_user_id',
        error,
      ),
      availabilitySlotId: DocumentFields.requireObjectId(
        document,
        'availability_slot_id',
        error,
      ),
      serviceId: DocumentFields.requireObjectId(document, 'service_id', error),
      status: BookingStatus.fromWire(
        DocumentFields.requireString(document, 'status', error),
      ),
      reservationActive: DocumentFields.requireBool(
        document,
        'reservation_active',
        error,
      ),
      durationMinutes: DocumentFields.requireInt(
        document,
        'duration_minutes',
        error,
      ),
      hourlyRateMinor: DocumentFields.requireInt(
        document,
        'hourly_rate_minor',
        error,
      ),
      quotedTotalMinor: DocumentFields.requireInt(
        document,
        'quoted_total_minor',
        error,
      ),
      currencyCode: DocumentFields.requireString(
        document,
        'currency_code',
        error,
      ),
      serviceSnapshot: BookingServiceSnapshot.fromDocument(
        DocumentFields.requireMap(document, 'service_snapshot', error),
      ),
      addressSnapshot: BookingAddressSnapshot.fromDocument(
        DocumentFields.requireMap(document, 'address_snapshot', error),
      ),
      customerNotes: DocumentFields.optionalString(
        document,
        'customer_notes',
        error,
      ),
      idempotencyKey: DocumentFields.requireString(
        document,
        'idempotency_key',
        error,
      ),
      requestFingerprint: DocumentFields.requireString(
        document,
        'request_fingerprint',
        error,
      ),
      startAt: DocumentFields.requireUtcDateTime(document, 'start_at', error),
      endAt: DocumentFields.requireUtcDateTime(document, 'end_at', error),
      acceptedAt: DocumentFields.optionalUtcDateTime(
        document,
        'accepted_at',
        error,
      ),
      declinedAt: DocumentFields.optionalUtcDateTime(
        document,
        'declined_at',
        error,
      ),
      startedAt: DocumentFields.optionalUtcDateTime(
        document,
        'started_at',
        error,
      ),
      completedAt: DocumentFields.optionalUtcDateTime(
        document,
        'completed_at',
        error,
      ),
      cancelledAt: DocumentFields.optionalUtcDateTime(
        document,
        'cancelled_at',
        error,
      ),
      statusHistory: [
        for (final item in historyRaw)
          if (item is Map)
            BookingStatusHistoryEntry.fromDocument(
              Map<String, dynamic>.from(item),
            ),
      ],
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

  /// Booking customer `users._id`.
  final ObjectId customerUserId;

  /// Assigned cleaner `users._id`.
  final ObjectId cleanerUserId;

  /// Booked `availability_slots._id`.
  final ObjectId availabilitySlotId;

  /// Platform `services._id` at booking time.
  final ObjectId serviceId;

  /// Current lifecycle status.
  final BookingStatus status;

  /// Explicit concurrency field matching [BookingStatus.reservationActive].
  final bool reservationActive;

  /// Slot duration in minutes.
  final int durationMinutes;

  /// Hourly rate snapshot in minor units.
  final int hourlyRateMinor;

  /// Immutable quoted total in minor units. Not a payment.
  final int quotedTotalMinor;

  /// Currency snapshot, uppercase.
  final String currencyCode;

  /// Catalog snapshot at creation.
  final BookingServiceSnapshot serviceSnapshot;

  /// Customer address snapshot at creation.
  final BookingAddressSnapshot addressSnapshot;

  /// Optional trimmed customer notes.
  final String? customerNotes;

  /// Customer-scoped idempotency key. Not exposed in public DTOs.
  final String idempotencyKey;

  /// SHA-256 hex of creation intent. Not exposed in public DTOs.
  final String requestFingerprint;

  /// Slot start, UTC.
  final DateTime startAt;

  /// Slot end, UTC.
  final DateTime endAt;

  /// UTC accept timestamp.
  final DateTime? acceptedAt;

  /// UTC decline timestamp.
  final DateTime? declinedAt;

  /// UTC start-job timestamp.
  final DateTime? startedAt;

  /// UTC complete timestamp.
  final DateTime? completedAt;

  /// UTC cancel timestamp.
  final DateTime? cancelledAt;

  /// Embedded status history.
  final List<BookingStatusHistoryEntry> statusHistory;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last-update timestamp.
  final DateTime updatedAt;

  /// MongoDB document representation. Does not copy security identity.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'customer_user_id': customerUserId,
      'cleaner_user_id': cleanerUserId,
      'availability_slot_id': availabilitySlotId,
      'service_id': serviceId,
      'status': status.wireValue,
      'reservation_active': reservationActive,
      'duration_minutes': durationMinutes,
      'hourly_rate_minor': hourlyRateMinor,
      'quoted_total_minor': quotedTotalMinor,
      'currency_code': currencyCode,
      'service_snapshot': serviceSnapshot.toDocument(),
      'address_snapshot': addressSnapshot.toDocument(),
      'customer_notes': customerNotes,
      'idempotency_key': idempotencyKey,
      'request_fingerprint': requestFingerprint,
      'start_at': startAt.toUtc(),
      'end_at': endAt.toUtc(),
      'accepted_at': acceptedAt?.toUtc(),
      'declined_at': declinedAt?.toUtc(),
      'started_at': startedAt?.toUtc(),
      'completed_at': completedAt?.toUtc(),
      'cancelled_at': cancelledAt?.toUtc(),
      'status_history': [
        for (final entry in statusHistory) entry.toDocument(),
      ],
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  Map<String, Object?> _sharedPublicJson() {
    return <String, Object?>{
      'id': id.oid,
      'status': status.wireValue,
      'duration_minutes': durationMinutes,
      'hourly_rate_minor': hourlyRateMinor,
      'quoted_total_minor': quotedTotalMinor,
      'currency_code': currencyCode,
      'service_snapshot': serviceSnapshot.toPublicJson(),
      'customer_notes': customerNotes,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'accepted_at': acceptedAt?.toUtc().toIso8601String(),
      'declined_at': declinedAt?.toUtc().toIso8601String(),
      'started_at': startedAt?.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'cancelled_at': cancelledAt?.toUtc().toIso8601String(),
      'status_history': [
        for (final entry in statusHistory) entry.toPublicJson(),
      ],
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Customer-facing JSON. Full own address. No cleaner contact/security.
  Map<String, Object?> toCustomerJson({
    required String cleanerPublicName,
    bool idempotentReplay = false,
  }) {
    return <String, Object?>{
      ..._sharedPublicJson(),
      'cleaner_user_id': cleanerUserId.oid,
      'cleaner_full_name': cleanerPublicName,
      'address_snapshot': addressSnapshot.toFullJson(),
      'idempotent_replay': idempotentReplay,
    };
  }

  /// Cleaner-facing JSON. Address is privacy-shaped by [status].
  Map<String, Object?> toCleanerJson({required String customerDisplayName}) {
    return <String, Object?>{
      ..._sharedPublicJson(),
      'customer_display_name': customerDisplayName,
      'address_snapshot': status.exposesFullAddressToCleaner
          ? addressSnapshot.toFullJson()
          : addressSnapshot.toCoarseJson(),
    };
  }

  @override
  String toString() => 'Booking(id: ${id.oid}, status: ${status.wireValue})';
}

/// One keyset page of bookings.
class BookingPage {
  /// Creates a page with an optional descending `_id` cursor.
  const BookingPage({required this.items, required this.nextCursor});

  /// Page items.
  final List<Booking> items;

  /// Hex `_id` cursor for the next page, or `null`.
  final String? nextCursor;
}

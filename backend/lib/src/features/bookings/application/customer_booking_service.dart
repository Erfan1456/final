import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/approved_cleaner_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_address_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_quotation.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_service_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status_history_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_sink.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/booking_cancellation_orchestrator.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent customer booking operations.
class CustomerBookingService {
  /// Creates a service over repositories.
  CustomerBookingService({
    required AddressRepository addresses,
    required AvailabilityRepository slots,
    required UserRepository users,
    required CleanerProfileRepository cleanerProfiles,
    required ServiceRepository services,
    required CleanerServiceRepository offerings,
    required BookingRepository bookings,
    required BookingCancellationOrchestrator cancellation,
    NotificationSink? notifications,
    DateTime Function()? clock,
  }) : _addresses = addresses,
       _slots = slots,
       _users = users,
       _cleanerProfiles = cleanerProfiles,
       _services = services,
       _offerings = offerings,
       _bookings = bookings,
       _cancellation = cancellation,
       _notifications = notifications ?? const NoOpNotificationSink(),
       _clock = clock ?? DateTime.now;

  final AddressRepository _addresses;
  final AvailabilityRepository _slots;
  final UserRepository _users;
  final CleanerProfileRepository _cleanerProfiles;
  final ServiceRepository _services;
  final CleanerServiceRepository _offerings;
  final BookingRepository _bookings;
  final BookingCancellationOrchestrator _cancellation;
  final NotificationSink _notifications;
  final DateTime Function() _clock;

  /// Creates a booking or returns an identical idempotent replay.
  Future<({Map<String, Object?> booking, bool created})> createBooking({
    required UserAccount user,
    required String? idempotencyKeyRaw,
    required Object? availabilitySlotIdRaw,
    required Object? addressIdRaw,
    required Object? customerNotesRaw,
  }) async {
    final idempotencyKey = BookingValidation.requireIdempotencyKey(
      idempotencyKeyRaw,
    );
    final notes = BookingValidation.optionalCustomerNotes(customerNotesRaw);
    final addressId = _requireOwnedAddressId(addressIdRaw);
    final slotId = _requireSlotId(availabilitySlotIdRaw);
    final fingerprint = BookingValidation.requestFingerprint(
      customerUserId: user.id,
      availabilitySlotId: slotId,
      addressId: addressId,
      customerNotes: notes,
    );

    final existingByKey = await _bookings.findByCustomerAndIdempotencyKey(
      customerUserId: user.id,
      idempotencyKey: idempotencyKey,
    );
    if (existingByKey != null) {
      if (existingByKey.requestFingerprint != fingerprint) {
        throw const IdempotencyKeyReusedException();
      }
      final names = await _cleanerNames([existingByKey.cleanerUserId]);
      return (
        booking: existingByKey.toCustomerJson(
          cleanerPublicName:
              names[existingByKey.cleanerUserId.oid] ?? 'Cleaner',
          idempotentReplay: true,
        ),
        created: false,
      );
    }

    final address = await _addresses.findOwnedById(
      id: addressId,
      userId: user.id,
    );
    if (address == null) {
      throw const AddressNotFoundException();
    }

    final now = _clock().toUtc();
    final slot = await _slots.findById(slotId);
    if (slot == null || !slot.startAt.isAfter(now)) {
      throw const AvailabilityUnavailableException();
    }

    final cleaner = await _users.findById(slot.cleanerUserId);
    if (cleaner == null ||
        cleaner.role != UserRole.cleaner ||
        cleaner.accountStatus != AccountStatus.active) {
      throw const AvailabilityUnavailableException();
    }
    final profile = await _cleanerProfiles.findByUserId(cleaner.id);
    if (profile == null ||
        !ApprovedCleanerPolicy.isDiscoverable(
          user: cleaner,
          profile: profile,
        )) {
      throw const AvailabilityUnavailableException();
    }

    final service = await _services.findById(slot.serviceId);
    if (service == null || !service.active) {
      throw const AvailabilityUnavailableException();
    }
    final offering = await _offerings.findActiveOffering(
      cleanerUserId: cleaner.id,
      serviceId: slot.serviceId,
    );
    if (offering == null) {
      throw const AvailabilityUnavailableException();
    }

    final existingSlotBooking = await _bookings.findActiveByAvailabilitySlot(
      slot.id,
    );
    if (existingSlotBooking != null) {
      throw const AvailabilityUnavailableException();
    }
    final overlap = await _bookings.findActiveOverlapForCleaner(
      cleanerUserId: cleaner.id,
      startAt: slot.startAt,
      endAt: slot.endAt,
    );
    if (overlap != null) {
      throw const AvailabilityUnavailableException();
    }

    final duration = BookingQuotation.durationMinutes(
      startAt: slot.startAt,
      endAt: slot.endAt,
    );
    final quoted = BookingQuotation.quotedTotalMinor(
      hourlyRateMinor: offering.hourlyRateMinor,
      durationMinutes: duration,
    );
    final booking = Booking(
      id: ObjectId(),
      customerUserId: user.id,
      cleanerUserId: cleaner.id,
      availabilitySlotId: slot.id,
      serviceId: slot.serviceId,
      status: BookingStatus.pending,
      reservationActive: true,
      durationMinutes: duration,
      hourlyRateMinor: offering.hourlyRateMinor,
      quotedTotalMinor: quoted,
      currencyCode: offering.currencyCode,
      serviceSnapshot: BookingServiceSnapshot.fromService(service),
      addressSnapshot: BookingAddressSnapshot.fromAddress(address),
      customerNotes: notes,
      idempotencyKey: idempotencyKey,
      requestFingerprint: fingerprint,
      startAt: slot.startAt,
      endAt: slot.endAt,
      statusHistory: [
        BookingStatusHistoryEntry(
          toStatus: BookingStatus.pending,
          actorUserId: user.id,
          actorRole: UserRole.customer,
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    try {
      final stored = await _bookings.create(booking);
      await _notifications.notifyBestEffort(
        userId: stored.cleanerUserId,
        type: NotificationType.bookingRequested,
        title: 'New booking request',
        body: 'You have a new booking request.',
        dedupeKey: 'booking:${stored.id.oid}:created',
        resourceType: 'booking',
        resourceId: stored.id,
      );
      return (
        booking: stored.toCustomerJson(cleanerPublicName: profile.fullName),
        created: true,
      );
    } on BookingDuplicateKeyException {
      return _replayOrConflict(
        customerUserId: user.id,
        idempotencyKey: idempotencyKey,
        fingerprint: fingerprint,
      );
    }
  }

  /// Lists owned bookings with keyset pagination.
  Future<Map<String, Object?>> listBookings({
    required UserAccount user,
    Object? status,
    Object? limitRaw,
    Object? after,
  }) async {
    final query = BookingListQuery.parse(
      status: status,
      limitRaw: limitRaw,
      after: after,
    );
    final page = await _bookings.listForCustomerPage(
      customerUserId: user.id,
      limit: query.limit,
      status: query.status,
      after: query.after,
    );
    final names = await _cleanerNames(
      page.items.map((item) => item.cleanerUserId),
    );
    return <String, Object?>{
      'items': [
        for (final item in page.items)
          item.toCustomerJson(
            cleanerPublicName: names[item.cleanerUserId.oid] ?? 'Cleaner',
          ),
      ],
      'next_cursor': page.nextCursor,
    };
  }

  /// Returns one owned booking.
  Future<Map<String, Object?>> getBooking({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    final booking = await _bookings.findCustomerBookingById(
      id: bookingId,
      customerUserId: user.id,
    );
    if (booking == null) {
      throw const BookingNotFoundException();
    }
    final names = await _cleanerNames([booking.cleanerUserId]);
    return booking.toCustomerJson(
      cleanerPublicName: names[booking.cleanerUserId.oid] ?? 'Cleaner',
    );
  }

  /// Cancels an owned pending/confirmed booking that has not started.
  Future<Map<String, Object?>> cancelBooking({
    required UserAccount user,
    required ObjectId bookingId,
    Object? reasonRaw,
  }) async {
    final reason = BookingValidation.optionalReason(reasonRaw);
    final updated = await _cancellation.cancelByCustomer(
      user: user,
      bookingId: bookingId,
      reason: reason,
    );
    await _notifications.notifyBestEffort(
      userId: updated.cleanerUserId,
      type: NotificationType.bookingCancelled,
      title: 'Booking cancelled',
      body: 'A booking was cancelled.',
      dedupeKey: 'booking:${updated.id.oid}:cancelled',
      resourceType: 'booking',
      resourceId: updated.id,
    );
    final names = await _cleanerNames([updated.cleanerUserId]);
    return updated.toCustomerJson(
      cleanerPublicName: names[updated.cleanerUserId.oid] ?? 'Cleaner',
    );
  }

  Future<({Map<String, Object?> booking, bool created})> _replayOrConflict({
    required ObjectId customerUserId,
    required String idempotencyKey,
    required String fingerprint,
  }) async {
    final existing = await _bookings.findByCustomerAndIdempotencyKey(
      customerUserId: customerUserId,
      idempotencyKey: idempotencyKey,
    );
    if (existing == null) {
      throw const AvailabilityUnavailableException();
    }
    if (existing.requestFingerprint != fingerprint) {
      throw const IdempotencyKeyReusedException();
    }
    final names = await _cleanerNames([existing.cleanerUserId]);
    return (
      booking: existing.toCustomerJson(
        cleanerPublicName: names[existing.cleanerUserId.oid] ?? 'Cleaner',
        idempotentReplay: true,
      ),
      created: false,
    );
  }

  Future<Map<String, String>> _cleanerNames(Iterable<ObjectId> ids) async {
    final profiles = await _cleanerProfiles.findByUserIds(ids);
    return <String, String>{
      for (final profile in profiles) profile.userId.oid: profile.fullName,
    };
  }

  ObjectId _requireOwnedAddressId(Object? raw) {
    final id = _tryObjectId(raw);
    if (id == null) {
      throw const AddressNotFoundException();
    }
    return id;
  }

  ObjectId _requireSlotId(Object? raw) {
    final id = _tryObjectId(raw);
    if (id == null) {
      throw const AvailabilityUnavailableException();
    }
    return id;
  }

  ObjectId? _tryObjectId(Object? raw) {
    if (raw is ObjectId) {
      return raw;
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        return ObjectId.fromHexString(raw.trim());
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

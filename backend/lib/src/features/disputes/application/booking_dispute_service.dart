// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/authorization/forbidden_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/data/dispute_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_history_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_sink.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Participant create/get/close of a booking-scoped dispute.
class BookingDisputeService {
  BookingDisputeService({
    required BookingRepository bookings,
    required DisputeRepository disputes,
    required CustomerProfileRepository customerProfiles,
    required CleanerProfileRepository cleanerProfiles,
    NotificationSink? notifications,
    DateTime Function()? clock,
  }) : _bookings = bookings,
       _disputes = disputes,
       _customerProfiles = customerProfiles,
       _cleanerProfiles = cleanerProfiles,
       _notifications = notifications ?? const NoOpNotificationSink(),
       _clock = clock ?? DateTime.now;

  final BookingRepository _bookings;
  final DisputeRepository _disputes;
  final CustomerProfileRepository _customerProfiles;
  final CleanerProfileRepository _cleanerProfiles;
  final NotificationSink _notifications;
  final DateTime Function() _clock;

  static const _eligible = <BookingStatus>{
    BookingStatus.confirmed,
    BookingStatus.inProgress,
    BookingStatus.completed,
    BookingStatus.cancelled,
  };

  Future<Map<String, Object?>> getForBooking({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    final booking = await _requireParticipantBooking(
      user: user,
      bookingId: bookingId,
    );
    final dispute = await _disputes.findByBookingId(booking.id);
    return <String, Object?>{
      'dispute': dispute == null
          ? null
          : await _participantJson(user: user, dispute: dispute),
    };
  }

  Future<Map<String, Object?>> create({
    required UserAccount user,
    required ObjectId bookingId,
    required Object? categoryRaw,
    required Object? subjectRaw,
    required Object? descriptionRaw,
  }) async {
    if (user.role == UserRole.admin) {
      throw const ForbiddenException();
    }
    final booking = await _requireParticipantBooking(
      user: user,
      bookingId: bookingId,
    );
    if (!_eligible.contains(booking.status)) {
      throw const DisputeNotAllowedException();
    }
    final existing = await _disputes.findByBookingId(booking.id);
    if (existing != null) {
      throw const DisputeAlreadyExistsException();
    }
    final now = _clock().toUtc();
    final dispute = Dispute(
      id: ObjectId(),
      bookingId: booking.id,
      customerUserId: booking.customerUserId,
      cleanerUserId: booking.cleanerUserId,
      openedByUserId: user.id,
      openedByRole: user.role,
      category: DisputeValidation.requireCategory(categoryRaw),
      status: DisputeStatus.open,
      subject: DisputeValidation.requireSubject(subjectRaw),
      description: DisputeValidation.requireDescription(descriptionRaw),
      createdAt: now,
      updatedAt: now,
      history: <DisputeHistoryEntry>[
        DisputeHistoryEntry(
          toStatus: DisputeStatus.open,
          actorUserId: user.id,
          actorRole: user.role,
          createdAt: now,
        ),
      ],
    );
    Dispute stored;
    try {
      stored = await _disputes.create(dispute);
    } on DisputeDuplicateKeyException {
      throw const DisputeAlreadyExistsException();
    }
    final other = user.id == booking.customerUserId
        ? booking.cleanerUserId
        : booking.customerUserId;
    await _notifications.notifyBestEffort(
      userId: other,
      type: NotificationType.disputeOpened,
      title: 'A dispute was opened',
      body: 'A booking dispute was opened and is waiting for review.',
      dedupeKey: 'dispute_opened:${stored.id.oid}:${other.oid}',
      resourceType: 'dispute',
      resourceId: booking.id,
    );
    return <String, Object?>{
      'dispute': await _participantJson(user: user, dispute: stored),
    };
  }

  Future<Map<String, Object?>> close({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    final booking = await _requireParticipantBooking(
      user: user,
      bookingId: bookingId,
    );
    final existing = await _disputes.findByBookingId(booking.id);
    if (existing == null) {
      throw const DisputeNotFoundException();
    }
    final closed = await _disputes.close(
      id: existing.id,
      actorUserId: user.id,
      actorRole: user.role,
      now: _clock().toUtc(),
    );
    if (closed != null) {
      await _notifications.notifyBestEffort(
        userId: user.id == booking.customerUserId
            ? booking.cleanerUserId
            : booking.customerUserId,
        type: NotificationType.disputeClosed,
        title: 'A dispute was closed',
        body: 'The booking dispute was closed.',
        dedupeKey: 'dispute_closed:${existing.id.oid}',
        resourceType: 'dispute',
        resourceId: booking.id,
      );
      return <String, Object?>{
        'dispute': await _participantJson(user: user, dispute: closed),
      };
    }
    if (existing.status == DisputeStatus.closed) {
      throw const InvalidDisputeStateException();
    }
    throw const InvalidDisputeStateException();
  }

  Future<Booking> _requireParticipantBooking({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    if (user.role != UserRole.customer && user.role != UserRole.cleaner) {
      throw const ForbiddenException();
    }
    final booking = await _bookings.findById(bookingId);
    if (booking == null ||
        (booking.customerUserId != user.id &&
            booking.cleanerUserId != user.id)) {
      throw const BookingNotFoundException();
    }
    return booking;
  }

  Future<Map<String, Object?>> _participantJson({
    required UserAccount user,
    required Dispute dispute,
  }) async {
    if (user.id == dispute.customerUserId) {
      final cleaner = await _cleanerProfiles.findByUserId(
        dispute.cleanerUserId,
      );
      return dispute.toCustomerJson(
        cleanerPublicName: cleaner?.fullName ?? 'Cleaner',
      );
    }
    final customer = await _customerProfiles.findByUserId(
      dispute.customerUserId,
    );
    return dispute.toCleanerJson(
      customerDisplayName:
          customer?.fullName ?? BookingValidation.fallbackCustomerDisplayName,
    );
  }
}

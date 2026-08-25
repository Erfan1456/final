import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_sink.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/booking_cancellation_orchestrator.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent cleaner booking/job operations.
///
/// Existing assigned bookings remain accessible without ApprovedCleanerPolicy.
class CleanerBookingService {
  /// Creates a service over repositories.
  CleanerBookingService({
    required BookingRepository bookings,
    required CustomerProfileRepository customerProfiles,
    required BookingCancellationOrchestrator cancellation,
    NotificationSink? notifications,
    DateTime Function()? clock,
  }) : _bookings = bookings,
       _customerProfiles = customerProfiles,
       _cancellation = cancellation,
       _notifications = notifications ?? const NoOpNotificationSink(),
       _clock = clock ?? DateTime.now;

  final BookingRepository _bookings;
  final CustomerProfileRepository _customerProfiles;
  final BookingCancellationOrchestrator _cancellation;
  final NotificationSink _notifications;
  final DateTime Function() _clock;

  /// Lists assigned bookings with keyset pagination.
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
    final page = await _bookings.listForCleanerPage(
      cleanerUserId: user.id,
      limit: query.limit,
      status: query.status,
      after: query.after,
    );
    final names = await _customerNames(
      page.items.map((item) => item.customerUserId),
    );
    return <String, Object?>{
      'items': [
        for (final item in page.items)
          item.toCleanerJson(
            customerDisplayName:
                names[item.customerUserId.oid] ??
                BookingValidation.fallbackCustomerDisplayName,
          ),
      ],
      'next_cursor': page.nextCursor,
    };
  }

  /// Returns one assigned booking.
  Future<Map<String, Object?>> getBooking({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    final booking = await _requireOwned(user: user, bookingId: bookingId);
    return _toJson(booking);
  }

  /// Accepts a pending booking.
  Future<Map<String, Object?>> accept({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    final updated = await _bookings.acceptPending(
      id: bookingId,
      cleanerUserId: user.id,
      now: _clock().toUtc(),
    );
    return _requireTransitionResult(
      user: user,
      bookingId: bookingId,
      updated: updated,
    );
  }

  /// Declines a pending booking with a required reason.
  Future<Map<String, Object?>> decline({
    required UserAccount user,
    required ObjectId bookingId,
    required Object? reasonRaw,
  }) async {
    final reason = BookingValidation.requireReason(reasonRaw);
    final updated = await _bookings.declinePending(
      id: bookingId,
      cleanerUserId: user.id,
      now: _clock().toUtc(),
      reason: reason,
    );
    return _requireTransitionResult(
      user: user,
      bookingId: bookingId,
      updated: updated,
    );
  }

  /// Cancels a confirmed booking that has not started.
  Future<Map<String, Object?>> cancel({
    required UserAccount user,
    required ObjectId bookingId,
    required Object? reasonRaw,
  }) async {
    final reason = BookingValidation.requireReason(reasonRaw);
    final updated = await _cancellation.cancelByCleaner(
      user: user,
      bookingId: bookingId,
      reason: reason,
    );
    await _notifications.notifyBestEffort(
      userId: updated.customerUserId,
      type: NotificationType.bookingCancelled,
      title: 'Booking cancelled',
      body: 'A booking was cancelled.',
      dedupeKey: 'booking:${updated.id.oid}:cancelled',
      resourceType: 'booking',
      resourceId: updated.id,
    );
    return _toJson(updated);
  }

  /// Starts a confirmed booking inside the slot window.
  Future<Map<String, Object?>> start({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    final updated = await _bookings.startConfirmed(
      id: bookingId,
      cleanerUserId: user.id,
      now: _clock().toUtc(),
    );
    return _requireTransitionResult(
      user: user,
      bookingId: bookingId,
      updated: updated,
    );
  }

  /// Completes an in-progress booking.
  Future<Map<String, Object?>> complete({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    final updated = await _bookings.completeInProgress(
      id: bookingId,
      cleanerUserId: user.id,
      now: _clock().toUtc(),
    );
    return _requireTransitionResult(
      user: user,
      bookingId: bookingId,
      updated: updated,
    );
  }

  Future<Map<String, Object?>> _requireTransitionResult({
    required UserAccount user,
    required ObjectId bookingId,
    required Booking? updated,
  }) async {
    if (updated != null) {
      await _notifyCustomerTransition(updated);
      return _toJson(updated);
    }
    await _requireOwned(user: user, bookingId: bookingId);
    throw const InvalidBookingStateException();
  }

  Future<Booking> _requireOwned({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    final booking = await _bookings.findCleanerBookingById(
      id: bookingId,
      cleanerUserId: user.id,
    );
    if (booking == null) {
      throw const BookingNotFoundException();
    }
    return booking;
  }

  Future<Map<String, Object?>> _toJson(Booking booking) async {
    final names = await _customerNames([booking.customerUserId]);
    return booking.toCleanerJson(
      customerDisplayName:
          names[booking.customerUserId.oid] ??
          BookingValidation.fallbackCustomerDisplayName,
    );
  }

  Future<Map<String, String>> _customerNames(Iterable<ObjectId> ids) async {
    final profiles = await _customerProfiles.findByUserIds(ids);
    return <String, String>{
      for (final profile in profiles) profile.userId.oid: profile.fullName,
    };
  }

  Future<void> _notifyCustomerTransition(Booking booking) {
    final NotificationType type;
    final String title;
    final String body;
    final String suffix;
    switch (booking.status) {
      case BookingStatus.confirmed:
        type = NotificationType.bookingConfirmed;
        title = 'Your booking was confirmed';
        body = 'Your booking was confirmed.';
        suffix = 'confirmed';
      case BookingStatus.declined:
        type = NotificationType.bookingDeclined;
        title = 'Booking declined';
        body = 'Your booking was declined.';
        suffix = 'declined';
      case BookingStatus.inProgress:
        type = NotificationType.jobStarted;
        title = 'Job started';
        body = 'Your cleaner has started the job.';
        suffix = 'started';
      case BookingStatus.completed:
        type = NotificationType.jobCompleted;
        title = 'Job completed';
        body = 'Your booking was completed.';
        suffix = 'completed';
      case BookingStatus.pending:
      case BookingStatus.cancelled:
        return Future<void>.value();
    }
    return _notifications.notifyBestEffort(
      userId: booking.customerUserId,
      type: type,
      title: title,
      body: body,
      dedupeKey: 'booking:${booking.id.oid}:$suffix',
      resourceType: 'booking',
      resourceId: booking.id,
    );
  }
}

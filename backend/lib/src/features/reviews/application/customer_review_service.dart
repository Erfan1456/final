// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_sink.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/data/review_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_moderation_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Customer create/update of a completed-booking review.
class CustomerReviewService {
  CustomerReviewService({
    required BookingRepository bookings,
    required ReviewRepository reviews,
    NotificationSink? notifications,
    DateTime Function()? clock,
  }) : _bookings = bookings,
       _reviews = reviews,
       _notifications = notifications ?? const NoOpNotificationSink(),
       _clock = clock ?? DateTime.now;

  final BookingRepository _bookings;
  final ReviewRepository _reviews;
  final NotificationSink _notifications;
  final DateTime Function() _clock;

  Future<Map<String, Object?>> getForBooking({
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
    final review = await _reviews.findByBooking(bookingId);
    return <String, Object?>{'review': review?.toCustomerJson()};
  }

  Future<({Map<String, Object?> review, bool created})>
  upsertForCompletedBooking({
    required UserAccount user,
    required ObjectId bookingId,
    required Object? ratingRaw,
    required Object? commentRaw,
  }) async {
    final booking = await _requireCompletedOwnedBooking(
      user: user,
      bookingId: bookingId,
    );
    final rating = ReviewValidation.requireRating(ratingRaw);
    final comment = ReviewValidation.optionalComment(commentRaw);
    final existing = await _reviews.findByBooking(booking.id);
    if (existing != null) {
      if (existing.customerUserId != user.id) {
        throw const BookingNotFoundException();
      }
      final updated = await _reviews.updateCustomerReview(
        bookingId: booking.id,
        customerUserId: user.id,
        rating: rating,
        comment: comment,
        now: _clock().toUtc(),
      );
      if (updated == null) {
        throw const ReviewWriteException();
      }
      return (review: updated.toCustomerJson(), created: false);
    }

    final now = _clock().toUtc();
    final review = Review(
      id: ObjectId(),
      bookingId: booking.id,
      customerUserId: booking.customerUserId,
      cleanerUserId: booking.cleanerUserId,
      rating: rating,
      comment: comment,
      moderationStatus: ReviewModerationStatus.published,
      createdAt: now,
      updatedAt: now,
    );
    Review stored;
    try {
      stored = await _reviews.create(review);
    } on ReviewDuplicateKeyException {
      final replay = await _reviews.findByBooking(booking.id);
      if (replay == null || replay.customerUserId != user.id) {
        throw const ReviewWriteException();
      }
      final updated = await _reviews.updateCustomerReview(
        bookingId: booking.id,
        customerUserId: user.id,
        rating: rating,
        comment: comment,
        now: now,
      );
      return (
        review: (updated ?? replay).toCustomerJson(),
        created: false,
      );
    }
    await _notifications.notifyBestEffort(
      userId: stored.cleanerUserId,
      type: NotificationType.reviewReceived,
      title: 'New review received',
      body: 'A verified customer left a review.',
      dedupeKey: 'review:${stored.id.oid}:created',
      resourceType: 'review',
      resourceId: stored.id,
    );
    return (review: stored.toCustomerJson(), created: true);
  }

  Future<Booking> _requireCompletedOwnedBooking({
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
    if (booking.status != BookingStatus.completed) {
      throw const ReviewNotAllowedException();
    }
    return booking;
  }
}

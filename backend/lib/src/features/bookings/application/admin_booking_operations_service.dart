// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/audit/application/audit_log_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/data/dispute_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_sink.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/booking_cancellation_orchestrator.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Administrator booking list, detail, and payment-aware cancellation.
class AdminBookingOperationsService {
  AdminBookingOperationsService({
    required BookingRepository bookings,
    required PaymentRepository payments,
    required DisputeRepository disputes,
    required CustomerProfileRepository customerProfiles,
    required CleanerProfileRepository cleanerProfiles,
    required BookingCancellationOrchestrator cancellation,
    NotificationSink? notifications,
    AuditSink? audit,
  }) : _bookings = bookings,
       _payments = payments,
       _disputes = disputes,
       _customerProfiles = customerProfiles,
       _cleanerProfiles = cleanerProfiles,
       _cancellation = cancellation,
       _notifications = notifications ?? const NoOpNotificationSink(),
       _audit = audit ?? const NoOpAuditSink();

  final BookingRepository _bookings;
  final PaymentRepository _payments;
  final DisputeRepository _disputes;
  final CustomerProfileRepository _customerProfiles;
  final CleanerProfileRepository _cleanerProfiles;
  final BookingCancellationOrchestrator _cancellation;
  final NotificationSink _notifications;
  final AuditSink _audit;

  Future<Map<String, Object?>> list({
    Object? status,
    Object? customerUserId,
    Object? cleanerUserId,
    Object? serviceId,
    Object? from,
    Object? to,
    Object? limitRaw,
    Object? after,
  }) async {
    final page = await _bookings.adminPage(
      limit: BookingValidation.requireLimit(limitRaw),
      status: BookingValidation.optionalStatus(status),
      customerUserId: BookingValidation.optionalObjectId(
        customerUserId,
        field: 'customer_user_id',
      ),
      cleanerUserId: BookingValidation.optionalObjectId(
        cleanerUserId,
        field: 'cleaner_user_id',
      ),
      serviceId: BookingValidation.optionalObjectId(
        serviceId,
        field: 'service_id',
      ),
      from: BookingValidation.optionalUtcDateTime(from, field: 'from'),
      to: BookingValidation.optionalUtcDateTime(to, field: 'to'),
      after: BookingValidation.optionalCursor(after),
    );
    final payments = await _payments.findByBookingIds(
      page.items.map((item) => item.id),
    );
    final disputes = await _disputes.findByBookingIds(
      page.items.map((item) => item.id),
    );
    final customers = await _customerProfiles.findByUserIds(
      page.items.map((item) => item.customerUserId),
    );
    final cleaners = await _cleanerProfiles.findByUserIds(
      page.items.map((item) => item.cleanerUserId),
    );
    final latestPayments = _latestPayments(payments);
    final disputesByBooking = <ObjectId, Dispute>{
      for (final dispute in disputes) dispute.bookingId: dispute,
    };
    final customerNames = <ObjectId, String>{
      for (final profile in customers) profile.userId: profile.fullName,
    };
    final cleanerNames = <ObjectId, String>{
      for (final profile in cleaners) profile.userId: profile.fullName,
    };
    return <String, Object?>{
      'items': [
        for (final booking in page.items)
          _summaryJson(
            booking: booking,
            customerName: customerNames[booking.customerUserId] ?? 'Customer',
            cleanerName: cleanerNames[booking.cleanerUserId] ?? 'Cleaner',
            payment: latestPayments[booking.id],
            dispute: disputesByBooking[booking.id],
          ),
      ],
      'next_cursor': page.nextCursor,
    };
  }

  Future<Map<String, Object?>> detail(ObjectId bookingId) async {
    final booking = await _bookings.findById(bookingId);
    if (booking == null) {
      throw const BookingNotFoundException();
    }
    final payments = await _payments.listForBooking(booking.id);
    final dispute = await _disputes.findByBookingId(booking.id);
    final customer = await _customerProfiles.findByUserId(
      booking.customerUserId,
    );
    final cleaner = await _cleanerProfiles.findByUserId(booking.cleanerUserId);
    return <String, Object?>{
      'booking': _detailJson(
        booking: booking,
        customerName: customer?.fullName ?? 'Customer',
        cleanerName: cleaner?.fullName ?? 'Cleaner',
      ),
      'payments': [
        for (final payment in payments) _paymentSummary(payment),
      ],
      'dispute': dispute == null ? null : _disputeSummary(dispute),
    };
  }

  Future<Map<String, Object?>> cancel({
    required UserAccount user,
    required ObjectId bookingId,
    required Object? reasonRaw,
  }) async {
    final reason = BookingValidation.requireReason(reasonRaw);
    final existing = await _bookings.findById(bookingId);
    if (existing == null) {
      throw const BookingNotFoundException();
    }
    if (existing.status != BookingStatus.pending &&
        existing.status != BookingStatus.confirmed) {
      throw const AdminBookingNotCancellableException();
    }
    final cancelled = await _cancellation.cancelByAdmin(
      admin: user,
      bookingId: bookingId,
      reason: reason,
    );
    await _notifications.notifyBestEffort(
      userId: cancelled.customerUserId,
      type: NotificationType.bookingCancelled,
      title: 'Booking cancelled',
      body: 'An administrator cancelled this booking.',
      dedupeKey: 'booking_cancelled_admin:${cancelled.id.oid}:customer',
      resourceType: 'booking',
      resourceId: cancelled.id,
    );
    await _notifications.notifyBestEffort(
      userId: cancelled.cleanerUserId,
      type: NotificationType.bookingCancelled,
      title: 'Booking cancelled',
      body: 'An administrator cancelled this booking.',
      dedupeKey: 'booking_cancelled_admin:${cancelled.id.oid}:cleaner',
      resourceType: 'booking',
      resourceId: cancelled.id,
    );
    await _audit.appendBestEffort(
      actorUserId: user.id,
      actorRole: UserRole.admin,
      action: AuditAction.bookingAdminCancelled,
      targetType: AuditTargetType.booking,
      targetId: cancelled.id,
      reason: reason,
      metadata: <String, Object?>{
        'previous_status': existing.status.wireValue,
        'new_status': BookingStatus.cancelled.wireValue,
      },
    );
    return detail(cancelled.id);
  }

  Map<ObjectId, Payment> _latestPayments(List<Payment> payments) {
    final latest = <ObjectId, Payment>{};
    for (final payment in payments) {
      final current = latest[payment.bookingId];
      if (current == null || payment.attemptNumber >= current.attemptNumber) {
        latest[payment.bookingId] = payment;
      }
    }
    return latest;
  }

  Map<String, Object?> _summaryJson({
    required Booking booking,
    required String customerName,
    required String cleanerName,
    required Payment? payment,
    required Dispute? dispute,
  }) {
    return <String, Object?>{
      'id': booking.id.oid,
      'status': booking.status.wireValue,
      'customer_user_id': booking.customerUserId.oid,
      'cleaner_user_id': booking.cleanerUserId.oid,
      'customer_display_name': customerName,
      'cleaner_public_name': cleanerName,
      'service_name': booking.serviceSnapshot.name,
      'start_at': booking.startAt.toUtc().toIso8601String(),
      'end_at': booking.endAt.toUtc().toIso8601String(),
      'quoted_total_minor': booking.quotedTotalMinor,
      'currency_code': booking.currencyCode,
      'payment': payment == null ? null : _paymentSummary(payment),
      'dispute': dispute == null ? null : _disputeSummary(dispute),
    };
  }

  Map<String, Object?> _detailJson({
    required Booking booking,
    required String customerName,
    required String cleanerName,
  }) {
    return <String, Object?>{
      'id': booking.id.oid,
      'status': booking.status.wireValue,
      'customer_user_id': booking.customerUserId.oid,
      'cleaner_user_id': booking.cleanerUserId.oid,
      'customer_display_name': customerName,
      'cleaner_public_name': cleanerName,
      'service_id': booking.serviceId.oid,
      'duration_minutes': booking.durationMinutes,
      'hourly_rate_minor': booking.hourlyRateMinor,
      'quoted_total_minor': booking.quotedTotalMinor,
      'currency_code': booking.currencyCode,
      'service_snapshot': booking.serviceSnapshot.toPublicJson(),
      'address_snapshot': booking.addressSnapshot.toFullJson(),
      'customer_notes': booking.customerNotes,
      'start_at': booking.startAt.toUtc().toIso8601String(),
      'end_at': booking.endAt.toUtc().toIso8601String(),
      'status_history': [
        for (final entry in booking.statusHistory) entry.toPublicJson(),
      ],
      'created_at': booking.createdAt.toUtc().toIso8601String(),
      'updated_at': booking.updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, Object?> _paymentSummary(Payment payment) {
    return <String, Object?>{
      'id': payment.id.oid,
      'status': payment.status.wireValue,
      'amount_minor': payment.amountMinor,
      'currency_code': payment.currencyCode,
      'refunded_amount_minor': payment.refundedAmountMinor,
    };
  }

  Map<String, Object?> _disputeSummary(Dispute dispute) {
    return <String, Object?>{
      'id': dispute.id.oid,
      'status': dispute.status.wireValue,
      'category': dispute.category.wireValue,
    };
  }
}

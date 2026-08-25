// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/audit/application/audit_log_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/data/dispute_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_sink.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Administrator dispute queue, review, resolution, and close.
class AdminDisputeService {
  AdminDisputeService({
    required DisputeRepository disputes,
    required BookingRepository bookings,
    required CustomerProfileRepository customerProfiles,
    required CleanerProfileRepository cleanerProfiles,
    NotificationSink? notifications,
    AuditSink? audit,
    DateTime Function()? clock,
  }) : _disputes = disputes,
       _bookings = bookings,
       _customerProfiles = customerProfiles,
       _cleanerProfiles = cleanerProfiles,
       _notifications = notifications ?? const NoOpNotificationSink(),
       _audit = audit ?? const NoOpAuditSink(),
       _clock = clock ?? DateTime.now;

  final DisputeRepository _disputes;
  final BookingRepository _bookings;
  final CustomerProfileRepository _customerProfiles;
  final CleanerProfileRepository _cleanerProfiles;
  final NotificationSink _notifications;
  final AuditSink _audit;
  final DateTime Function() _clock;

  Future<Map<String, Object?>> list({
    Object? status,
    Object? category,
    Object? bookingId,
    Object? customerUserId,
    Object? cleanerUserId,
    Object? limitRaw,
    Object? after,
  }) async {
    final parsedStatus = status == null
        ? DisputeStatus.open
        : DisputeValidation.optionalStatus(status);
    final page = await _disputes.adminPage(
      limit: DisputeValidation.requireLimit(limitRaw),
      status: parsedStatus,
      category: DisputeValidation.optionalCategory(category),
      bookingId: DisputeValidation.optionalObjectId(bookingId),
      customerUserId: DisputeValidation.optionalObjectId(customerUserId),
      cleanerUserId: DisputeValidation.optionalObjectId(cleanerUserId),
      after: DisputeValidation.optionalAfter(after),
    );
    final customers = await _customerProfiles.findByUserIds(
      page.items.map((item) => item.customerUserId),
    );
    final cleaners = await _cleanerProfiles.findByUserIds(
      page.items.map((item) => item.cleanerUserId),
    );
    final customerNames = <ObjectId, String>{
      for (final profile in customers) profile.userId: profile.fullName,
    };
    final cleanerNames = <ObjectId, String>{
      for (final profile in cleaners) profile.userId: profile.fullName,
    };
    return <String, Object?>{
      'items': [
        for (final item in page.items)
          <String, Object?>{
            ...item.toAdminJson(),
            'customer_display_name':
                customerNames[item.customerUserId] ?? 'Customer',
            'cleaner_public_name':
                cleanerNames[item.cleanerUserId] ?? 'Cleaner',
          },
      ],
      'next_cursor': page.nextCursor,
    };
  }

  Future<Map<String, Object?>> detail(ObjectId disputeId) async {
    final dispute = await _disputes.findById(disputeId);
    if (dispute == null) {
      throw const DisputeNotFoundException();
    }
    return _adminDetail(dispute);
  }

  Future<Map<String, Object?>> startReview({
    required UserAccount user,
    required ObjectId disputeId,
  }) async {
    final updated = await _disputes.markUnderReview(
      id: disputeId,
      adminUserId: user.id,
      now: _clock().toUtc(),
    );
    if (updated != null) {
      await _notifyParticipants(
        dispute: updated,
        type: NotificationType.disputeUnderReview,
        title: 'Dispute under review',
        body: 'An administrator is reviewing this booking dispute.',
        dedupePrefix: 'dispute_under_review',
      );
      await _audit.appendBestEffort(
        actorUserId: user.id,
        actorRole: UserRole.admin,
        action: AuditAction.disputeReviewStarted,
        targetType: AuditTargetType.dispute,
        targetId: updated.id,
        metadata: <String, Object?>{
          'previous_status': DisputeStatus.open.wireValue,
          'new_status': DisputeStatus.underReview.wireValue,
          'booking_id': updated.bookingId.oid,
        },
      );
      return _adminDetail(updated);
    }
    final existing = await _disputes.findById(disputeId);
    if (existing == null) {
      throw const DisputeNotFoundException();
    }
    if (existing.status == DisputeStatus.underReview) {
      return _adminDetail(existing);
    }
    throw const InvalidDisputeStateException();
  }

  Future<Map<String, Object?>> resolve({
    required UserAccount user,
    required ObjectId disputeId,
    required Object? resolutionRaw,
  }) async {
    final resolution = DisputeValidation.requireResolution(resolutionRaw);
    final existing = await _disputes.findById(disputeId);
    if (existing == null) {
      throw const DisputeNotFoundException();
    }
    final previous = existing.status.wireValue;
    final updated = await _disputes.resolve(
      id: disputeId,
      adminUserId: user.id,
      resolution: resolution,
      now: _clock().toUtc(),
    );
    if (updated == null) {
      throw const InvalidDisputeStateException();
    }
    await _notifyParticipants(
      dispute: updated,
      type: NotificationType.disputeResolved,
      title: 'Dispute resolved',
      body: 'An administrator recorded a resolution for this booking dispute.',
      dedupePrefix: 'dispute_resolved',
    );
    await _audit.appendBestEffort(
      actorUserId: user.id,
      actorRole: UserRole.admin,
      action: AuditAction.disputeResolved,
      targetType: AuditTargetType.dispute,
      targetId: updated.id,
      reason: resolution,
      metadata: <String, Object?>{
        'previous_status': previous,
        'new_status': DisputeStatus.resolved.wireValue,
        'booking_id': updated.bookingId.oid,
      },
    );
    return _adminDetail(updated);
  }

  Future<Map<String, Object?>> close({
    required UserAccount user,
    required ObjectId disputeId,
  }) async {
    final existing = await _disputes.findById(disputeId);
    if (existing == null) {
      throw const DisputeNotFoundException();
    }
    final updated = await _disputes.close(
      id: disputeId,
      actorUserId: user.id,
      actorRole: UserRole.admin,
      now: _clock().toUtc(),
    );
    if (updated == null) {
      throw const InvalidDisputeStateException();
    }
    await _notifyParticipants(
      dispute: updated,
      type: NotificationType.disputeClosed,
      title: 'Dispute closed',
      body: 'This booking dispute was closed.',
      dedupePrefix: 'dispute_closed',
    );
    await _audit.appendBestEffort(
      actorUserId: user.id,
      actorRole: UserRole.admin,
      action: AuditAction.disputeClosed,
      targetType: AuditTargetType.dispute,
      targetId: updated.id,
      metadata: <String, Object?>{
        'previous_status': DisputeStatus.resolved.wireValue,
        'new_status': DisputeStatus.closed.wireValue,
        'booking_id': updated.bookingId.oid,
      },
    );
    return _adminDetail(updated);
  }

  Future<void> _notifyParticipants({
    required Dispute dispute,
    required NotificationType type,
    required String title,
    required String body,
    required String dedupePrefix,
  }) async {
    for (final userId in <ObjectId>[
      dispute.customerUserId,
      dispute.cleanerUserId,
    ]) {
      await _notifications.notifyBestEffort(
        userId: userId,
        type: type,
        title: title,
        body: body,
        dedupeKey: '$dedupePrefix:${dispute.id.oid}:${userId.oid}',
        resourceType: 'dispute',
        resourceId: dispute.bookingId,
      );
    }
  }

  Future<Map<String, Object?>> _adminRow(Dispute dispute) async {
    final customer = await _customerProfiles.findByUserId(
      dispute.customerUserId,
    );
    final cleaner = await _cleanerProfiles.findByUserId(dispute.cleanerUserId);
    return <String, Object?>{
      ...dispute.toAdminJson(),
      'customer_display_name': customer?.fullName ?? 'Customer',
      'cleaner_public_name': cleaner?.fullName ?? 'Cleaner',
    };
  }

  Future<Map<String, Object?>> _adminDetail(Dispute dispute) async {
    final booking = await _bookings.findById(dispute.bookingId);
    final row = await _adminRow(dispute);
    return <String, Object?>{
      'dispute': row,
      'booking': booking == null
          ? null
          : <String, Object?>{
              'id': booking.id.oid,
              'status': booking.status.wireValue,
              'service_name': booking.serviceSnapshot.name,
              'start_at': booking.startAt.toUtc().toIso8601String(),
              'end_at': booking.endAt.toUtc().toIso8601String(),
              'quoted_total_minor': booking.quotedTotalMinor,
              'currency_code': booking.currencyCode,
            },
    };
  }
}

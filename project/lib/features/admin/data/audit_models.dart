enum AuditAction {
  userSuspended,
  userReactivated,
  userDeactivated,
  cleanerApproved,
  cleanerRejected,
  reviewHidden,
  reviewUnhidden,
  paymentRefundRequested,
  disputeReviewStarted,
  disputeResolved,
  disputeClosed,
  bookingAdminCancelled,
  payoutProcessingStarted,
  payoutRejected,
  payoutSandboxSimulated,
  unknown;

  static AuditAction fromWire(String value) {
    switch (value) {
      case 'user_suspended':
        return AuditAction.userSuspended;
      case 'user_reactivated':
        return AuditAction.userReactivated;
      case 'user_deactivated':
        return AuditAction.userDeactivated;
      case 'cleaner_approved':
        return AuditAction.cleanerApproved;
      case 'cleaner_rejected':
        return AuditAction.cleanerRejected;
      case 'review_hidden':
        return AuditAction.reviewHidden;
      case 'review_unhidden':
        return AuditAction.reviewUnhidden;
      case 'payment_refund_requested':
        return AuditAction.paymentRefundRequested;
      case 'dispute_review_started':
        return AuditAction.disputeReviewStarted;
      case 'dispute_resolved':
        return AuditAction.disputeResolved;
      case 'dispute_closed':
        return AuditAction.disputeClosed;
      case 'booking_admin_cancelled':
        return AuditAction.bookingAdminCancelled;
      case 'payout_processing_started':
        return AuditAction.payoutProcessingStarted;
      case 'payout_rejected':
        return AuditAction.payoutRejected;
      case 'payout_sandbox_simulated':
        return AuditAction.payoutSandboxSimulated;
      default:
        return AuditAction.unknown;
    }
  }

  String get wireValue {
    switch (this) {
      case AuditAction.userSuspended:
        return 'user_suspended';
      case AuditAction.userReactivated:
        return 'user_reactivated';
      case AuditAction.userDeactivated:
        return 'user_deactivated';
      case AuditAction.cleanerApproved:
        return 'cleaner_approved';
      case AuditAction.cleanerRejected:
        return 'cleaner_rejected';
      case AuditAction.reviewHidden:
        return 'review_hidden';
      case AuditAction.reviewUnhidden:
        return 'review_unhidden';
      case AuditAction.paymentRefundRequested:
        return 'payment_refund_requested';
      case AuditAction.disputeReviewStarted:
        return 'dispute_review_started';
      case AuditAction.disputeResolved:
        return 'dispute_resolved';
      case AuditAction.disputeClosed:
        return 'dispute_closed';
      case AuditAction.bookingAdminCancelled:
        return 'booking_admin_cancelled';
      case AuditAction.payoutProcessingStarted:
        return 'payout_processing_started';
      case AuditAction.payoutRejected:
        return 'payout_rejected';
      case AuditAction.payoutSandboxSimulated:
        return 'payout_sandbox_simulated';
      case AuditAction.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case AuditAction.userSuspended:
        return 'User suspended';
      case AuditAction.userReactivated:
        return 'User reactivated';
      case AuditAction.userDeactivated:
        return 'User deactivated';
      case AuditAction.cleanerApproved:
        return 'Cleaner approved';
      case AuditAction.cleanerRejected:
        return 'Cleaner rejected';
      case AuditAction.reviewHidden:
        return 'Review hidden';
      case AuditAction.reviewUnhidden:
        return 'Review unhidden';
      case AuditAction.paymentRefundRequested:
        return 'Payment refund requested';
      case AuditAction.disputeReviewStarted:
        return 'Dispute review started';
      case AuditAction.disputeResolved:
        return 'Dispute resolved';
      case AuditAction.disputeClosed:
        return 'Dispute closed';
      case AuditAction.bookingAdminCancelled:
        return 'Booking cancelled by admin';
      case AuditAction.payoutProcessingStarted:
        return 'Payout processing started';
      case AuditAction.payoutRejected:
        return 'Payout rejected';
      case AuditAction.payoutSandboxSimulated:
        return 'Payout sandbox simulated';
      case AuditAction.unknown:
        return 'Unknown action';
    }
  }

  static const List<AuditAction> filterable = <AuditAction>[
    AuditAction.userSuspended,
    AuditAction.userReactivated,
    AuditAction.userDeactivated,
    AuditAction.cleanerApproved,
    AuditAction.cleanerRejected,
    AuditAction.reviewHidden,
    AuditAction.reviewUnhidden,
    AuditAction.paymentRefundRequested,
    AuditAction.disputeReviewStarted,
    AuditAction.disputeResolved,
    AuditAction.disputeClosed,
    AuditAction.bookingAdminCancelled,
  ];
}

class AdminAuditLogSummary {
  const AdminAuditLogSummary({
    required this.id,
    required this.actorUserId,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    this.reason,
    this.metadata = const <String, Object?>{},
  });

  factory AdminAuditLogSummary.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    return AdminAuditLogSummary(
      id: _requireString(json, 'id'),
      actorUserId: _requireString(json, 'actor_user_id'),
      actorRole: _requireString(json, 'actor_role'),
      action: AuditAction.fromWire(_requireString(json, 'action')),
      targetType: _requireString(json, 'target_type'),
      targetId: _requireString(json, 'target_id'),
      reason: json['reason'] is String ? json['reason'] as String : null,
      metadata: _safeMetadata(metadata),
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
    );
  }

  final String id;
  final String actorUserId;
  final String actorRole;
  final AuditAction action;
  final String targetType;
  final String targetId;
  final String? reason;
  final Map<String, Object?> metadata;
  final DateTime createdAt;
}

typedef AdminAuditLogDetail = AdminAuditLogSummary;

class AdminAuditLogPage {
  const AdminAuditLogPage({required this.items, this.nextCursor});

  final List<AdminAuditLogSummary> items;
  final String? nextCursor;
}

Map<String, Object?> _safeMetadata(Object? raw) {
  if (raw is! Map) {
    return const <String, Object?>{};
  }
  final sanitized = <String, Object?>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String || key.isEmpty) {
      continue;
    }
    if (value == null || value is String || value is bool || value is int) {
      sanitized[key] = value;
    }
  }
  return sanitized;
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Audit log JSON field $key is invalid.');
  }
  return value;
}

// ignore_for_file: public_member_api_docs
import 'dart:developer' as developer;

import 'package:home_cleaning_marketplace_api/src/features/audit/application/audit_log_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_json.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/data/dispute_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/email_normalization.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Administrator user listing and account moderation.
class AdminUserManagementService {
  AdminUserManagementService({
    required UserRepository users,
    required CustomerProfileRepository customerProfiles,
    required CleanerProfileRepository cleanerProfiles,
    required BookingRepository bookings,
    required PaymentRepository payments,
    required DisputeRepository disputes,
    required Future<int> Function(ObjectId userId) revokeAllSessions,
    AuditSink? audit,
    DateTime Function()? clock,
  }) : _users = users,
       _customerProfiles = customerProfiles,
       _cleanerProfiles = cleanerProfiles,
       _bookings = bookings,
       _payments = payments,
       _disputes = disputes,
       _revokeAllSessions = revokeAllSessions,
       _audit = audit ?? const NoOpAuditSink(),
       _clock = clock ?? DateTime.now;

  final UserRepository _users;
  final CustomerProfileRepository _customerProfiles;
  final CleanerProfileRepository _cleanerProfiles;
  final BookingRepository _bookings;
  final PaymentRepository _payments;
  final DisputeRepository _disputes;
  final Future<int> Function(ObjectId userId) _revokeAllSessions;
  final AuditSink _audit;
  final DateTime Function() _clock;

  static const int _defaultLimit = 20;
  static const int _minLimit = 1;
  static const int _maxLimit = 50;

  Future<Map<String, Object?>> listUsers({
    Object? role,
    Object? status,
    Object? email,
    Object? limitRaw,
    Object? after,
  }) async {
    final page = await _users.adminPage(
      limit: _requireLimit(limitRaw),
      role: _optionalRole(role),
      status: _optionalStatus(status),
      emailNormalized: _optionalExactEmail(email),
      after: _optionalCursor(after),
    );
    final customers = await _customerProfiles.findByUserIds(
      page.items
          .where((user) => user.role == UserRole.customer)
          .map((user) => user.id),
    );
    final cleaners = await _cleanerProfiles.findByUserIds(
      page.items
          .where((user) => user.role == UserRole.cleaner)
          .map((user) => user.id),
    );
    final customerNames = <ObjectId, String>{
      for (final profile in customers) profile.userId: profile.fullName,
    };
    final cleanerSummaries = <ObjectId, Map<String, Object?>>{
      for (final profile in cleaners)
        profile.userId: <String, Object?>{
          'full_name': profile.fullName,
          'onboarding_status': profile.onboardingStatus.wireValue,
        },
    };
    return <String, Object?>{
      'items': [
        for (final user in page.items)
          <String, Object?>{
            ...authUserJson(user),
            if (user.role == UserRole.customer &&
                customerNames.containsKey(user.id))
              'full_name': customerNames[user.id],
            if (user.role == UserRole.cleaner &&
                cleanerSummaries.containsKey(user.id))
              ...cleanerSummaries[user.id]!,
          },
      ],
      'next_cursor': page.nextCursor,
    };
  }

  Future<Map<String, Object?>> getUser(ObjectId userId) async {
    final user = await _users.findById(userId);
    if (user == null) {
      throw const UserNotFoundException();
    }
    Map<String, Object?>? profile;
    if (user.role == UserRole.customer) {
      profile = (await _customerProfiles.findByUserId(user.id))?.toPublicJson();
    } else if (user.role == UserRole.cleaner) {
      profile = (await _cleanerProfiles.findByUserId(user.id))?.toPublicJson();
    }
    final bookingCount = user.role == UserRole.customer
        ? await _bookings.countForCustomer(user.id)
        : user.role == UserRole.cleaner
        ? await _bookings.countForCleaner(user.id)
        : 0;
    final paymentCount = user.role == UserRole.customer
        ? await _payments.countForCustomer(user.id)
        : 0;
    final activeDisputes = user.role == UserRole.admin
        ? 0
        : await _disputes.countActiveForUser(user.id);
    return <String, Object?>{
      'user': authUserJson(user),
      'profile': profile,
      'protected_admin_account': user.role == UserRole.admin,
      'booking_count': bookingCount,
      'payment_count': paymentCount,
      'active_dispute_count': activeDisputes,
    };
  }

  Future<Map<String, Object?>> suspend({
    required UserAccount actor,
    required ObjectId userId,
    required Object? reasonRaw,
  }) async {
    _rejectSelfOrAdminTarget(actor: actor, userId: userId);
    final reason = _requireReason(reasonRaw);
    final updated = await _users.setActiveToSuspended(
      userId: userId,
      now: _clock().toUtc(),
    );
    if (updated != null) {
      await _revokeSessions(updated.id);
      await _audit.appendBestEffort(
        actorUserId: actor.id,
        actorRole: UserRole.admin,
        action: AuditAction.userSuspended,
        targetType: AuditTargetType.user,
        targetId: updated.id,
        reason: reason,
        metadata: <String, Object?>{
          'previous_status': AccountStatus.active.wireValue,
          'new_status': AccountStatus.suspended.wireValue,
        },
      );
      return getUser(updated.id);
    }
    return _idempotentOrReject(
      userId: userId,
      acceptable: AccountStatus.suspended,
    );
  }

  Future<Map<String, Object?>> reactivate({
    required UserAccount actor,
    required ObjectId userId,
  }) async {
    _rejectSelfOrAdminTarget(actor: actor, userId: userId);
    final updated = await _users.setSuspendedToActive(
      userId: userId,
      now: _clock().toUtc(),
    );
    if (updated != null) {
      await _audit.appendBestEffort(
        actorUserId: actor.id,
        actorRole: UserRole.admin,
        action: AuditAction.userReactivated,
        targetType: AuditTargetType.user,
        targetId: updated.id,
        metadata: <String, Object?>{
          'previous_status': AccountStatus.suspended.wireValue,
          'new_status': AccountStatus.active.wireValue,
        },
      );
      return getUser(updated.id);
    }
    return _idempotentOrReject(
      userId: userId,
      acceptable: AccountStatus.active,
      rejectDeactivated: true,
    );
  }

  Future<Map<String, Object?>> deactivate({
    required UserAccount actor,
    required ObjectId userId,
    required Object? reasonRaw,
  }) async {
    _rejectSelfOrAdminTarget(actor: actor, userId: userId);
    final reason = _requireReason(reasonRaw);
    final existing = await _users.findById(userId);
    if (existing == null) {
      throw const UserNotFoundException();
    }
    _protectAdmin(existing);
    final previous = existing.accountStatus.wireValue;
    final updated = await _users.setActiveOrSuspendedToDeactivated(
      userId: userId,
      now: _clock().toUtc(),
    );
    if (updated != null) {
      await _revokeSessions(updated.id);
      await _audit.appendBestEffort(
        actorUserId: actor.id,
        actorRole: UserRole.admin,
        action: AuditAction.userDeactivated,
        targetType: AuditTargetType.user,
        targetId: updated.id,
        reason: reason,
        metadata: <String, Object?>{
          'previous_status': previous,
          'new_status': AccountStatus.deactivated.wireValue,
        },
      );
      return getUser(updated.id);
    }
    if (existing.accountStatus == AccountStatus.deactivated) {
      throw const InvalidAccountStateException();
    }
    throw const InvalidAccountStateException();
  }

  Future<Map<String, Object?>> _idempotentOrReject({
    required ObjectId userId,
    required AccountStatus acceptable,
    bool rejectDeactivated = false,
  }) async {
    final existing = await _users.findById(userId);
    if (existing == null) {
      throw const UserNotFoundException();
    }
    _protectAdmin(existing);
    if (rejectDeactivated &&
        existing.accountStatus == AccountStatus.deactivated) {
      throw const InvalidAccountStateException();
    }
    if (existing.accountStatus == acceptable) {
      return getUser(existing.id);
    }
    throw const InvalidAccountStateException();
  }

  void _rejectSelfOrAdminTarget({
    required UserAccount actor,
    required ObjectId userId,
  }) {
    if (actor.id == userId) {
      throw const ProtectedAdminAccountException();
    }
  }

  void _protectAdmin(UserAccount target) {
    if (target.role == UserRole.admin) {
      throw const ProtectedAdminAccountException();
    }
  }

  Future<void> _revokeSessions(ObjectId userId) async {
    try {
      await _revokeAllSessions(userId);
    } catch (_) {
      developer.log('session_revocation_failed', name: 'admin_users');
    }
  }

  static String _requireReason(Object? raw) {
    if (raw is! String) {
      throw const InvalidModerationReasonException(
        message: 'Reason must be plain text.',
      );
    }
    final trimmed = raw.trim();
    for (final rune in trimmed.runes) {
      if (rune < 0x20 || rune == 0x7F) {
        throw const InvalidModerationReasonException(
          message: 'Reason contains invalid characters.',
        );
      }
    }
    if (trimmed.runes.length < 5 || trimmed.runes.length > 500) {
      throw const InvalidModerationReasonException(
        message: 'Reason must be between 5 and 500 characters.',
      );
    }
    return trimmed;
  }

  static UserRole? _optionalRole(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw const InvalidAdminUserQueryException();
    }
    try {
      return UserRole.fromWire(raw.trim());
    } on FormatException {
      throw const InvalidAdminUserQueryException();
    }
  }

  static AccountStatus? _optionalStatus(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw const InvalidAdminUserQueryException();
    }
    try {
      return AccountStatus.fromWire(raw.trim());
    } on FormatException {
      throw const InvalidAdminUserQueryException();
    }
  }

  static String? _optionalExactEmail(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw const InvalidAdminUserQueryException();
    }
    return normalizeEmail(raw);
  }

  static int _requireLimit(Object? raw) {
    if (raw == null) {
      return _defaultLimit;
    }
    final value = raw is int
        ? raw
        : raw is String
        ? int.tryParse(raw.trim())
        : null;
    if (value == null || value < _minLimit || value > _maxLimit) {
      throw const InvalidAdminUserQueryException();
    }
    return value;
  }

  static ObjectId? _optionalCursor(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is ObjectId) {
      return raw;
    }
    if (raw is String) {
      try {
        return ObjectId.fromHexString(raw.trim());
      } catch (_) {
        throw const UserNotFoundException();
      }
    }
    throw const UserNotFoundException();
  }
}

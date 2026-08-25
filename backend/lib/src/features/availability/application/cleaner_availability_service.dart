import 'package:home_cleaning_marketplace_api/src/features/authorization/approved_cleaner_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_slot.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/http/api_date_time.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent cleaner availability management.
class CleanerAvailabilityService {
  /// Creates a service over repositories and [policy].
  CleanerAvailabilityService({
    required ApprovedCleanerPolicy policy,
    required ServiceRepository services,
    required CleanerServiceRepository offerings,
    required AvailabilityRepository slots,
    DateTime Function()? clock,
  }) : _policy = policy,
       _services = services,
       _offerings = offerings,
       _slots = slots,
       _clock = clock ?? DateTime.now;

  final ApprovedCleanerPolicy _policy;
  final ServiceRepository _services;
  final CleanerServiceRepository _offerings;
  final AvailabilityRepository _slots;
  final DateTime Function() _clock;

  /// Lists owned slots in the requested window.
  Future<List<Map<String, Object?>>> list({
    required UserAccount user,
    Object? fromRaw,
    Object? toRaw,
    ObjectId? serviceId,
  }) async {
    await _policy.requireApproved(user);
    final now = _clock().toUtc();
    final range = _parseListRange(fromRaw: fromRaw, toRaw: toRaw, now: now);
    final items = await _slots.listForCleaner(
      cleanerUserId: user.id,
      from: range.from,
      to: range.to,
      serviceId: serviceId,
    );
    return [for (final slot in items) slot.toPublicJson()];
  }

  /// Returns one owned future slot.
  Future<Map<String, Object?>> get({
    required UserAccount user,
    required ObjectId slotId,
  }) async {
    await _policy.requireApproved(user);
    final slot = await _slots.findOwnedFutureById(
      id: slotId,
      cleanerUserId: user.id,
      now: _clock().toUtc(),
    );
    if (slot == null) {
      throw const AvailabilityNotFoundException();
    }
    return slot.toPublicJson();
  }

  /// Creates a future open slot.
  Future<Map<String, Object?>> create({
    required UserAccount user,
    required Object? serviceIdRaw,
    required Object? startAt,
    required Object? endAt,
  }) async {
    await _policy.requireApproved(user);
    final now = _clock().toUtc();
    final serviceId = _requireObjectId(serviceIdRaw);
    await _requireActiveOffering(user.id, serviceId);
    final window = AvailabilityValidation.requireSlotWindow(
      startRaw: startAt,
      endRaw: endAt,
      now: now,
    );
    final futureCount = await _slots.countFutureForCleaner(
      cleanerUserId: user.id,
      now: now,
    );
    if (futureCount >= AvailabilityValidation.maxFutureSlots) {
      throw const AvailabilityLimitReachedException();
    }
    await _rejectOverlap(
      cleanerUserId: user.id,
      startAt: window.startAt,
      endAt: window.endAt,
    );
    final created = AvailabilitySlot(
      id: ObjectId(),
      cleanerUserId: user.id,
      serviceId: serviceId,
      startAt: window.startAt,
      endAt: window.endAt,
      createdAt: now,
      updatedAt: now,
    );
    final stored = await _slots.create(created);
    return stored.toPublicJson();
  }

  /// Updates an owned future slot.
  Future<Map<String, Object?>> update({
    required UserAccount user,
    required ObjectId slotId,
    required Object? serviceIdRaw,
    required Object? startAt,
    required Object? endAt,
  }) async {
    await _policy.requireApproved(user);
    final now = _clock().toUtc();
    final existing = await _slots.findOwnedFutureById(
      id: slotId,
      cleanerUserId: user.id,
      now: now,
    );
    if (existing == null) {
      throw const AvailabilityNotFoundException();
    }
    final serviceId = _requireObjectId(serviceIdRaw);
    await _requireActiveOffering(user.id, serviceId);
    final window = AvailabilityValidation.requireSlotWindow(
      startRaw: startAt,
      endRaw: endAt,
      now: now,
    );
    await _rejectOverlap(
      cleanerUserId: user.id,
      startAt: window.startAt,
      endAt: window.endAt,
      excludeId: slotId,
    );
    final updated = await _slots.updateOwnedFuture(
      id: slotId,
      cleanerUserId: user.id,
      now: now,
      serviceId: serviceId,
      startAt: window.startAt,
      endAt: window.endAt,
    );
    if (updated == null) {
      throw const AvailabilityNotFoundException();
    }
    return updated.toPublicJson();
  }

  /// Physically deletes an owned future slot.
  Future<void> delete({
    required UserAccount user,
    required ObjectId slotId,
  }) async {
    await _policy.requireApproved(user);
    final deleted = await _slots.deleteOwnedFuture(
      id: slotId,
      cleanerUserId: user.id,
      now: _clock().toUtc(),
    );
    if (!deleted) {
      throw const AvailabilityNotFoundException();
    }
  }

  Future<void> _requireActiveOffering(
    ObjectId cleanerUserId,
    ObjectId serviceId,
  ) async {
    final service = await _services.findById(serviceId);
    if (service == null || !service.active) {
      throw const ServiceNotFoundException();
    }
    final offering = await _offerings.findActiveOffering(
      cleanerUserId: cleanerUserId,
      serviceId: serviceId,
    );
    if (offering == null) {
      throw const ServiceNotFoundException();
    }
  }

  Future<void> _rejectOverlap({
    required ObjectId cleanerUserId,
    required DateTime startAt,
    required DateTime endAt,
    ObjectId? excludeId,
  }) async {
    final overlap = await _slots.findOverlap(
      cleanerUserId: cleanerUserId,
      startAt: startAt,
      endAt: endAt,
      excludeId: excludeId,
    );
    if (overlap != null) {
      throw const AvailabilityOverlapException();
    }
  }

  ({DateTime from, DateTime to}) _parseListRange({
    required Object? fromRaw,
    required Object? toRaw,
    required DateTime now,
  }) {
    if ((fromRaw == null) != (toRaw == null)) {
      throw const InvalidAvailabilityWindowException(
        message: 'from and to must be supplied together.',
      );
    }
    if (fromRaw == null) {
      return AvailabilityValidation.requireRange(
        from: now,
        to: now.add(AvailabilityValidation.defaultListHorizon),
        maxRange: AvailabilityValidation.maxListRange,
      );
    }
    DateTime from;
    DateTime to;
    try {
      from = ApiDateTime.parseRequiredUtc(fromRaw, field: 'from');
      to = ApiDateTime.parseRequiredUtc(toRaw, field: 'to');
    } on FormatException {
      throw const InvalidAvailabilityWindowException(
        message: 'from and to must be ISO-8601 timestamps with a timezone.',
      );
    }
    return AvailabilityValidation.requireRange(
      from: from,
      to: to,
      maxRange: AvailabilityValidation.maxListRange,
    );
  }

  ObjectId _requireObjectId(Object? raw) {
    if (raw is ObjectId) {
      return raw;
    }
    if (raw is String) {
      try {
        return ObjectId.fromHexString(raw);
      } catch (_) {
        throw const ServiceNotFoundException();
      }
    }
    throw const ServiceNotFoundException();
  }
}

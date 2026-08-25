import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/http/api_date_time.dart';

/// Duration and overlap rules for open availability slots.
abstract final class AvailabilityValidation {
  /// Minimum slot duration.
  static const Duration minDuration = Duration(minutes: 60);

  /// Maximum slot duration.
  static const Duration maxDuration = Duration(hours: 8);

  /// Slot duration must be a multiple of this increment.
  static const Duration increment = Duration(minutes: 30);

  /// Maximum future open slots per cleaner.
  static const int maxFutureSlots = 180;

  /// Maximum GET query range for cleaner availability listing.
  static const Duration maxListRange = Duration(days: 180);

  /// Default GET query horizon when `to` is omitted.
  static const Duration defaultListHorizon = Duration(days: 90);

  /// Maximum discovery availability filter window.
  static const Duration maxDiscoveryWindow = Duration(days: 31);

  /// Default discovery-detail availability horizon.
  static const Duration defaultDetailHorizon = Duration(days: 30);

  /// Maximum slots returned on discovery detail.
  static const int maxDetailSlots = 60;

  /// Parses [raw] as UTC with an explicit timezone/offset.
  static DateTime requireTimestamp(Object? raw, {required String field}) {
    try {
      return ApiDateTime.parseRequiredUtc(raw, field: field);
    } on FormatException {
      throw InvalidAvailabilityWindowException(
        message: '$field must be an ISO-8601 timestamp with a timezone.',
      );
    }
  }

  /// Validates a create/update slot window against [now].
  static ({DateTime startAt, DateTime endAt}) requireSlotWindow({
    required Object? startRaw,
    required Object? endRaw,
    required DateTime now,
  }) {
    final startAt = requireTimestamp(startRaw, field: 'start_at');
    final endAt = requireTimestamp(endRaw, field: 'end_at');
    if (!startAt.isBefore(endAt)) {
      throw const InvalidAvailabilityWindowException(
        message: 'start_at must be before end_at.',
      );
    }
    if (!startAt.isAfter(now)) {
      throw const InvalidAvailabilityWindowException(
        message: 'Availability must start in the future.',
      );
    }
    final duration = endAt.difference(startAt);
    if (duration.inMilliseconds % Duration.millisecondsPerMinute != 0) {
      throw const InvalidAvailabilityWindowException(
        message: 'Slot duration must be a whole number of minutes.',
      );
    }
    if (duration < minDuration || duration > maxDuration) {
      throw const InvalidAvailabilityWindowException(
        message: 'Slot duration must be between 60 minutes and 8 hours.',
      );
    }
    if (duration.inMinutes % increment.inMinutes != 0) {
      throw const InvalidAvailabilityWindowException(
        message: 'Slot duration must be a multiple of 30 minutes.',
      );
    }
    return (startAt: startAt, endAt: endAt);
  }

  /// Validates an optional listing or discovery range.
  static ({DateTime from, DateTime to}) requireRange({
    required DateTime from,
    required DateTime to,
    required Duration maxRange,
  }) {
    if (!from.isBefore(to)) {
      throw const InvalidAvailabilityWindowException(
        message: 'The start of the range must be before the end.',
      );
    }
    if (to.difference(from) > maxRange) {
      throw const InvalidAvailabilityWindowException(
        message: 'The requested date range is too large.',
      );
    }
    return (from: from, to: to);
  }
}

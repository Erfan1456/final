/// Client-side availability window rules matching the backend.
abstract final class AvailabilityWindow {
  static const Duration minDuration = Duration(minutes: 60);
  static const Duration maxDuration = Duration(hours: 8);
  static const Duration increment = Duration(minutes: 30);

  /// Next start time at least one hour from [now], aligned to 30 minutes.
  static DateTime nextValidStart([DateTime? now]) {
    final base = (now ?? DateTime.now()).add(const Duration(hours: 1));
    return alignToIncrement(base, roundUp: true);
  }

  /// Default two-hour window starting at [nextValidStart].
  static DateTime defaultEnd(DateTime start) {
    return start.add(const Duration(hours: 2));
  }

  /// Drops seconds/milliseconds and aligns minutes to 0 or 30.
  static DateTime alignToIncrement(DateTime value, {bool roundUp = false}) {
    final trimmed = DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    );
    final remainder = trimmed.minute % increment.inMinutes;
    if (remainder == 0) {
      return trimmed;
    }
    if (roundUp) {
      return trimmed.add(Duration(minutes: increment.inMinutes - remainder));
    }
    return trimmed.subtract(Duration(minutes: remainder));
  }

  /// User-facing validation, or `null` when the window is acceptable.
  static String? validate({
    required DateTime start,
    required DateTime end,
    DateTime? now,
  }) {
    if (!start.isBefore(end)) {
      return 'End time must be after start time.';
    }
    if (!start.isAfter(now ?? DateTime.now())) {
      return 'Availability must start in the future.';
    }
    final duration = end.difference(start);
    if (duration < minDuration || duration > maxDuration) {
      return 'Slot duration must be between 60 minutes and 8 hours.';
    }
    if (duration.inMinutes % increment.inMinutes != 0) {
      return 'Slot duration must be a multiple of 30 minutes.';
    }
    return null;
  }
}

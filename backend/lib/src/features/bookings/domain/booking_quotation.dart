/// Integer minor-unit quotation for a complete booked slot.
///
/// Does not use floating-point arithmetic. The result is a snapshot, not a
/// payment, authorization, or captured amount.
abstract final class BookingQuotation {
  /// Round-half-up quoted total in minor units.
  ///
  /// `quoted_total_minor = (hourly_rate_minor * duration_minutes + 30) ~/ 60`
  static int quotedTotalMinor({
    required int hourlyRateMinor,
    required int durationMinutes,
  }) {
    final numerator = hourlyRateMinor * durationMinutes;
    return (numerator + 30) ~/ 60;
  }

  /// Slot duration in whole minutes.
  static int durationMinutes({
    required DateTime startAt,
    required DateTime endAt,
  }) {
    return endAt.toUtc().difference(startAt.toUtc()).inMinutes;
  }
}

/// Safe local date/time presentation using Dart SDK only.
///
/// Server timestamps are treated as UTC when [isUtc] is true (typical for
/// parsed ISO-8601 values) and converted to the device local zone for display.
String formatAppDateTime(DateTime? value) {
  if (value == null) {
    return '—';
  }
  final local = value.toLocal();
  final day = local.day;
  final month = _monthName(local.month);
  final year = local.year;
  final hour = local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$day $month $year, $hour12:$minute $period';
}

/// Backward-compatible alias used by existing feature screens.
String formatLocalDateTime(DateTime value) => formatAppDateTime(value);

String _monthName(int month) {
  const names = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (month < 1 || month > 12) {
    return '???';
  }
  return names[month - 1];
}

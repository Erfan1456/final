/// Parses API timestamps that must include an explicit timezone or offset.
abstract final class ApiDateTime {
  static final RegExp _explicitOffset = RegExp(
    r'(Z|[+-]\d{2}:?\d{2})$',
    caseSensitive: false,
  );

  /// Parses [raw] as ISO-8601 and returns UTC.
  ///
  /// Requires a [String] with an explicit `Z` or numeric offset. Timezone-less
  /// values are rejected so the backend never infers a client local zone.
  static DateTime parseRequiredUtc(Object? raw, {required String field}) {
    if (raw is! String || raw.trim().isEmpty) {
      throw FormatException('$field must be an ISO-8601 timestamp string.');
    }
    final value = raw.trim();
    if (!_explicitOffset.hasMatch(value)) {
      throw FormatException(
        '$field must include an explicit timezone or offset.',
      );
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('$field is not a valid ISO-8601 timestamp.');
    }
    return parsed.toUtc();
  }

  /// Whether [raw] can be parsed as an explicit-offset ISO-8601 timestamp.
  static bool hasExplicitOffset(String raw) {
    return _explicitOffset.hasMatch(raw.trim());
  }
}

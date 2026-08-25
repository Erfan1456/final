enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  declined,
  cancelled,
  unknown;

  static BookingStatus fromWire(String value) {
    switch (value) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'declined':
        return BookingStatus.declined;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.unknown;
    }
  }

  String get wireValue {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.declined:
        return 'declined';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.unknown:
        return 'Unknown';
    }
  }

  bool get exposesFullAddressToCleaner {
    switch (this) {
      case BookingStatus.confirmed:
      case BookingStatus.inProgress:
      case BookingStatus.completed:
        return true;
      case BookingStatus.pending:
      case BookingStatus.declined:
      case BookingStatus.cancelled:
      case BookingStatus.unknown:
        return false;
    }
  }

  bool get canOpenDispute {
    switch (this) {
      case BookingStatus.confirmed:
      case BookingStatus.inProgress:
      case BookingStatus.completed:
      case BookingStatus.cancelled:
        return true;
      case BookingStatus.pending:
      case BookingStatus.declined:
      case BookingStatus.unknown:
        return false;
    }
  }
}

class BookingServiceSnapshot {
  const BookingServiceSnapshot({
    required this.slug,
    required this.name,
    required this.billingModel,
  });

  factory BookingServiceSnapshot.fromJson(Map<String, dynamic> json) {
    final slug = json['slug'];
    final name = json['name'];
    final billing = json['billing_model'];
    if (slug is! String || name is! String || billing is! String) {
      throw const FormatException('Booking service snapshot JSON is invalid.');
    }
    return BookingServiceSnapshot(
      slug: slug,
      name: name,
      billingModel: billing,
    );
  }

  final String slug;
  final String name;
  final String billingModel;
}

class BookingAddressSnapshot {
  const BookingAddressSnapshot({
    required this.city,
    required this.region,
    required this.countryCode,
    this.label,
    this.line1,
    this.line2,
    this.postalCode,
  });

  factory BookingAddressSnapshot.fromJson(Map<String, dynamic> json) {
    final city = json['city'];
    final region = json['region'];
    final country = json['country_code'];
    if (city is! String || region is! String || country is! String) {
      throw const FormatException('Booking address snapshot JSON is invalid.');
    }
    return BookingAddressSnapshot(
      label: json['label'] is String ? json['label'] as String : null,
      line1: json['line1'] is String ? json['line1'] as String : null,
      line2: json['line2'] is String ? json['line2'] as String : null,
      city: city,
      region: region,
      postalCode: json['postal_code'] is String
          ? json['postal_code'] as String
          : null,
      countryCode: country,
    );
  }

  final String? label;
  final String? line1;
  final String? line2;
  final String city;
  final String region;
  final String? postalCode;
  final String countryCode;

  bool get isFull => line1 != null;

  String get coarseSummary => '$city, $region, $countryCode';

  String get summary {
    if (line1 == null) {
      return coarseSummary;
    }
    final prefix = label == null ? line1! : '$label · $line1';
    return '$prefix, $city';
  }
}

class BookingStatusHistoryEntry {
  const BookingStatusHistoryEntry({
    required this.toStatus,
    required this.actorUserId,
    required this.actorRole,
    required this.createdAt,
    this.fromStatus,
    this.reason,
  });

  factory BookingStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    final toStatus = json['to_status'];
    final actorUserId = json['actor_user_id'];
    final actorRole = json['actor_role'];
    final createdAt = json['created_at'];
    if (toStatus is! String ||
        actorUserId is! String ||
        actorRole is! String ||
        createdAt is! String) {
      throw const FormatException('Booking history JSON is invalid.');
    }
    final fromStatus = json['from_status'];
    return BookingStatusHistoryEntry(
      fromStatus: fromStatus is String
          ? BookingStatus.fromWire(fromStatus)
          : null,
      toStatus: BookingStatus.fromWire(toStatus),
      actorUserId: actorUserId,
      actorRole: actorRole,
      reason: json['reason'] is String ? json['reason'] as String : null,
      createdAt: DateTime.parse(createdAt).toUtc(),
    );
  }

  final BookingStatus? fromStatus;
  final BookingStatus toStatus;
  final String actorUserId;
  final String actorRole;
  final String? reason;
  final DateTime createdAt;
}

class CustomerBooking {
  const CustomerBooking({
    required this.id,
    required this.status,
    required this.cleanerUserId,
    required this.cleanerFullName,
    required this.serviceSnapshot,
    required this.addressSnapshot,
    required this.durationMinutes,
    required this.hourlyRateMinor,
    required this.quotedTotalMinor,
    required this.currencyCode,
    required this.startAt,
    required this.endAt,
    required this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
    this.customerNotes,
    this.acceptedAt,
    this.declinedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.idempotentReplay = false,
  });

  factory CustomerBooking.fromJson(Map<String, dynamic> json) {
    return CustomerBooking(
      id: _requireString(json, 'id'),
      status: BookingStatus.fromWire(_requireString(json, 'status')),
      cleanerUserId: _requireString(json, 'cleaner_user_id'),
      cleanerFullName: _requireString(json, 'cleaner_full_name'),
      serviceSnapshot: BookingServiceSnapshot.fromJson(
        _requireMap(json, 'service_snapshot'),
      ),
      addressSnapshot: BookingAddressSnapshot.fromJson(
        _requireMap(json, 'address_snapshot'),
      ),
      durationMinutes: _requireInt(json, 'duration_minutes'),
      hourlyRateMinor: _requireInt(json, 'hourly_rate_minor'),
      quotedTotalMinor: _requireInt(json, 'quoted_total_minor'),
      currencyCode: _requireString(json, 'currency_code'),
      customerNotes: json['customer_notes'] is String
          ? json['customer_notes'] as String
          : null,
      startAt: DateTime.parse(_requireString(json, 'start_at')).toUtc(),
      endAt: DateTime.parse(_requireString(json, 'end_at')).toUtc(),
      acceptedAt: _optionalTime(json['accepted_at']),
      declinedAt: _optionalTime(json['declined_at']),
      startedAt: _optionalTime(json['started_at']),
      completedAt: _optionalTime(json['completed_at']),
      cancelledAt: _optionalTime(json['cancelled_at']),
      statusHistory: _history(json['status_history']),
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      updatedAt: DateTime.parse(_requireString(json, 'updated_at')).toUtc(),
      idempotentReplay: json['idempotent_replay'] == true,
    );
  }

  final String id;
  final BookingStatus status;
  final String cleanerUserId;
  final String cleanerFullName;
  final BookingServiceSnapshot serviceSnapshot;
  final BookingAddressSnapshot addressSnapshot;
  final int durationMinutes;
  final int hourlyRateMinor;
  final int quotedTotalMinor;
  final String currencyCode;
  final String? customerNotes;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final List<BookingStatusHistoryEntry> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool idempotentReplay;

  bool get canCancel =>
      (status == BookingStatus.pending || status == BookingStatus.confirmed) &&
      startAt.isAfter(DateTime.now().toUtc());
}

class CleanerBooking {
  const CleanerBooking({
    required this.id,
    required this.status,
    required this.customerDisplayName,
    required this.serviceSnapshot,
    required this.addressSnapshot,
    required this.durationMinutes,
    required this.hourlyRateMinor,
    required this.quotedTotalMinor,
    required this.currencyCode,
    required this.startAt,
    required this.endAt,
    required this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
    this.customerNotes,
    this.acceptedAt,
    this.declinedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });

  factory CleanerBooking.fromJson(Map<String, dynamic> json) {
    return CleanerBooking(
      id: _requireString(json, 'id'),
      status: BookingStatus.fromWire(_requireString(json, 'status')),
      customerDisplayName: _requireString(json, 'customer_display_name'),
      serviceSnapshot: BookingServiceSnapshot.fromJson(
        _requireMap(json, 'service_snapshot'),
      ),
      addressSnapshot: BookingAddressSnapshot.fromJson(
        _requireMap(json, 'address_snapshot'),
      ),
      durationMinutes: _requireInt(json, 'duration_minutes'),
      hourlyRateMinor: _requireInt(json, 'hourly_rate_minor'),
      quotedTotalMinor: _requireInt(json, 'quoted_total_minor'),
      currencyCode: _requireString(json, 'currency_code'),
      customerNotes: json['customer_notes'] is String
          ? json['customer_notes'] as String
          : null,
      startAt: DateTime.parse(_requireString(json, 'start_at')).toUtc(),
      endAt: DateTime.parse(_requireString(json, 'end_at')).toUtc(),
      acceptedAt: _optionalTime(json['accepted_at']),
      declinedAt: _optionalTime(json['declined_at']),
      startedAt: _optionalTime(json['started_at']),
      completedAt: _optionalTime(json['completed_at']),
      cancelledAt: _optionalTime(json['cancelled_at']),
      statusHistory: _history(json['status_history']),
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      updatedAt: DateTime.parse(_requireString(json, 'updated_at')).toUtc(),
    );
  }

  final String id;
  final BookingStatus status;
  final String customerDisplayName;
  final BookingServiceSnapshot serviceSnapshot;
  final BookingAddressSnapshot addressSnapshot;
  final int durationMinutes;
  final int hourlyRateMinor;
  final int quotedTotalMinor;
  final String currencyCode;
  final String? customerNotes;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final List<BookingStatusHistoryEntry> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get canAccept => status == BookingStatus.pending;
  bool get canDecline => status == BookingStatus.pending;
  bool get canCancel =>
      status == BookingStatus.confirmed &&
      startAt.isAfter(DateTime.now().toUtc());
  bool get canStart {
    final now = DateTime.now().toUtc();
    return status == BookingStatus.confirmed &&
        !now.isBefore(startAt) &&
        now.isBefore(endAt);
  }

  bool get canComplete => status == BookingStatus.inProgress;
}

class BookingPage<T> {
  const BookingPage({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;
}

int quotedTotalMinorPreview({
  required int hourlyRateMinor,
  required int durationMinutes,
}) {
  return (hourlyRateMinor * durationMinutes + 30) ~/ 60;
}

String formatQuotedTotal(int quotedTotalMinor, String currencyCode) {
  return 'Quoted total: $currencyCode $quotedTotalMinor minor units';
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Booking JSON field $key is invalid.');
  }
  return value;
}

int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Booking JSON field $key is invalid.');
  }
  return value;
}

Map<String, dynamic> _requireMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) {
    throw FormatException('Booking JSON field $key is invalid.');
  }
  return Map<String, dynamic>.from(value);
}

DateTime? _optionalTime(Object? raw) {
  if (raw is! String || raw.isEmpty) {
    return null;
  }
  return DateTime.parse(raw).toUtc();
}

List<BookingStatusHistoryEntry> _history(Object? raw) {
  if (raw is! List) {
    throw const FormatException('Booking history JSON is invalid.');
  }
  return [
    for (final item in raw)
      if (item is Map)
        BookingStatusHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
  ];
}

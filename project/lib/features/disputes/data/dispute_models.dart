enum DisputeStatus {
  open,
  underReview,
  resolved,
  closed,
  unknown;

  static DisputeStatus fromWire(String value) {
    switch (value) {
      case 'open':
        return DisputeStatus.open;
      case 'under_review':
        return DisputeStatus.underReview;
      case 'resolved':
        return DisputeStatus.resolved;
      case 'closed':
        return DisputeStatus.closed;
      default:
        return DisputeStatus.unknown;
    }
  }

  String get wireValue {
    switch (this) {
      case DisputeStatus.open:
        return 'open';
      case DisputeStatus.underReview:
        return 'under_review';
      case DisputeStatus.resolved:
        return 'resolved';
      case DisputeStatus.closed:
        return 'closed';
      case DisputeStatus.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case DisputeStatus.open:
        return 'Open';
      case DisputeStatus.underReview:
        return 'Under Review';
      case DisputeStatus.resolved:
        return 'Resolved';
      case DisputeStatus.closed:
        return 'Closed';
      case DisputeStatus.unknown:
        return 'Unknown';
    }
  }
}

enum DisputeCategory {
  serviceQuality,
  cleanerNoShow,
  customerNoShow,
  paymentIssue,
  bookingIssue,
  conduct,
  other,
  unknown;

  static DisputeCategory fromWire(String value) {
    switch (value) {
      case 'service_quality':
        return DisputeCategory.serviceQuality;
      case 'cleaner_no_show':
        return DisputeCategory.cleanerNoShow;
      case 'customer_no_show':
        return DisputeCategory.customerNoShow;
      case 'payment_issue':
        return DisputeCategory.paymentIssue;
      case 'booking_issue':
        return DisputeCategory.bookingIssue;
      case 'conduct':
        return DisputeCategory.conduct;
      case 'other':
        return DisputeCategory.other;
      default:
        return DisputeCategory.unknown;
    }
  }

  String get wireValue {
    switch (this) {
      case DisputeCategory.serviceQuality:
        return 'service_quality';
      case DisputeCategory.cleanerNoShow:
        return 'cleaner_no_show';
      case DisputeCategory.customerNoShow:
        return 'customer_no_show';
      case DisputeCategory.paymentIssue:
        return 'payment_issue';
      case DisputeCategory.bookingIssue:
        return 'booking_issue';
      case DisputeCategory.conduct:
        return 'conduct';
      case DisputeCategory.other:
        return 'other';
      case DisputeCategory.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case DisputeCategory.serviceQuality:
        return 'Service quality';
      case DisputeCategory.cleanerNoShow:
        return 'Cleaner no-show';
      case DisputeCategory.customerNoShow:
        return 'Customer no-show';
      case DisputeCategory.paymentIssue:
        return 'Payment issue';
      case DisputeCategory.bookingIssue:
        return 'Booking issue';
      case DisputeCategory.conduct:
        return 'Conduct';
      case DisputeCategory.other:
        return 'Other';
      case DisputeCategory.unknown:
        return 'Unknown';
    }
  }

  static const List<DisputeCategory> selectable = <DisputeCategory>[
    DisputeCategory.serviceQuality,
    DisputeCategory.cleanerNoShow,
    DisputeCategory.customerNoShow,
    DisputeCategory.paymentIssue,
    DisputeCategory.bookingIssue,
    DisputeCategory.conduct,
    DisputeCategory.other,
  ];
}

class DisputeHistoryEntry {
  const DisputeHistoryEntry({
    required this.toStatus,
    required this.actorUserId,
    required this.actorRole,
    required this.createdAt,
    this.fromStatus,
    this.note,
  });

  factory DisputeHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DisputeHistoryEntry(
      fromStatus: json['from_status'] is String
          ? DisputeStatus.fromWire(json['from_status'] as String)
          : null,
      toStatus: DisputeStatus.fromWire(_requireString(json, 'to_status')),
      actorUserId: _requireString(json, 'actor_user_id'),
      actorRole: _requireString(json, 'actor_role'),
      note: json['note'] is String ? json['note'] as String : null,
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
    );
  }

  final DisputeStatus? fromStatus;
  final DisputeStatus toStatus;
  final String actorUserId;
  final String actorRole;
  final String? note;
  final DateTime createdAt;
}

class BookingDispute {
  const BookingDispute({
    required this.id,
    required this.bookingId,
    required this.category,
    required this.status,
    required this.subject,
    required this.description,
    required this.history,
    required this.createdAt,
    required this.updatedAt,
    this.resolution,
    this.resolvedAt,
    this.cleanerPublicName,
    this.customerDisplayName,
  });

  factory BookingDispute.fromJson(Map<String, dynamic> json) {
    final history = json['history'];
    if (history is! List) {
      throw const FormatException('Dispute history JSON is invalid.');
    }
    return BookingDispute(
      id: _requireString(json, 'id'),
      bookingId: _requireString(json, 'booking_id'),
      category: DisputeCategory.fromWire(_requireString(json, 'category')),
      status: DisputeStatus.fromWire(_requireString(json, 'status')),
      subject: _requireString(json, 'subject'),
      description: _requireString(json, 'description'),
      resolution: json['resolution'] is String
          ? json['resolution'] as String
          : null,
      history: [
        for (final item in history)
          if (item is Map)
            DisputeHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
      ],
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      updatedAt: DateTime.parse(_requireString(json, 'updated_at')).toUtc(),
      resolvedAt: _optionalDate(json, 'resolved_at'),
      cleanerPublicName: json['cleaner_public_name'] is String
          ? json['cleaner_public_name'] as String
          : null,
      customerDisplayName: json['customer_display_name'] is String
          ? json['customer_display_name'] as String
          : null,
    );
  }

  final String id;
  final String bookingId;
  final DisputeCategory category;
  final DisputeStatus status;
  final String subject;
  final String description;
  final String? resolution;
  final List<DisputeHistoryEntry> history;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? cleanerPublicName;
  final String? customerDisplayName;

  bool get canClose => status == DisputeStatus.resolved;

  String get counterpartName =>
      cleanerPublicName ?? customerDisplayName ?? 'Participant';
}

class AdminDisputeSummary {
  const AdminDisputeSummary({
    required this.id,
    required this.bookingId,
    required this.category,
    required this.status,
    required this.subject,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.customerDisplayName,
    required this.cleanerPublicName,
    required this.createdAt,
  });

  factory AdminDisputeSummary.fromJson(Map<String, dynamic> json) {
    return AdminDisputeSummary(
      id: _requireString(json, 'id'),
      bookingId: _requireString(json, 'booking_id'),
      category: DisputeCategory.fromWire(_requireString(json, 'category')),
      status: DisputeStatus.fromWire(_requireString(json, 'status')),
      subject: _requireString(json, 'subject'),
      customerUserId: _requireString(json, 'customer_user_id'),
      cleanerUserId: _requireString(json, 'cleaner_user_id'),
      customerDisplayName: json['customer_display_name'] is String
          ? json['customer_display_name'] as String
          : 'Customer',
      cleanerPublicName: json['cleaner_public_name'] is String
          ? json['cleaner_public_name'] as String
          : 'Cleaner',
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
    );
  }

  final String id;
  final String bookingId;
  final DisputeCategory category;
  final DisputeStatus status;
  final String subject;
  final String customerUserId;
  final String cleanerUserId;
  final String customerDisplayName;
  final String cleanerPublicName;
  final DateTime createdAt;
}

class AdminDisputeBookingSummary {
  const AdminDisputeBookingSummary({
    required this.id,
    required this.status,
    required this.serviceName,
    required this.startAt,
    required this.endAt,
    required this.quotedTotalMinor,
    required this.currencyCode,
  });

  factory AdminDisputeBookingSummary.fromJson(Map<String, dynamic> json) {
    return AdminDisputeBookingSummary(
      id: _requireString(json, 'id'),
      status: _requireString(json, 'status'),
      serviceName: _requireString(json, 'service_name'),
      startAt: DateTime.parse(_requireString(json, 'start_at')).toUtc(),
      endAt: DateTime.parse(_requireString(json, 'end_at')).toUtc(),
      quotedTotalMinor: _requireInt(json, 'quoted_total_minor'),
      currencyCode: _requireString(json, 'currency_code'),
    );
  }

  final String id;
  final String status;
  final String serviceName;
  final DateTime startAt;
  final DateTime endAt;
  final int quotedTotalMinor;
  final String currencyCode;
}

class AdminDisputeDetail {
  const AdminDisputeDetail({required this.dispute, this.booking});

  factory AdminDisputeDetail.fromJson(Map<String, dynamic> json) {
    final dispute = json['dispute'];
    if (dispute is! Map) {
      throw const FormatException('Admin dispute JSON is invalid.');
    }
    final booking = json['booking'];
    return AdminDisputeDetail(
      dispute: AdminDisputeBody.fromJson(Map<String, dynamic>.from(dispute)),
      booking: booking is Map
          ? AdminDisputeBookingSummary.fromJson(
              Map<String, dynamic>.from(booking),
            )
          : null,
    );
  }

  final AdminDisputeBody dispute;
  final AdminDisputeBookingSummary? booking;
}

class AdminDisputeBody extends AdminDisputeSummary {
  const AdminDisputeBody({
    required super.id,
    required super.bookingId,
    required super.category,
    required super.status,
    required super.subject,
    required super.customerUserId,
    required super.cleanerUserId,
    required super.customerDisplayName,
    required super.cleanerPublicName,
    required super.createdAt,
    required this.description,
    required this.history,
    required this.updatedAt,
    this.resolution,
    this.openedByUserId,
    this.openedByRole,
    this.resolvedBy,
    this.resolvedAt,
  });

  factory AdminDisputeBody.fromJson(Map<String, dynamic> json) {
    final history = json['history'];
    if (history is! List) {
      throw const FormatException('Dispute history JSON is invalid.');
    }
    return AdminDisputeBody(
      id: _requireString(json, 'id'),
      bookingId: _requireString(json, 'booking_id'),
      category: DisputeCategory.fromWire(_requireString(json, 'category')),
      status: DisputeStatus.fromWire(_requireString(json, 'status')),
      subject: _requireString(json, 'subject'),
      customerUserId: _requireString(json, 'customer_user_id'),
      cleanerUserId: _requireString(json, 'cleaner_user_id'),
      customerDisplayName: json['customer_display_name'] is String
          ? json['customer_display_name'] as String
          : 'Customer',
      cleanerPublicName: json['cleaner_public_name'] is String
          ? json['cleaner_public_name'] as String
          : 'Cleaner',
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      description: _requireString(json, 'description'),
      resolution: json['resolution'] is String
          ? json['resolution'] as String
          : null,
      history: [
        for (final item in history)
          if (item is Map)
            DisputeHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
      ],
      updatedAt: DateTime.parse(_requireString(json, 'updated_at')).toUtc(),
      openedByUserId: json['opened_by_user_id'] is String
          ? json['opened_by_user_id'] as String
          : null,
      openedByRole: json['opened_by_role'] is String
          ? json['opened_by_role'] as String
          : null,
      resolvedBy: json['resolved_by'] is String
          ? json['resolved_by'] as String
          : null,
      resolvedAt: _optionalDate(json, 'resolved_at'),
    );
  }

  final String description;
  final String? resolution;
  final List<DisputeHistoryEntry> history;
  final DateTime updatedAt;
  final String? openedByUserId;
  final String? openedByRole;
  final String? resolvedBy;
  final DateTime? resolvedAt;
}

class DisputePage<T> {
  const DisputePage({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Dispute JSON field $key is invalid.');
  }
  return value;
}

int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Dispute JSON field $key is invalid.');
  }
  return value;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('Dispute JSON field $key is invalid.');
  }
  return DateTime.parse(value).toUtc();
}

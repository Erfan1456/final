enum ReviewModerationStatus {
  published,
  hidden,
  unknown;

  static ReviewModerationStatus fromWire(String value) {
    switch (value) {
      case 'published':
        return ReviewModerationStatus.published;
      case 'hidden':
        return ReviewModerationStatus.hidden;
      default:
        return ReviewModerationStatus.unknown;
    }
  }

  String get wireValue {
    switch (this) {
      case ReviewModerationStatus.published:
        return 'published';
      case ReviewModerationStatus.hidden:
        return 'hidden';
      case ReviewModerationStatus.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case ReviewModerationStatus.published:
        return 'Published';
      case ReviewModerationStatus.hidden:
        return 'Hidden';
      case ReviewModerationStatus.unknown:
        return 'Unknown';
    }
  }
}

class CustomerReview {
  const CustomerReview({
    required this.id,
    required this.bookingId,
    required this.rating,
    required this.moderationStatus,
    required this.verifiedBooking,
    required this.createdAt,
    required this.updatedAt,
    this.comment,
  });

  factory CustomerReview.fromJson(Map<String, dynamic> json) {
    return CustomerReview(
      id: _requireString(json, 'id'),
      bookingId: _requireString(json, 'booking_id'),
      rating: _requireInt(json, 'rating'),
      comment: json['comment'] is String ? json['comment'] as String : null,
      moderationStatus: ReviewModerationStatus.fromWire(
        _requireString(json, 'moderation_status'),
      ),
      verifiedBooking: json['verified_booking'] == true,
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      updatedAt: DateTime.parse(_requireString(json, 'updated_at')).toUtc(),
    );
  }

  final String id;
  final String bookingId;
  final int rating;
  final String? comment;
  final ReviewModerationStatus moderationStatus;
  final bool verifiedBooking;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isHidden => moderationStatus == ReviewModerationStatus.hidden;
}

class CleanerReview {
  const CleanerReview({
    required this.id,
    required this.bookingId,
    required this.rating,
    required this.moderationStatus,
    required this.verifiedBooking,
    required this.reviewerDisplayName,
    required this.createdAt,
    required this.updatedAt,
    this.comment,
  });

  factory CleanerReview.fromJson(Map<String, dynamic> json) {
    return CleanerReview(
      id: _requireString(json, 'id'),
      bookingId: _requireString(json, 'booking_id'),
      rating: _requireInt(json, 'rating'),
      comment: json['comment'] is String ? json['comment'] as String : null,
      moderationStatus: ReviewModerationStatus.fromWire(
        _requireString(json, 'moderation_status'),
      ),
      verifiedBooking: json['verified_booking'] == true,
      reviewerDisplayName: json['reviewer_display_name'] is String
          ? json['reviewer_display_name'] as String
          : 'Verified customer',
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      updatedAt: DateTime.parse(_requireString(json, 'updated_at')).toUtc(),
    );
  }

  final String id;
  final String bookingId;
  final int rating;
  final String? comment;
  final ReviewModerationStatus moderationStatus;
  final bool verifiedBooking;
  final String reviewerDisplayName;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PublicCleanerReview {
  const PublicCleanerReview({
    required this.rating,
    required this.createdAt,
    required this.verifiedBooking,
    required this.reviewerDisplayName,
    this.comment,
  });

  factory PublicCleanerReview.fromJson(Map<String, dynamic> json) {
    return PublicCleanerReview(
      rating: _requireInt(json, 'rating'),
      comment: json['comment'] is String ? json['comment'] as String : null,
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      verifiedBooking: json['verified_booking'] == true,
      reviewerDisplayName: json['reviewer_display_name'] is String
          ? json['reviewer_display_name'] as String
          : 'Verified customer',
    );
  }

  final int rating;
  final String? comment;
  final DateTime createdAt;
  final bool verifiedBooking;
  final String reviewerDisplayName;
}

class AdminReviewSummary {
  const AdminReviewSummary({
    required this.id,
    required this.bookingId,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.rating,
    required this.moderationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.comment,
    this.hiddenReason,
    this.hiddenBy,
    this.hiddenAt,
  });

  factory AdminReviewSummary.fromJson(Map<String, dynamic> json) {
    return AdminReviewSummary(
      id: _requireString(json, 'id'),
      bookingId: _requireString(json, 'booking_id'),
      customerUserId: _requireString(json, 'customer_user_id'),
      cleanerUserId: _requireString(json, 'cleaner_user_id'),
      rating: _requireInt(json, 'rating'),
      comment: json['comment'] is String ? json['comment'] as String : null,
      moderationStatus: ReviewModerationStatus.fromWire(
        _requireString(json, 'moderation_status'),
      ),
      hiddenReason: json['hidden_reason'] is String
          ? json['hidden_reason'] as String
          : null,
      hiddenBy: json['hidden_by'] is String
          ? json['hidden_by'] as String
          : null,
      hiddenAt: _optionalDate(json, 'hidden_at'),
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      updatedAt: DateTime.parse(_requireString(json, 'updated_at')).toUtc(),
    );
  }

  final String id;
  final String bookingId;
  final String customerUserId;
  final String cleanerUserId;
  final int rating;
  final String? comment;
  final ReviewModerationStatus moderationStatus;
  final String? hiddenReason;
  final String? hiddenBy;
  final DateTime? hiddenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get shortId => id.length <= 8 ? id : id.substring(0, 8);
}

class AdminReviewDetail {
  const AdminReviewDetail({
    required this.id,
    required this.bookingId,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.rating,
    required this.moderationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.comment,
    this.hiddenReason,
    this.hiddenBy,
    this.hiddenAt,
  });

  factory AdminReviewDetail.fromJson(Map<String, dynamic> json) {
    return AdminReviewDetail(
      id: _requireString(json, 'id'),
      bookingId: _requireString(json, 'booking_id'),
      customerUserId: _requireString(json, 'customer_user_id'),
      cleanerUserId: _requireString(json, 'cleaner_user_id'),
      rating: _requireInt(json, 'rating'),
      comment: json['comment'] is String ? json['comment'] as String : null,
      moderationStatus: ReviewModerationStatus.fromWire(
        _requireString(json, 'moderation_status'),
      ),
      hiddenReason: json['hidden_reason'] is String
          ? json['hidden_reason'] as String
          : null,
      hiddenBy: json['hidden_by'] is String
          ? json['hidden_by'] as String
          : null,
      hiddenAt: _optionalDate(json, 'hidden_at'),
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      updatedAt: DateTime.parse(_requireString(json, 'updated_at')).toUtc(),
    );
  }

  final String id;
  final String bookingId;
  final String customerUserId;
  final String cleanerUserId;
  final int rating;
  final String? comment;
  final ReviewModerationStatus moderationStatus;
  final String? hiddenReason;
  final String? hiddenBy;
  final DateTime? hiddenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isHidden => moderationStatus == ReviewModerationStatus.hidden;

  String get shortId => id.length <= 8 ? id : id.substring(0, 8);
}

class ReviewPage<T> {
  const ReviewPage({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Review JSON field $key is invalid.');
  }
  return value;
}

int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Review JSON field $key is invalid.');
  }
  return value;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('Review JSON field $key is invalid.');
  }
  return DateTime.parse(value).toUtc();
}

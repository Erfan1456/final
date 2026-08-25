import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_models.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';

class AdminBookingPaymentSummary {
  const AdminBookingPaymentSummary({
    required this.id,
    required this.status,
    required this.amountMinor,
    required this.currencyCode,
    required this.refundedAmountMinor,
  });

  factory AdminBookingPaymentSummary.fromJson(Map<String, dynamic> json) {
    return AdminBookingPaymentSummary(
      id: _requireString(json, 'id'),
      status: PaymentStatus.fromWire(_requireString(json, 'status')),
      amountMinor: _requireInt(json, 'amount_minor'),
      currencyCode: _requireString(json, 'currency_code'),
      refundedAmountMinor: json['refunded_amount_minor'] is int
          ? json['refunded_amount_minor'] as int
          : 0,
    );
  }

  final String id;
  final PaymentStatus status;
  final int amountMinor;
  final String currencyCode;
  final int refundedAmountMinor;

  bool get mayRequireRefund =>
      status == PaymentStatus.paid || status == PaymentStatus.partiallyRefunded;
}

class AdminBookingDisputeSummary {
  const AdminBookingDisputeSummary({
    required this.id,
    required this.status,
    required this.category,
  });

  factory AdminBookingDisputeSummary.fromJson(Map<String, dynamic> json) {
    return AdminBookingDisputeSummary(
      id: _requireString(json, 'id'),
      status: DisputeStatus.fromWire(_requireString(json, 'status')),
      category: DisputeCategory.fromWire(_requireString(json, 'category')),
    );
  }

  final String id;
  final DisputeStatus status;
  final DisputeCategory category;
}

class AdminBookingSummary {
  const AdminBookingSummary({
    required this.id,
    required this.status,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.customerDisplayName,
    required this.cleanerPublicName,
    required this.serviceName,
    required this.startAt,
    required this.endAt,
    required this.quotedTotalMinor,
    required this.currencyCode,
    this.payment,
    this.dispute,
  });

  factory AdminBookingSummary.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'];
    final dispute = json['dispute'];
    return AdminBookingSummary(
      id: _requireString(json, 'id'),
      status: BookingStatus.fromWire(_requireString(json, 'status')),
      customerUserId: _requireString(json, 'customer_user_id'),
      cleanerUserId: _requireString(json, 'cleaner_user_id'),
      customerDisplayName: _requireString(json, 'customer_display_name'),
      cleanerPublicName: _requireString(json, 'cleaner_public_name'),
      serviceName: _requireString(json, 'service_name'),
      startAt: DateTime.parse(_requireString(json, 'start_at')).toUtc(),
      endAt: DateTime.parse(_requireString(json, 'end_at')).toUtc(),
      quotedTotalMinor: _requireInt(json, 'quoted_total_minor'),
      currencyCode: _requireString(json, 'currency_code'),
      payment: payment is Map
          ? AdminBookingPaymentSummary.fromJson(
              Map<String, dynamic>.from(payment),
            )
          : null,
      dispute: dispute is Map
          ? AdminBookingDisputeSummary.fromJson(
              Map<String, dynamic>.from(dispute),
            )
          : null,
    );
  }

  final String id;
  final BookingStatus status;
  final String customerUserId;
  final String cleanerUserId;
  final String customerDisplayName;
  final String cleanerPublicName;
  final String serviceName;
  final DateTime startAt;
  final DateTime endAt;
  final int quotedTotalMinor;
  final String currencyCode;
  final AdminBookingPaymentSummary? payment;
  final AdminBookingDisputeSummary? dispute;

  bool get canCancel =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;
}

class AdminBookingDetail {
  const AdminBookingDetail({
    required this.booking,
    required this.payments,
    this.dispute,
  });

  factory AdminBookingDetail.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'];
    final payments = json['payments'];
    final dispute = json['dispute'];
    if (booking is! Map || payments is! List) {
      throw const FormatException('Admin booking detail JSON is invalid.');
    }
    return AdminBookingDetail(
      booking: AdminBookingOperational.fromJson(
        Map<String, dynamic>.from(booking),
      ),
      payments: [
        for (final item in payments)
          if (item is Map)
            AdminBookingPaymentSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
      ],
      dispute: dispute is Map
          ? AdminBookingDisputeSummary.fromJson(
              Map<String, dynamic>.from(dispute),
            )
          : null,
    );
  }

  final AdminBookingOperational booking;
  final List<AdminBookingPaymentSummary> payments;
  final AdminBookingDisputeSummary? dispute;

  bool get canCancel => booking.canCancel;

  bool get paidCancelWarning => payments.any((row) => row.mayRequireRefund);
}

class AdminBookingOperational {
  const AdminBookingOperational({
    required this.id,
    required this.status,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.customerDisplayName,
    required this.cleanerPublicName,
    required this.serviceId,
    required this.durationMinutes,
    required this.hourlyRateMinor,
    required this.quotedTotalMinor,
    required this.currencyCode,
    required this.serviceSnapshot,
    required this.addressSnapshot,
    required this.startAt,
    required this.endAt,
    required this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
    this.customerNotes,
  });

  factory AdminBookingOperational.fromJson(Map<String, dynamic> json) {
    final history = json['status_history'];
    if (history is! List) {
      throw const FormatException('Admin booking history JSON is invalid.');
    }
    return AdminBookingOperational(
      id: _requireString(json, 'id'),
      status: BookingStatus.fromWire(_requireString(json, 'status')),
      customerUserId: _requireString(json, 'customer_user_id'),
      cleanerUserId: _requireString(json, 'cleaner_user_id'),
      customerDisplayName: _requireString(json, 'customer_display_name'),
      cleanerPublicName: _requireString(json, 'cleaner_public_name'),
      serviceId: _requireString(json, 'service_id'),
      durationMinutes: _requireInt(json, 'duration_minutes'),
      hourlyRateMinor: _requireInt(json, 'hourly_rate_minor'),
      quotedTotalMinor: _requireInt(json, 'quoted_total_minor'),
      currencyCode: _requireString(json, 'currency_code'),
      serviceSnapshot: BookingServiceSnapshot.fromJson(
        Map<String, dynamic>.from(json['service_snapshot'] as Map),
      ),
      addressSnapshot: BookingAddressSnapshot.fromJson(
        Map<String, dynamic>.from(json['address_snapshot'] as Map),
      ),
      customerNotes: json['customer_notes'] is String
          ? json['customer_notes'] as String
          : null,
      startAt: DateTime.parse(_requireString(json, 'start_at')).toUtc(),
      endAt: DateTime.parse(_requireString(json, 'end_at')).toUtc(),
      statusHistory: [
        for (final item in history)
          if (item is Map)
            BookingStatusHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
      ],
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      updatedAt: DateTime.parse(_requireString(json, 'updated_at')).toUtc(),
    );
  }

  final String id;
  final BookingStatus status;
  final String customerUserId;
  final String cleanerUserId;
  final String customerDisplayName;
  final String cleanerPublicName;
  final String serviceId;
  final int durationMinutes;
  final int hourlyRateMinor;
  final int quotedTotalMinor;
  final String currencyCode;
  final BookingServiceSnapshot serviceSnapshot;
  final BookingAddressSnapshot addressSnapshot;
  final String? customerNotes;
  final DateTime startAt;
  final DateTime endAt;
  final List<BookingStatusHistoryEntry> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get canCancel =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;
}

class AdminBookingPage {
  const AdminBookingPage({required this.items, this.nextCursor});

  final List<AdminBookingSummary> items;
  final String? nextCursor;
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Admin booking JSON field $key is invalid.');
  }
  return value;
}

int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Admin booking JSON field $key is invalid.');
  }
  return value;
}

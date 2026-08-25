enum PaymentStatus {
  pending,
  authorized,
  paid,
  failed,
  cancelled,
  partiallyRefunded,
  refunded,
  unknown;

  static PaymentStatus fromWire(String value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'authorized':
        return PaymentStatus.authorized;
      case 'paid':
        return PaymentStatus.paid;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'partially_refunded':
        return PaymentStatus.partiallyRefunded;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.unknown;
    }
  }

  String get wireValue {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.authorized:
        return 'authorized';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.cancelled:
        return 'cancelled';
      case PaymentStatus.partiallyRefunded:
        return 'partially_refunded';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.authorized:
        return 'Authorized';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.unknown:
        return 'Unknown';
    }
  }

  bool get isPendingAttempt =>
      this == PaymentStatus.pending || this == PaymentStatus.authorized;

  bool get canRetry =>
      this == PaymentStatus.failed || this == PaymentStatus.cancelled;

  bool get allowsRefund =>
      this == PaymentStatus.paid || this == PaymentStatus.partiallyRefunded;
}

enum PaymentProviderType {
  sandbox,
  unknown;

  static PaymentProviderType fromWire(String value) {
    switch (value) {
      case 'sandbox':
        return PaymentProviderType.sandbox;
      default:
        return PaymentProviderType.unknown;
    }
  }

  String get wireValue {
    switch (this) {
      case PaymentProviderType.sandbox:
        return 'sandbox';
      case PaymentProviderType.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case PaymentProviderType.sandbox:
        return 'Development Sandbox';
      case PaymentProviderType.unknown:
        return 'Unknown';
    }
  }
}

class SandboxPaymentSession {
  const SandboxPaymentSession({
    required this.paymentId,
    required this.simulationAvailable,
  });

  factory SandboxPaymentSession.fromJson(Map<String, dynamic> json) {
    final paymentId = json['payment_id'];
    final available = json['simulation_available'];
    if (paymentId is! String || available is! bool) {
      throw const FormatException('Sandbox session JSON is invalid.');
    }
    return SandboxPaymentSession(
      paymentId: paymentId,
      simulationAvailable: available,
    );
  }

  final String paymentId;
  final bool simulationAvailable;
}

class PaymentAttempt {
  const PaymentAttempt({
    required this.id,
    required this.bookingId,
    required this.provider,
    required this.status,
    required this.amountMinor,
    required this.currencyCode,
    required this.attemptNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.refundedAmountMinor,
    this.paidAt,
    this.failedAt,
    this.cancelledAt,
    this.refundedAt,
    this.sandboxSession,
  });

  factory PaymentAttempt.fromJson(Map<String, dynamic> json) {
    return PaymentAttempt(
      id: _requireString(json, 'id'),
      bookingId: _requireString(json, 'booking_id'),
      provider: PaymentProviderType.fromWire(_requireString(json, 'provider')),
      status: PaymentStatus.fromWire(_requireString(json, 'status')),
      amountMinor: _requireInt(json, 'amount_minor'),
      currencyCode: _requireString(json, 'currency_code'),
      attemptNumber: _requireInt(json, 'attempt_number'),
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      updatedAt: DateTime.parse(_requireString(json, 'updated_at')).toUtc(),
      paidAt: _optionalDate(json, 'paid_at'),
      failedAt: _optionalDate(json, 'failed_at'),
      cancelledAt: _optionalDate(json, 'cancelled_at'),
      refundedAt: _optionalDate(json, 'refunded_at'),
      refundedAmountMinor: _requireInt(json, 'refunded_amount_minor'),
      sandboxSession: _optionalSandbox(json['sandbox_session']),
    );
  }

  final String id;
  final String bookingId;
  final PaymentProviderType provider;
  final PaymentStatus status;
  final int amountMinor;
  final String currencyCode;
  final int attemptNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;
  final int refundedAmountMinor;
  final SandboxPaymentSession? sandboxSession;

  bool get simulationAvailable => sandboxSession?.simulationAvailable == true;
}

typedef PaymentSummary = PaymentAttempt;

class PaymentHistory {
  const PaymentHistory({
    this.current,
    this.attempts = const <PaymentAttempt>[],
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    final currentRaw = json['current'];
    final attemptsRaw = json['attempts'];
    if (attemptsRaw is! List) {
      throw const FormatException('Payment history JSON is invalid.');
    }
    return PaymentHistory(
      current: currentRaw is Map
          ? PaymentAttempt.fromJson(Map<String, dynamic>.from(currentRaw))
          : null,
      attempts: [
        for (final item in attemptsRaw)
          if (item is Map)
            PaymentAttempt.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }

  final PaymentAttempt? current;
  final List<PaymentAttempt> attempts;
}

class PaymentWebhookEventSummary {
  const PaymentWebhookEventSummary({
    required this.providerEventId,
    required this.eventType,
    required this.processingStatus,
    required this.createdAt,
    this.processedAt,
  });

  factory PaymentWebhookEventSummary.fromJson(Map<String, dynamic> json) {
    return PaymentWebhookEventSummary(
      providerEventId: _requireString(json, 'provider_event_id'),
      eventType: _requireString(json, 'event_type'),
      processingStatus: _requireString(json, 'processing_status'),
      processedAt: _optionalDate(json, 'processed_at'),
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
    );
  }

  final String providerEventId;
  final String eventType;
  final String processingStatus;
  final DateTime? processedAt;
  final DateTime createdAt;
}

class AdminPaymentSummary {
  const AdminPaymentSummary({
    required this.id,
    required this.bookingId,
    required this.provider,
    required this.status,
    required this.amountMinor,
    required this.currencyCode,
    required this.attemptNumber,
    required this.createdAt,
    required this.refundedAmountMinor,
    this.customerUserId,
    this.cleanerUserId,
  });

  factory AdminPaymentSummary.fromJson(Map<String, dynamic> json) {
    return AdminPaymentSummary(
      id: _requireString(json, 'id'),
      bookingId: _requireString(json, 'booking_id'),
      provider: PaymentProviderType.fromWire(_requireString(json, 'provider')),
      status: PaymentStatus.fromWire(_requireString(json, 'status')),
      amountMinor: _requireInt(json, 'amount_minor'),
      currencyCode: _requireString(json, 'currency_code'),
      attemptNumber: _requireInt(json, 'attempt_number'),
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      refundedAmountMinor: _requireInt(json, 'refunded_amount_minor'),
      customerUserId: json['customer_user_id'] is String
          ? json['customer_user_id'] as String
          : null,
      cleanerUserId: json['cleaner_user_id'] is String
          ? json['cleaner_user_id'] as String
          : null,
    );
  }

  final String id;
  final String bookingId;
  final PaymentProviderType provider;
  final PaymentStatus status;
  final int amountMinor;
  final String currencyCode;
  final int attemptNumber;
  final DateTime createdAt;
  final int refundedAmountMinor;
  final String? customerUserId;
  final String? cleanerUserId;

  String get shortId => id.length <= 8 ? id : id.substring(0, 8);
}

class AdminPaymentDetail {
  const AdminPaymentDetail({
    required this.id,
    required this.bookingId,
    required this.provider,
    required this.status,
    required this.amountMinor,
    required this.currencyCode,
    required this.attemptNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.refundedAmountMinor,
    required this.events,
    this.customerUserId,
    this.cleanerUserId,
    this.providerPaymentId,
    this.providerReference,
    this.failureCode,
    this.failureMessage,
    this.paidAt,
    this.failedAt,
    this.cancelledAt,
    this.refundedAt,
    this.authorizedAt,
    this.bookingStatus,
    this.serviceSnapshotName,
  });

  factory AdminPaymentDetail.fromJson(Map<String, dynamic> json) {
    final paymentRaw = json['payment'] is Map ? json['payment'] : json;
    final payment = Map<String, dynamic>.from(paymentRaw as Map);
    final eventsRaw = json['events'];
    return AdminPaymentDetail(
      id: _requireString(payment, 'id'),
      bookingId: _requireString(payment, 'booking_id'),
      provider: PaymentProviderType.fromWire(
        _requireString(payment, 'provider'),
      ),
      status: PaymentStatus.fromWire(_requireString(payment, 'status')),
      amountMinor: _requireInt(payment, 'amount_minor'),
      currencyCode: _requireString(payment, 'currency_code'),
      attemptNumber: _requireInt(payment, 'attempt_number'),
      createdAt: DateTime.parse(_requireString(payment, 'created_at')).toUtc(),
      updatedAt: DateTime.parse(_requireString(payment, 'updated_at')).toUtc(),
      paidAt: _optionalDate(payment, 'paid_at'),
      failedAt: _optionalDate(payment, 'failed_at'),
      cancelledAt: _optionalDate(payment, 'cancelled_at'),
      refundedAt: _optionalDate(payment, 'refunded_at'),
      authorizedAt: _optionalDate(payment, 'authorized_at'),
      refundedAmountMinor: _requireInt(payment, 'refunded_amount_minor'),
      customerUserId: payment['customer_user_id'] is String
          ? payment['customer_user_id'] as String
          : null,
      cleanerUserId: payment['cleaner_user_id'] is String
          ? payment['cleaner_user_id'] as String
          : null,
      providerPaymentId: payment['provider_payment_id'] is String
          ? payment['provider_payment_id'] as String
          : null,
      providerReference: payment['provider_reference'] is String
          ? payment['provider_reference'] as String
          : null,
      failureCode: payment['failure_code'] is String
          ? payment['failure_code'] as String
          : null,
      failureMessage: payment['failure_message'] is String
          ? payment['failure_message'] as String
          : null,
      bookingStatus: payment['booking_status'] is String
          ? payment['booking_status'] as String
          : null,
      serviceSnapshotName: payment['service_snapshot_name'] is String
          ? payment['service_snapshot_name'] as String
          : null,
      events: [
        if (eventsRaw is List)
          for (final item in eventsRaw)
            if (item is Map)
              PaymentWebhookEventSummary.fromJson(
                Map<String, dynamic>.from(item),
              ),
      ],
    );
  }

  final String id;
  final String bookingId;
  final PaymentProviderType provider;
  final PaymentStatus status;
  final int amountMinor;
  final String currencyCode;
  final int attemptNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;
  final DateTime? authorizedAt;
  final int refundedAmountMinor;
  final String? customerUserId;
  final String? cleanerUserId;
  final String? providerPaymentId;
  final String? providerReference;
  final String? failureCode;
  final String? failureMessage;
  final String? bookingStatus;
  final String? serviceSnapshotName;
  final List<PaymentWebhookEventSummary> events;

  bool get allowsRefund => status.allowsRefund;

  String get shortId => id.length <= 8 ? id : id.substring(0, 8);
}

class AdminPaymentPage {
  const AdminPaymentPage({required this.items, this.nextCursor});

  factory AdminPaymentPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final next = json['next_cursor'];
    if (items is! List) {
      throw const FormatException('Admin payment page JSON is invalid.');
    }
    return AdminPaymentPage(
      items: [
        for (final item in items)
          if (item is Map)
            AdminPaymentSummary.fromJson(Map<String, dynamic>.from(item)),
      ],
      nextCursor: next is String ? next : null,
    );
  }

  final List<AdminPaymentSummary> items;
  final String? nextCursor;
}

String formatPaymentAmount(int amountMinor, String currencyCode) {
  return '$currencyCode $amountMinor minor units';
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Payment JSON field $key is invalid.');
  }
  return value;
}

int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Payment JSON field $key is invalid.');
  }
  return value;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('Payment JSON field $key is invalid.');
  }
  return DateTime.parse(value).toUtc();
}

SandboxPaymentSession? _optionalSandbox(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is! Map) {
    throw const FormatException('Sandbox session JSON is invalid.');
  }
  return SandboxPaymentSession.fromJson(Map<String, dynamic>.from(raw));
}

import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';

enum EarningsEntryType {
  serviceEarning,
  refundAdjustment,
  unknown;

  static EarningsEntryType fromWire(String value) {
    switch (value) {
      case 'service_earning':
        return EarningsEntryType.serviceEarning;
      case 'refund_adjustment':
        return EarningsEntryType.refundAdjustment;
      default:
        return EarningsEntryType.unknown;
    }
  }

  String get wireValue {
    switch (this) {
      case EarningsEntryType.serviceEarning:
        return 'service_earning';
      case EarningsEntryType.refundAdjustment:
        return 'refund_adjustment';
      case EarningsEntryType.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case EarningsEntryType.serviceEarning:
        return 'Service earning';
      case EarningsEntryType.refundAdjustment:
        return 'Refund adjustment';
      case EarningsEntryType.unknown:
        return 'Unknown';
    }
  }
}

enum PayoutStatus {
  requested,
  processing,
  paid,
  failed,
  cancelled,
  rejected,
  unknown;

  static PayoutStatus fromWire(String value) {
    switch (value) {
      case 'requested':
        return PayoutStatus.requested;
      case 'processing':
        return PayoutStatus.processing;
      case 'paid':
        return PayoutStatus.paid;
      case 'failed':
        return PayoutStatus.failed;
      case 'cancelled':
        return PayoutStatus.cancelled;
      case 'rejected':
        return PayoutStatus.rejected;
      default:
        return PayoutStatus.unknown;
    }
  }

  String get wireValue {
    switch (this) {
      case PayoutStatus.requested:
        return 'requested';
      case PayoutStatus.processing:
        return 'processing';
      case PayoutStatus.paid:
        return 'paid';
      case PayoutStatus.failed:
        return 'failed';
      case PayoutStatus.cancelled:
        return 'cancelled';
      case PayoutStatus.rejected:
        return 'rejected';
      case PayoutStatus.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case PayoutStatus.requested:
        return 'Requested';
      case PayoutStatus.processing:
        return 'Processing';
      case PayoutStatus.paid:
        return 'Paid';
      case PayoutStatus.failed:
        return 'Failed';
      case PayoutStatus.cancelled:
        return 'Cancelled';
      case PayoutStatus.rejected:
        return 'Rejected';
      case PayoutStatus.unknown:
        return 'Unknown';
    }
  }

  bool get canCancel => this == PayoutStatus.requested;
}

class CleanerCurrencyEarningsSummary {
  const CleanerCurrencyEarningsSummary({
    required this.currencyCode,
    required this.grossEarnedMinor,
    required this.platformFeesMinor,
    required this.refundsGrossMinor,
    required this.cleanerRefundAdjustmentsMinor,
    required this.netLedgerMinor,
    required this.reservedPayoutMinor,
    required this.paidOutMinor,
    required this.availableBalanceMinor,
  });

  factory CleanerCurrencyEarningsSummary.fromJson(Map<String, dynamic> json) {
    return CleanerCurrencyEarningsSummary(
      currencyCode: _requireString(json, 'currency_code'),
      grossEarnedMinor: _requireInt(json, 'gross_earned_minor'),
      platformFeesMinor: _requireInt(json, 'platform_fees_minor'),
      refundsGrossMinor: _requireInt(json, 'refunds_gross_minor'),
      cleanerRefundAdjustmentsMinor: _requireInt(
        json,
        'cleaner_refund_adjustments_minor',
      ),
      netLedgerMinor: _requireInt(json, 'net_ledger_minor'),
      reservedPayoutMinor: _requireInt(json, 'reserved_payout_minor'),
      paidOutMinor: _requireInt(json, 'paid_out_minor'),
      availableBalanceMinor: _requireInt(json, 'available_balance_minor'),
    );
  }

  final String currencyCode;
  final int grossEarnedMinor;
  final int platformFeesMinor;
  final int refundsGrossMinor;
  final int cleanerRefundAdjustmentsMinor;
  final int netLedgerMinor;
  final int reservedPayoutMinor;
  final int paidOutMinor;
  final int availableBalanceMinor;

  String format(int amountMinor) =>
      formatPaymentAmount(amountMinor, currencyCode);
}

class EarningsSummary {
  const EarningsSummary({required this.currencies});

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    final items = json['currencies'];
    if (items is! List) {
      throw const FormatException('Earnings summary JSON is invalid.');
    }
    return EarningsSummary(
      currencies: [
        for (final item in items)
          if (item is Map)
            CleanerCurrencyEarningsSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
      ],
    );
  }

  final List<CleanerCurrencyEarningsSummary> currencies;
}

class EarningsLedgerEntry {
  const EarningsLedgerEntry({
    required this.id,
    required this.bookingId,
    required this.paymentId,
    required this.entryType,
    required this.grossAmountMinor,
    required this.commissionBps,
    required this.platformFeeMinor,
    required this.cleanerAmountMinor,
    required this.currencyCode,
    required this.createdAt,
  });

  factory EarningsLedgerEntry.fromJson(Map<String, dynamic> json) {
    return EarningsLedgerEntry(
      id: _requireString(json, 'id'),
      bookingId: _requireString(json, 'booking_id'),
      paymentId: _requireString(json, 'payment_id'),
      entryType: EarningsEntryType.fromWire(_requireString(json, 'entry_type')),
      grossAmountMinor: _requireInt(json, 'gross_amount_minor'),
      commissionBps: _requireInt(json, 'commission_bps'),
      platformFeeMinor: _requireInt(json, 'platform_fee_minor'),
      cleanerAmountMinor: _requireInt(json, 'cleaner_amount_minor'),
      currencyCode: _requireString(json, 'currency_code'),
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
    );
  }

  final String id;
  final String bookingId;
  final String paymentId;
  final EarningsEntryType entryType;
  final int grossAmountMinor;
  final int commissionBps;
  final int platformFeeMinor;
  final int cleanerAmountMinor;
  final String currencyCode;
  final DateTime createdAt;

  bool get isNegativeAdjustment =>
      entryType == EarningsEntryType.refundAdjustment || cleanerAmountMinor < 0;
}

class EarningsLedgerPage {
  const EarningsLedgerPage({required this.items, this.nextCursor});

  factory EarningsLedgerPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final next = json['next_cursor'];
    if (items is! List) {
      throw const FormatException('Earnings ledger JSON is invalid.');
    }
    return EarningsLedgerPage(
      items: [
        for (final item in items)
          if (item is Map)
            EarningsLedgerEntry.fromJson(Map<String, dynamic>.from(item)),
      ],
      nextCursor: next is String ? next : null,
    );
  }

  final List<EarningsLedgerEntry> items;
  final String? nextCursor;
}

class CleanerPayout {
  const CleanerPayout({
    required this.id,
    required this.amountMinor,
    required this.currencyCode,
    required this.status,
    required this.attemptNumber,
    required this.requestedAt,
    this.processingAt,
    this.paidAt,
    this.failedAt,
    this.cancelledAt,
    this.rejectedAt,
    this.failureCode,
    this.failureMessage,
    this.rejectionReason,
    this.cleanerUserId,
    this.cleanerDisplayName,
    this.provider,
    this.providerPayoutId,
    this.simulationAvailable = false,
  });

  factory CleanerPayout.fromJson(Map<String, dynamic> json) {
    return CleanerPayout(
      id: _requireString(json, 'id'),
      amountMinor: _requireInt(json, 'amount_minor'),
      currencyCode: _requireString(json, 'currency_code'),
      status: PayoutStatus.fromWire(_requireString(json, 'status')),
      attemptNumber: _requireInt(json, 'attempt_number'),
      requestedAt: DateTime.parse(_requireString(json, 'requested_at')).toUtc(),
      processingAt: _optionalDate(json, 'processing_at'),
      paidAt: _optionalDate(json, 'paid_at'),
      failedAt: _optionalDate(json, 'failed_at'),
      cancelledAt: _optionalDate(json, 'cancelled_at'),
      rejectedAt: _optionalDate(json, 'rejected_at'),
      failureCode: json['failure_code'] is String
          ? json['failure_code'] as String
          : null,
      failureMessage: json['failure_message'] is String
          ? json['failure_message'] as String
          : null,
      rejectionReason: json['rejection_reason'] is String
          ? json['rejection_reason'] as String
          : null,
      cleanerUserId: json['cleaner_user_id'] is String
          ? json['cleaner_user_id'] as String
          : null,
      cleanerDisplayName: json['cleaner_display_name'] is String
          ? json['cleaner_display_name'] as String
          : null,
      provider: json['provider'] is String ? json['provider'] as String : null,
      providerPayoutId: json['provider_payout_id'] is String
          ? json['provider_payout_id'] as String
          : null,
      simulationAvailable: json['simulation_available'] == true,
    );
  }

  final String id;
  final int amountMinor;
  final String currencyCode;
  final PayoutStatus status;
  final int attemptNumber;
  final DateTime requestedAt;
  final DateTime? processingAt;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? cancelledAt;
  final DateTime? rejectedAt;
  final String? failureCode;
  final String? failureMessage;
  final String? rejectionReason;
  final String? cleanerUserId;
  final String? cleanerDisplayName;
  final String? provider;
  final String? providerPayoutId;
  final bool simulationAvailable;

  String get shortId => id.length <= 8 ? id : id.substring(0, 8);
}

class CleanerPayoutPage {
  const CleanerPayoutPage({required this.items, this.nextCursor});

  factory CleanerPayoutPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final next = json['next_cursor'];
    if (items is! List) {
      throw const FormatException('Payout list JSON is invalid.');
    }
    return CleanerPayoutPage(
      items: [
        for (final item in items)
          if (item is Map)
            CleanerPayout.fromJson(Map<String, dynamic>.from(item)),
      ],
      nextCursor: next is String ? next : null,
    );
  }

  final List<CleanerPayout> items;
  final String? nextCursor;
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Earnings JSON field $key is invalid.');
  }
  return value;
}

int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Earnings JSON field $key is invalid.');
  }
  return value;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('Earnings JSON field $key is invalid.');
  }
  return DateTime.parse(value).toUtc();
}

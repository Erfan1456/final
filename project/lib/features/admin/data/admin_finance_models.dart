import 'package:home_cleaning_marketplace/features/earnings/data/earnings_models.dart';

class PayoutProviderEventSummary {
  const PayoutProviderEventSummary({
    required this.providerEventId,
    required this.eventType,
    required this.processingStatus,
    required this.createdAt,
    this.processedAt,
  });

  factory PayoutProviderEventSummary.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    if (json['provider_event_id'] is! String ||
        json['event_type'] is! String ||
        json['processing_status'] is! String ||
        created is! String) {
      throw const FormatException('Payout event JSON is invalid.');
    }
    final processed = json['processed_at'];
    return PayoutProviderEventSummary(
      providerEventId: json['provider_event_id'] as String,
      eventType: json['event_type'] as String,
      processingStatus: json['processing_status'] as String,
      createdAt: DateTime.parse(created).toUtc(),
      processedAt: processed is String
          ? DateTime.parse(processed).toUtc()
          : null,
    );
  }

  final String providerEventId;
  final String eventType;
  final String processingStatus;
  final DateTime createdAt;
  final DateTime? processedAt;
}

class AdminPayoutDetail {
  const AdminPayoutDetail({
    required this.payout,
    required this.earningsSummary,
    required this.providerEvents,
  });

  factory AdminPayoutDetail.fromJson(Map<String, dynamic> json) {
    final payout = json['payout'];
    final summary = json['earnings_summary'];
    final events = json['provider_events'];
    if (payout is! Map || summary is! Map || events is! List) {
      throw const FormatException('Admin payout detail JSON is invalid.');
    }
    return AdminPayoutDetail(
      payout: CleanerPayout.fromJson(Map<String, dynamic>.from(payout)),
      earningsSummary: CleanerCurrencyEarningsSummary.fromJson(
        Map<String, dynamic>.from(summary),
      ),
      providerEvents: [
        for (final item in events)
          if (item is Map)
            PayoutProviderEventSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
      ],
    );
  }

  final CleanerPayout payout;
  final CleanerCurrencyEarningsSummary earningsSummary;
  final List<PayoutProviderEventSummary> providerEvents;
}

class AdminFinanceCurrencySummary {
  const AdminFinanceCurrencySummary({
    required this.currencyCode,
    required this.grossServiceVolumeMinor,
    required this.platformFeeMinor,
    required this.cleanerNetEarningsMinor,
    required this.refundGrossMinor,
    required this.cleanerRefundAdjustmentsMinor,
    required this.payoutRequestedMinor,
    required this.payoutProcessingMinor,
    required this.payoutPaidMinor,
    required this.payoutFailedMinor,
  });

  factory AdminFinanceCurrencySummary.fromJson(Map<String, dynamic> json) {
    int requireInt(String key) {
      final value = json[key];
      if (value is! int) {
        throw FormatException('Finance JSON field $key is invalid.');
      }
      return value;
    }

    final currency = json['currency_code'];
    if (currency is! String) {
      throw const FormatException('Finance JSON is invalid.');
    }
    return AdminFinanceCurrencySummary(
      currencyCode: currency,
      grossServiceVolumeMinor: requireInt('gross_service_volume_minor'),
      platformFeeMinor: requireInt('platform_fee_minor'),
      cleanerNetEarningsMinor: requireInt('cleaner_net_earnings_minor'),
      refundGrossMinor: requireInt('refund_gross_minor'),
      cleanerRefundAdjustmentsMinor: requireInt(
        'cleaner_refund_adjustments_minor',
      ),
      payoutRequestedMinor: requireInt('payout_requested_minor'),
      payoutProcessingMinor: requireInt('payout_processing_minor'),
      payoutPaidMinor: requireInt('payout_paid_minor'),
      payoutFailedMinor: requireInt('payout_failed_minor'),
    );
  }

  final String currencyCode;
  final int grossServiceVolumeMinor;
  final int platformFeeMinor;
  final int cleanerNetEarningsMinor;
  final int refundGrossMinor;
  final int cleanerRefundAdjustmentsMinor;
  final int payoutRequestedMinor;
  final int payoutProcessingMinor;
  final int payoutPaidMinor;
  final int payoutFailedMinor;
}

class AdminFinanceSummary {
  const AdminFinanceSummary({
    required this.from,
    required this.to,
    required this.currencies,
  });

  factory AdminFinanceSummary.fromJson(Map<String, dynamic> json) {
    final from = json['from'];
    final to = json['to'];
    final currencies = json['currencies'];
    if (from is! String || to is! String || currencies is! List) {
      throw const FormatException('Finance summary JSON is invalid.');
    }
    return AdminFinanceSummary(
      from: DateTime.parse(from).toUtc(),
      to: DateTime.parse(to).toUtc(),
      currencies: [
        for (final item in currencies)
          if (item is Map)
            AdminFinanceCurrencySummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
      ],
    );
  }

  final DateTime from;
  final DateTime to;
  final List<AdminFinanceCurrencySummary> currencies;
}

class FinanceReconciliationIssue {
  const FinanceReconciliationIssue({
    required this.issueType,
    required this.bookingId,
    required this.paymentId,
    required this.currencyCode,
    required this.explanation,
  });

  factory FinanceReconciliationIssue.fromJson(Map<String, dynamic> json) {
    final issueType = json['issue_type'];
    final bookingId = json['booking_id'];
    final paymentId = json['payment_id'];
    final currency = json['currency_code'];
    final explanation = json['explanation'];
    if (issueType is! String ||
        bookingId is! String ||
        paymentId is! String ||
        currency is! String ||
        explanation is! String) {
      throw const FormatException('Reconciliation JSON is invalid.');
    }
    return FinanceReconciliationIssue(
      issueType: issueType,
      bookingId: bookingId,
      paymentId: paymentId,
      currencyCode: currency,
      explanation: explanation,
    );
  }

  final String issueType;
  final String bookingId;
  final String paymentId;
  final String currencyCode;
  final String explanation;

  String get label {
    switch (issueType) {
      case 'missing_service_earning':
        return 'Missing service earning';
      case 'refund_adjustment_mismatch':
        return 'Refund adjustment mismatch';
      default:
        return issueType;
    }
  }
}

class FinanceReconciliationPage {
  const FinanceReconciliationPage({required this.items, this.nextCursor});

  factory FinanceReconciliationPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final next = json['next_cursor'];
    if (items is! List) {
      throw const FormatException('Reconciliation page JSON is invalid.');
    }
    return FinanceReconciliationPage(
      items: [
        for (final item in items)
          if (item is Map)
            FinanceReconciliationIssue.fromJson(
              Map<String, dynamic>.from(item),
            ),
      ],
      nextCursor: next is String ? next : null,
    );
  }

  final List<FinanceReconciliationIssue> items;
  final String? nextCursor;
}

class AdminCleanerFinanceDetail {
  const AdminCleanerFinanceDetail({
    required this.cleanerUserId,
    required this.cleanerDisplayName,
    required this.currencies,
    required this.recentLedger,
    required this.recentPayouts,
  });

  factory AdminCleanerFinanceDetail.fromJson(Map<String, dynamic> json) {
    final userId = json['cleaner_user_id'];
    final name = json['cleaner_display_name'];
    final currencies = json['currencies'];
    final ledger = json['recent_ledger'];
    final payouts = json['recent_payouts'];
    if (userId is! String ||
        name is! String ||
        currencies is! List ||
        ledger is! List ||
        payouts is! List) {
      throw const FormatException('Cleaner finance JSON is invalid.');
    }
    return AdminCleanerFinanceDetail(
      cleanerUserId: userId,
      cleanerDisplayName: name,
      currencies: [
        for (final item in currencies)
          if (item is Map)
            CleanerCurrencyEarningsSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
      ],
      recentLedger: [
        for (final item in ledger)
          if (item is Map)
            EarningsLedgerEntry.fromJson(Map<String, dynamic>.from(item)),
      ],
      recentPayouts: [
        for (final item in payouts)
          if (item is Map)
            CleanerPayout.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }

  final String cleanerUserId;
  final String cleanerDisplayName;
  final List<CleanerCurrencyEarningsSummary> currencies;
  final List<EarningsLedgerEntry> recentLedger;
  final List<CleanerPayout> recentPayouts;
}

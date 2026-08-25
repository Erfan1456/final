/// Per-currency earnings totals. Never mixed with another currency.
class CleanerCurrencyEarningsSummary {
  /// Creates a per-currency summary. Negative [availableBalanceMinor] is kept.
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

  /// ISO 4217 currency code.
  final String currencyCode;

  /// Sum of original service-earning gross amounts.
  final int grossEarnedMinor;

  /// Sum of original service-earning platform fees.
  final int platformFeesMinor;

  /// Absolute sum of refund-adjustment gross amounts.
  final int refundsGrossMinor;

  /// Sum of refund-adjustment cleaner amounts (negative or zero).
  final int cleanerRefundAdjustmentsMinor;

  /// Sum of all `cleaner_amount_minor` ledger rows.
  final int netLedgerMinor;

  /// Sum of payout amounts in `requested` or `processing`.
  final int reservedPayoutMinor;

  /// Sum of payout amounts in `paid`.
  final int paidOutMinor;

  /// [netLedgerMinor] minus reserved and paid-out amounts. May be negative.
  final int availableBalanceMinor;

  /// Safe JSON object for one currency.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'currency_code': currencyCode,
      'gross_earned_minor': grossEarnedMinor,
      'platform_fees_minor': platformFeesMinor,
      'refunds_gross_minor': refundsGrossMinor,
      'cleaner_refund_adjustments_minor': cleanerRefundAdjustmentsMinor,
      'net_ledger_minor': netLedgerMinor,
      'reserved_payout_minor': reservedPayoutMinor,
      'paid_out_minor': paidOutMinor,
      'available_balance_minor': availableBalanceMinor,
    };
  }
}

/// Mutable accumulator used while folding ledger and payout totals.
class CurrencySummaryAccumulator {
  /// Creates a zeroed accumulator for [currencyCode].
  CurrencySummaryAccumulator(this.currencyCode);

  /// Currency being accumulated.
  final String currencyCode;

  /// Original service-earning gross.
  int grossEarnedMinor = 0;

  /// Original service-earning platform fees.
  int platformFeesMinor = 0;

  /// Absolute refund-adjustment gross.
  int refundsGrossMinor = 0;

  /// Refund-adjustment cleaner amounts (negative).
  int cleanerRefundAdjustmentsMinor = 0;

  /// Sum of cleaner amounts.
  int netLedgerMinor = 0;

  /// Active payout reservation.
  int reservedPayoutMinor = 0;

  /// Successfully paid payouts.
  int paidOutMinor = 0;

  /// Builds an immutable summary. Does not clamp negative available balance.
  CleanerCurrencyEarningsSummary toSummary() {
    return CleanerCurrencyEarningsSummary(
      currencyCode: currencyCode,
      grossEarnedMinor: grossEarnedMinor,
      platformFeesMinor: platformFeesMinor,
      refundsGrossMinor: refundsGrossMinor,
      cleanerRefundAdjustmentsMinor: cleanerRefundAdjustmentsMinor,
      netLedgerMinor: netLedgerMinor,
      reservedPayoutMinor: reservedPayoutMinor,
      paidOutMinor: paidOutMinor,
      availableBalanceMinor:
          netLedgerMinor - reservedPayoutMinor - paidOutMinor,
    );
  }
}

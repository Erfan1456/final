/// Honest minor-unit money presentation.
///
/// Does **not** divide by 100. Currency decimal metadata is not modeled.
String formatMinorUnits(int amountMinor, String currencyCode) {
  final code = currencyCode.trim().isEmpty ? 'XXX' : currencyCode.trim();
  return '$code $amountMinor minor units';
}

/// Alias matching existing payment helper naming.
String formatPaymentAmount(int amountMinor, String currencyCode) =>
    formatMinorUnits(amountMinor, currencyCode);

/// Quoted booking total label.
String formatQuotedTotal(int quotedTotalMinor, String currencyCode) {
  return 'Quoted total: ${formatMinorUnits(quotedTotalMinor, currencyCode)}';
}

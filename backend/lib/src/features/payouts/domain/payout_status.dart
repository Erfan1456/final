/// Payout-request lifecycle. Wire/database values are lowercase.
enum PayoutStatus {
  /// Cleaner requested a payout. Reserves available balance.
  requested,

  /// Administrator started provider processing. Still reserved.
  processing,

  /// Provider reported success. Terminal.
  paid,

  /// Provider reported failure. Terminal; releases reservation.
  failed,

  /// Cleaner cancelled a requested payout. Terminal.
  cancelled,

  /// Administrator rejected a requested payout. Terminal.
  rejected;

  /// Stable database/wire representation. Never persist [index].
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
    }
  }

  /// Whether this request occupies the one-active-payout slot.
  bool get payoutActive {
    switch (this) {
      case PayoutStatus.requested:
      case PayoutStatus.processing:
        return true;
      case PayoutStatus.paid:
      case PayoutStatus.failed:
      case PayoutStatus.cancelled:
      case PayoutStatus.rejected:
        return false;
    }
  }

  /// Whether the status is terminal and cannot be reopened.
  bool get isTerminal {
    switch (this) {
      case PayoutStatus.paid:
      case PayoutStatus.failed:
      case PayoutStatus.cancelled:
      case PayoutStatus.rejected:
        return true;
      case PayoutStatus.requested:
      case PayoutStatus.processing:
        return false;
    }
  }

  /// Parses a stored status string. Unknown values fail.
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
        throw const FormatException('Unknown PayoutStatus.');
    }
  }
}

/// Payment-attempt lifecycle status. Wire/database values are lowercase.
enum PaymentStatus {
  /// Provider session created; awaiting asynchronous completion.
  pending,

  /// Provider authorized funds that are not yet captured.
  authorized,

  /// Provider reported a successful capture/settlement.
  paid,

  /// Provider reported a failed attempt. Terminal for this attempt.
  failed,

  /// Customer cancelled a pending attempt. Terminal for this attempt.
  cancelled,

  /// A successful payment with a remaining refundable balance.
  partiallyRefunded,

  /// A successful payment fully refunded. Terminal.
  refunded;

  /// Stable database/wire representation. Never persist [index].
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
    }
  }

  /// Whether this attempt currently occupies the active-payment slot.
  bool get paymentActive {
    switch (this) {
      case PaymentStatus.pending:
      case PaymentStatus.authorized:
        return true;
      case PaymentStatus.paid:
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
      case PaymentStatus.partiallyRefunded:
      case PaymentStatus.refunded:
        return false;
    }
  }

  /// Whether this attempt records a successful settlement for the booking.
  bool get settlementRecorded {
    switch (this) {
      case PaymentStatus.paid:
      case PaymentStatus.partiallyRefunded:
      case PaymentStatus.refunded:
        return true;
      case PaymentStatus.pending:
      case PaymentStatus.authorized:
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
        return false;
    }
  }

  /// Whether a new charge attempt is blocked by this status.
  bool get blocksNewCharge {
    switch (this) {
      case PaymentStatus.pending:
      case PaymentStatus.authorized:
      case PaymentStatus.paid:
      case PaymentStatus.partiallyRefunded:
      case PaymentStatus.refunded:
        return true;
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
        return false;
    }
  }

  /// Whether an admin or cancellation refund may be issued.
  bool get allowsRefund {
    switch (this) {
      case PaymentStatus.paid:
      case PaymentStatus.partiallyRefunded:
        return true;
      case PaymentStatus.pending:
      case PaymentStatus.authorized:
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
      case PaymentStatus.refunded:
        return false;
    }
  }

  /// Parses a stored status string. Unknown values fail.
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
        throw const FormatException('Unknown PaymentStatus.');
    }
  }
}

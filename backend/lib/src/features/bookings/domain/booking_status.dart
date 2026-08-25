/// Booking lifecycle status. Wire/database values are lowercase strings.
enum BookingStatus {
  /// Customer created the booking; awaiting cleaner accept/decline.
  pending,

  /// Cleaner accepted; reservation remains active.
  confirmed,

  /// Cleaner started the job inside the booked window.
  inProgress,

  /// Cleaner completed the job. Terminal.
  completed,

  /// Cleaner declined a pending booking. Terminal.
  declined,

  /// Customer or cleaner cancelled before start. Terminal.
  cancelled;

  /// Stable database/wire representation. Never persist [index].
  String get wireValue {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.declined:
        return 'declined';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Whether this status holds an active slot reservation.
  bool get reservationActive {
    switch (this) {
      case BookingStatus.pending:
      case BookingStatus.confirmed:
      case BookingStatus.inProgress:
        return true;
      case BookingStatus.completed:
      case BookingStatus.declined:
      case BookingStatus.cancelled:
        return false;
    }
  }

  /// Whether this status is terminal.
  bool get isTerminal {
    switch (this) {
      case BookingStatus.completed:
      case BookingStatus.declined:
      case BookingStatus.cancelled:
        return true;
      case BookingStatus.pending:
      case BookingStatus.confirmed:
      case BookingStatus.inProgress:
        return false;
    }
  }

  /// Whether a cleaner DTO may expose the full address snapshot.
  bool get exposesFullAddressToCleaner {
    switch (this) {
      case BookingStatus.confirmed:
      case BookingStatus.inProgress:
      case BookingStatus.completed:
        return true;
      case BookingStatus.pending:
      case BookingStatus.declined:
      case BookingStatus.cancelled:
        return false;
    }
  }

  /// Parses a stored status string. Unknown values fail.
  static BookingStatus fromWire(String value) {
    switch (value) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'declined':
        return BookingStatus.declined;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        throw const FormatException('Unknown BookingStatus.');
    }
  }
}

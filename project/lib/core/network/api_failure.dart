/// Safe client failure for marketplace feature APIs.
class ApiFailure implements Exception {
  /// Creates a sanitized failure.
  const ApiFailure({required this.code, required this.message});

  /// Machine-readable code from the backend or a local client code.
  final String code;

  /// Safe user-readable message.
  final String message;

  @override
  String toString() => 'ApiFailure($code)';
}

/// User-readable messages for known backend error codes.
String messageForApiCode(String code) {
  switch (code) {
    case 'forbidden':
      return 'You do not have permission to perform this action.';
    case 'account_unavailable':
      return 'This account is currently unavailable.';
    case 'customer_profile_required':
      return 'Create your profile before setting a default address.';
    case 'address_not_found':
      return 'Address was not found.';
    case 'address_limit_reached':
      return 'You can save at most 20 addresses.';
    case 'cleaner_profile_required':
      return 'Save your cleaner profile before submitting for review.';
    case 'cleaner_profile_locked':
      return 'This profile cannot be edited while it is under review or approved.';
    case 'invalid_onboarding_state':
      return 'This onboarding action is not allowed right now.';
    case 'cleaner_application_not_found':
      return 'Cleaner application was not found.';
    case 'service_not_found':
      return 'Service was not found.';
    case 'cleaner_not_approved':
      return 'Your cleaner account must be approved before managing services.';
    case 'cleaner_service_not_found':
      return 'Service offering was not found.';
    case 'invalid_hourly_rate':
      return 'Hourly rate must be a whole number in minor units.';
    case 'invalid_currency_code':
      return 'Currency code must be three letters.';
    case 'availability_not_found':
      return 'Availability slot was not found.';
    case 'availability_overlap':
      return 'This availability window overlaps another slot.';
    case 'availability_limit_reached':
      return 'You can save at most 180 future availability slots.';
    case 'invalid_availability_window':
      return 'The availability window is invalid.';
    case 'cleaner_not_found':
      return 'Cleaner was not found.';
    case 'booking_not_found':
      return 'Booking was not found.';
    case 'availability_unavailable':
      return 'That time slot is no longer available.';
    case 'availability_reserved':
      return 'This availability slot is reserved by a booking.';
    case 'invalid_booking_state':
      return 'This booking cannot be changed in its current state.';
    case 'idempotency_key_required':
      return 'Please try booking again.';
    case 'invalid_idempotency_key':
      return 'Please try booking again.';
    case 'idempotency_key_reused':
      return 'Please start a new booking attempt.';
    case 'invalid_customer_notes':
      return 'Notes must be plain text up to 500 characters.';
    case 'payment_not_found':
      return 'Payment was not found.';
    case 'booking_not_payable':
      return 'This booking cannot be paid until it is confirmed.';
    case 'payment_already_active':
      return 'A payment attempt is already in progress.';
    case 'payment_already_paid':
      return 'This booking has already been paid.';
    case 'payment_provider_unavailable':
      return 'Payment is temporarily unavailable.';
    case 'payment_integrity_mismatch':
      return 'Payment details could not be verified.';
    case 'invalid_payment_state':
      return 'This payment action is not allowed right now.';
    case 'payment_refund_failed':
    case 'refund_required':
      return 'Your payment must be refunded before this booking can be cancelled.';
    case 'invalid_refund_amount':
      return 'Refund amount is invalid.';
    case 'invalid_refund_reason':
      return 'Refund reason must be between 5 and 500 characters.';
    case 'webhook_event_conflict':
      return 'This payment event could not be processed.';
    case 'conversation_not_found':
      return 'Conversation was not found.';
    case 'conversation_read_only':
      return 'This conversation is read-only because the booking is closed.';
    case 'invalid_message':
      return 'Message must be plain text up to 2000 characters.';
    case 'invalid_message_cursor':
      return 'The message list could not be loaded.';
    case 'notification_not_found':
      return 'Notification was not found.';
    case 'review_not_allowed':
      return 'You can review a booking only after it is completed.';
    case 'review_not_found':
      return 'Review was not found.';
    case 'invalid_review_rating':
      return 'Rating must be a whole number from 1 to 5.';
    case 'invalid_review_comment':
      return 'Comment must be plain text up to 1000 characters.';
    case 'invalid_review_reason':
      return 'Reason must be between 5 and 500 characters.';
    case 'invalid_review_state':
      return 'This review cannot be changed in its current state.';
    case 'dispute_not_found':
      return 'Dispute was not found.';
    case 'dispute_already_exists':
      return 'A dispute already exists for this booking.';
    case 'dispute_not_allowed':
      return 'A dispute cannot be opened for this booking.';
    case 'invalid_dispute_state':
      return 'This dispute cannot be changed in its current state.';
    case 'invalid_dispute_subject':
      return 'Subject must be between 5 and 120 characters.';
    case 'invalid_dispute_description':
      return 'Description must be between 20 and 3000 characters.';
    case 'invalid_dispute_resolution':
      return 'Resolution must be between 10 and 3000 characters.';
    case 'user_not_found':
      return 'User was not found.';
    case 'protected_admin_account':
      return 'Administrator accounts cannot be changed from this screen.';
    case 'invalid_account_state':
      return 'This account cannot be changed in its current state.';
    case 'invalid_moderation_reason':
      return 'Reason must be between 5 and 500 characters.';
    case 'admin_booking_not_cancellable':
      return 'This booking cannot be cancelled by an administrator.';
    case 'audit_log_not_found':
      return 'Audit log was not found.';
    case 'insufficient_payout_balance':
      return 'Available payout balance is insufficient.';
    case 'payout_already_active':
      return 'A payout request is already in progress.';
    case 'payout_not_found':
      return 'Payout was not found.';
    case 'invalid_payout_state':
      return 'This payout action is not allowed right now.';
    case 'payout_provider_unavailable':
      return 'Payout processing is temporarily unavailable.';
    case 'invalid_payout_amount':
      return 'Payout amount must be a whole number of at least 1 minor unit.';
    case 'invalid_payout_currency':
      return 'Currency code must be three letters.';
    case 'payout_integrity_mismatch':
      return 'Payout details could not be verified.';
    case 'payout_webhook_event_conflict':
      return 'This payout event could not be processed.';
    case 'invalid_payout_rejection_reason':
      return 'Rejection reason must be between 5 and 500 characters.';
    case 'invalid_input':
      return 'Please check your details and try again.';
    case 'invalid_access_token':
      return 'Authentication is required.';
    case 'invalid_json':
      return 'Please check your details and try again.';
    default:
      return 'Something went wrong. Please try again.';
  }
}

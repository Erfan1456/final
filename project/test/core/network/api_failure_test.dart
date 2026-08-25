import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';

void main() {
  test('maps known backend codes to safe messages', () {
    expect(
      messageForApiCode('forbidden'),
      equals('You do not have permission to perform this action.'),
    );
    expect(
      messageForApiCode('address_limit_reached'),
      equals('You can save at most 20 addresses.'),
    );
    expect(
      messageForApiCode('customer_profile_required'),
      equals('Create your profile before setting a default address.'),
    );
    expect(
      messageForApiCode('cleaner_profile_locked'),
      contains('cannot be edited'),
    );
    expect(
      messageForApiCode('availability_overlap'),
      equals('This availability window overlaps another slot.'),
    );
    expect(messageForApiCode('cleaner_not_approved'), contains('approved'));
    expect(
      messageForApiCode('booking_not_found'),
      equals('Booking was not found.'),
    );
    expect(
      messageForApiCode('availability_unavailable'),
      equals('That time slot is no longer available.'),
    );
    expect(
      messageForApiCode('invalid_booking_state'),
      contains('current state'),
    );
    expect(messageForApiCode('availability_reserved'), contains('reserved'));
    expect(
      messageForApiCode('payment_refund_failed'),
      contains('refunded before this booking can be cancelled'),
    );
    expect(messageForApiCode('booking_not_payable'), contains('confirmed'));
    expect(
      messageForApiCode('conversation_not_found'),
      equals('Conversation was not found.'),
    );
    expect(messageForApiCode('conversation_read_only'), contains('read-only'));
    expect(messageForApiCode('invalid_message'), contains('plain text'));
    expect(
      messageForApiCode('notification_not_found'),
      contains('Notification'),
    );
    expect(messageForApiCode('review_not_allowed'), contains('completed'));
    expect(
      messageForApiCode('review_not_found'),
      equals('Review was not found.'),
    );
    expect(messageForApiCode('invalid_review_rating'), contains('1 to 5'));
    expect(messageForApiCode('dispute_not_found'), 'Dispute was not found.');
    expect(
      messageForApiCode('protected_admin_account'),
      contains('Administrator'),
    );
    expect(
      messageForApiCode('audit_log_not_found'),
      'Audit log was not found.',
    );
    expect(
      messageForApiCode('admin_booking_not_cancellable'),
      contains('cannot be cancelled'),
    );
    expect(
      messageForApiCode('insufficient_payout_balance'),
      contains('insufficient'),
    );
    expect(messageForApiCode('payout_already_active'), contains('already'));
    expect(messageForApiCode('payout_not_found'), 'Payout was not found.');
    expect(
      messageForApiCode('invalid_payout_rejection_reason'),
      contains('5 and 500'),
    );
    expect(
      messageForApiCode('some_unknown_code'),
      equals('Something went wrong. Please try again.'),
    );
  });

  test('ApiFailure toString omits raw exception text', () {
    const failure = ApiFailure(
      code: 'address_not_found',
      message: 'Address was not found.',
    );
    expect(failure.toString(), equals('ApiFailure(address_not_found)'));
    expect(failure.toString(), isNot(contains('Mongo')));
  });
}

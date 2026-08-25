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

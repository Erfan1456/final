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

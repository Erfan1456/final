import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile_api.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeCustomerProfileApi extends CustomerProfileApi {
  _FakeCustomerProfileApi() : super(Dio());

  CustomerProfile? nextProfile;
  ApiFailure? nextError;
  int getCalls = 0;
  int saveCalls = 0;

  @override
  Future<CustomerProfile?> getProfile() async {
    getCalls += 1;
    final error = nextError;
    if (error != null) {
      throw error;
    }
    return nextProfile;
  }

  @override
  Future<CustomerProfile> saveProfile({
    required String fullName,
    required String? phoneE164,
  }) async {
    saveCalls += 1;
    final error = nextError;
    if (error != null) {
      throw error;
    }
    return CustomerProfile.fromJson(
      customerProfileJson(fullName: fullName, phoneE164: phoneE164),
    );
  }
}

void main() {
  late _FakeCustomerProfileApi api;
  late ProviderContainer container;

  setUp(() {
    api = _FakeCustomerProfileApi();
    container = ProviderContainer(
      overrides: [customerProfileApiProvider.overrideWithValue(api)],
    );
  });

  tearDown(() => container.dispose());

  Future<CustomerProfileState> settle() async {
    container.listen(customerProfileControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container.read(customerProfileControllerProvider);
  }

  test('load absent profile', () async {
    api.nextProfile = null;
    final state = await settle();
    expect(state.loading, isFalse);
    expect(state.hasProfile, isFalse);
    expect(api.getCalls, equals(1));
  });

  test('load existing profile', () async {
    api.nextProfile = CustomerProfile.fromJson(customerProfileJson());
    final state = await settle();
    expect(state.profile?.fullName, equals('Test Customer'));
  });

  test('save updates state', () async {
    api.nextProfile = null;
    await settle();
    final ok = await container
        .read(customerProfileControllerProvider.notifier)
        .save(fullName: 'Ada Example', phoneE164: null);
    expect(ok, isTrue);
    expect(api.saveCalls, equals(1));
    expect(
      container.read(customerProfileControllerProvider).profile?.fullName,
      equals('Ada Example'),
    );
  });

  test('safe error stays user-readable', () async {
    api.nextError = const ApiFailure(
      code: 'forbidden',
      message: 'You do not have permission to perform this action.',
    );
    final state = await settle();
    expect(
      state.errorMessage,
      equals('You do not have permission to perform this action.'),
    );
  });
}

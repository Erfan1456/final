import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/addresses/data/address.dart';
import 'package:home_cleaning_marketplace/features/addresses/data/address_api.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeAddressApi extends AddressApi {
  _FakeAddressApi() : super(Dio());

  List<Address> items = <Address>[];
  ApiFailure? nextError;
  int listCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int defaultCalls = 0;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<List<Address>> list() async {
    listCalls += 1;
    _throwIfNeeded();
    return items;
  }

  @override
  Future<Address> create(Map<String, Object?> body) async {
    createCalls += 1;
    _throwIfNeeded();
    final created = Address.fromJson(addressJson(label: '${body['label']}'));
    items = [...items, created];
    return created;
  }

  @override
  Future<Address> update(String id, Map<String, Object?> body) async {
    updateCalls += 1;
    _throwIfNeeded();
    return Address.fromJson(addressJson(id: id, label: '${body['label']}'));
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls += 1;
    _throwIfNeeded();
    items = [
      for (final item in items)
        if (item.id != id) item,
    ];
  }

  @override
  Future<CustomerProfile> setDefault(String id) async {
    defaultCalls += 1;
    _throwIfNeeded();
    items = [
      for (final item in items)
        Address.fromJson(addressJson(id: item.id, isDefault: item.id == id)),
    ];
    return CustomerProfile.fromJson(customerProfileJson(defaultAddressId: id));
  }
}

void main() {
  late _FakeAddressApi api;
  late ProviderContainer container;

  setUp(() {
    api = _FakeAddressApi();
    container = ProviderContainer(
      overrides: [addressApiProvider.overrideWithValue(api)],
    );
  });

  tearDown(() => container.dispose());

  Future<AddressListState> settle() async {
    container.listen(addressControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container.read(addressControllerProvider);
  }

  test('load returns owned addresses', () async {
    api.items = [Address.fromJson(addressJson(isDefault: true))];
    final state = await settle();
    expect(state.addresses, hasLength(1));
    expect(state.defaultAddress?.isDefault, isTrue);
  });

  test('create reloads the list', () async {
    await settle();
    final ok = await container
        .read(addressControllerProvider.notifier)
        .create(
          label: 'Office',
          line1: '2 Test Street',
          line2: null,
          city: 'Dhaka',
          region: 'Dhaka',
          postalCode: '1206',
          countryCode: 'bd',
        );
    expect(ok, isTrue);
    expect(api.createCalls, equals(1));
    expect(api.listCalls, greaterThan(1));
  });

  test('update, delete, and setDefault call the API', () async {
    api.items = [Address.fromJson(addressJson())];
    await settle();
    final notifier = container.read(addressControllerProvider.notifier);
    expect(
      await notifier.update(
        id: '507f1f77bcf86cd799439031',
        label: 'Home 2',
        line1: '1 Test Street',
        line2: null,
        city: 'Dhaka',
        region: 'Dhaka',
        postalCode: '1205',
        countryCode: 'BD',
      ),
      isTrue,
    );
    expect(api.updateCalls, equals(1));
    expect(await notifier.setDefault('507f1f77bcf86cd799439031'), isTrue);
    expect(api.defaultCalls, equals(1));
    expect(await notifier.delete('507f1f77bcf86cd799439031'), isTrue);
    expect(api.deleteCalls, equals(1));
  });

  test('address limit error is mapped safely', () async {
    await settle();
    api.nextError = ApiFailure(
      code: 'address_limit_reached',
      message: messageForApiCode('address_limit_reached'),
    );
    final ok = await container
        .read(addressControllerProvider.notifier)
        .create(
          label: 'Extra',
          line1: '9 Test Street',
          line2: null,
          city: 'Dhaka',
          region: 'Dhaka',
          postalCode: '1205',
          countryCode: 'BD',
        );
    expect(ok, isFalse);
    expect(
      container.read(addressControllerProvider).errorMessage,
      equals('You can save at most 20 addresses.'),
    );
  });

  test('foreign or missing address error is mapped', () async {
    await settle();
    api.nextError = ApiFailure(
      code: 'address_not_found',
      message: messageForApiCode('address_not_found'),
    );
    final ok = await container
        .read(addressControllerProvider.notifier)
        .delete('someone-elses-id');
    expect(ok, isFalse);
    expect(
      container.read(addressControllerProvider).errorMessage,
      equals('Address was not found.'),
    );
  });
}

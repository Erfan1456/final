import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/application/customer_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../helpers/memory_collection_store.dart';

void main() {
  late MemoryCollectionDocumentStore profiles;
  late MemoryCollectionDocumentStore addresses;
  late CustomerAccountService service;
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
  final otherUser = ObjectId.fromHexString('507f1f77bcf86cd799439099');

  setUp(() {
    profiles = MemoryCollectionDocumentStore();
    addresses = MemoryCollectionDocumentStore();
    service = CustomerAccountService(
      profiles: MongoCustomerProfileRepository(documents: profiles),
      addresses: MongoAddressRepository(documents: addresses),
    );
  });

  Future<ObjectId> createAddress({
    ObjectId? owner,
    String label = 'Home',
  }) async {
    final created = await service.createAddress(
      userId: owner ?? userId,
      label: label,
      line1: '1 Test Street',
      line2: null,
      city: 'Dhaka',
      region: 'Dhaka',
      postalCode: '1205',
      countryCode: 'bd',
    );
    return created.address.id;
  }

  group('CustomerAccountService profile', () {
    test('getProfile returns null when absent', () async {
      expect(await service.getProfile(userId), isNull);
    });

    test('upsert creates then updates', () async {
      final created = await service.upsertProfile(
        userId: userId,
        fullName: '  Test Customer  ',
        phoneE164: '  ',
      );
      expect(created.fullName, equals('Test Customer'));
      expect(created.phoneE164, isNull);
      expect(created.userId, equals(userId));

      final updated = await service.upsertProfile(
        userId: userId,
        fullName: 'Updated Customer',
        phoneE164: '+15555550100',
      );
      expect(updated.id, equals(created.id));
      expect(updated.phoneE164, equals('+15555550100'));
      expect(profiles.documents, hasLength(1));
    });
  });

  group('CustomerAccountService addresses', () {
    test('create normalizes country code and lists newest first', () async {
      final first = await createAddress(label: 'Older');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final second = await createAddress(label: 'Newer');
      final listed = await service.listAddresses(userId);
      expect(listed.map((item) => item.address.id), equals([second, first]));
      expect(listed.first.address.countryCode, equals('BD'));
      expect(listed.every((item) => !item.isDefault), isTrue);
    });

    test('enforces the 20-address product limit', () async {
      for (var i = 0; i < 20; i++) {
        await createAddress(label: 'A$i');
      }
      expect(
        () => createAddress(label: 'Overflow'),
        throwsA(isA<AddressLimitReachedException>()),
      );
    });

    test('foreign address is not found', () async {
      final id = await createAddress(owner: otherUser);
      expect(
        () => service.getAddress(userId: userId, addressId: id),
        throwsA(isA<AddressNotFoundException>()),
      );
      expect(
        () => service.updateAddress(
          userId: userId,
          addressId: id,
          label: 'X',
          line1: '1 Test Street',
          line2: null,
          city: 'Dhaka',
          region: 'Dhaka',
          postalCode: '1205',
          countryCode: 'BD',
        ),
        throwsA(isA<AddressNotFoundException>()),
      );
      expect(
        () => service.deleteAddress(userId: userId, addressId: id),
        throwsA(isA<AddressNotFoundException>()),
      );
      expect(
        () => service.setDefaultAddress(userId: userId, addressId: id),
        throwsA(isA<AddressNotFoundException>()),
      );
    });

    test('set default requires a customer profile', () async {
      final id = await createAddress();
      expect(
        () => service.setDefaultAddress(userId: userId, addressId: id),
        throwsA(isA<CustomerProfileRequiredException>()),
      );
    });

    test(
      'set default and computed is_default, then delete clears pointer',
      () async {
        await service.upsertProfile(
          userId: userId,
          fullName: 'Test Customer',
          phoneE164: null,
        );
        final first = await createAddress();
        final second = await createAddress(label: 'Office');
        await service.setDefaultAddress(userId: userId, addressId: first);
        var listed = await service.listAddresses(userId);
        expect(
          listed.firstWhere((item) => item.address.id == first).isDefault,
          isTrue,
        );
        expect(
          listed.firstWhere((item) => item.address.id == second).isDefault,
          isFalse,
        );

        await service.deleteAddress(userId: userId, addressId: first);
        final profile = await service.getProfile(userId);
        expect(profile?.defaultAddressId, isNull);
        listed = await service.listAddresses(userId);
        expect(listed, hasLength(1));
        expect(listed.single.isDefault, isFalse);
      },
    );

    test('ownership queries include _id and user_id', () async {
      final id = await createAddress();
      await MongoAddressRepository(documents: addresses).updateOwned(
        id: id,
        userId: userId,
        data: const AddressWriteData(
          label: 'Home',
          line1: '2 Test Street',
          city: 'Dhaka',
          region: 'Dhaka',
          postalCode: '1205',
          countryCode: 'BD',
        ),
      );
      expect(addresses.lastUpdateSelector?['_id'], equals(id));
      expect(addresses.lastUpdateSelector?['user_id'], equals(userId));
    });
  });
}

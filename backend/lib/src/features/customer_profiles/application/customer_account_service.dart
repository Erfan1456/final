import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_field_validation.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Maximum owned addresses per customer. Application-level product limit.
const int maxAddressesPerCustomer = 20;

/// Address plus computed default flag for HTTP listing.
class OwnedAddress {
  /// Creates a list item.
  const OwnedAddress({required this.address, required this.isDefault});

  /// Persisted address.
  final Address address;

  /// Whether this address is the customer profile's default pointer.
  final bool isDefault;

  /// Safe public JSON including computed `is_default`.
  Map<String, Object?> toPublicJson() =>
      address.toPublicJson(isDefault: isDefault);
}

/// HTTP-independent customer profile and address use cases.
class CustomerAccountService {
  /// Creates a service over [profiles] and [addresses].
  CustomerAccountService({
    required CustomerProfileRepository profiles,
    required AddressRepository addresses,
  }) : _profiles = profiles,
       _addresses = addresses;

  final CustomerProfileRepository _profiles;
  final AddressRepository _addresses;

  /// Returns the profile for [userId], or `null` when none exists.
  Future<CustomerProfile?> getProfile(ObjectId userId) {
    return _profiles.findByUserId(userId);
  }

  /// Creates or updates the owned customer profile.
  Future<CustomerProfile> upsertProfile({
    required ObjectId userId,
    required Object? fullName,
    required Object? phoneE164,
  }) {
    return _profiles.upsertProfile(
      userId: userId,
      fullName: ProfileFieldValidation.requireFullName(fullName),
      phoneE164: ProfileFieldValidation.optionalPhoneE164(phoneE164),
    );
  }

  /// Lists owned addresses, newest first, with computed `is_default`.
  Future<List<OwnedAddress>> listAddresses(ObjectId userId) async {
    final profile = await _profiles.findByUserId(userId);
    final defaultId = profile?.defaultAddressId;
    final addresses = await _addresses.listForUser(userId);
    return addresses
        .map(
          (address) => OwnedAddress(
            address: address,
            isDefault: defaultId != null && address.id == defaultId,
          ),
        )
        .toList();
  }

  /// Returns one owned address with computed default flag.
  Future<OwnedAddress> getAddress({
    required ObjectId userId,
    required ObjectId addressId,
  }) async {
    final address = await _addresses.findOwnedById(
      id: addressId,
      userId: userId,
    );
    if (address == null) {
      throw const AddressNotFoundException();
    }
    final profile = await _profiles.findByUserId(userId);
    return OwnedAddress(
      address: address,
      isDefault: profile?.defaultAddressId == address.id,
    );
  }

  /// Creates an owned address. Profile is not required.
  Future<OwnedAddress> createAddress({
    required ObjectId userId,
    required Object? label,
    required Object? line1,
    required Object? line2,
    required Object? city,
    required Object? region,
    required Object? postalCode,
    required Object? countryCode,
  }) async {
    final count = await _addresses.countForUser(userId);
    if (count >= maxAddressesPerCustomer) {
      throw const AddressLimitReachedException();
    }
    final data = _writeData(
      label: label,
      line1: line1,
      line2: line2,
      city: city,
      region: region,
      postalCode: postalCode,
      countryCode: countryCode,
    );
    final address = await _addresses.create(userId: userId, data: data);
    return OwnedAddress(address: address, isDefault: false);
  }

  /// Updates editable fields of an owned address.
  Future<OwnedAddress> updateAddress({
    required ObjectId userId,
    required ObjectId addressId,
    required Object? label,
    required Object? line1,
    required Object? line2,
    required Object? city,
    required Object? region,
    required Object? postalCode,
    required Object? countryCode,
  }) async {
    final data = _writeData(
      label: label,
      line1: line1,
      line2: line2,
      city: city,
      region: region,
      postalCode: postalCode,
      countryCode: countryCode,
    );
    final address = await _addresses.updateOwned(
      id: addressId,
      userId: userId,
      data: data,
    );
    if (address == null) {
      throw const AddressNotFoundException();
    }
    final profile = await _profiles.findByUserId(userId);
    return OwnedAddress(
      address: address,
      isDefault: profile?.defaultAddressId == address.id,
    );
  }

  /// Deletes an owned address and clears the default pointer when it matched.
  ///
  /// Clear then delete is not a MongoDB multi-document transaction.
  Future<void> deleteAddress({
    required ObjectId userId,
    required ObjectId addressId,
  }) async {
    final existing = await _addresses.findOwnedById(
      id: addressId,
      userId: userId,
    );
    if (existing == null) {
      throw const AddressNotFoundException();
    }
    await _profiles.clearDefaultAddressIfMatches(
      userId: userId,
      addressId: addressId,
    );
    final deleted = await _addresses.deleteOwned(id: addressId, userId: userId);
    if (!deleted) {
      throw const AddressNotFoundException();
    }
  }

  /// Sets the default address pointer. Requires an existing customer profile.
  Future<CustomerProfile> setDefaultAddress({
    required ObjectId userId,
    required ObjectId addressId,
  }) async {
    final address = await _addresses.findOwnedById(
      id: addressId,
      userId: userId,
    );
    if (address == null) {
      throw const AddressNotFoundException();
    }
    final profile = await _profiles.setDefaultAddress(
      userId: userId,
      addressId: addressId,
    );
    if (profile == null) {
      throw const CustomerProfileRequiredException();
    }
    return profile;
  }

  AddressWriteData _writeData({
    required Object? label,
    required Object? line1,
    required Object? line2,
    required Object? city,
    required Object? region,
    required Object? postalCode,
    required Object? countryCode,
  }) {
    return AddressWriteData(
      label: AddressValidation.requireText(
        label,
        max: AddressValidation.labelMax,
        label: 'Label',
      ),
      line1: AddressValidation.requireText(
        line1,
        max: AddressValidation.line1Max,
        label: 'Address line 1',
      ),
      line2: AddressValidation.optionalLine2(line2),
      city: AddressValidation.requireText(
        city,
        max: AddressValidation.cityMax,
        label: 'City',
      ),
      region: AddressValidation.requireText(
        region,
        max: AddressValidation.regionMax,
        label: 'Region',
      ),
      postalCode: AddressValidation.requireText(
        postalCode,
        max: AddressValidation.postalCodeMax,
        label: 'Postal code',
      ),
      countryCode: AddressValidation.requireCountryCode(countryCode),
    );
  }
}

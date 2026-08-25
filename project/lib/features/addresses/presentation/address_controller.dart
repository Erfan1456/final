import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/addresses/data/address.dart';
import 'package:home_cleaning_marketplace/features/addresses/data/address_api.dart';

/// Address list presentation state.
class AddressListState {
  /// Creates an explicit state.
  const AddressListState({
    required this.loading,
    this.addresses = const <Address>[],
    this.saving = false,
    this.errorMessage,
  });

  /// Initial load.
  const AddressListState.loading()
    : loading = true,
      addresses = const <Address>[],
      saving = false,
      errorMessage = null;

  final bool loading;
  final List<Address> addresses;
  final bool saving;
  final String? errorMessage;

  Address? get defaultAddress {
    for (final address in addresses) {
      if (address.isDefault) {
        return address;
      }
    }
    return null;
  }

  AddressListState copyWith({
    bool? loading,
    List<Address>? addresses,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddressListState(
      loading: loading ?? this.loading,
      addresses: addresses ?? this.addresses,
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Loads and mutates the owned address list.
class AddressController extends Notifier<AddressListState> {
  @override
  AddressListState build() {
    Future<void>(load);
    return const AddressListState.loading();
  }

  AddressApi get _api => ref.read(addressApiProvider);

  /// Reloads addresses.
  Future<void> load() async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final addresses = await _api.list();
      if (!ref.mounted) {
        return;
      }
      state = AddressListState(loading: false, addresses: addresses);
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = AddressListState(loading: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = const AddressListState(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Map<String, Object?> _body({
    required String label,
    required String line1,
    required String? line2,
    required String city,
    required String region,
    required String postalCode,
    required String countryCode,
  }) {
    return <String, Object?>{
      'label': label,
      'line1': line1,
      'line2': line2,
      'city': city,
      'region': region,
      'postal_code': postalCode,
      'country_code': countryCode.toUpperCase(),
    };
  }

  /// Creates an address then reloads.
  Future<bool> create({
    required String label,
    required String line1,
    required String? line2,
    required String city,
    required String region,
    required String postalCode,
    required String countryCode,
  }) {
    return _mutate(
      () => _api.create(
        _body(
          label: label,
          line1: line1,
          line2: line2,
          city: city,
          region: region,
          postalCode: postalCode,
          countryCode: countryCode,
        ),
      ),
    );
  }

  /// Updates an address then reloads.
  Future<bool> update({
    required String id,
    required String label,
    required String line1,
    required String? line2,
    required String city,
    required String region,
    required String postalCode,
    required String countryCode,
  }) {
    return _mutate(
      () => _api.update(
        id,
        _body(
          label: label,
          line1: line1,
          line2: line2,
          city: city,
          region: region,
          postalCode: postalCode,
          countryCode: countryCode,
        ),
      ),
    );
  }

  /// Deletes an address then reloads.
  Future<bool> delete(String id) => _mutate(() => _api.delete(id));

  /// Sets the default address then reloads.
  Future<bool> setDefault(String id) => _mutate(() => _api.setDefault(id));

  Future<bool> _mutate(Future<void> Function() action) async {
    if (!ref.mounted) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      await action();
      await load();
      return true;
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(saving: false, errorMessage: error.message);
      return false;
    } catch (_) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        saving: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }
}

/// Address list controller.
final addressControllerProvider =
    NotifierProvider<AddressController, AddressListState>(
      AddressController.new,
    );

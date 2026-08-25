import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile_api.dart';

/// Customer profile presentation state.
class CustomerProfileState {
  /// Creates an explicit state.
  const CustomerProfileState({
    required this.loading,
    this.profile,
    this.saving = false,
    this.errorMessage,
  });

  /// Initial load.
  const CustomerProfileState.loading()
    : loading = true,
      profile = null,
      saving = false,
      errorMessage = null;

  final bool loading;
  final CustomerProfile? profile;
  final bool saving;
  final String? errorMessage;

  bool get hasProfile => profile != null;

  CustomerProfileState copyWith({
    bool? loading,
    CustomerProfile? profile,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return CustomerProfileState(
      loading: loading ?? this.loading,
      profile: clearProfile ? null : (profile ?? this.profile),
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Loads and saves the customer profile.
class CustomerProfileController extends Notifier<CustomerProfileState> {
  @override
  CustomerProfileState build() {
    Future<void>(load);
    return const CustomerProfileState.loading();
  }

  CustomerProfileApi get _api => ref.read(customerProfileApiProvider);

  /// Reloads the profile.
  Future<void> load() async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final profile = await _api.getProfile();
      if (!ref.mounted) {
        return;
      }
      state = CustomerProfileState(loading: false, profile: profile);
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = CustomerProfileState(loading: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = const CustomerProfileState(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Saves full name and optional phone.
  Future<bool> save({
    required String fullName,
    required String? phoneE164,
  }) async {
    if (!ref.mounted) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final profile = await _api.saveProfile(
        fullName: fullName,
        phoneE164: phoneE164,
      );
      if (!ref.mounted) {
        return false;
      }
      state = CustomerProfileState(loading: false, profile: profile);
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

/// Customer profile controller.
final customerProfileControllerProvider =
    NotifierProvider<CustomerProfileController, CustomerProfileState>(
      CustomerProfileController.new,
    );

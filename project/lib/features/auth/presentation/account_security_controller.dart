import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_repository.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';

/// Authenticated password-change presentation state.
class AccountSecurityState {
  const AccountSecurityState({
    this.isSubmitting = false,
    this.errorMessage,
    this.passwordChanged = false,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final bool passwordChanged;

  AccountSecurityState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool? passwordChanged,
    bool clearError = false,
  }) {
    return AccountSecurityState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      passwordChanged: passwordChanged ?? this.passwordChanged,
    );
  }
}

/// Authenticated password change.
class AccountSecurityController extends Notifier<AccountSecurityState> {
  @override
  AccountSecurityState build() => const AccountSecurityState();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Changes the signed-in account password and clears local auth.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      passwordChanged: false,
    );
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!ref.mounted) {
        return false;
      }
      ref.read(authControllerProvider.notifier).clearAuthenticatedSession();
      state = const AccountSecurityState(passwordChanged: true);
      return true;
    } on AuthFailure catch (error) {
      if (!ref.mounted) {
        return false;
      }
      state = AccountSecurityState(errorMessage: error.message);
      return false;
    } catch (_) {
      if (!ref.mounted) {
        return false;
      }
      state = const AccountSecurityState(
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }
}

final accountSecurityControllerProvider =
    NotifierProvider<AccountSecurityController, AccountSecurityState>(
      AccountSecurityController.new,
    );

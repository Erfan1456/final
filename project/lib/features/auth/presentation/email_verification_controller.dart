import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_repository.dart';
import 'package:home_cleaning_marketplace/features/auth/data/development_account_action.dart';

/// Email verification presentation state.
class EmailVerificationState {
  const EmailVerificationState({
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.developmentAction,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final DevelopmentAccountAction? developmentAction;

  EmailVerificationState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    DevelopmentAccountAction? developmentAction,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearDevelopmentAction = false,
  }) {
    return EmailVerificationState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      developmentAction: clearDevelopmentAction
          ? null
          : (developmentAction ?? this.developmentAction),
    );
  }
}

/// Resend and consume email verification tokens.
class EmailVerificationController extends Notifier<EmailVerificationState> {
  @override
  EmailVerificationState build() => const EmailVerificationState();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Requests a new verification email.
  Future<void> requestVerification(String email) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
      clearDevelopmentAction: true,
    );
    try {
      final result = await _repository.requestEmailVerification(email.trim());
      if (!ref.mounted) {
        return;
      }
      state = EmailVerificationState(
        successMessage: result.message,
        developmentAction: result.developmentAction,
      );
    } on AuthFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = EmailVerificationState(errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = const EmailVerificationState(
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Consumes a verification token.
  Future<bool> verify(String token) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _repository.verifyEmail(token.trim());
      if (!ref.mounted) {
        return false;
      }
      state = const EmailVerificationState(
        successMessage: 'Email verified. You can sign in now.',
      );
      return true;
    } on AuthFailure catch (error) {
      if (!ref.mounted) {
        return false;
      }
      state = EmailVerificationState(errorMessage: error.message);
      return false;
    } catch (_) {
      if (!ref.mounted) {
        return false;
      }
      state = const EmailVerificationState(
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }
}

final emailVerificationControllerProvider =
    NotifierProvider<EmailVerificationController, EmailVerificationState>(
      EmailVerificationController.new,
    );

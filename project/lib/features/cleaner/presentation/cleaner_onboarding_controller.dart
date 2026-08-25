import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile_api.dart';

/// Cleaner onboarding presentation state.
class CleanerOnboardingState {
  /// Creates an explicit state.
  const CleanerOnboardingState({
    required this.loading,
    this.profile,
    this.saving = false,
    this.submitting = false,
    this.errorMessage,
  });

  /// Initial load.
  const CleanerOnboardingState.loading()
    : loading = true,
      profile = null,
      saving = false,
      submitting = false,
      errorMessage = null;

  final bool loading;
  final CleanerProfile? profile;
  final bool saving;
  final bool submitting;
  final String? errorMessage;

  OnboardingStatus get status =>
      profile?.onboardingStatus ?? OnboardingStatus.unknown;

  bool get hasProfile => profile != null;

  CleanerOnboardingState copyWith({
    bool? loading,
    CleanerProfile? profile,
    bool? saving,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return CleanerOnboardingState(
      loading: loading ?? this.loading,
      profile: clearProfile ? null : (profile ?? this.profile),
      saving: saving ?? this.saving,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Loads, saves, and submits cleaner onboarding.
class CleanerOnboardingController extends Notifier<CleanerOnboardingState> {
  @override
  CleanerOnboardingState build() {
    Future<void>(load);
    return const CleanerOnboardingState.loading();
  }

  CleanerProfileApi get _api => ref.read(cleanerProfileApiProvider);

  /// Reloads the cleaner profile.
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
      state = CleanerOnboardingState(loading: false, profile: profile);
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = CleanerOnboardingState(
        loading: false,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = const CleanerOnboardingState(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Saves draft/rejected onboarding fields.
  Future<bool> save(Map<String, Object?> body) async {
    if (!ref.mounted) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final profile = await _api.saveProfile(body);
      if (!ref.mounted) {
        return false;
      }
      state = CleanerOnboardingState(loading: false, profile: profile);
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

  /// Submits the current profile for review.
  Future<bool> submit() async {
    if (!ref.mounted) {
      return false;
    }
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final profile = await _api.submit();
      if (!ref.mounted) {
        return false;
      }
      state = CleanerOnboardingState(loading: false, profile: profile);
      return true;
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(submitting: false, errorMessage: error.message);
      return false;
    } catch (_) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        submitting: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }
}

/// Cleaner onboarding controller.
final cleanerOnboardingControllerProvider =
    NotifierProvider<CleanerOnboardingController, CleanerOnboardingState>(
      CleanerOnboardingController.new,
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/data/cleaner_service_api.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/data/cleaner_service_offering.dart';

class CleanerServiceState {
  const CleanerServiceState({
    required this.loading,
    this.offerings = const <CleanerServiceOffering>[],
    this.saving = false,
    this.errorMessage,
  });

  const CleanerServiceState.loading()
    : loading = true,
      offerings = const <CleanerServiceOffering>[],
      saving = false,
      errorMessage = null;

  final bool loading;
  final List<CleanerServiceOffering> offerings;
  final bool saving;
  final String? errorMessage;

  CleanerServiceOffering? offeringFor(String serviceId) {
    for (final offering in offerings) {
      if (offering.service.id == serviceId) {
        return offering;
      }
    }
    return null;
  }

  CleanerServiceState copyWith({
    bool? loading,
    List<CleanerServiceOffering>? offerings,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CleanerServiceState(
      loading: loading ?? this.loading,
      offerings: offerings ?? this.offerings,
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CleanerServiceController extends Notifier<CleanerServiceState> {
  @override
  CleanerServiceState build() {
    Future<void>(load);
    return const CleanerServiceState.loading();
  }

  Future<void> load() async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final offerings = await ref.read(cleanerServiceApiProvider).list();
      if (!ref.mounted) {
        return;
      }
      state = CleanerServiceState(loading: false, offerings: offerings);
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = CleanerServiceState(loading: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = const CleanerServiceState(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<bool> save({
    required String serviceId,
    required int hourlyRateMinor,
    required String currencyCode,
    required bool isActive,
  }) {
    return _mutate(
      () => ref
          .read(cleanerServiceApiProvider)
          .upsert(
            serviceId: serviceId,
            hourlyRateMinor: hourlyRateMinor,
            currencyCode: currencyCode,
            isActive: isActive,
          ),
    );
  }

  Future<bool> deactivate(String serviceId) {
    return _mutate(
      () => ref.read(cleanerServiceApiProvider).deactivate(serviceId),
    );
  }

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

final cleanerServiceControllerProvider =
    NotifierProvider<CleanerServiceController, CleanerServiceState>(
      CleanerServiceController.new,
    );

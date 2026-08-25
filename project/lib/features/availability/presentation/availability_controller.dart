import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/availability/data/availability_api.dart';
import 'package:home_cleaning_marketplace/features/availability/data/availability_slot.dart';

class AvailabilityState {
  const AvailabilityState({
    required this.loading,
    this.slots = const <AvailabilitySlot>[],
    this.saving = false,
    this.errorMessage,
  });

  const AvailabilityState.loading()
    : loading = true,
      slots = const <AvailabilitySlot>[],
      saving = false,
      errorMessage = null;

  final bool loading;
  final List<AvailabilitySlot> slots;
  final bool saving;
  final String? errorMessage;

  AvailabilitySlot? slotById(String id) {
    for (final slot in slots) {
      if (slot.id == id) {
        return slot;
      }
    }
    return null;
  }

  AvailabilityState copyWith({
    bool? loading,
    List<AvailabilitySlot>? slots,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AvailabilityState(
      loading: loading ?? this.loading,
      slots: slots ?? this.slots,
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AvailabilityController extends Notifier<AvailabilityState> {
  @override
  AvailabilityState build() {
    Future<void>(load);
    return const AvailabilityState.loading();
  }

  Future<void> load() async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final slots = await ref.read(availabilityApiProvider).list();
      if (!ref.mounted) {
        return;
      }
      state = AvailabilityState(loading: false, slots: slots);
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = AvailabilityState(loading: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = const AvailabilityState(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<bool> create({
    required String serviceId,
    required String startAt,
    required String endAt,
  }) {
    return _mutate(
      () => ref
          .read(availabilityApiProvider)
          .create(serviceId: serviceId, startAt: startAt, endAt: endAt),
    );
  }

  Future<bool> update({
    required String slotId,
    required String serviceId,
    required String startAt,
    required String endAt,
  }) {
    return _mutate(
      () => ref
          .read(availabilityApiProvider)
          .update(
            slotId: slotId,
            serviceId: serviceId,
            startAt: startAt,
            endAt: endAt,
          ),
    );
  }

  Future<bool> delete(String slotId) {
    return _mutate(() => ref.read(availabilityApiProvider).delete(slotId));
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

final availabilityControllerProvider =
    NotifierProvider<AvailabilityController, AvailabilityState>(
      AvailabilityController.new,
    );

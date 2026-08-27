import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_identity.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_api.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_idempotency.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';

class CustomerBookingState {
  const CustomerBookingState({
    required this.loading,
    this.loadingMore = false,
    this.submitting = false,
    this.items = const <CustomerBooking>[],
    this.nextCursor,
    this.statusFilter,
    this.detail,
    this.errorMessage,
    this.idempotencyKey,
    this.submittedBooking,
  });

  const CustomerBookingState.loading()
    : loading = true,
      loadingMore = false,
      submitting = false,
      items = const <CustomerBooking>[],
      nextCursor = null,
      statusFilter = null,
      detail = null,
      errorMessage = null,
      idempotencyKey = null,
      submittedBooking = null;

  final bool loading;
  final bool loadingMore;
  final bool submitting;
  final List<CustomerBooking> items;
  final String? nextCursor;
  final BookingStatus? statusFilter;
  final CustomerBooking? detail;
  final String? errorMessage;
  final String? idempotencyKey;
  final CustomerBooking? submittedBooking;

  CustomerBookingState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? submitting,
    List<CustomerBooking>? items,
    String? nextCursor,
    BookingStatus? statusFilter,
    CustomerBooking? detail,
    String? errorMessage,
    String? idempotencyKey,
    CustomerBooking? submittedBooking,
    bool clearError = false,
    bool clearCursor = false,
    bool clearFilter = false,
    bool clearDetail = false,
    bool clearSubmitted = false,
  }) {
    return CustomerBookingState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      submitting: submitting ?? this.submitting,
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
      detail: clearDetail ? null : (detail ?? this.detail),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      submittedBooking: clearSubmitted
          ? null
          : (submittedBooking ?? this.submittedBooking),
    );
  }
}

class CustomerBookingController extends Notifier<CustomerBookingState> {
  @override
  CustomerBookingState build() {
    // Rebuild/clear when authenticated identity changes (same root ProviderScope).
    watchAuthIdentityKey(ref);
    if (!watchHasAuthSession(ref)) {
      return const CustomerBookingState(loading: false);
    }
    Future<void>(load);
    return const CustomerBookingState.loading();
  }

  CustomerBookingApi get _api => ref.read(customerBookingApiProvider);

  void beginSubmitAttempt({String Function()? keyFactory}) {
    state = state.copyWith(
      submitting: false,
      idempotencyKey: (keyFactory ?? generateBookingIdempotencyKey)(),
      clearError: true,
      clearSubmitted: true,
    );
  }

  Future<void> load({BookingStatus? status, bool clearFilter = false}) async {
    if (!ref.mounted) {
      return;
    }
    final filter = clearFilter ? null : (status ?? state.statusFilter);
    state = CustomerBookingState(
      loading: true,
      statusFilter: filter,
      idempotencyKey: state.idempotencyKey,
    );
    try {
      final page = await _api.listBookings(status: filter?.wireValue);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        items: page.items,
        nextCursor: page.nextCursor,
        statusFilter: filter,
        clearCursor: page.nextCursor == null,
        clearFilter: filter == null,
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> loadMore() async {
    if (!ref.mounted) {
      return;
    }
    final cursor = state.nextCursor;
    if (cursor == null || state.loading || state.loadingMore) {
      return;
    }
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final page = await _api.listBookings(
        status: state.statusFilter?.wireValue,
        after: cursor,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loadingMore: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> loadDetail(String bookingId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearDetail: true);
    try {
      final detail = await _api.getBooking(bookingId);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false, detail: detail);
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<CustomerBooking?> submit({
    required String availabilitySlotId,
    required String addressId,
    String? customerNotes,
  }) async {
    if (!ref.mounted || state.submitting) {
      return state.submittedBooking;
    }
    final key = state.idempotencyKey ?? generateBookingIdempotencyKey();
    state = state.copyWith(
      submitting: true,
      idempotencyKey: key,
      clearError: true,
    );
    try {
      final booking = await _api.createBooking(
        availabilitySlotId: availabilitySlotId,
        addressId: addressId,
        customerNotes: customerNotes,
        idempotencyKey: key,
      );
      if (!ref.mounted) {
        return booking;
      }
      state = state.copyWith(submitting: false, submittedBooking: booking);
      return booking;
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return null;
      }
      state = state.copyWith(submitting: false, errorMessage: error.message);
      return null;
    } catch (_) {
      if (!ref.mounted) {
        return null;
      }
      state = state.copyWith(
        submitting: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return null;
    }
  }

  Future<bool> cancel(String bookingId, {String? reason}) async {
    if (!ref.mounted) {
      return false;
    }
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final booking = await _api.cancelBooking(bookingId, reason: reason);
      if (!ref.mounted) {
        return true;
      }
      state = state.copyWith(
        submitting: false,
        detail: booking,
        items: [
          for (final item in state.items)
            if (item.id == booking.id) booking else item,
        ],
      );
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

final customerBookingControllerProvider =
    NotifierProvider<CustomerBookingController, CustomerBookingState>(
      CustomerBookingController.new,
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_api.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';

class CleanerBookingState {
  const CleanerBookingState({
    required this.loading,
    this.loadingMore = false,
    this.mutating = false,
    this.items = const <CleanerBooking>[],
    this.nextCursor,
    this.statusFilter,
    this.detail,
    this.errorMessage,
  });

  const CleanerBookingState.loading()
    : loading = true,
      loadingMore = false,
      mutating = false,
      items = const <CleanerBooking>[],
      nextCursor = null,
      statusFilter = null,
      detail = null,
      errorMessage = null;

  final bool loading;
  final bool loadingMore;
  final bool mutating;
  final List<CleanerBooking> items;
  final String? nextCursor;
  final BookingStatus? statusFilter;
  final CleanerBooking? detail;
  final String? errorMessage;

  CleanerBookingState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? mutating,
    List<CleanerBooking>? items,
    String? nextCursor,
    BookingStatus? statusFilter,
    CleanerBooking? detail,
    String? errorMessage,
    bool clearError = false,
    bool clearCursor = false,
    bool clearFilter = false,
    bool clearDetail = false,
  }) {
    return CleanerBookingState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      mutating: mutating ?? this.mutating,
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
      detail: clearDetail ? null : (detail ?? this.detail),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CleanerBookingController extends Notifier<CleanerBookingState> {
  @override
  CleanerBookingState build() {
    Future<void>(load);
    return const CleanerBookingState.loading();
  }

  CleanerBookingApi get _api => ref.read(cleanerBookingApiProvider);

  Future<void> load({BookingStatus? status, bool clearFilter = false}) async {
    if (!ref.mounted) {
      return;
    }
    final filter = clearFilter ? null : (status ?? state.statusFilter);
    state = CleanerBookingState(loading: true, statusFilter: filter);
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

  Future<bool> accept(String bookingId) {
    return _mutate(() => _api.accept(bookingId));
  }

  Future<bool> decline(String bookingId, {required String reason}) {
    return _mutate(() => _api.decline(bookingId, reason: reason));
  }

  Future<bool> cancel(String bookingId, {required String reason}) {
    return _mutate(() => _api.cancel(bookingId, reason: reason));
  }

  Future<bool> start(String bookingId) {
    return _mutate(() => _api.start(bookingId));
  }

  Future<bool> complete(String bookingId) {
    return _mutate(() => _api.complete(bookingId));
  }

  Future<bool> _mutate(Future<CleanerBooking> Function() action) async {
    if (!ref.mounted || state.mutating) {
      return false;
    }
    state = state.copyWith(mutating: true, clearError: true);
    try {
      final booking = await action();
      if (!ref.mounted) {
        return true;
      }
      state = state.copyWith(
        mutating: false,
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
      state = state.copyWith(mutating: false, errorMessage: error.message);
      return false;
    } catch (_) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        mutating: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }
}

final cleanerBookingControllerProvider =
    NotifierProvider<CleanerBookingController, CleanerBookingState>(
      CleanerBookingController.new,
    );

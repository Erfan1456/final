import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_booking_api.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_booking_models.dart';

class AdminBookingFilters {
  const AdminBookingFilters({this.status, this.from, this.to});

  final String? status;
  final String? from;
  final String? to;

  AdminBookingFilters copyWith({
    String? status,
    String? from,
    String? to,
    bool clearStatus = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return AdminBookingFilters(
      status: clearStatus ? null : (status ?? this.status),
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }
}

class AdminBookingOperationsState {
  const AdminBookingOperationsState({
    required this.loading,
    this.loadingMore = false,
    this.saving = false,
    this.items = const <AdminBookingSummary>[],
    this.nextCursor,
    this.filters = const AdminBookingFilters(),
    this.detail,
    this.errorMessage,
  });

  const AdminBookingOperationsState.loading()
    : loading = true,
      loadingMore = false,
      saving = false,
      items = const <AdminBookingSummary>[],
      nextCursor = null,
      filters = const AdminBookingFilters(),
      detail = null,
      errorMessage = null;

  final bool loading;
  final bool loadingMore;
  final bool saving;
  final List<AdminBookingSummary> items;
  final String? nextCursor;
  final AdminBookingFilters filters;
  final AdminBookingDetail? detail;
  final String? errorMessage;

  AdminBookingOperationsState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? saving,
    List<AdminBookingSummary>? items,
    String? nextCursor,
    AdminBookingFilters? filters,
    AdminBookingDetail? detail,
    String? errorMessage,
    bool clearError = false,
    bool clearCursor = false,
    bool clearDetail = false,
  }) {
    return AdminBookingOperationsState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      saving: saving ?? this.saving,
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      filters: filters ?? this.filters,
      detail: clearDetail ? null : (detail ?? this.detail),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AdminBookingOperationsController
    extends Notifier<AdminBookingOperationsState> {
  @override
  AdminBookingOperationsState build() {
    Future<void>(load);
    return const AdminBookingOperationsState.loading();
  }

  AdminBookingApi get _api => ref.read(adminBookingApiProvider);

  Future<void> load({AdminBookingFilters? filters}) async {
    if (!ref.mounted) {
      return;
    }
    final nextFilters = filters ?? state.filters;
    state = AdminBookingOperationsState(loading: true, filters: nextFilters);
    try {
      final page = await _api.list(
        status: nextFilters.status,
        from: nextFilters.from,
        to: nextFilters.to,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        items: page.items,
        nextCursor: page.nextCursor,
        filters: nextFilters,
        clearCursor: page.nextCursor == null,
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = AdminBookingOperationsState(
        loading: false,
        filters: nextFilters,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = AdminBookingOperationsState(
        loading: false,
        filters: nextFilters,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> applyFilters(AdminBookingFilters filters) {
    return load(filters: filters);
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
      final page = await _api.list(
        status: state.filters.status,
        from: state.filters.from,
        to: state.filters.to,
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
      final detail = await _api.get(bookingId);
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

  Future<bool> cancel({
    required String bookingId,
    required String reason,
  }) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final detail = await _api.cancel(bookingId: bookingId, reason: reason);
      if (!ref.mounted) {
        return true;
      }
      state = state.copyWith(saving: false, detail: detail);
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

final adminBookingOperationsControllerProvider =
    NotifierProvider<
      AdminBookingOperationsController,
      AdminBookingOperationsState
    >(AdminBookingOperationsController.new);

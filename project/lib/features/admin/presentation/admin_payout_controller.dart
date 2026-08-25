import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_finance_models.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_payout_api.dart';
import 'package:home_cleaning_marketplace/features/earnings/data/earnings_models.dart';

class AdminPayoutFilters {
  const AdminPayoutFilters({this.status = 'requested', this.currency});

  final String? status;
  final String? currency;

  AdminPayoutFilters copyWith({
    String? status,
    String? currency,
    bool clearStatus = false,
    bool clearCurrency = false,
  }) {
    return AdminPayoutFilters(
      status: clearStatus ? null : (status ?? this.status),
      currency: clearCurrency ? null : (currency ?? this.currency),
    );
  }
}

class AdminPayoutState {
  const AdminPayoutState({
    required this.loading,
    this.loadingMore = false,
    this.saving = false,
    this.items = const <CleanerPayout>[],
    this.nextCursor,
    this.filters = const AdminPayoutFilters(),
    this.detail,
    this.errorMessage,
  });

  const AdminPayoutState.loading()
    : loading = true,
      loadingMore = false,
      saving = false,
      items = const <CleanerPayout>[],
      nextCursor = null,
      filters = const AdminPayoutFilters(),
      detail = null,
      errorMessage = null;

  final bool loading;
  final bool loadingMore;
  final bool saving;
  final List<CleanerPayout> items;
  final String? nextCursor;
  final AdminPayoutFilters filters;
  final AdminPayoutDetail? detail;
  final String? errorMessage;

  AdminPayoutState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? saving,
    List<CleanerPayout>? items,
    String? nextCursor,
    AdminPayoutFilters? filters,
    AdminPayoutDetail? detail,
    String? errorMessage,
    bool clearError = false,
    bool clearCursor = false,
    bool clearDetail = false,
  }) {
    return AdminPayoutState(
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

class AdminPayoutController extends Notifier<AdminPayoutState> {
  @override
  AdminPayoutState build() {
    Future<void>(load);
    return const AdminPayoutState.loading();
  }

  AdminPayoutApi get _api => ref.read(adminPayoutApiProvider);

  Future<void> load({AdminPayoutFilters? filters}) async {
    if (!ref.mounted) {
      return;
    }
    final nextFilters = filters ?? state.filters;
    state = AdminPayoutState(loading: true, filters: nextFilters);
    try {
      final page = await _api.listPayouts(
        status: nextFilters.status,
        currency: nextFilters.currency,
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
      state = AdminPayoutState(
        loading: false,
        filters: nextFilters,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = AdminPayoutState(
        loading: false,
        filters: nextFilters,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> applyFilters(AdminPayoutFilters filters) {
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
      final page = await _api.listPayouts(
        status: state.filters.status,
        currency: state.filters.currency,
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

  Future<void> loadDetail(String payoutId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearDetail: true);
    try {
      final detail = await _api.getPayout(payoutId);
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

  Future<bool> process(String payoutId) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _api.process(payoutId);
      if (!ref.mounted) {
        return true;
      }
      await loadDetail(payoutId);
      state = state.copyWith(saving: false);
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

  Future<bool> reject({
    required String payoutId,
    required String reason,
  }) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _api.reject(payoutId: payoutId, reason: reason);
      if (!ref.mounted) {
        return true;
      }
      await loadDetail(payoutId);
      state = state.copyWith(saving: false);
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

  Future<bool> simulateSuccess(String payoutId) async {
    return _simulate(payoutId, success: true);
  }

  Future<bool> simulateFailure(String payoutId) async {
    return _simulate(payoutId, success: false);
  }

  Future<bool> _simulate(String payoutId, {required bool success}) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      if (success) {
        await _api.simulateSuccess(payoutId);
      } else {
        await _api.simulateFailure(payoutId);
      }
      if (!ref.mounted) {
        return true;
      }
      await loadDetail(payoutId);
      state = state.copyWith(saving: false);
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

final adminPayoutControllerProvider =
    NotifierProvider<AdminPayoutController, AdminPayoutState>(
      AdminPayoutController.new,
    );

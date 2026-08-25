import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_api.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_models.dart';

class AdminDisputeFilters {
  const AdminDisputeFilters({this.status = 'open', this.category});

  final String? status;
  final String? category;

  AdminDisputeFilters copyWith({
    String? status,
    String? category,
    bool clearStatus = false,
    bool clearCategory = false,
  }) {
    return AdminDisputeFilters(
      status: clearStatus ? null : (status ?? this.status),
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

class AdminDisputeState {
  const AdminDisputeState({
    required this.loading,
    this.loadingMore = false,
    this.saving = false,
    this.items = const <AdminDisputeSummary>[],
    this.nextCursor,
    this.filters = const AdminDisputeFilters(),
    this.detail,
    this.errorMessage,
  });

  const AdminDisputeState.loading()
    : loading = true,
      loadingMore = false,
      saving = false,
      items = const <AdminDisputeSummary>[],
      nextCursor = null,
      filters = const AdminDisputeFilters(),
      detail = null,
      errorMessage = null;

  final bool loading;
  final bool loadingMore;
  final bool saving;
  final List<AdminDisputeSummary> items;
  final String? nextCursor;
  final AdminDisputeFilters filters;
  final AdminDisputeDetail? detail;
  final String? errorMessage;

  AdminDisputeState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? saving,
    List<AdminDisputeSummary>? items,
    String? nextCursor,
    AdminDisputeFilters? filters,
    AdminDisputeDetail? detail,
    String? errorMessage,
    bool clearError = false,
    bool clearCursor = false,
    bool clearDetail = false,
  }) {
    return AdminDisputeState(
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

class AdminDisputeController extends Notifier<AdminDisputeState> {
  @override
  AdminDisputeState build() {
    Future<void>(load);
    return const AdminDisputeState.loading();
  }

  AdminDisputeApi get _api => ref.read(adminDisputeApiProvider);

  Future<void> load({AdminDisputeFilters? filters}) async {
    if (!ref.mounted) {
      return;
    }
    final nextFilters = filters ?? state.filters;
    state = AdminDisputeState(loading: true, filters: nextFilters);
    try {
      final page = await _api.list(
        status: nextFilters.status,
        category: nextFilters.category,
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
      state = AdminDisputeState(
        loading: false,
        filters: nextFilters,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = AdminDisputeState(
        loading: false,
        filters: nextFilters,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> applyFilters(AdminDisputeFilters filters) {
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
        category: state.filters.category,
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

  Future<void> loadDetail(String disputeId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearDetail: true);
    try {
      final detail = await _api.get(disputeId);
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

  Future<bool> startReview(String disputeId) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final detail = await _api.markUnderReview(disputeId);
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

  Future<bool> resolve({
    required String disputeId,
    required String resolution,
  }) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final detail = await _api.resolve(
        disputeId: disputeId,
        resolution: resolution,
      );
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

  Future<bool> close(String disputeId) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final detail = await _api.close(disputeId);
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

final adminDisputeControllerProvider =
    NotifierProvider<AdminDisputeController, AdminDisputeState>(
      AdminDisputeController.new,
    );

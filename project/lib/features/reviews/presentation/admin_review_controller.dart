import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_api.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_models.dart';

class AdminReviewFilters {
  const AdminReviewFilters({this.status, this.rating});

  final String? status;
  final int? rating;

  AdminReviewFilters copyWith({
    String? status,
    int? rating,
    bool clearStatus = false,
    bool clearRating = false,
  }) {
    return AdminReviewFilters(
      status: clearStatus ? null : (status ?? this.status),
      rating: clearRating ? null : (rating ?? this.rating),
    );
  }
}

class AdminReviewState {
  const AdminReviewState({
    required this.loading,
    this.loadingMore = false,
    this.saving = false,
    this.items = const <AdminReviewSummary>[],
    this.nextCursor,
    this.filters = const AdminReviewFilters(),
    this.detail,
    this.errorMessage,
  });

  const AdminReviewState.loading()
    : loading = true,
      loadingMore = false,
      saving = false,
      items = const <AdminReviewSummary>[],
      nextCursor = null,
      filters = const AdminReviewFilters(),
      detail = null,
      errorMessage = null;

  final bool loading;
  final bool loadingMore;
  final bool saving;
  final List<AdminReviewSummary> items;
  final String? nextCursor;
  final AdminReviewFilters filters;
  final AdminReviewDetail? detail;
  final String? errorMessage;

  AdminReviewState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? saving,
    List<AdminReviewSummary>? items,
    String? nextCursor,
    AdminReviewFilters? filters,
    AdminReviewDetail? detail,
    String? errorMessage,
    bool clearError = false,
    bool clearCursor = false,
    bool clearDetail = false,
  }) {
    return AdminReviewState(
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

class AdminReviewController extends Notifier<AdminReviewState> {
  @override
  AdminReviewState build() {
    Future<void>(load);
    return const AdminReviewState.loading();
  }

  AdminReviewApi get _api => ref.read(adminReviewApiProvider);

  Future<void> load({AdminReviewFilters? filters}) async {
    if (!ref.mounted) {
      return;
    }
    final nextFilters = filters ?? state.filters;
    state = AdminReviewState(loading: true, filters: nextFilters);
    try {
      final page = await _api.list(
        status: nextFilters.status,
        rating: nextFilters.rating,
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
      state = AdminReviewState(
        loading: false,
        filters: nextFilters,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = AdminReviewState(
        loading: false,
        filters: nextFilters,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> applyFilters(AdminReviewFilters filters) {
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
        rating: state.filters.rating,
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

  Future<void> loadDetail(String reviewId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearDetail: true);
    try {
      final detail = await _api.get(reviewId);
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

  Future<bool> hide({required String reviewId, required String reason}) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final detail = await _api.hide(reviewId: reviewId, reason: reason);
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

  Future<bool> unhide(String reviewId) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final detail = await _api.unhide(reviewId);
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

final adminReviewControllerProvider =
    NotifierProvider<AdminReviewController, AdminReviewState>(
      AdminReviewController.new,
    );

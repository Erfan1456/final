import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_cleaner_api.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_cleaner_models.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';

/// Admin cleaner-review presentation state.
class AdminCleanerReviewState {
  /// Creates an explicit state.
  const AdminCleanerReviewState({
    required this.loading,
    this.statusFilter = 'pending',
    this.items = const <AdminCleanerApplicationSummary>[],
    this.nextCursor,
    this.detail,
    this.saving = false,
    this.errorMessage,
  });

  /// Initial pending list load.
  const AdminCleanerReviewState.loading()
    : loading = true,
      statusFilter = 'pending',
      items = const <AdminCleanerApplicationSummary>[],
      nextCursor = null,
      detail = null,
      saving = false,
      errorMessage = null;

  final bool loading;
  final String statusFilter;
  final List<AdminCleanerApplicationSummary> items;
  final String? nextCursor;
  final AdminCleanerApplicationDetail? detail;
  final bool saving;
  final String? errorMessage;

  AdminCleanerReviewState copyWith({
    bool? loading,
    String? statusFilter,
    List<AdminCleanerApplicationSummary>? items,
    String? nextCursor,
    AdminCleanerApplicationDetail? detail,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
    bool clearCursor = false,
    bool clearDetail = false,
  }) {
    return AdminCleanerReviewState(
      loading: loading ?? this.loading,
      statusFilter: statusFilter ?? this.statusFilter,
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      detail: clearDetail ? null : (detail ?? this.detail),
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Loads the admin approval queue and reviews applications.
class AdminCleanerReviewController extends Notifier<AdminCleanerReviewState> {
  @override
  AdminCleanerReviewState build() {
    Future<void>(load);
    return const AdminCleanerReviewState.loading();
  }

  AdminCleanerApi get _api => ref.read(adminCleanerApiProvider);

  /// Loads the first page for [status] or the current filter.
  Future<void> load({String? status}) async {
    if (!ref.mounted) {
      return;
    }
    final filter = status ?? state.statusFilter;
    state = state.copyWith(
      loading: true,
      statusFilter: filter,
      clearError: true,
      clearCursor: true,
    );
    try {
      final page = await _api.list(status: filter);
      if (!ref.mounted) {
        return;
      }
      state = AdminCleanerReviewState(
        loading: false,
        statusFilter: filter,
        items: page.items,
        nextCursor: page.nextCursor,
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = AdminCleanerReviewState(
        loading: false,
        statusFilter: filter,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = AdminCleanerReviewState(
        loading: false,
        statusFilter: filter,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Loads the next page when a cursor exists.
  Future<void> loadMore() async {
    if (!ref.mounted) {
      return;
    }
    final cursor = state.nextCursor;
    if (cursor == null || state.loading) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await _api.list(status: state.statusFilter, after: cursor);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
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

  /// Loads one application detail.
  Future<void> loadDetail(String userId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearDetail: true);
    try {
      final detail = await _api.get(userId);
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

  /// Approves the pending application and updates the queue.
  Future<bool> approve(String userId) {
    return _review(() => _api.approve(userId), userId);
  }

  /// Rejects the pending application and updates the queue.
  Future<bool> reject(String userId, String reason) {
    return _review(() => _api.reject(userId, reason), userId);
  }

  Future<bool> _review(
    Future<CleanerProfile> Function() action,
    String userId,
  ) async {
    if (!ref.mounted) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final profile = await action();
      if (!ref.mounted) {
        return false;
      }
      final remaining = [
        for (final item in state.items)
          if (item.userId != userId) item,
      ];
      final current = state.detail;
      state = state.copyWith(
        saving: false,
        items: remaining,
        detail: current == null
            ? null
            : AdminCleanerApplicationDetail(
                userId: current.userId,
                email: current.email,
                profile: profile,
              ),
      );
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

/// Admin cleaner-review controller.
final adminCleanerReviewControllerProvider =
    NotifierProvider<AdminCleanerReviewController, AdminCleanerReviewState>(
      AdminCleanerReviewController.new,
    );

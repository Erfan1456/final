import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_user_api.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_user_models.dart';

class AdminUserFilters {
  const AdminUserFilters({this.role, this.status, this.email});

  final String? role;
  final String? status;
  final String? email;

  AdminUserFilters copyWith({
    String? role,
    String? status,
    String? email,
    bool clearRole = false,
    bool clearStatus = false,
    bool clearEmail = false,
  }) {
    return AdminUserFilters(
      role: clearRole ? null : (role ?? this.role),
      status: clearStatus ? null : (status ?? this.status),
      email: clearEmail ? null : (email ?? this.email),
    );
  }
}

class AdminUserManagementState {
  const AdminUserManagementState({
    required this.loading,
    this.loadingMore = false,
    this.saving = false,
    this.items = const <AdminUserSummary>[],
    this.nextCursor,
    this.filters = const AdminUserFilters(),
    this.detail,
    this.errorMessage,
  });

  const AdminUserManagementState.loading()
    : loading = true,
      loadingMore = false,
      saving = false,
      items = const <AdminUserSummary>[],
      nextCursor = null,
      filters = const AdminUserFilters(),
      detail = null,
      errorMessage = null;

  final bool loading;
  final bool loadingMore;
  final bool saving;
  final List<AdminUserSummary> items;
  final String? nextCursor;
  final AdminUserFilters filters;
  final AdminUserDetail? detail;
  final String? errorMessage;

  AdminUserManagementState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? saving,
    List<AdminUserSummary>? items,
    String? nextCursor,
    AdminUserFilters? filters,
    AdminUserDetail? detail,
    String? errorMessage,
    bool clearError = false,
    bool clearCursor = false,
    bool clearDetail = false,
  }) {
    return AdminUserManagementState(
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

class AdminUserManagementController extends Notifier<AdminUserManagementState> {
  @override
  AdminUserManagementState build() {
    Future<void>(load);
    return const AdminUserManagementState.loading();
  }

  AdminUserApi get _api => ref.read(adminUserApiProvider);

  Future<void> load({AdminUserFilters? filters}) async {
    if (!ref.mounted) {
      return;
    }
    final nextFilters = filters ?? state.filters;
    state = AdminUserManagementState(loading: true, filters: nextFilters);
    try {
      final page = await _api.list(
        role: nextFilters.role,
        status: nextFilters.status,
        email: nextFilters.email,
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
      state = AdminUserManagementState(
        loading: false,
        filters: nextFilters,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = AdminUserManagementState(
        loading: false,
        filters: nextFilters,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> applyFilters(AdminUserFilters filters) {
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
        role: state.filters.role,
        status: state.filters.status,
        email: state.filters.email,
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

  Future<bool> suspend({required String userId, required String reason}) {
    return _mutate(() => _api.suspend(userId: userId, reason: reason));
  }

  Future<bool> reactivate(String userId) {
    return _mutate(() => _api.reactivate(userId));
  }

  Future<bool> deactivate({required String userId, required String reason}) {
    return _mutate(() => _api.deactivate(userId: userId, reason: reason));
  }

  Future<bool> _mutate(Future<AdminUserDetail> Function() action) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final detail = await action();
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

final adminUserManagementControllerProvider =
    NotifierProvider<AdminUserManagementController, AdminUserManagementState>(
      AdminUserManagementController.new,
    );

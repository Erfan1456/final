import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/admin/data/audit_api.dart';
import 'package:home_cleaning_marketplace/features/admin/data/audit_models.dart';

class AdminAuditFilters {
  const AdminAuditFilters({this.action, this.targetType});

  final String? action;
  final String? targetType;

  AdminAuditFilters copyWith({
    String? action,
    String? targetType,
    bool clearAction = false,
    bool clearTargetType = false,
  }) {
    return AdminAuditFilters(
      action: clearAction ? null : (action ?? this.action),
      targetType: clearTargetType ? null : (targetType ?? this.targetType),
    );
  }
}

class AdminAuditLogState {
  const AdminAuditLogState({
    required this.loading,
    this.loadingMore = false,
    this.items = const <AdminAuditLogSummary>[],
    this.nextCursor,
    this.filters = const AdminAuditFilters(),
    this.detail,
    this.errorMessage,
  });

  const AdminAuditLogState.loading()
    : loading = true,
      loadingMore = false,
      items = const <AdminAuditLogSummary>[],
      nextCursor = null,
      filters = const AdminAuditFilters(),
      detail = null,
      errorMessage = null;

  final bool loading;
  final bool loadingMore;
  final List<AdminAuditLogSummary> items;
  final String? nextCursor;
  final AdminAuditFilters filters;
  final AdminAuditLogDetail? detail;
  final String? errorMessage;

  AdminAuditLogState copyWith({
    bool? loading,
    bool? loadingMore,
    List<AdminAuditLogSummary>? items,
    String? nextCursor,
    AdminAuditFilters? filters,
    AdminAuditLogDetail? detail,
    String? errorMessage,
    bool clearError = false,
    bool clearCursor = false,
    bool clearDetail = false,
  }) {
    return AdminAuditLogState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      filters: filters ?? this.filters,
      detail: clearDetail ? null : (detail ?? this.detail),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AdminAuditLogController extends Notifier<AdminAuditLogState> {
  @override
  AdminAuditLogState build() {
    Future<void>(load);
    return const AdminAuditLogState.loading();
  }

  AdminAuditApi get _api => ref.read(adminAuditApiProvider);

  Future<void> load({AdminAuditFilters? filters}) async {
    if (!ref.mounted) {
      return;
    }
    final nextFilters = filters ?? state.filters;
    state = AdminAuditLogState(loading: true, filters: nextFilters);
    try {
      final page = await _api.list(
        action: nextFilters.action,
        targetType: nextFilters.targetType,
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
      state = AdminAuditLogState(
        loading: false,
        filters: nextFilters,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = AdminAuditLogState(
        loading: false,
        filters: nextFilters,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> applyFilters(AdminAuditFilters filters) {
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
        action: state.filters.action,
        targetType: state.filters.targetType,
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

  Future<void> loadDetail(String auditLogId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearDetail: true);
    try {
      final detail = await _api.get(auditLogId);
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
}

final adminAuditLogControllerProvider =
    NotifierProvider<AdminAuditLogController, AdminAuditLogState>(
      AdminAuditLogController.new,
    );

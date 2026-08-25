import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_finance_models.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_payout_api.dart';

class AdminFinanceState {
  const AdminFinanceState({
    required this.loading,
    this.loadingMore = false,
    this.summary,
    this.issues = const <FinanceReconciliationIssue>[],
    this.nextCursor,
    this.cleanerFinance,
    this.currency,
    this.from,
    this.to,
    this.errorMessage,
  });

  const AdminFinanceState.loading()
    : loading = true,
      loadingMore = false,
      summary = null,
      issues = const <FinanceReconciliationIssue>[],
      nextCursor = null,
      cleanerFinance = null,
      currency = null,
      from = null,
      to = null,
      errorMessage = null;

  final bool loading;
  final bool loadingMore;
  final AdminFinanceSummary? summary;
  final List<FinanceReconciliationIssue> issues;
  final String? nextCursor;
  final AdminCleanerFinanceDetail? cleanerFinance;
  final String? currency;
  final String? from;
  final String? to;
  final String? errorMessage;

  AdminFinanceState copyWith({
    bool? loading,
    bool? loadingMore,
    AdminFinanceSummary? summary,
    List<FinanceReconciliationIssue>? issues,
    String? nextCursor,
    AdminCleanerFinanceDetail? cleanerFinance,
    String? currency,
    String? from,
    String? to,
    String? errorMessage,
    bool clearError = false,
    bool clearCursor = false,
    bool clearCleaner = false,
  }) {
    return AdminFinanceState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      summary: summary ?? this.summary,
      issues: issues ?? this.issues,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      cleanerFinance: clearCleaner
          ? null
          : (cleanerFinance ?? this.cleanerFinance),
      currency: currency ?? this.currency,
      from: from ?? this.from,
      to: to ?? this.to,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AdminFinanceController extends Notifier<AdminFinanceState> {
  @override
  AdminFinanceState build() {
    Future<void>(loadSummary);
    return const AdminFinanceState.loading();
  }

  AdminFinanceApi get _api => ref.read(adminFinanceApiProvider);

  Future<void> loadSummary({String? from, String? to, String? currency}) async {
    if (!ref.mounted) {
      return;
    }
    state = AdminFinanceState(
      loading: true,
      from: from ?? state.from,
      to: to ?? state.to,
      currency: currency ?? state.currency,
      issues: state.issues,
    );
    try {
      final summary = await _api.getSummary(
        from: from ?? state.from,
        to: to ?? state.to,
        currency: currency ?? state.currency,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        summary: summary,
        from: from ?? state.from,
        to: to ?? state.to,
        currency: currency ?? state.currency,
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = AdminFinanceState(loading: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = const AdminFinanceState(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> loadReconciliation({String? currency}) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearCursor: true);
    try {
      final page = await _api.getReconciliation(currency: currency);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        issues: page.items,
        nextCursor: page.nextCursor,
        currency: currency ?? state.currency,
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

  Future<void> loadMoreReconciliation() async {
    if (!ref.mounted) {
      return;
    }
    final cursor = state.nextCursor;
    if (cursor == null || state.loading || state.loadingMore) {
      return;
    }
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final page = await _api.getReconciliation(
        currency: state.currency,
        after: cursor,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        issues: [...state.issues, ...page.items],
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

  Future<void> loadCleanerFinance(String userId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearCleaner: true);
    try {
      final detail = await _api.getCleanerFinance(userId);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false, cleanerFinance: detail);
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

final adminFinanceControllerProvider =
    NotifierProvider<AdminFinanceController, AdminFinanceState>(
      AdminFinanceController.new,
    );

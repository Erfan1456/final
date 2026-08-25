import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_api.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_models.dart';

class CleanerReviewsState {
  const CleanerReviewsState({
    required this.loading,
    this.loadingMore = false,
    this.items = const <CleanerReview>[],
    this.nextCursor,
    this.status,
    this.errorMessage,
  });

  const CleanerReviewsState.loading()
    : loading = true,
      loadingMore = false,
      items = const <CleanerReview>[],
      nextCursor = null,
      status = null,
      errorMessage = null;

  final bool loading;
  final bool loadingMore;
  final List<CleanerReview> items;
  final String? nextCursor;
  final String? status;
  final String? errorMessage;

  CleanerReviewsState copyWith({
    bool? loading,
    bool? loadingMore,
    List<CleanerReview>? items,
    String? nextCursor,
    String? status,
    String? errorMessage,
    bool clearError = false,
    bool clearCursor = false,
    bool clearStatus = false,
  }) {
    return CleanerReviewsState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      status: clearStatus ? null : (status ?? this.status),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CleanerReviewsController extends Notifier<CleanerReviewsState> {
  @override
  CleanerReviewsState build() {
    Future<void>(load);
    return const CleanerReviewsState.loading();
  }

  CleanerReviewApi get _api => ref.read(cleanerReviewApiProvider);

  Future<void> load({String? status, bool clearStatus = false}) async {
    if (!ref.mounted) {
      return;
    }
    final nextStatus = clearStatus ? null : (status ?? state.status);
    state = CleanerReviewsState(loading: true, status: nextStatus);
    try {
      final page = await _api.list(status: nextStatus);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        items: page.items,
        nextCursor: page.nextCursor,
        status: nextStatus,
        clearCursor: page.nextCursor == null,
        clearStatus: nextStatus == null,
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = CleanerReviewsState(
        loading: false,
        status: nextStatus,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = CleanerReviewsState(
        loading: false,
        status: nextStatus,
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
      final page = await _api.list(status: state.status, after: cursor);
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
}

final cleanerReviewsControllerProvider =
    NotifierProvider<CleanerReviewsController, CleanerReviewsState>(
      CleanerReviewsController.new,
    );

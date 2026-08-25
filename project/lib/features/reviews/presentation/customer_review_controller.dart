import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_api.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_models.dart';

class CustomerReviewState {
  const CustomerReviewState({
    required this.loading,
    this.saving = false,
    this.review,
    this.errorMessage,
  });

  const CustomerReviewState.idle()
    : loading = false,
      saving = false,
      review = null,
      errorMessage = null;

  final bool loading;
  final bool saving;
  final CustomerReview? review;
  final String? errorMessage;

  CustomerReviewState copyWith({
    bool? loading,
    bool? saving,
    CustomerReview? review,
    String? errorMessage,
    bool clearError = false,
    bool clearReview = false,
  }) {
    return CustomerReviewState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      review: clearReview ? null : (review ?? this.review),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CustomerReviewController extends Notifier<CustomerReviewState> {
  @override
  CustomerReviewState build() => const CustomerReviewState.idle();

  CustomerReviewApi get _api => ref.read(customerReviewApiProvider);

  Future<void> load(String bookingId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearReview: true);
    try {
      final review = await _api.getForBooking(bookingId);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false, review: review);
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      if (error.code == 'review_not_allowed') {
        state = state.copyWith(loading: false, clearReview: true);
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

  Future<bool> save({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final review = await _api.upsertForBooking(
        bookingId: bookingId,
        rating: rating,
        comment: comment,
      );
      if (!ref.mounted) {
        return true;
      }
      state = state.copyWith(saving: false, review: review);
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

final customerReviewControllerProvider =
    NotifierProvider<CustomerReviewController, CustomerReviewState>(
      CustomerReviewController.new,
    );

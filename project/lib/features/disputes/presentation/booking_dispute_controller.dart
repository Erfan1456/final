import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_api.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_models.dart';

class BookingDisputeState {
  const BookingDisputeState({
    required this.loading,
    this.saving = false,
    this.dispute,
    this.errorMessage,
  });

  const BookingDisputeState.loading()
    : loading = true,
      saving = false,
      dispute = null,
      errorMessage = null;

  final bool loading;
  final bool saving;
  final BookingDispute? dispute;
  final String? errorMessage;

  BookingDisputeState copyWith({
    bool? loading,
    bool? saving,
    BookingDispute? dispute,
    String? errorMessage,
    bool clearError = false,
    bool clearDispute = false,
  }) {
    return BookingDisputeState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      dispute: clearDispute ? null : (dispute ?? this.dispute),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BookingDisputeController extends Notifier<BookingDisputeState> {
  @override
  BookingDisputeState build() => const BookingDisputeState(loading: false);

  BookingDisputeApi get _api => ref.read(bookingDisputeApiProvider);

  Future<void> load(String bookingId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearDispute: true);
    try {
      final dispute = await _api.getForBooking(bookingId);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false, dispute: dispute);
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

  Future<bool> create({
    required String bookingId,
    required String category,
    required String subject,
    required String description,
  }) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final dispute = await _api.create(
        bookingId: bookingId,
        category: category,
        subject: subject,
        description: description,
      );
      if (!ref.mounted) {
        return true;
      }
      state = state.copyWith(saving: false, dispute: dispute);
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

  Future<bool> close(String bookingId) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final dispute = await _api.close(bookingId);
      if (!ref.mounted) {
        return true;
      }
      state = state.copyWith(saving: false, dispute: dispute);
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

final bookingDisputeControllerProvider =
    NotifierProvider<BookingDisputeController, BookingDisputeState>(
      BookingDisputeController.new,
    );

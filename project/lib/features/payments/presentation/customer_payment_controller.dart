import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_idempotency.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_api.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';

class CustomerPaymentState {
  const CustomerPaymentState({
    required this.loading,
    this.submitting = false,
    this.history,
    this.errorMessage,
    this.idempotencyKey,
  });

  const CustomerPaymentState.idle()
    : loading = false,
      submitting = false,
      history = null,
      errorMessage = null,
      idempotencyKey = null;

  final bool loading;
  final bool submitting;
  final PaymentHistory? history;
  final String? errorMessage;
  final String? idempotencyKey;

  PaymentAttempt? get current => history?.current;

  CustomerPaymentState copyWith({
    bool? loading,
    bool? submitting,
    PaymentHistory? history,
    String? errorMessage,
    String? idempotencyKey,
    bool clearError = false,
    bool clearHistory = false,
  }) {
    return CustomerPaymentState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      history: clearHistory ? null : (history ?? this.history),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }
}

class CustomerPaymentController extends Notifier<CustomerPaymentState> {
  @override
  CustomerPaymentState build() => const CustomerPaymentState.idle();

  CustomerPaymentApi get _api => ref.read(customerPaymentApiProvider);

  SandboxPaymentApi get _sandbox => ref.read(sandboxPaymentApiProvider);

  void beginAttempt({String Function()? keyFactory}) {
    state = state.copyWith(
      submitting: false,
      idempotencyKey: (keyFactory ?? generateBookingIdempotencyKey)(),
      clearError: true,
    );
  }

  Future<void> load(String bookingId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      loading: true,
      submitting: false,
      clearError: true,
      clearHistory: true,
    );
    try {
      final history = await _api.getPayment(bookingId);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false, history: history);
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

  Future<PaymentAttempt?> startPayment(
    String bookingId, {
    String Function()? keyFactory,
  }) async {
    if (!ref.mounted || state.submitting) {
      return state.current;
    }
    final key =
        state.idempotencyKey ?? (keyFactory ?? generateBookingIdempotencyKey)();
    state = state.copyWith(
      submitting: true,
      idempotencyKey: key,
      clearError: true,
    );
    try {
      final payment = await _api.startPayment(
        bookingId: bookingId,
        idempotencyKey: key,
      );
      if (!ref.mounted) {
        return payment;
      }
      await load(bookingId);
      return payment;
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return null;
      }
      state = state.copyWith(submitting: false, errorMessage: error.message);
      return null;
    } catch (_) {
      if (!ref.mounted) {
        return null;
      }
      state = state.copyWith(
        submitting: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return null;
    }
  }

  Future<PaymentAttempt?> retryPayment(String bookingId) {
    beginAttempt();
    return startPayment(bookingId);
  }

  Future<bool> cancelPayment(String bookingId) async {
    if (!ref.mounted || state.submitting) {
      return false;
    }
    state = state.copyWith(submitting: true, clearError: true);
    try {
      await _api.cancelPayment(bookingId);
      if (!ref.mounted) {
        return true;
      }
      await load(bookingId);
      return true;
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(submitting: false, errorMessage: error.message);
      return false;
    } catch (_) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        submitting: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<bool> simulateSuccess(String bookingId, String paymentId) {
    return _simulate(bookingId, () => _sandbox.simulateSuccess(paymentId));
  }

  Future<bool> simulateFailure(String bookingId, String paymentId) {
    return _simulate(bookingId, () => _sandbox.simulateFailure(paymentId));
  }

  Future<bool> _simulate(
    String bookingId,
    Future<PaymentAttempt> Function() action,
  ) async {
    if (!ref.mounted || state.submitting) {
      return false;
    }
    state = state.copyWith(submitting: true, clearError: true);
    try {
      await action();
      if (!ref.mounted) {
        return true;
      }
      await load(bookingId);
      return true;
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(submitting: false, errorMessage: error.message);
      return false;
    } catch (_) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        submitting: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }
}

final customerPaymentControllerProvider =
    NotifierProvider<CustomerPaymentController, CustomerPaymentState>(
      CustomerPaymentController.new,
    );

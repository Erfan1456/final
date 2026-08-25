import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_idempotency.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_api.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';

class AdminPaymentFilters {
  const AdminPaymentFilters({this.status, this.provider, this.currency});

  final String? status;
  final String? provider;
  final String? currency;

  AdminPaymentFilters copyWith({
    String? status,
    String? provider,
    String? currency,
    bool clearStatus = false,
    bool clearProvider = false,
    bool clearCurrency = false,
  }) {
    return AdminPaymentFilters(
      status: clearStatus ? null : (status ?? this.status),
      provider: clearProvider ? null : (provider ?? this.provider),
      currency: clearCurrency ? null : (currency ?? this.currency),
    );
  }
}

class AdminPaymentState {
  const AdminPaymentState({
    required this.loading,
    this.loadingMore = false,
    this.saving = false,
    this.items = const <AdminPaymentSummary>[],
    this.nextCursor,
    this.filters = const AdminPaymentFilters(),
    this.detail,
    this.events = const <PaymentWebhookEventSummary>[],
    this.errorMessage,
    this.refundIdempotencyKey,
  });

  const AdminPaymentState.loading()
    : loading = true,
      loadingMore = false,
      saving = false,
      items = const <AdminPaymentSummary>[],
      nextCursor = null,
      filters = const AdminPaymentFilters(),
      detail = null,
      events = const <PaymentWebhookEventSummary>[],
      errorMessage = null,
      refundIdempotencyKey = null;

  final bool loading;
  final bool loadingMore;
  final bool saving;
  final List<AdminPaymentSummary> items;
  final String? nextCursor;
  final AdminPaymentFilters filters;
  final AdminPaymentDetail? detail;
  final List<PaymentWebhookEventSummary> events;
  final String? errorMessage;
  final String? refundIdempotencyKey;

  AdminPaymentState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? saving,
    List<AdminPaymentSummary>? items,
    String? nextCursor,
    AdminPaymentFilters? filters,
    AdminPaymentDetail? detail,
    List<PaymentWebhookEventSummary>? events,
    String? errorMessage,
    String? refundIdempotencyKey,
    bool clearError = false,
    bool clearCursor = false,
    bool clearDetail = false,
  }) {
    return AdminPaymentState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      saving: saving ?? this.saving,
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      filters: filters ?? this.filters,
      detail: clearDetail ? null : (detail ?? this.detail),
      events: events ?? this.events,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      refundIdempotencyKey: refundIdempotencyKey ?? this.refundIdempotencyKey,
    );
  }
}

class AdminPaymentController extends Notifier<AdminPaymentState> {
  @override
  AdminPaymentState build() {
    Future<void>(load);
    return const AdminPaymentState.loading();
  }

  AdminPaymentApi get _api => ref.read(adminPaymentApiProvider);

  void beginRefundAttempt({String Function()? keyFactory}) {
    state = state.copyWith(
      refundIdempotencyKey: (keyFactory ?? generateBookingIdempotencyKey)(),
      clearError: true,
    );
  }

  Future<void> load({AdminPaymentFilters? filters}) async {
    if (!ref.mounted) {
      return;
    }
    final nextFilters = filters ?? state.filters;
    state = AdminPaymentState(
      loading: true,
      filters: nextFilters,
      refundIdempotencyKey: state.refundIdempotencyKey,
    );
    try {
      final page = await _api.list(
        status: nextFilters.status,
        provider: nextFilters.provider,
        currency: nextFilters.currency,
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
      state = AdminPaymentState(
        loading: false,
        filters: nextFilters,
        errorMessage: error.message,
        refundIdempotencyKey: state.refundIdempotencyKey,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = AdminPaymentState(
        loading: false,
        filters: nextFilters,
        errorMessage: 'Something went wrong. Please try again.',
        refundIdempotencyKey: state.refundIdempotencyKey,
      );
    }
  }

  Future<void> applyFilters(AdminPaymentFilters filters) {
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
        provider: state.filters.provider,
        currency: state.filters.currency,
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

  Future<void> loadDetail(String paymentId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearDetail: true);
    try {
      final detail = await _api.get(paymentId);
      final events = await _api.events(paymentId);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false, detail: detail, events: events);
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

  Future<bool> refund({
    required String paymentId,
    required String reason,
    int? amountMinor,
    String Function()? keyFactory,
  }) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    final key =
        state.refundIdempotencyKey ??
        (keyFactory ?? generateBookingIdempotencyKey)();
    state = state.copyWith(
      saving: true,
      refundIdempotencyKey: key,
      clearError: true,
    );
    try {
      final detail = await _api.refund(
        paymentId: paymentId,
        idempotencyKey: key,
        reason: reason,
        amountMinor: amountMinor,
      );
      if (!ref.mounted) {
        return true;
      }
      state = state.copyWith(
        saving: false,
        detail: detail,
        events: detail.events,
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

final adminPaymentControllerProvider =
    NotifierProvider<AdminPaymentController, AdminPaymentState>(
      AdminPaymentController.new,
    );

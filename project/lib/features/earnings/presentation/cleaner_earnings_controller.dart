import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_identity.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_idempotency.dart';
import 'package:home_cleaning_marketplace/features/earnings/data/earnings_api.dart';
import 'package:home_cleaning_marketplace/features/earnings/data/earnings_models.dart';

class CleanerEarningsState {
  const CleanerEarningsState({
    required this.loading,
    this.loadingMore = false,
    this.saving = false,
    this.summary,
    this.selectedCurrency,
    this.ledger = const <EarningsLedgerEntry>[],
    this.ledgerCursor,
    this.payouts = const <CleanerPayout>[],
    this.payoutsCursor,
    this.errorMessage,
    this.requestIdempotencyKey,
  });

  const CleanerEarningsState.loading()
    : loading = true,
      loadingMore = false,
      saving = false,
      summary = null,
      selectedCurrency = null,
      ledger = const <EarningsLedgerEntry>[],
      ledgerCursor = null,
      payouts = const <CleanerPayout>[],
      payoutsCursor = null,
      errorMessage = null,
      requestIdempotencyKey = null;

  final bool loading;
  final bool loadingMore;
  final bool saving;
  final EarningsSummary? summary;
  final String? selectedCurrency;
  final List<EarningsLedgerEntry> ledger;
  final String? ledgerCursor;
  final List<CleanerPayout> payouts;
  final String? payoutsCursor;
  final String? errorMessage;
  final String? requestIdempotencyKey;

  CleanerCurrencyEarningsSummary? get selectedSummary {
    final currencies =
        summary?.currencies ?? const <CleanerCurrencyEarningsSummary>[];
    if (currencies.isEmpty) {
      return null;
    }
    for (final item in currencies) {
      if (item.currencyCode == selectedCurrency) {
        return item;
      }
    }
    return currencies.first;
  }

  CleanerEarningsState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? saving,
    EarningsSummary? summary,
    String? selectedCurrency,
    List<EarningsLedgerEntry>? ledger,
    String? ledgerCursor,
    List<CleanerPayout>? payouts,
    String? payoutsCursor,
    String? errorMessage,
    String? requestIdempotencyKey,
    bool clearError = false,
    bool clearLedgerCursor = false,
    bool clearPayoutsCursor = false,
  }) {
    return CleanerEarningsState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      saving: saving ?? this.saving,
      summary: summary ?? this.summary,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      ledger: ledger ?? this.ledger,
      ledgerCursor: clearLedgerCursor
          ? null
          : (ledgerCursor ?? this.ledgerCursor),
      payouts: payouts ?? this.payouts,
      payoutsCursor: clearPayoutsCursor
          ? null
          : (payoutsCursor ?? this.payoutsCursor),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      requestIdempotencyKey:
          requestIdempotencyKey ?? this.requestIdempotencyKey,
    );
  }
}

class CleanerEarningsController extends Notifier<CleanerEarningsState> {
  @override
  CleanerEarningsState build() {
    watchAuthIdentityKey(ref);
    if (!watchHasAuthSession(ref)) {
      return const CleanerEarningsState(loading: false);
    }
    Future<void>(load);
    return const CleanerEarningsState.loading();
  }

  CleanerEarningsApi get _api => ref.read(cleanerEarningsApiProvider);

  Future<void> load() async {
    if (!ref.mounted) {
      return;
    }
    state = const CleanerEarningsState.loading();
    try {
      final summary = await _api.getSummary();
      final currency = summary.currencies.isEmpty
          ? null
          : summary.currencies.first.currencyCode;
      final ledger = await _api.getLedger(currency: currency);
      final payouts = await _api.listPayouts(currency: currency);
      if (!ref.mounted) {
        return;
      }
      state = CleanerEarningsState(
        loading: false,
        summary: summary,
        selectedCurrency: currency,
        ledger: ledger.items,
        ledgerCursor: ledger.nextCursor,
        payouts: payouts.items,
        payoutsCursor: payouts.nextCursor,
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = CleanerEarningsState(loading: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = const CleanerEarningsState(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> selectCurrency(String currencyCode) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      loading: true,
      selectedCurrency: currencyCode,
      clearError: true,
    );
    try {
      final ledger = await _api.getLedger(currency: currencyCode);
      final payouts = await _api.listPayouts(currency: currencyCode);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        selectedCurrency: currencyCode,
        ledger: ledger.items,
        ledgerCursor: ledger.nextCursor,
        payouts: payouts.items,
        payoutsCursor: payouts.nextCursor,
        clearLedgerCursor: ledger.nextCursor == null,
        clearPayoutsCursor: payouts.nextCursor == null,
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

  Future<void> loadMoreLedger() async {
    if (!ref.mounted) {
      return;
    }
    final cursor = state.ledgerCursor;
    if (cursor == null || state.loading || state.loadingMore) {
      return;
    }
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final page = await _api.getLedger(
        currency: state.selectedCurrency,
        after: cursor,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        ledger: [...state.ledger, ...page.items],
        ledgerCursor: page.nextCursor,
        clearLedgerCursor: page.nextCursor == null,
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

  Future<void> loadMorePayouts() async {
    if (!ref.mounted) {
      return;
    }
    final cursor = state.payoutsCursor;
    if (cursor == null || state.loading || state.loadingMore) {
      return;
    }
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final page = await _api.listPayouts(
        currency: state.selectedCurrency,
        after: cursor,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        payouts: [...state.payouts, ...page.items],
        payoutsCursor: page.nextCursor,
        clearPayoutsCursor: page.nextCursor == null,
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

  void beginPayoutRequest({String Function()? keyFactory}) {
    state = state.copyWith(
      requestIdempotencyKey: (keyFactory ?? generateBookingIdempotencyKey)(),
      clearError: true,
    );
  }

  Future<bool> requestPayout({
    required int amountMinor,
    required String currencyCode,
    String Function()? keyFactory,
  }) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    final key =
        state.requestIdempotencyKey ??
        (keyFactory ?? generateBookingIdempotencyKey)();
    state = state.copyWith(
      saving: true,
      requestIdempotencyKey: key,
      clearError: true,
    );
    try {
      await _api.requestPayout(
        amountMinor: amountMinor,
        currencyCode: currencyCode,
        idempotencyKey: key,
      );
      if (!ref.mounted) {
        return true;
      }
      state = state.copyWith(saving: false);
      await load();
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

  Future<bool> cancelPayout(String payoutId) async {
    if (!ref.mounted || state.saving) {
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _api.cancelPayout(payoutId);
      if (!ref.mounted) {
        return true;
      }
      state = state.copyWith(saving: false);
      await load();
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

final cleanerEarningsControllerProvider =
    NotifierProvider<CleanerEarningsController, CleanerEarningsState>(
      CleanerEarningsController.new,
    );

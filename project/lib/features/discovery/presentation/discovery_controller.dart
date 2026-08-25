import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/discovery/data/cleaner_discovery_models.dart';
import 'package:home_cleaning_marketplace/features/discovery/data/discovery_api.dart';

class DiscoveryFilters {
  const DiscoveryFilters({
    this.service = 'home-cleaning',
    this.currency,
    this.maxRateMinor,
    this.minExperience,
    this.availableFrom,
    this.availableTo,
  });

  final String service;
  final String? currency;
  final int? maxRateMinor;
  final int? minExperience;
  final String? availableFrom;
  final String? availableTo;

  DiscoveryFilters copyWith({
    String? service,
    String? currency,
    int? maxRateMinor,
    int? minExperience,
    String? availableFrom,
    String? availableTo,
    bool clearCurrency = false,
    bool clearMaxRate = false,
    bool clearMinExperience = false,
    bool clearAvailability = false,
  }) {
    return DiscoveryFilters(
      service: service ?? this.service,
      currency: clearCurrency ? null : (currency ?? this.currency),
      maxRateMinor: clearMaxRate ? null : (maxRateMinor ?? this.maxRateMinor),
      minExperience: clearMinExperience
          ? null
          : (minExperience ?? this.minExperience),
      availableFrom: clearAvailability
          ? null
          : (availableFrom ?? this.availableFrom),
      availableTo: clearAvailability ? null : (availableTo ?? this.availableTo),
    );
  }
}

class DiscoveryState {
  const DiscoveryState({
    required this.loading,
    this.loadingMore = false,
    this.items = const <CleanerDiscoverySummary>[],
    this.nextCursor,
    this.filters = const DiscoveryFilters(),
    this.detail,
    this.errorMessage,
  });

  const DiscoveryState.loading()
    : loading = true,
      loadingMore = false,
      items = const <CleanerDiscoverySummary>[],
      nextCursor = null,
      filters = const DiscoveryFilters(),
      detail = null,
      errorMessage = null;

  final bool loading;
  final bool loadingMore;
  final List<CleanerDiscoverySummary> items;
  final String? nextCursor;
  final DiscoveryFilters filters;
  final CleanerDiscoveryDetail? detail;
  final String? errorMessage;

  DiscoveryState copyWith({
    bool? loading,
    bool? loadingMore,
    List<CleanerDiscoverySummary>? items,
    String? nextCursor,
    DiscoveryFilters? filters,
    CleanerDiscoveryDetail? detail,
    String? errorMessage,
    bool clearError = false,
    bool clearCursor = false,
    bool clearDetail = false,
  }) {
    return DiscoveryState(
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

class DiscoveryController extends Notifier<DiscoveryState> {
  @override
  DiscoveryState build() {
    Future<void>(load);
    return const DiscoveryState.loading();
  }

  Future<void> load({DiscoveryFilters? filters}) async {
    if (!ref.mounted) {
      return;
    }
    final nextFilters = filters ?? state.filters;
    state = DiscoveryState(loading: true, filters: nextFilters);
    try {
      final page = await _page(nextFilters);
      if (!ref.mounted) {
        return;
      }
      state = DiscoveryState(
        loading: false,
        items: page.items,
        nextCursor: page.nextCursor,
        filters: nextFilters,
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = DiscoveryState(
        loading: false,
        filters: nextFilters,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = DiscoveryState(
        loading: false,
        filters: nextFilters,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> applyFilters(DiscoveryFilters filters) {
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
      final page = await _page(state.filters, after: cursor);
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

  Future<void> loadDetail(String cleanerUserId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearDetail: true);
    try {
      final detail = await ref
          .read(discoveryApiProvider)
          .getCleanerDetail(
            cleanerUserId: cleanerUserId,
            service: state.filters.service,
          );
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

  Future<CleanerDiscoveryPage> _page(
    DiscoveryFilters filters, {
    String? after,
  }) {
    return ref
        .read(discoveryApiProvider)
        .listCleaners(
          service: filters.service,
          currency: filters.currency,
          maxRateMinor: filters.maxRateMinor,
          minExperience: filters.minExperience,
          availableFrom: filters.availableFrom,
          availableTo: filters.availableTo,
          after: after,
        );
  }
}

final discoveryControllerProvider =
    NotifierProvider<DiscoveryController, DiscoveryState>(
      DiscoveryController.new,
    );

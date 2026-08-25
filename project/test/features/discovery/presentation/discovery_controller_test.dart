import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/discovery/data/cleaner_discovery_models.dart';
import 'package:home_cleaning_marketplace/features/discovery/data/discovery_api.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/comparison_controller.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/discovery_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeDiscoveryApi extends DiscoveryApi {
  _FakeDiscoveryApi() : super(Dio());

  CleanerDiscoveryPage firstPage = const CleanerDiscoveryPage(items: []);
  CleanerDiscoveryPage morePage = const CleanerDiscoveryPage(items: []);
  CleanerDiscoveryDetail? detail;
  ApiFailure? nextError;
  int listCalls = 0;
  int moreCalls = 0;
  String? lastAfter;
  DiscoveryFilters? lastFilters;
  bool gateMore = false;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<CleanerDiscoveryPage> listCleaners({
    String? service,
    String? currency,
    int? maxRateMinor,
    int? minExperience,
    String? availableFrom,
    String? availableTo,
    int? limit,
    String? after,
  }) async {
    if (after != null) {
      moreCalls += 1;
      lastAfter = after;
      if (gateMore) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    } else {
      listCalls += 1;
    }
    _throwIfNeeded();
    lastFilters = DiscoveryFilters(
      service: service ?? 'home-cleaning',
      currency: currency,
      maxRateMinor: maxRateMinor,
      minExperience: minExperience,
      availableFrom: availableFrom,
      availableTo: availableTo,
    );
    return after == null ? firstPage : morePage;
  }

  @override
  Future<CleanerDiscoveryDetail> getCleanerDetail({
    required String cleanerUserId,
    String? service,
  }) async {
    _throwIfNeeded();
    return detail ?? testDiscoveryDetail(cleanerUserId: cleanerUserId);
  }
}

void main() {
  late _FakeDiscoveryApi api;
  late ProviderContainer container;

  setUp(() {
    api = _FakeDiscoveryApi();
    container = ProviderContainer(
      overrides: [discoveryApiProvider.overrideWithValue(api)],
    );
  });

  tearDown(() => container.dispose());

  Future<DiscoveryState> settle() async {
    container.listen(discoveryControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container.read(discoveryControllerProvider);
  }

  test('first page loads items and cursor', () async {
    api.firstPage = CleanerDiscoveryPage(
      items: [testDiscoverySummary()],
      nextCursor: 'cursor-1',
    );
    final state = await settle();
    expect(state.items, hasLength(1));
    expect(state.nextCursor, equals('cursor-1'));
    expect(api.listCalls, equals(1));
  });

  test('applying filters reloads from the beginning', () async {
    api.firstPage = CleanerDiscoveryPage(items: [testDiscoverySummary()]);
    await settle();
    await container
        .read(discoveryControllerProvider.notifier)
        .applyFilters(
          const DiscoveryFilters(service: 'home-cleaning', currency: 'USD'),
        );
    await pumpEventQueue();
    expect(api.listCalls, equals(2));
    expect(api.lastAfter, isNull);
    expect(api.lastFilters?.currency, equals('USD'));
    expect(container.read(discoveryControllerProvider).items, hasLength(1));
  });

  test('load more appends the next page once', () async {
    api.firstPage = CleanerDiscoveryPage(
      items: [testDiscoverySummary()],
      nextCursor: 'cursor-1',
    );
    api.morePage = CleanerDiscoveryPage(
      items: [
        testDiscoverySummary(
          cleanerUserId: '507f1f77bcf86cd799439082',
          fullName: 'Bea Cleaner',
        ),
      ],
    );
    await settle();
    await container.read(discoveryControllerProvider.notifier).loadMore();
    await pumpEventQueue();
    expect(api.moreCalls, equals(1));
    expect(container.read(discoveryControllerProvider).items, hasLength(2));
    expect(container.read(discoveryControllerProvider).nextCursor, isNull);
  });

  test('load more ignores a duplicate concurrent request', () async {
    api.gateMore = true;
    api.firstPage = CleanerDiscoveryPage(
      items: [testDiscoverySummary()],
      nextCursor: 'cursor-1',
    );
    api.morePage = const CleanerDiscoveryPage(items: []);
    await settle();
    final notifier = container.read(discoveryControllerProvider.notifier);
    final first = notifier.loadMore();
    final second = notifier.loadMore();
    await Future.wait(<Future<void>>[first, second]);
    expect(api.moreCalls, equals(1));
  });

  test('empty result is not an error', () async {
    final state = await settle();
    expect(state.items, isEmpty);
    expect(state.errorMessage, isNull);
  });

  test('list error is a safe message', () async {
    api.nextError = ApiFailure(
      code: 'invalid_availability_window',
      message: messageForApiCode('invalid_availability_window'),
    );
    final state = await settle();
    expect(state.errorMessage, equals('The availability window is invalid.'));
  });

  test('comparison allows at most three unique cleaners', () {
    final comparison = ProviderContainer();
    addTearDown(comparison.dispose);
    comparison.listen(comparisonControllerProvider, (_, _) {});
    final notifier = comparison.read(comparisonControllerProvider.notifier);
    expect(notifier.add(testDiscoverySummary()), ComparisonAddResult.added);
    expect(
      notifier.add(testDiscoverySummary()),
      ComparisonAddResult.alreadySelected,
    );
    expect(
      notifier.add(testDiscoverySummary(cleanerUserId: '2', fullName: 'Bea')),
      ComparisonAddResult.added,
    );
    expect(
      notifier.add(testDiscoverySummary(cleanerUserId: '3', fullName: 'Cara')),
      ComparisonAddResult.added,
    );
    expect(
      notifier.add(testDiscoverySummary(cleanerUserId: '4', fullName: 'Dee')),
      ComparisonAddResult.atCapacity,
    );
    expect(comparison.read(comparisonControllerProvider).items, hasLength(3));
  });
}

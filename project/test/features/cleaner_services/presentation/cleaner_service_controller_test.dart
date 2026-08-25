import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/data/cleaner_service_api.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/data/cleaner_service_offering.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/presentation/cleaner_service_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeCleanerServiceApi extends CleanerServiceApi {
  _FakeCleanerServiceApi() : super(Dio());

  List<CleanerServiceOffering> items = <CleanerServiceOffering>[];
  ApiFailure? nextError;
  int listCalls = 0;
  int upsertCalls = 0;
  int deactivateCalls = 0;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<List<CleanerServiceOffering>> list() async {
    listCalls += 1;
    _throwIfNeeded();
    return items;
  }

  @override
  Future<CleanerServiceOffering> upsert({
    required String serviceId,
    required int hourlyRateMinor,
    required String currencyCode,
    required bool isActive,
  }) async {
    upsertCalls += 1;
    _throwIfNeeded();
    final offering = CleanerServiceOffering.fromJson(
      cleanerOfferingJson(isActive: isActive),
    );
    items = [offering];
    return offering;
  }

  @override
  Future<CleanerServiceOffering> deactivate(String serviceId) async {
    deactivateCalls += 1;
    _throwIfNeeded();
    final offering = CleanerServiceOffering.fromJson(
      cleanerOfferingJson(isActive: false),
    );
    items = [offering];
    return offering;
  }
}

void main() {
  late _FakeCleanerServiceApi api;
  late ProviderContainer container;

  setUp(() {
    api = _FakeCleanerServiceApi();
    container = ProviderContainer(
      overrides: [cleanerServiceApiProvider.overrideWithValue(api)],
    );
  });

  tearDown(() => container.dispose());

  Future<CleanerServiceState> settle() async {
    container.listen(cleanerServiceControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container.read(cleanerServiceControllerProvider);
  }

  test('load returns offerings', () async {
    api.items = [CleanerServiceOffering.fromJson(cleanerOfferingJson())];
    final state = await settle();
    expect(state.offerings, hasLength(1));
    expect(state.offerings.single.hourlyRateMinor, equals(250000));
  });

  test('save reloads offerings', () async {
    await settle();
    final ok = await container
        .read(cleanerServiceControllerProvider.notifier)
        .save(
          serviceId: '507f1f77bcf86cd799439051',
          hourlyRateMinor: 250000,
          currencyCode: 'BDT',
          isActive: true,
        );
    expect(ok, isTrue);
    expect(api.upsertCalls, equals(1));
    expect(api.listCalls, greaterThan(1));
    expect(
      container
          .read(cleanerServiceControllerProvider)
          .offerings
          .single
          .isActive,
      isTrue,
    );
  });

  test('deactivate then reactivate updates state', () async {
    api.items = [CleanerServiceOffering.fromJson(cleanerOfferingJson())];
    await settle();
    await container
        .read(cleanerServiceControllerProvider.notifier)
        .deactivate('507f1f77bcf86cd799439051');
    expect(api.deactivateCalls, equals(1));
    expect(
      container
          .read(cleanerServiceControllerProvider)
          .offerings
          .single
          .isActive,
      isFalse,
    );
    await container
        .read(cleanerServiceControllerProvider.notifier)
        .save(
          serviceId: '507f1f77bcf86cd799439051',
          hourlyRateMinor: 250000,
          currencyCode: 'BDT',
          isActive: true,
        );
    expect(
      container
          .read(cleanerServiceControllerProvider)
          .offerings
          .single
          .isActive,
      isTrue,
    );
  });

  test('approval failure stays as a safe error', () async {
    api.nextError = ApiFailure(
      code: 'cleaner_not_approved',
      message: messageForApiCode('cleaner_not_approved'),
    );
    final state = await settle();
    expect(state.errorMessage, contains('approved'));
  });
}

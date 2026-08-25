import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/availability/data/availability_api.dart';
import 'package:home_cleaning_marketplace/features/availability/data/availability_slot.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/availability_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeAvailabilityApi extends AvailabilityApi {
  _FakeAvailabilityApi() : super(Dio());

  List<AvailabilitySlot> items = <AvailabilitySlot>[];
  ApiFailure? nextError;
  int listCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<List<AvailabilitySlot>> list({
    String? from,
    String? to,
    String? serviceId,
  }) async {
    listCalls += 1;
    _throwIfNeeded();
    return items;
  }

  @override
  Future<AvailabilitySlot> create({
    required String serviceId,
    required String startAt,
    required String endAt,
  }) async {
    createCalls += 1;
    _throwIfNeeded();
    final slot = AvailabilitySlot.fromJson(availabilitySlotJson());
    items = [...items, slot];
    return slot;
  }

  @override
  Future<AvailabilitySlot> update({
    required String slotId,
    required String serviceId,
    required String startAt,
    required String endAt,
  }) async {
    updateCalls += 1;
    _throwIfNeeded();
    return AvailabilitySlot.fromJson(availabilitySlotJson(id: slotId));
  }

  @override
  Future<void> delete(String slotId) async {
    deleteCalls += 1;
    _throwIfNeeded();
    items = [
      for (final slot in items)
        if (slot.id != slotId) slot,
    ];
  }
}

void main() {
  late _FakeAvailabilityApi api;
  late ProviderContainer container;

  setUp(() {
    api = _FakeAvailabilityApi();
    container = ProviderContainer(
      overrides: [availabilityApiProvider.overrideWithValue(api)],
    );
  });

  tearDown(() => container.dispose());

  Future<AvailabilityState> settle() async {
    container.listen(availabilityControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container.read(availabilityControllerProvider);
  }

  test('load returns future slots', () async {
    api.items = [AvailabilitySlot.fromJson(availabilitySlotJson())];
    final state = await settle();
    expect(state.slots, hasLength(1));
    expect(state.slots.single.duration.inMinutes, equals(120));
  });

  test('create reloads the list', () async {
    await settle();
    final ok = await container
        .read(availabilityControllerProvider.notifier)
        .create(
          serviceId: '507f1f77bcf86cd799439051',
          startAt: '2026-09-01T03:00:00.000Z',
          endAt: '2026-09-01T05:00:00.000Z',
        );
    expect(ok, isTrue);
    expect(api.createCalls, equals(1));
    expect(api.listCalls, greaterThan(1));
  });

  test('update and delete call the API', () async {
    api.items = [AvailabilitySlot.fromJson(availabilitySlotJson())];
    await settle();
    await container
        .read(availabilityControllerProvider.notifier)
        .update(
          slotId: '507f1f77bcf86cd799439071',
          serviceId: '507f1f77bcf86cd799439051',
          startAt: '2026-09-01T03:00:00.000Z',
          endAt: '2026-09-01T05:00:00.000Z',
        );
    expect(api.updateCalls, equals(1));
    await container
        .read(availabilityControllerProvider.notifier)
        .delete('507f1f77bcf86cd799439071');
    expect(api.deleteCalls, equals(1));
    expect(container.read(availabilityControllerProvider).slots, isEmpty);
  });

  test('overlap error is a safe message', () async {
    await settle();
    api.nextError = ApiFailure(
      code: 'availability_overlap',
      message: messageForApiCode('availability_overlap'),
    );
    final ok = await container
        .read(availabilityControllerProvider.notifier)
        .create(
          serviceId: '507f1f77bcf86cd799439051',
          startAt: '2026-09-01T03:00:00.000Z',
          endAt: '2026-09-01T05:00:00.000Z',
        );
    expect(ok, isFalse);
    expect(
      container.read(availabilityControllerProvider).errorMessage,
      equals('This availability window overlaps another slot.'),
    );
  });

  test('limit error is a safe message', () async {
    await settle();
    api.nextError = ApiFailure(
      code: 'availability_limit_reached',
      message: messageForApiCode('availability_limit_reached'),
    );
    final ok = await container
        .read(availabilityControllerProvider.notifier)
        .create(
          serviceId: '507f1f77bcf86cd799439051',
          startAt: '2026-09-01T03:00:00.000Z',
          endAt: '2026-09-01T05:00:00.000Z',
        );
    expect(ok, isFalse);
    expect(
      container.read(availabilityControllerProvider).errorMessage,
      contains('180'),
    );
  });
}

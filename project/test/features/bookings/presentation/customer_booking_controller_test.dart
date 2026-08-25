import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_api.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeCustomerBookingApi extends CustomerBookingApi {
  _FakeCustomerBookingApi() : super(Dio());

  BookingPage<CustomerBooking> page = BookingPage<CustomerBooking>(
    items: [testCustomerBooking()],
  );
  CustomerBooking detail = testCustomerBooking();
  ApiFailure? nextError;
  int listCalls = 0;
  int createCalls = 0;
  Completer<void>? createGate;
  String? lastIdempotencyKey;
  String? lastAfter;
  String? lastStatus;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<CustomerBooking> createBooking({
    required String availabilitySlotId,
    required String addressId,
    required String idempotencyKey,
    String? customerNotes,
  }) async {
    createCalls += 1;
    lastIdempotencyKey = idempotencyKey;
    final gate = createGate;
    if (gate != null) {
      await gate.future;
    }
    _throwIfNeeded();
    return detail;
  }

  @override
  Future<BookingPage<CustomerBooking>> listBookings({
    String? status,
    int? limit,
    String? after,
  }) async {
    listCalls += 1;
    lastStatus = status;
    lastAfter = after;
    _throwIfNeeded();
    return page;
  }

  @override
  Future<CustomerBooking> getBooking(String bookingId) async {
    _throwIfNeeded();
    return detail;
  }

  @override
  Future<CustomerBooking> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    _throwIfNeeded();
    return testCustomerBooking(status: BookingStatus.cancelled);
  }
}

void main() {
  late _FakeCustomerBookingApi api;
  late ProviderContainer container;

  setUp(() {
    api = _FakeCustomerBookingApi();
    container = ProviderContainer(
      overrides: [customerBookingApiProvider.overrideWithValue(api)],
    );
  });

  tearDown(() => container.dispose());

  Future<CustomerBookingState> settle() async {
    container.listen(customerBookingControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container.read(customerBookingControllerProvider);
  }

  test('load returns the first page', () async {
    final state = await settle();
    expect(state.items, hasLength(1));
    expect(state.items.single.cleanerFullName, equals('Ada Cleaner'));
    expect(api.listCalls, equals(1));
  });

  test('filter and pagination pass query values', () async {
    api.page = BookingPage<CustomerBooking>(
      items: [testCustomerBooking()],
      nextCursor: 'cursor-1',
    );
    await settle();
    await container
        .read(customerBookingControllerProvider.notifier)
        .load(status: BookingStatus.pending);
    expect(api.lastStatus, equals('pending'));
    await container.read(customerBookingControllerProvider.notifier).loadMore();
    expect(api.lastAfter, equals('cursor-1'));
  });

  test(
    'submit reuses one idempotency key and ignores duplicate presses',
    () async {
      await settle();
      api.createGate = Completer<void>();
      final notifier = container.read(
        customerBookingControllerProvider.notifier,
      );
      notifier.beginSubmitAttempt(keyFactory: () => 'fixed-idempotency-key');
      final first = notifier.submit(
        availabilitySlotId: 'slot-1',
        addressId: 'addr-1',
      );
      await pumpEventQueue();
      final second = notifier.submit(
        availabilitySlotId: 'slot-1',
        addressId: 'addr-1',
      );
      api.createGate!.complete();
      await Future.wait<CustomerBooking?>([first, second]);
      expect(api.createCalls, equals(1));
      expect(api.lastIdempotencyKey, equals('fixed-idempotency-key'));
    },
  );

  test('detail and cancel update state', () async {
    await settle();
    await container
        .read(customerBookingControllerProvider.notifier)
        .loadDetail('507f1f77bcf86cd799439091');
    expect(
      container.read(customerBookingControllerProvider).detail?.id,
      equals('507f1f77bcf86cd799439091'),
    );
    final ok = await container
        .read(customerBookingControllerProvider.notifier)
        .cancel('507f1f77bcf86cd799439091');
    expect(ok, isTrue);
    expect(
      container.read(customerBookingControllerProvider).detail?.status,
      equals(BookingStatus.cancelled),
    );
  });

  test('safe error is stored without raw exception text', () async {
    await settle();
    api.nextError = ApiFailure(
      code: 'availability_unavailable',
      message: messageForApiCode('availability_unavailable'),
    );
    container
        .read(customerBookingControllerProvider.notifier)
        .beginSubmitAttempt(keyFactory: () => 'fixed-idempotency-key');
    final created = await container
        .read(customerBookingControllerProvider.notifier)
        .submit(availabilitySlotId: 'slot-1', addressId: 'addr-1');
    expect(created, isNull);
    expect(
      container.read(customerBookingControllerProvider).errorMessage,
      equals('That time slot is no longer available.'),
    );
    expect(
      container.read(customerBookingControllerProvider).errorMessage,
      isNot(contains('Mongo')),
    );
  });
}

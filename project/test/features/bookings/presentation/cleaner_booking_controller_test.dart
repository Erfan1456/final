import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_api.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeCleanerBookingApi extends CleanerBookingApi {
  _FakeCleanerBookingApi() : super(Dio());

  BookingPage<CleanerBooking> page = BookingPage<CleanerBooking>(
    items: [testCleanerBooking()],
  );
  CleanerBooking detail = testCleanerBooking();
  ApiFailure? nextError;
  int listCalls = 0;
  int acceptCalls = 0;
  int declineCalls = 0;
  int cancelCalls = 0;
  int startCalls = 0;
  int completeCalls = 0;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<BookingPage<CleanerBooking>> listBookings({
    String? status,
    int? limit,
    String? after,
  }) async {
    listCalls += 1;
    _throwIfNeeded();
    return page;
  }

  @override
  Future<CleanerBooking> getBooking(String bookingId) async {
    _throwIfNeeded();
    return detail;
  }

  @override
  Future<CleanerBooking> accept(String bookingId) async {
    acceptCalls += 1;
    _throwIfNeeded();
    return testCleanerBooking(
      status: BookingStatus.confirmed,
      fullAddress: true,
    );
  }

  @override
  Future<CleanerBooking> decline(
    String bookingId, {
    required String reason,
  }) async {
    declineCalls += 1;
    _throwIfNeeded();
    return testCleanerBooking(status: BookingStatus.declined);
  }

  @override
  Future<CleanerBooking> cancel(
    String bookingId, {
    required String reason,
  }) async {
    cancelCalls += 1;
    _throwIfNeeded();
    return testCleanerBooking(status: BookingStatus.cancelled);
  }

  @override
  Future<CleanerBooking> start(String bookingId) async {
    startCalls += 1;
    _throwIfNeeded();
    return testCleanerBooking(
      status: BookingStatus.inProgress,
      fullAddress: true,
    );
  }

  @override
  Future<CleanerBooking> complete(String bookingId) async {
    completeCalls += 1;
    _throwIfNeeded();
    return testCleanerBooking(
      status: BookingStatus.completed,
      fullAddress: true,
    );
  }
}

void main() {
  late _FakeCleanerBookingApi api;
  late ProviderContainer container;

  setUp(() {
    api = _FakeCleanerBookingApi();
    container = ProviderContainer(
      overrides: [cleanerBookingApiProvider.overrideWithValue(api)],
    );
  });

  tearDown(() => container.dispose());

  Future<CleanerBookingState> settle() async {
    container.listen(cleanerBookingControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container.read(cleanerBookingControllerProvider);
  }

  test('load returns cleaner bookings', () async {
    final state = await settle();
    expect(state.items.single.customerDisplayName, equals('Test Customer'));
  });

  test('filter and load more', () async {
    await settle();
    api.page = BookingPage<CleanerBooking>(
      items: [testCleanerBooking()],
      nextCursor: 'cursor-1',
    );
    await container
        .read(cleanerBookingControllerProvider.notifier)
        .load(status: BookingStatus.pending);
    await container.read(cleanerBookingControllerProvider.notifier).loadMore();
    expect(api.listCalls, greaterThan(2));
  });

  test('lifecycle mutations update detail', () async {
    await settle();
    final notifier = container.read(cleanerBookingControllerProvider.notifier);
    await notifier.loadDetail('507f1f77bcf86cd799439091');
    expect(await notifier.accept('507f1f77bcf86cd799439091'), isTrue);
    expect(api.acceptCalls, equals(1));
    expect(
      await notifier.decline('id', reason: 'Slot no longer works.'),
      isTrue,
    );
    expect(
      await notifier.cancel('id', reason: 'Emergency schedule change.'),
      isTrue,
    );
    expect(await notifier.start('id'), isTrue);
    expect(await notifier.complete('id'), isTrue);
    expect(
      container.read(cleanerBookingControllerProvider).detail?.status,
      equals(BookingStatus.completed),
    );
  });

  test('safe mutation error', () async {
    await settle();
    api.nextError = ApiFailure(
      code: 'invalid_booking_state',
      message: messageForApiCode('invalid_booking_state'),
    );
    final ok = await container
        .read(cleanerBookingControllerProvider.notifier)
        .accept('id');
    expect(ok, isFalse);
    expect(
      container.read(cleanerBookingControllerProvider).errorMessage,
      equals('This booking cannot be changed in its current state.'),
    );
  });
}

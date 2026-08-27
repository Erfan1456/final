import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_api.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_models.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeBookingDisputeApi extends BookingDisputeApi {
  _FakeBookingDisputeApi() : super(Dio());

  BookingDispute? dispute;
  ApiFailure? nextError;
  Completer<void>? createGate;
  int getCalls = 0;
  int createCalls = 0;
  int closeCalls = 0;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<BookingDispute?> getForBooking(String bookingId) async {
    getCalls += 1;
    _throwIfNeeded();
    return dispute;
  }

  @override
  Future<BookingDispute> create({
    required String bookingId,
    required String category,
    required String subject,
    required String description,
  }) async {
    createCalls += 1;
    if (createGate != null) {
      await createGate!.future;
    }
    _throwIfNeeded();
    dispute = testBookingDispute();
    return dispute!;
  }

  @override
  Future<BookingDispute> close(String bookingId) async {
    closeCalls += 1;
    _throwIfNeeded();
    dispute = testBookingDispute(status: 'closed');
    return dispute!;
  }
}

void main() {
  test('loads none then create and close', () async {
    final api = _FakeBookingDisputeApi();
    final container = ProviderContainer(
      overrides: [bookingDisputeApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      bookingDisputeControllerProvider.notifier,
    );
    await controller.load('booking');
    expect(container.read(bookingDisputeControllerProvider).dispute, isNull);
    await controller.create(
      bookingId: 'booking',
      category: 'service_quality',
      subject: 'Late arrival issue',
      description: 'The cleaner arrived more than two hours late to the job.',
    );
    expect(
      container.read(bookingDisputeControllerProvider).dispute?.status,
      DisputeStatus.open,
    );
    api.dispute = testBookingDispute(status: 'resolved', resolution: 'Noted.');
    await controller.close('booking');
    expect(api.closeCalls, 1);
  });

  test('create ignores duplicate presses while in flight', () async {
    final api = _FakeBookingDisputeApi()..createGate = Completer<void>();
    final container = ProviderContainer(
      overrides: [bookingDisputeApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(bookingDisputeControllerProvider.notifier);
    final first = notifier.create(
      bookingId: 'booking',
      category: 'service_quality',
      subject: 'Late arrival issue',
      description: 'The cleaner arrived more than two hours late to the job.',
    );
    await pumpEventQueue();
    final second = notifier.create(
      bookingId: 'booking',
      category: 'service_quality',
      subject: 'Late arrival issue',
      description: 'The cleaner arrived more than two hours late to the job.',
    );
    api.createGate!.complete();
    final results = await Future.wait<bool>([first, second]);
    expect(results, equals([true, false]));
    expect(api.createCalls, equals(1));
  });

  test('surfaces safe errors', () async {
    final api = _FakeBookingDisputeApi()
      ..nextError = const ApiFailure(
        code: 'dispute_not_allowed',
        message: 'A dispute cannot be opened for this booking.',
      );
    final container = ProviderContainer(
      overrides: [bookingDisputeApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await container.read(bookingDisputeControllerProvider.notifier).load('id');
    expect(
      container.read(bookingDisputeControllerProvider).errorMessage,
      contains('cannot be opened'),
    );
  });
}

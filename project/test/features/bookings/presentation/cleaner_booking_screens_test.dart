import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_list_screen.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('list shows request state, coarse location, and load more', (
    tester,
  ) async {
    _useTallSurface(tester);
    final bookings = SeededCleanerBookingController(
      CleanerBookingState(
        loading: false,
        items: [testCleanerBooking()],
        nextCursor: 'cursor-1',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerBookingControllerProvider.overrideWith(() => bookings),
          bookingDisputeControllerProvider.overrideWith(
            () => SeededBookingDisputeController(
              const BookingDisputeState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(home: CleanerBookingListScreen()),
      ),
    );
    expect(find.text('Booking Requests / Jobs'), findsOneWidget);
    expect(find.textContaining('Booking request'), findsOneWidget);
    expect(find.textContaining('Test Customer'), findsOneWidget);
    expect(find.textContaining('Dhaka, Dhaka'), findsOneWidget);
    expect(find.textContaining('1 Test Street'), findsNothing);
    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(bookings.loadMoreCalls, equals(1));
    await tester.tap(find.widgetWithText(FilterChip, 'Completed'));
    await tester.pump();
    expect(bookings.loadCalls, equals(1));
    expect(bookings.lastStatus, equals(BookingStatus.completed));
  });

  testWidgets('pending detail shows coarse address and accept/decline', (
    tester,
  ) async {
    final bookings = SeededCleanerBookingController(
      CleanerBookingState(loading: false, detail: testCleanerBooking()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerBookingControllerProvider.overrideWith(() => bookings),
          bookingDisputeControllerProvider.overrideWith(
            () => SeededBookingDisputeController(
              const BookingDisputeState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(
          home: CleanerBookingDetailScreen(
            bookingId: '507f1f77bcf86cd799439091',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Location: Dhaka, Dhaka, BD'), findsOneWidget);
    expect(find.text('1 Test Street'), findsNothing);
    expect(find.text('Message Customer'), findsOneWidget);
    expect(find.text('Report a Problem'), findsNothing);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Start Job'), findsNothing);
    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(bookings.acceptCalls, equals(1));
  });

  testWidgets('decline requires a reason', (tester) async {
    final bookings = SeededCleanerBookingController(
      CleanerBookingState(loading: false, detail: testCleanerBooking()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerBookingControllerProvider.overrideWith(() => bookings),
          bookingDisputeControllerProvider.overrideWith(
            () => SeededBookingDisputeController(
              const BookingDisputeState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(
          home: CleanerBookingDetailScreen(
            bookingId: '507f1f77bcf86cd799439091',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Schedule conflict today.');
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(bookings.declineCalls, equals(1));
    expect(bookings.lastReason, equals('Schedule conflict today.'));
  });

  testWidgets('confirmed booking shows full address and cancel', (
    tester,
  ) async {
    _useTallSurface(tester);
    final bookings = SeededCleanerBookingController(
      CleanerBookingState(
        loading: false,
        detail: testCleanerBooking(
          status: BookingStatus.confirmed,
          fullAddress: true,
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerBookingControllerProvider.overrideWith(() => bookings),
          bookingDisputeControllerProvider.overrideWith(
            () => SeededBookingDisputeController(
              const BookingDisputeState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(
          home: CleanerBookingDetailScreen(
            bookingId: '507f1f77bcf86cd799439091',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 Test Street'), findsOneWidget);
    expect(find.text('Report a Problem'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Accept'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextField),
      'Unable to attend this slot.',
    );
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(bookings.cancelCalls, equals(1));
  });

  testWidgets('start job is available during the slot window', (tester) async {
    _useTallSurface(tester);
    final now = DateTime.now().toUtc();
    final startable = SeededCleanerBookingController(
      CleanerBookingState(
        loading: false,
        detail: testCleanerBooking(
          status: BookingStatus.confirmed,
          fullAddress: true,
          startAt: now.subtract(const Duration(minutes: 5)).toIso8601String(),
          endAt: now.add(const Duration(hours: 2)).toIso8601String(),
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerBookingControllerProvider.overrideWith(() => startable),
          bookingDisputeControllerProvider.overrideWith(
            () => SeededBookingDisputeController(
              const BookingDisputeState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(
          home: CleanerBookingDetailScreen(
            bookingId: '507f1f77bcf86cd799439091',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start Job'), findsOneWidget);
    await tester.tap(find.text('Start Job'));
    await tester.pump();
    expect(startable.startCalls, equals(1));
  });

  testWidgets('in-progress booking can be completed', (tester) async {
    _useTallSurface(tester);
    final completable = SeededCleanerBookingController(
      CleanerBookingState(
        loading: false,
        detail: testCleanerBooking(
          status: BookingStatus.inProgress,
          fullAddress: true,
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerBookingControllerProvider.overrideWith(() => completable),
          bookingDisputeControllerProvider.overrideWith(
            () => SeededBookingDisputeController(
              const BookingDisputeState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(
          home: CleanerBookingDetailScreen(
            bookingId: '507f1f77bcf86cd799439091',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Complete Job'), findsOneWidget);
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    await tester.tap(find.text('Complete Job'));
    await tester.pump();
    expect(completable.completeCalls, equals(1));
  });

  testWidgets('terminal booking has no lifecycle actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerBookingControllerProvider.overrideWith(
            () => SeededCleanerBookingController(
              CleanerBookingState(
                loading: false,
                detail: testCleanerBooking(status: BookingStatus.completed),
              ),
            ),
          ),
          bookingDisputeControllerProvider.overrideWith(
            () => SeededBookingDisputeController(
              const BookingDisputeState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(
          home: CleanerBookingDetailScreen(
            bookingId: '507f1f77bcf86cd799439091',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Decline'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Start Job'), findsNothing);
    expect(find.text('Complete Job'), findsNothing);
  });
}

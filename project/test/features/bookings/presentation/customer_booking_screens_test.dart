import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/booking_confirmation_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_list_screen.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/discovery_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('confirmation requires an address', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryControllerProvider.overrideWith(
            () => SeededDiscoveryController(
              DiscoveryState(loading: false, detail: testDiscoveryDetail()),
            ),
          ),
          addressControllerProvider.overrideWith(
            () =>
                SeededAddressController(const AddressListState(loading: false)),
          ),
          customerBookingControllerProvider.overrideWith(
            () => SeededCustomerBookingController(
              const CustomerBookingState(loading: false),
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.customerBookSlotLocation(
              '507f1f77bcf86cd799439081',
              '507f1f77bcf86cd799439071',
            ),
            routes: [
              GoRoute(
                path: AppRoutes.customerBookSlotPath,
                builder: (context, state) => BookingConfirmationScreen(
                  cleanerUserId: state.pathParameters['cleanerUserId'] ?? '',
                  slotId: state.pathParameters['slotId'] ?? '',
                ),
              ),
              GoRoute(
                path: AppRoutes.customerAddressNewPath,
                builder: (context, state) =>
                    const Scaffold(body: Text('Address form')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add an address before booking'), findsOneWidget);
    expect(find.text('Ada Cleaner'), findsOneWidget);
    expect(find.text('Home Cleaning'), findsOneWidget);
    expect(find.text(formatMinorHourlyRate(250000, 'BDT')), findsOneWidget);
    expect(find.text('Quoted total: BDT 500000 minor units'), findsOneWidget);
    await tester.tap(find.text('Add address'));
    await tester.pumpAndSettle();
    expect(find.text('Address form'), findsOneWidget);
  });

  testWidgets('confirmation submits notes and selected address', (
    tester,
  ) async {
    final bookings = SeededCustomerBookingController(
      const CustomerBookingState(loading: false),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryControllerProvider.overrideWith(
            () => SeededDiscoveryController(
              DiscoveryState(loading: false, detail: testDiscoveryDetail()),
            ),
          ),
          addressControllerProvider.overrideWith(
            () => SeededAddressController(
              AddressListState(
                loading: false,
                addresses: [testAddress(isDefault: true)],
              ),
            ),
          ),
          customerBookingControllerProvider.overrideWith(() => bookings),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.customerBookSlotLocation(
              '507f1f77bcf86cd799439081',
              '507f1f77bcf86cd799439071',
            ),
            routes: [
              GoRoute(
                path: AppRoutes.customerBookSlotPath,
                builder: (context, state) => BookingConfirmationScreen(
                  cleanerUserId: state.pathParameters['cleanerUserId'] ?? '',
                  slotId: state.pathParameters['slotId'] ?? '',
                ),
              ),
              GoRoute(
                path: AppRoutes.customerBookingDetailPath,
                builder: (context, state) =>
                    const Scaffold(body: Text('Booking detail route')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
    await tester.enterText(
      find.byType(TextField),
      'Please use the side entrance.',
    );
    await tester.tap(find.text('Confirm Booking'));
    await tester.pumpAndSettle();
    expect(bookings.submitCalls, equals(1));
    expect(bookings.lastSubmitSlotId, equals('507f1f77bcf86cd799439071'));
    expect(bookings.lastSubmitAddressId, equals(testAddress().id));
    expect(bookings.lastNotes, equals('Please use the side entrance.'));
    expect(bookings.beginAttemptCalls, equals(1));
    expect(find.text('Booking detail route'), findsOneWidget);
  });

  testWidgets('list shows cards, filters, and load more', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bookings = SeededCustomerBookingController(
      CustomerBookingState(
        loading: false,
        items: [testCustomerBooking()],
        nextCursor: 'cursor-1',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerBookingControllerProvider.overrideWith(() => bookings),
        ],
        child: const MaterialApp(home: CustomerBookingListScreen()),
      ),
    );
    expect(find.text('My Bookings'), findsOneWidget);
    expect(find.text('Ada Cleaner'), findsOneWidget);
    expect(find.textContaining('Home Cleaning'), findsOneWidget);
    expect(find.textContaining('Pending'), findsWidgets);
    expect(
      find.textContaining('Quoted total: BDT 500000 minor units'),
      findsOneWidget,
    );
    expect(find.text('Load More'), findsOneWidget);
    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(bookings.loadMoreCalls, equals(1));
    await tester.tap(find.widgetWithText(FilterChip, 'Confirmed'));
    await tester.pump();
    expect(bookings.loadCalls, equals(1));
    expect(bookings.lastStatus, equals(BookingStatus.confirmed));
  });

  testWidgets('detail shows snapshot, history, and cancel confirmation', (
    tester,
  ) async {
    final bookings = SeededCustomerBookingController(
      CustomerBookingState(loading: false, detail: testCustomerBooking()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerBookingControllerProvider.overrideWith(() => bookings),
        ],
        child: const MaterialApp(
          home: CustomerBookingDetailScreen(
            bookingId: '507f1f77bcf86cd799439091',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ada Cleaner'), findsOneWidget);
    expect(find.text('1 Test Street'), findsOneWidget);
    expect(find.text('Notes: Please use the side entrance.'), findsOneWidget);
    expect(find.textContaining('Status history'), findsOneWidget);
    expect(find.text('Cancel Booking'), findsOneWidget);
    await tester.tap(find.text('Cancel Booking'));
    await tester.pump();
    expect(find.text('Cancel Booking'), findsWidgets);
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(bookings.cancelCalls, equals(1));
  });
}

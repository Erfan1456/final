import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_home_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/admin_dispute_controller.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/admin_dispute_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/admin_dispute_list_screen.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_controller.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_screen.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/customer_review_controller.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('pending booking does not show a dispute CTA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerBookingControllerProvider.overrideWith(
            () => SeededCustomerBookingController(
              CustomerBookingState(
                loading: false,
                detail: testCustomerBooking(),
              ),
            ),
          ),
          customerPaymentControllerProvider.overrideWith(
            () => SeededCustomerPaymentController(
              const CustomerPaymentState(loading: false),
            ),
          ),
          customerReviewControllerProvider.overrideWith(
            () => SeededCustomerReviewController(
              const CustomerReviewState(loading: false),
            ),
          ),
          bookingDisputeControllerProvider.overrideWith(
            () => SeededBookingDisputeController(
              const BookingDisputeState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(
          home: CustomerBookingDetailScreen(
            bookingId: '507f1f77bcf86cd799439091',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Report a Problem'), findsNothing);
    expect(find.text('View Dispute'), findsNothing);
  });

  testWidgets('eligible booking shows Report a Problem', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerBookingControllerProvider.overrideWith(
            () => SeededCustomerBookingController(
              CustomerBookingState(
                loading: false,
                detail: testCustomerBooking(status: BookingStatus.confirmed),
              ),
            ),
          ),
          customerPaymentControllerProvider.overrideWith(
            () => SeededCustomerPaymentController(
              const CustomerPaymentState(loading: false),
            ),
          ),
          customerReviewControllerProvider.overrideWith(
            () => SeededCustomerReviewController(
              const CustomerReviewState(loading: false),
            ),
          ),
          bookingDisputeControllerProvider.overrideWith(
            () => SeededBookingDisputeController(
              const BookingDisputeState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(
          home: CustomerBookingDetailScreen(
            bookingId: '507f1f77bcf86cd799439091',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Report a Problem'), findsOneWidget);
  });

  testWidgets('create form validates and submits', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SeededBookingDisputeController(
      const BookingDisputeState(loading: false),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDisputeControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(
          home: BookingDisputeScreen(bookingId: '507f1f77bcf86cd799439091'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'hey');
    await tester.tap(find.text('Submit Dispute'));
    await tester.pump();
    expect(find.textContaining('Subject must be between'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Late arrival issue');
    await tester.enterText(
      find.byType(TextField).at(1),
      'The cleaner arrived more than two hours late to the job.',
    );
    await tester.tap(find.text('Submit Dispute'));
    await tester.pump();
    expect(controller.createCalls, 1);
    expect(controller.lastSubject, 'Late arrival issue');
  });

  testWidgets('existing resolved dispute can close', (tester) async {
    final controller = SeededBookingDisputeController(
      BookingDisputeState(
        loading: false,
        dispute: testBookingDispute(
          status: 'resolved',
          resolution: 'Operational note recorded.',
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDisputeControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(
          home: BookingDisputeScreen(bookingId: '507f1f77bcf86cd799439091'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.textContaining('History'), findsOneWidget);
    await tester.tap(find.text('Close Dispute'));
    await tester.pumpAndSettle();
    expect(find.text('Close this dispute?'), findsOneWidget);
    await tester.tap(find.text('Close dispute'));
    await tester.pumpAndSettle();
    expect(controller.closeCalls, 1);
  });

  testWidgets('admin home lists disputes users bookings and audit log', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(
              AuthState.authenticated(testUser(role: 'admin')),
            ),
          ),
          notificationControllerProvider.overrideWith(
            () => SeededNotificationController(
              const NotificationState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminHomeScreen()),
      ),
    );
    expect(find.text('Disputes'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Audit Log'), findsOneWidget);
  });

  testWidgets('admin dispute list filters and load more', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final list = SeededAdminDisputeController(
      AdminDisputeState(
        loading: false,
        items: [testAdminDisputeSummary()],
        nextCursor: 'next',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminDisputeControllerProvider.overrideWith(() => list)],
        child: const MaterialApp(home: AdminDisputeListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Late arrival issue'), findsOneWidget);
    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(list.loadMoreCalls, 1);
  });

  testWidgets('admin dispute detail can start review and resolve', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final detail = SeededAdminDisputeController(
      AdminDisputeState(loading: false, detail: testAdminDisputeDetail()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminDisputeControllerProvider.overrideWith(() => detail)],
        child: const MaterialApp(
          home: AdminDisputeDetailScreen(disputeId: '507f1f77bcf86cd7994390d1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start Review'), findsOneWidget);
    await tester.tap(find.text('Start Review'));
    await tester.pump();
    expect(detail.startReviewCalls, 1);
    await tester.tap(find.text('Resolve'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextField),
      'Operational note: both parties were contacted.',
    );
    await tester.tap(find.text('Resolve').last);
    await tester.pump();
    expect(detail.resolveCalls, 1);
  });
}

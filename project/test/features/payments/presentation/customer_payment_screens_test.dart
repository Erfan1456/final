import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_screen.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/customer_review_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('confirmed booking does not show Pay Now', (
    tester,
  ) async {
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
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.customerBookingDetailLocation(
              '507f1f77bcf86cd799439091',
            ),
            routes: [
              GoRoute(
                path: AppRoutes.customerBookingDetailPath,
                builder: (context, state) => const CustomerBookingDetailScreen(
                  bookingId: '507f1f77bcf86cd799439091',
                ),
              ),
              GoRoute(
                path: AppRoutes.customerBookingPaymentPath,
                builder: (context, state) =>
                    const Scaffold(body: Text('Payment route')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pay Now'), findsNothing);
    expect(find.text('Card number'), findsNothing);
    expect(find.text('CVV'), findsNothing);
  });

  testWidgets('pending payment shows cancel and sandbox when available', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final payments = SeededCustomerPaymentController(
      CustomerPaymentState(
        loading: false,
        history: PaymentHistory(
          current: testPaymentAttempt(simulationAvailable: true),
          attempts: [testPaymentAttempt(simulationAvailable: true)],
        ),
      ),
    );
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
          customerPaymentControllerProvider.overrideWith(() => payments),
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
          home: CustomerPaymentScreen(
            bookingId: '507f1f77bcf86cd799439091',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Cancel Payment'), findsOneWidget);
    expect(find.textContaining('Development Sandbox'), findsWidgets);
    expect(find.text('Simulate Success'), findsOneWidget);
    expect(find.text('Simulate Failure'), findsOneWidget);
    await tester.tap(find.text('Cancel Payment'));
    await tester.pump();
    expect(payments.cancelCalls, equals(1));
    await tester.ensureVisible(find.text('Simulate Success'));
    await tester.tap(find.text('Simulate Success'));
    await tester.pump();
    expect(payments.simulateSuccessCalls, equals(1));
  });

  testWidgets('paid, failed, refunded, and retry states', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> pumpStatus(String status, {int refunded = 0}) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
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
                CustomerPaymentState(
                  loading: false,
                  history: PaymentHistory(
                    current: testPaymentAttempt(
                      status: status,
                      refundedAmountMinor: refunded,
                      paidAt: status == 'paid'
                          ? '2026-08-25T12:05:00.000Z'
                          : null,
                    ),
                    attempts: [
                      testPaymentAttempt(
                        status: status,
                        refundedAmountMinor: refunded,
                      ),
                    ],
                  ),
                ),
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
            home: CustomerPaymentScreen(
              bookingId: '507f1f77bcf86cd799439091',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpStatus('paid');
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Simulate Success'), findsNothing);

    await pumpStatus('failed');
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Retry Payment'), findsOneWidget);

    await pumpStatus('cancelled');
    expect(find.text('Retry Payment'), findsOneWidget);

    await pumpStatus('refunded', refunded: 500000);
    expect(find.textContaining('Refunded'), findsWidgets);

    await pumpStatus('partially_refunded', refunded: 100000);
    expect(find.textContaining('Partially Refunded'), findsOneWidget);
  });

  testWidgets('payment screen starts payment and hides card fields', (
    tester,
  ) async {
    final payments = SeededCustomerPaymentController(
      const CustomerPaymentState(loading: false),
    );
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
          customerPaymentControllerProvider.overrideWith(() => payments),
        ],
        child: const MaterialApp(
          home: CustomerPaymentScreen(bookingId: '507f1f77bcf86cd799439091'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start Payment'), findsOneWidget);
    expect(find.text('Card number'), findsNothing);
    expect(find.text('CVV'), findsNothing);
    expect(find.text('Simulate Success'), findsNothing);
    await tester.tap(find.text('Start Payment'));
    await tester.pump();
    expect(payments.beginAttemptCalls, equals(1));
    expect(payments.startCalls, equals(1));
  });

  testWidgets('sandbox labels appear only when simulation is available', (
    tester,
  ) async {
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
              CustomerPaymentState(
                loading: false,
                history: PaymentHistory(
                  current: testPaymentAttempt(),
                  attempts: [testPaymentAttempt()],
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: CustomerPaymentScreen(bookingId: '507f1f77bcf86cd799439091'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Development Sandbox'), findsNothing);
    expect(find.text('Simulate Success'), findsNothing);
  });
}

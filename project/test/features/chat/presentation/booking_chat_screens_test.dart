import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/chat/presentation/booking_chat_controller.dart';
import 'package:home_cleaning_marketplace/features/chat/presentation/booking_chat_screen.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/customer_review_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('customer booking detail shows Message Cleaner', (tester) async {
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
                path: AppRoutes.customerBookingChatPath,
                builder: (context, state) =>
                    const Scaffold(body: Text('Chat route')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Message Cleaner'), findsOneWidget);
    expect(find.text('Leave Review'), findsNothing);
    await tester.tap(find.text('Message Cleaner'));
    await tester.pumpAndSettle();
    expect(find.text('Chat route'), findsOneWidget);
  });

  testWidgets('completed booking shows Leave Review', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerBookingControllerProvider.overrideWith(
            () => SeededCustomerBookingController(
              CustomerBookingState(
                loading: false,
                detail: testCustomerBooking(status: BookingStatus.completed),
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
    expect(find.text('Leave Review'), findsOneWidget);
    expect(find.text('Edit Review'), findsNothing);
    expect(find.text('Message Cleaner'), findsOneWidget);
  });

  testWidgets('completed booking with review shows Edit Review', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerBookingControllerProvider.overrideWith(
            () => SeededCustomerBookingController(
              CustomerBookingState(
                loading: false,
                detail: testCustomerBooking(status: BookingStatus.completed),
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
              CustomerReviewState(loading: false, review: testCustomerReview()),
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
    expect(find.text('Edit Review'), findsOneWidget);
  });

  testWidgets('cleaner booking detail shows Message Customer', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerBookingControllerProvider.overrideWith(
            () => SeededCleanerBookingController(
              CleanerBookingState(loading: false, detail: testCleanerBooking()),
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
            initialLocation: AppRoutes.cleanerBookingDetailLocation(
              '507f1f77bcf86cd799439091',
            ),
            routes: [
              GoRoute(
                path: AppRoutes.cleanerBookingDetailPath,
                builder: (context, state) => const CleanerBookingDetailScreen(
                  bookingId: '507f1f77bcf86cd799439091',
                ),
              ),
              GoRoute(
                path: AppRoutes.cleanerBookingChatPath,
                builder: (context, state) =>
                    const Scaffold(body: Text('Chat route')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Message Customer'), findsOneWidget);
    await tester.tap(find.text('Message Customer'));
    await tester.pumpAndSettle();
    expect(find.text('Chat route'), findsOneWidget);
  });

  testWidgets('chat shows mine vs other, composer, and no contacts', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingChatControllerProvider.overrideWith(
            () => SeededBookingChatController(
              BookingChatState(
                loading: false,
                conversation: testConversationDetail(),
                messages: [
                  testChatMessage(body: 'From me', isMine: true),
                  testChatMessage(
                    id: '507f1f77bcf86cd7994390b2',
                    body: 'From them',
                    isMine: false,
                    senderRole: 'cleaner',
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: BookingChatScreen(bookingId: '507f1f77bcf86cd799439091'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ada Cleaner'), findsOneWidget);
    expect(find.text('From me'), findsOneWidget);
    expect(find.text('From them'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.textContaining('phone'), findsNothing);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('read-only chat hides the composer', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingChatControllerProvider.overrideWith(
            () => SeededBookingChatController(
              BookingChatState(
                loading: false,
                readOnly: true,
                conversation: testConversationDetail(
                  bookingStatus: 'completed',
                  readOnly: true,
                ),
                messages: [testChatMessage()],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: BookingChatScreen(bookingId: '507f1f77bcf86cd799439091'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'This conversation is read-only because the booking is closed.',
      ),
      findsOneWidget,
    );
    expect(find.text('Send'), findsNothing);
  });
}

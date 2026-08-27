import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/login_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_home_screen.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_controller.dart';
import 'package:home_cleaning_marketplace/features/chat/presentation/booking_chat_controller.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/discovery_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/customer_review_controller.dart';

import '../helpers/auth_test_fakes.dart';
import '../helpers/feature_test_fakes.dart';
import 'acceptance_harness.dart';

const _bookingId = '507f1f77bcf86cd799439091';
const _cleanerId = '507f1f77bcf86cd799439081';
const _slotId = '507f1f77bcf86cd799439071';

void main() {
  testWidgets('customer unauthenticated paths: login, signup, verify pending', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpAcceptanceApp(tester, const AuthState.unauthenticated());
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsWidgets);
    expect(find.text('Customer'), findsOneWidget);

    routerOf(tester, find.text('Create account').first).go(
      AppRoutes.verifyEmailPendingLocation(
        email: 'customer@example.com',
        token: 'dev-token-abc',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Verify email'), findsWidgets);
    expect(find.text('Verification token'), findsOneWidget);
    expect(find.text('Verify email'), findsWidgets);
  });

  testWidgets('customer login from unauthenticated reaches home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = SeededAuthController(const AuthState.unauthenticated())
      ..nextAuthenticatedUser = testUser();
    await pumpAcceptanceApp(
      tester,
      const AuthState.unauthenticated(),
      controller: auth,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'person@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(auth.loginCalls, equals(1));
    expect(find.byType(CustomerHomeScreen), findsOneWidget);
  });

  testWidgets('customer authenticated journey covers all required stages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = await pumpAcceptanceApp(
      tester,
      AuthState.authenticated(testUser()),
      featureOverrides: () => featureControllerOverrides(
        customerProfile: CustomerProfileState(
          loading: false,
          profile: testCustomerProfile(),
        ),
        addresses: AddressListState(
          loading: false,
          addresses: [testAddress(isDefault: true)],
        ),
        discovery: DiscoveryState(
          loading: false,
          items: [testDiscoverySummary(ratingAverage: 4.8, reviewCount: 12)],
          detail: testDiscoveryDetail(ratingAverage: 4.8, reviewCount: 12),
        ),
        customerBooking: CustomerBookingState(
          loading: false,
          items: [testCustomerBooking(status: BookingStatus.confirmed)],
          detail: testCustomerBooking(status: BookingStatus.confirmed),
        ),
        customerPayment: CustomerPaymentState(
          loading: false,
          history: PaymentHistory(
            current: testPaymentAttempt(
              status: 'paid',
              paidAt: '2026-08-25T12:05:00.000Z',
            ),
            attempts: [
              testPaymentAttempt(
                status: 'paid',
                paidAt: '2026-08-25T12:05:00.000Z',
              ),
            ],
          ),
        ),
        bookingChat: BookingChatState(
          loading: false,
          conversation: testConversationDetail(),
          messages: [testChatMessage(body: 'Hello')],
        ),
        customerReview: CustomerReviewState(
          loading: false,
          review: testCustomerReview(),
        ),
      ),
    );
    expect(find.byType(CustomerHomeScreen), findsOneWidget);
    expect(find.text('Customer Home'), findsOneWidget);
    expect(find.text('Home Cleaning Service Marketplace'), findsOneWidget);
    expect(find.textContaining('person@example.com'), findsOneWidget);
    expect(find.text('Find a Cleaner'), findsOneWidget);
    expect(find.text('My Bookings'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);

    final router = routerOf(tester, find.byType(CustomerHomeScreen));

    router.go(AppRoutes.cleanerHomePath);
    await tester.pumpAndSettle();
    expect(find.byType(CustomerHomeScreen), findsOneWidget);
    router.go(AppRoutes.adminHomePath);
    await tester.pumpAndSettle();
    expect(find.byType(CustomerHomeScreen), findsOneWidget);

    router.go(AppRoutes.customerProfilePath);
    await tester.pumpAndSettle();
    expect(find.text('Customer profile'), findsWidgets);

    router.go(AppRoutes.customerAddressesPath);
    await tester.pumpAndSettle();
    expect(find.text('Addresses'), findsWidgets);

    router.go(AppRoutes.customerDiscoverPath);
    await tester.pumpAndSettle();
    expect(find.text('Find Cleaners'), findsWidgets);
    expect(find.textContaining('4.8'), findsWidgets);

    router.go('/customer/cleaners/$_cleanerId');
    await tester.pumpAndSettle();
    expect(find.text('Ada Cleaner'), findsWidgets);

    router.go(AppRoutes.customerBookSlotLocation(_cleanerId, _slotId));
    await tester.pumpAndSettle();
    expect(find.text('Confirm booking'), findsWidgets);

    router.go(AppRoutes.customerBookingsPath);
    await tester.pumpAndSettle();
    expect(find.text('My Bookings'), findsWidgets);
    expect(find.text('Ada Cleaner'), findsWidgets);

    router.go(AppRoutes.customerBookingDetailLocation(_bookingId));
    await tester.pumpAndSettle();
    expect(find.text('Booking details'), findsOneWidget);

    router.go(AppRoutes.customerBookingPaymentLocation(_bookingId));
    await tester.pumpAndSettle();
    expect(find.text('Payment'), findsWidgets);
    expect(find.text('Paid'), findsWidgets);

    router.go(AppRoutes.customerBookingChatLocation(_bookingId));
    await tester.pumpAndSettle();
    expect(find.text('Ada Cleaner'), findsWidgets);
    expect(find.text('Hello'), findsOneWidget);

    router.go(AppRoutes.notificationsPath);
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsWidgets);

    router.go(AppRoutes.customerBookingReviewLocation(_bookingId));
    await tester.pumpAndSettle();
    expect(find.text('Review'), findsWidgets);

    router.go(AppRoutes.customerBookingDisputeLocation(_bookingId));
    await tester.pumpAndSettle();
    expect(find.text('Dispute'), findsWidgets);

    router.go(AppRoutes.accountSecurityPath);
    await tester.pumpAndSettle();
    expect(find.text('Account security'), findsWidgets);

    router.go(AppRoutes.customerHomePath);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(auth.logoutCalls, equals(1));
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

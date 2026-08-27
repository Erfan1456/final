import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_finance_controller.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_finance_screens.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_home_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/account_security_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/login_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/signup_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/chat/presentation/booking_chat_controller.dart';
import 'package:home_cleaning_marketplace/features/chat/presentation/booking_chat_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_home_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_home_screen.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_controller.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_controller.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_screen.dart';
import 'package:home_cleaning_marketplace/features/earnings/presentation/cleaner_earnings_controller.dart';
import 'package:home_cleaning_marketplace/features/earnings/presentation/cleaner_earnings_screen.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_screen.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/customer_review_controller.dart';

import '../helpers/auth_test_fakes.dart';
import '../helpers/feature_test_fakes.dart';
import 'acceptance_harness.dart';

void main() {
  Future<void> expectNoOverflowFor(
    WidgetTester tester,
    Widget screen, {
    List<dynamic> overrides = const [],
    Size size = const Size(360, 640),
    double textScale = 1.0,
  }) async {
    final overflows = await captureOverflowErrors(() async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...overrides],
          child: MaterialApp(home: screen),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
    expect(
      overflows,
      isEmpty,
      reason:
          'Expected no overflow at ${size.width}x${size.height} @${textScale}x text',
    );
  }

  final customerAuth = [
    authControllerProvider.overrideWith(
      () => SeededAuthController(AuthState.authenticated(testUser())),
    ),
    customerProfileControllerProvider.overrideWith(
      () => SeededCustomerProfileController(
        const CustomerProfileState(loading: false),
      ),
    ),
    addressControllerProvider.overrideWith(
      () => SeededAddressController(const AddressListState(loading: false)),
    ),
    notificationControllerProvider.overrideWith(
      () =>
          SeededNotificationController(const NotificationState(loading: false)),
    ),
  ];

  final bookingDetailOverrides = [
    ...customerAuth,
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
  ];

  final chatOverrides = [
    bookingChatControllerProvider.overrideWith(
      () => SeededBookingChatController(
        BookingChatState(
          loading: false,
          conversation: testConversationDetail(),
          messages: [testChatMessage()],
        ),
      ),
    ),
  ];

  final earningsOverrides = [
    cleanerEarningsControllerProvider.overrideWith(
      () => SeededCleanerEarningsController(
        const CleanerEarningsState(loading: false),
      ),
    ),
  ];

  final financeOverrides = [
    adminFinanceControllerProvider.overrideWith(
      () => SeededAdminFinanceController(
        AdminFinanceState(loading: false, summary: testAdminFinanceSummary()),
      ),
    ),
  ];

  final paymentOverrides = [
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
            current: testPaymentAttempt(status: 'failed'),
            attempts: [testPaymentAttempt(status: 'failed')],
          ),
        ),
      ),
    ),
  ];

  final disputeOverrides = [
    bookingDisputeControllerProvider.overrideWith(
      () => SeededBookingDisputeController(
        BookingDisputeState(loading: false, dispute: testBookingDispute()),
      ),
    ),
  ];

  testWidgets('Login survives compact layout', (tester) async {
    await expectNoOverflowFor(
      tester,
      const LoginScreen(),
      overrides: [
        authControllerProvider.overrideWith(
          () => SeededAuthController(const AuthState.unauthenticated()),
        ),
      ],
    );
  });

  testWidgets('Signup survives compact layout', (tester) async {
    await expectNoOverflowFor(tester, const SignupScreen());
  });

  testWidgets('CustomerHome survives compact layout', (tester) async {
    await expectNoOverflowFor(
      tester,
      const CustomerHomeScreen(),
      overrides: customerAuth,
    );
  });

  testWidgets('CleanerHome survives compact layout', (tester) async {
    await expectNoOverflowFor(
      tester,
      const CleanerHomeScreen(),
      overrides: [
        authControllerProvider.overrideWith(
          () => SeededAuthController(
            AuthState.authenticated(testUser(role: 'cleaner')),
          ),
        ),
        cleanerOnboardingControllerProvider.overrideWith(
          () => SeededCleanerOnboardingController(
            const CleanerOnboardingState(loading: false),
          ),
        ),
        notificationControllerProvider.overrideWith(
          () => SeededNotificationController(
            const NotificationState(loading: false),
          ),
        ),
      ],
    );
  });

  testWidgets('AdminHome survives compact layout', (tester) async {
    await expectNoOverflowFor(
      tester,
      const AdminHomeScreen(),
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
    );
  });

  testWidgets('AccountSecurity survives compact layout', (tester) async {
    await expectNoOverflowFor(tester, const AccountSecurityScreen());
  });

  testWidgets('Booking detail survives 360x640', (tester) async {
    await expectNoOverflowFor(
      tester,
      const CustomerBookingDetailScreen(bookingId: '507f1f77bcf86cd799439091'),
      overrides: bookingDetailOverrides,
    );
  });

  testWidgets('Booking chat survives 360x640', (tester) async {
    await expectNoOverflowFor(
      tester,
      const BookingChatScreen(bookingId: '507f1f77bcf86cd799439091'),
      overrides: chatOverrides,
    );
  });

  testWidgets('Cleaner earnings survives 360x640', (tester) async {
    await expectNoOverflowFor(
      tester,
      const CleanerEarningsScreen(),
      overrides: earningsOverrides,
    );
  });

  testWidgets('Admin finance survives 360x640', (tester) async {
    await expectNoOverflowFor(
      tester,
      const AdminFinanceScreen(),
      overrides: financeOverrides,
    );
  });

  testWidgets('Login survives large text scale', (tester) async {
    await expectNoOverflowFor(
      tester,
      const LoginScreen(),
      textScale: 2.0,
      overrides: [
        authControllerProvider.overrideWith(
          () => SeededAuthController(const AuthState.unauthenticated()),
        ),
      ],
    );
  });

  testWidgets('Booking detail survives large text scale', (tester) async {
    await expectNoOverflowFor(
      tester,
      const CustomerBookingDetailScreen(bookingId: '507f1f77bcf86cd799439091'),
      textScale: 2.0,
      overrides: bookingDetailOverrides,
    );
  });

  testWidgets('Booking chat survives large text scale', (tester) async {
    await expectNoOverflowFor(
      tester,
      const BookingChatScreen(bookingId: '507f1f77bcf86cd799439091'),
      textScale: 2.0,
      overrides: chatOverrides,
    );
  });

  testWidgets('Cleaner earnings survives large text scale', (tester) async {
    await expectNoOverflowFor(
      tester,
      const CleanerEarningsScreen(),
      textScale: 2.0,
      overrides: earningsOverrides,
    );
  });

  testWidgets('Admin finance survives large text scale', (tester) async {
    await expectNoOverflowFor(
      tester,
      const AdminFinanceScreen(),
      textScale: 2.0,
      overrides: financeOverrides,
    );
  });

  testWidgets('Customer payment survives large text scale', (tester) async {
    await expectNoOverflowFor(
      tester,
      const CustomerPaymentScreen(bookingId: '507f1f77bcf86cd799439091'),
      textScale: 2.0,
      overrides: paymentOverrides,
    );
  });

  testWidgets('Booking dispute survives large text scale', (tester) async {
    await expectNoOverflowFor(
      tester,
      const BookingDisputeScreen(bookingId: '507f1f77bcf86cd799439091'),
      textScale: 2.0,
      overrides: disputeOverrides,
    );
  });

  testWidgets('AccountSecurity survives large text scale', (tester) async {
    await expectNoOverflowFor(
      tester,
      const AccountSecurityScreen(),
      textScale: 2.0,
    );
  });
}

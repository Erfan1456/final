import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_home_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';
import 'package:home_cleaning_marketplace/features/earnings/data/earnings_models.dart';
import 'package:home_cleaning_marketplace/features/earnings/presentation/cleaner_earnings_controller.dart';
import 'package:home_cleaning_marketplace/features/earnings/presentation/cleaner_earnings_screen.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_controller.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('cleaner home shows Earnings & Payouts even when pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(
              AuthState.authenticated(testUser(role: 'cleaner')),
            ),
          ),
          cleanerOnboardingControllerProvider.overrideWith(
            () => SeededCleanerOnboardingController(
              CleanerOnboardingState(
                loading: false,
                profile: testCleanerProfile(status: OnboardingStatus.pending),
              ),
            ),
          ),
          notificationControllerProvider.overrideWith(
            () => SeededNotificationController(
              const NotificationState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(home: CleanerHomeScreen()),
      ),
    );
    expect(find.text('Earnings & Payouts'), findsOneWidget);
    expect(find.textContaining('bank'), findsNothing);
  });

  testWidgets('earnings screen shows summary values and negative balance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerEarningsControllerProvider.overrideWith(
            () => SeededCleanerEarningsController(
              CleanerEarningsState(
                loading: false,
                summary: EarningsSummary(
                  currencies: [
                    testEarningsSummary(available: -5000),
                    testEarningsSummary(currency: 'USD'),
                  ],
                ),
                selectedCurrency: 'BDT',
                ledger: [
                  testEarningsLedgerEntry(
                    type: 'refund_adjustment',
                    cleanerAmount: -17000,
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: CleanerEarningsScreen()),
      ),
    );
    expect(find.textContaining('Gross service value'), findsOneWidget);
    expect(find.textContaining('Platform fees'), findsOneWidget);
    expect(find.textContaining('Available balance:'), findsOneWidget);
    expect(find.textContaining('negative'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.textContaining('income received'), findsNothing);
    expect(find.textContaining('profit'), findsNothing);
  });

  testWidgets('payout request shows available balance and no bank form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerEarningsControllerProvider.overrideWith(
            () => SeededCleanerEarningsController(
              CleanerEarningsState(
                loading: false,
                summary: EarningsSummary(currencies: [testEarningsSummary()]),
                selectedCurrency: 'BDT',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: CleanerPayoutRequestScreen()),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Available balance'), findsOneWidget);
    expect(find.textContaining('development payout workflow'), findsOneWidget);
    expect(find.text('Request Payout'), findsOneWidget);
    expect(find.textContaining('bank account'), findsNothing);
    expect(find.textContaining('CVV'), findsNothing);
  });

  testWidgets('payout history shows cancel and rejection reason', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerEarningsControllerProvider.overrideWith(
            () => SeededCleanerEarningsController(
              CleanerEarningsState(
                loading: false,
                payouts: [
                  testCleanerPayout(),
                  testCleanerPayout(
                    status: 'rejected',
                    rejectionReason: 'Incomplete documentation for review.',
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: CleanerPayoutHistoryScreen()),
      ),
    );
    expect(find.text('Cancel Request'), findsOneWidget);
    expect(find.textContaining('Incomplete documentation'), findsOneWidget);
  });
}

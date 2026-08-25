import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_finance_controller.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_finance_screens.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_home_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_payout_controller.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_payout_screens.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_controller.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('AdminHome shows Payouts and Finance', (tester) async {
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
    expect(find.text('Payouts'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Disputes'), findsOneWidget);
  });

  testWidgets('payout list shows requested items and load more', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SeededAdminPayoutController(
      AdminPayoutState(
        loading: false,
        items: [testCleanerPayout()],
        nextCursor: 'next-id',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminPayoutControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: AdminPayoutListScreen()),
      ),
    );
    expect(find.textContaining('Ada Cleaner'), findsOneWidget);
    expect(find.text('Load More'), findsOneWidget);
    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(controller.loadMoreCalls, equals(1));
  });

  testWidgets('detail process reject and sandbox only when available', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SeededAdminPayoutController(
      AdminPayoutState(
        loading: false,
        detail: testAdminPayoutDetail(simulationAvailable: true),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminPayoutControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(
          home: AdminPayoutDetailScreen(payoutId: '507f1f77bcf86cd7994390f1'),
        ),
      ),
    );
    expect(find.text('Process'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Development Sandbox'), findsOneWidget);
    expect(find.text('Simulate Success'), findsOneWidget);
    expect(find.textContaining('bank transfer'), findsNothing);
    await tester.tap(find.text('Simulate Success'));
    await tester.pump();
    expect(controller.simulateSuccessCalls, equals(1));
  });

  testWidgets('sandbox buttons hidden when not available', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminPayoutControllerProvider.overrideWith(
            () => SeededAdminPayoutController(
              AdminPayoutState(loading: false, detail: testAdminPayoutDetail()),
            ),
          ),
        ],
        child: const MaterialApp(
          home: AdminPayoutDetailScreen(payoutId: '507f1f77bcf86cd7994390f1'),
        ),
      ),
    );
    expect(find.text('Simulate Success'), findsNothing);
    expect(find.text('Development Sandbox'), findsNothing);
  });

  testWidgets('finance summary separates currencies and has reconciliation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminFinanceControllerProvider.overrideWith(
            () => SeededAdminFinanceController(
              AdminFinanceState(
                loading: false,
                summary: testAdminFinanceSummary(),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminFinanceScreen()),
      ),
    );
    expect(find.textContaining('Gross service volume'), findsOneWidget);
    expect(find.textContaining('Platform fees'), findsOneWidget);
    expect(find.text('Reconciliation Issues'), findsOneWidget);
    expect(find.textContaining('profit'), findsNothing);
  });

  testWidgets('reconciliation shows missing earning issue', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminFinanceControllerProvider.overrideWith(
            () => SeededAdminFinanceController(
              AdminFinanceState(
                loading: false,
                issues: [
                  testReconciliationIssue(),
                  testReconciliationIssue(type: 'refund_adjustment_mismatch'),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminFinanceReconciliationScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Missing service earning'), findsOneWidget);
    expect(find.text('Refund adjustment mismatch'), findsOneWidget);
    expect(find.textContaining('Repair'), findsNothing);
  });
}

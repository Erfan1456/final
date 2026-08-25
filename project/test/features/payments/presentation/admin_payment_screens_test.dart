import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_home_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/admin_payment_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/admin_payment_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/admin_payment_list_screen.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_controller.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('AdminHome shows Payments', (tester) async {
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
    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('Cleaner Approvals'), findsOneWidget);
  });

  testWidgets('list shows items, filters, and load more', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SeededAdminPaymentController(
      AdminPaymentState(
        loading: false,
        items: [testAdminPaymentSummary()],
        nextCursor: 'next-id',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminPaymentControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: AdminPaymentListScreen()),
      ),
    );
    expect(find.textContaining('Paid'), findsWidgets);
    expect(find.textContaining('Development Sandbox'), findsOneWidget);
    expect(find.text('Load More'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Paid'));
    await tester.pump();
    expect(controller.loadCalls, equals(1));
    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(controller.loadMoreCalls, equals(1));
  });

  testWidgets('detail shows events and refund dialog validation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SeededAdminPaymentController(
      AdminPaymentState(
        loading: false,
        detail: testAdminPaymentDetail(),
        events: [PaymentWebhookEventSummary.fromJson(webhookEventJson())],
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminPaymentControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(
          home: AdminPaymentDetailScreen(paymentId: '507f1f77bcf86cd7994390d1'),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Webhook events'), findsOneWidget);
    expect(find.textContaining('payment.succeeded'), findsOneWidget);
    expect(find.text('Refund'), findsOneWidget);
    await tester.tap(find.text('Refund'));
    await tester.pumpAndSettle();
    expect(controller.beginRefundCalls, equals(1));
    await tester.enterText(find.byType(TextField).last, 'no');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Refund'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Reason must be between 5 and 500 characters.'),
      findsOneWidget,
    );
    expect(controller.refundCalls, equals(0));
    await tester.enterText(
      find.byType(TextField).last,
      'Customer requested a refund.',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Refund'),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.refundCalls, equals(1));
    expect(controller.lastRefundReason, equals('Customer requested a refund.'));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_audit_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_audit_list_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_audit_log_controller.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_booking_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_booking_list_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_booking_operations_controller.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_user_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_user_list_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_user_management_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('users list filters by role and load more', (tester) async {
    _useTallSurface(tester);
    final users = SeededAdminUserManagementController(
      AdminUserManagementState(
        loading: false,
        items: [testAdminUserSummary()],
        nextCursor: 'next',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserManagementControllerProvider.overrideWith(() => users),
        ],
        child: const MaterialApp(home: AdminUserListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('pat.customer@example.com'), findsOneWidget);
    await tester.tap(find.text('Cleaner'));
    await tester.pump();
    expect(users.lastFilters?.role, 'cleaner');
    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(users.loadMoreCalls, 1);
  });

  testWidgets('protected admin detail hides moderation actions', (
    tester,
  ) async {
    _useTallSurface(tester);
    final protected = SeededAdminUserManagementController(
      AdminUserManagementState(
        loading: false,
        detail: testAdminUserDetail(protectedAdmin: true),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserManagementControllerProvider.overrideWith(() => protected),
        ],
        child: const MaterialApp(
          home: AdminUserDetailScreen(userId: '507f1f77bcf86cd799439099'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Protected administrator account'), findsOneWidget);
    expect(find.text('Suspend'), findsNothing);
    expect(find.text('Deactivate'), findsNothing);
  });

  testWidgets('customer detail suspend requires a reason', (tester) async {
    _useTallSurface(tester);
    final active = SeededAdminUserManagementController(
      AdminUserManagementState(loading: false, detail: testAdminUserDetail()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserManagementControllerProvider.overrideWith(() => active),
        ],
        child: const MaterialApp(
          home: AdminUserDetailScreen(userId: '507f1f77bcf86cd799439011'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suspend'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextField),
      'Repeated no-show complaints',
    );
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(active.suspendCalls, 1);
    expect(active.lastReason, 'Repeated no-show complaints');
  });

  testWidgets('admin bookings list shows payment and dispute summary', (
    tester,
  ) async {
    _useTallSurface(tester);
    final list = SeededAdminBookingOperationsController(
      AdminBookingOperationsState(
        loading: false,
        items: [
          testAdminBookingSummary(paymentStatus: 'paid', disputeStatus: 'open'),
        ],
        nextCursor: 'next',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminBookingOperationsControllerProvider.overrideWith(() => list),
        ],
        child: const MaterialApp(home: AdminBookingListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Home Cleaning'), findsWidgets);
    expect(find.textContaining('Paid'), findsWidgets);
    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(list.loadMoreCalls, 1);
  });

  testWidgets('paid booking detail warns and cancels with a reason', (
    tester,
  ) async {
    _useTallSurface(tester);
    final detail = SeededAdminBookingOperationsController(
      AdminBookingOperationsState(
        loading: false,
        detail: testAdminBookingDetail(paymentStatus: 'paid'),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminBookingOperationsControllerProvider.overrideWith(() => detail),
        ],
        child: const MaterialApp(
          home: AdminBookingDetailScreen(bookingId: '507f1f77bcf86cd799439091'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('requires a refund'), findsOneWidget);
    await tester.tap(find.text('Cancel Booking'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextField),
      'Duplicate booking created by mistake',
    );
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(detail.cancelCalls, 1);
  });

  testWidgets('audit log list shows action and load more', (tester) async {
    _useTallSurface(tester);
    final list = SeededAdminAuditLogController(
      AdminAuditLogState(
        loading: false,
        items: [testAdminAuditLog()],
        nextCursor: 'next',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminAuditLogControllerProvider.overrideWith(() => list)],
        child: const MaterialApp(home: AdminAuditListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('User suspended'), findsWidgets);
    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(list.loadMoreCalls, 1);
  });

  testWidgets('audit detail renders safe metadata without raw JSON', (
    tester,
  ) async {
    _useTallSurface(tester);
    final detail = SeededAdminAuditLogController(
      AdminAuditLogState(loading: false, detail: testAdminAuditLog()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminAuditLogControllerProvider.overrideWith(() => detail)],
        child: const MaterialApp(
          home: AdminAuditDetailScreen(auditLogId: '507f1f77bcf86cd7994390f1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('previous_status: active'), findsOneWidget);
    expect(find.textContaining('{'), findsNothing);
  });
}

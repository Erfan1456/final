import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_cleaner_models.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_cleaner_review_controller.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_home_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/cleaner_approval_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/cleaner_approval_list_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('AdminHome shows dashboard and approvals navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(
              AuthState.authenticated(testUser(role: 'admin')),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminHomeScreen()),
      ),
    );
    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('admin@example.com'), findsNothing);
    expect(find.text('person@example.com'), findsOneWidget);
    expect(find.text('Cleaner Approvals'), findsOneWidget);
    expect(find.text('Payments'), findsOneWidget);
  });

  testWidgets('approval list shows pending items and filters', (tester) async {
    final controller = SeededAdminCleanerReviewController(
      AdminCleanerReviewState(
        loading: false,
        items: [testAdminSummary()],
        nextCursor: 'next-id',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminCleanerReviewControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: CleanerApprovalListScreen()),
      ),
    );

    expect(find.text('Pending Cleaner'), findsOneWidget);
    expect(find.textContaining('pending.cleaner@example.com'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Load More'), findsOneWidget);

    await tester.tap(find.text('Approved'));
    await tester.pump();
    expect(controller.loadCalls, equals(1));

    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(controller.loadMoreCalls, equals(1));
  });

  testWidgets('approval detail can confirm approve', (tester) async {
    final controller = SeededAdminCleanerReviewController(
      AdminCleanerReviewState(
        loading: false,
        detail: AdminCleanerApplicationDetail(
          userId: '507f1f77bcf86cd799439077',
          email: 'pending.cleaner@example.com',
          profile: testCleanerProfile(status: OnboardingStatus.pending),
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminCleanerReviewControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(
          home: CleanerApprovalDetailScreen(userId: '507f1f77bcf86cd799439077'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Test Cleaner'), findsOneWidget);
    expect(find.text('pending.cleaner@example.com'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(find.text('Approve cleaner?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Approve'));
    await tester.pumpAndSettle();
    expect(controller.approveCalls, equals(1));
  });

  testWidgets('reject reason shorter than 5 characters is rejected', (
    tester,
  ) async {
    final controller = SeededAdminCleanerReviewController(
      AdminCleanerReviewState(
        loading: false,
        detail: AdminCleanerApplicationDetail(
          userId: '507f1f77bcf86cd799439077',
          email: 'pending.cleaner@example.com',
          profile: testCleanerProfile(status: OnboardingStatus.pending),
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminCleanerReviewControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(
          home: CleanerApprovalDetailScreen(userId: '507f1f77bcf86cd799439077'),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no');
    await tester.tap(find.widgetWithText(TextButton, 'Reject'));
    await tester.pumpAndSettle();
    expect(find.text('Reason must be at least 5 characters.'), findsOneWidget);
    expect(controller.rejectCalls, equals(0));
  });
}

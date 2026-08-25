import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/admin_review_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/admin_review_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/admin_review_list_screen.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/cleaner_reviews_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/cleaner_reviews_screen.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/customer_review_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/customer_review_screen.dart';

import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('customer review form uses stars and hidden note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reviews = SeededCustomerReviewController(
      CustomerReviewState(
        loading: false,
        review: testCustomerReview(moderationStatus: 'hidden'),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerReviewControllerProvider.overrideWith(() => reviews),
          customerBookingControllerProvider.overrideWith(
            () => SeededCustomerBookingController(
              CustomerBookingState(
                loading: false,
                detail: testCustomerBooking(status: BookingStatus.completed),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: CustomerReviewScreen(bookingId: '507f1f77bcf86cd799439091'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ada Cleaner'), findsOneWidget);
    expect(find.text('Home Cleaning'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsWidgets);
    expect(
      find.text('This review is hidden. Editing it will keep it hidden.'),
      findsOneWidget,
    );
    expect(find.textContaining('republish'), findsNothing);
    await tester.tap(find.text('Save Review'));
    await tester.pump();
    expect(reviews.saveCalls, equals(1));
    expect(reviews.lastRating, equals(5));
  });

  testWidgets('cleaner reviews show verified customer and filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SeededCleanerReviewsController(
      CleanerReviewsState(
        loading: false,
        items: [testCleanerReview()],
        nextCursor: 'next',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerReviewsControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: CleanerReviewsScreen()),
      ),
    );
    expect(find.textContaining('Verified customer'), findsOneWidget);
    expect(find.text('Load More'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
    expect(find.textContaining('phone'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Hidden'));
    await tester.pump();
    expect(controller.lastStatus, equals('hidden'));
    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(controller.loadMoreCalls, equals(1));
  });

  testWidgets('admin list filters and load more', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SeededAdminReviewController(
      AdminReviewState(
        loading: false,
        items: [testAdminReviewSummary()],
        nextCursor: 'next',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminReviewControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: AdminReviewListScreen()),
      ),
    );
    expect(find.textContaining('Published'), findsWidgets);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Hidden'));
    await tester.pump();
    expect(controller.lastFilters?.status, equals('hidden'));
    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(controller.loadMoreCalls, equals(1));
  });

  testWidgets('admin detail hide requires a reason', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SeededAdminReviewController(
      AdminReviewState(loading: false, detail: testAdminReviewDetail()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminReviewControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(
          home: AdminReviewDetailScreen(reviewId: '507f1f77bcf86cd7994390e1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hide Review'), findsOneWidget);
    await tester.tap(find.text('Hide Review'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no');
    await tester.tap(find.widgetWithText(FilledButton, 'Hide'));
    await tester.pump();
    expect(
      find.text('Reason must be between 5 and 500 characters.'),
      findsOneWidget,
    );
    expect(controller.hideCalls, equals(0));
    await tester.enterText(find.byType(TextField), 'Off-topic language here.');
    await tester.tap(find.widgetWithText(FilledButton, 'Hide'));
    await tester.pumpAndSettle();
    expect(controller.hideCalls, equals(1));
    expect(controller.lastHideReason, equals('Off-topic language here.'));
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_api.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_models.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/admin_review_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/cleaner_reviews_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/customer_review_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeCustomerReviewApi extends CustomerReviewApi {
  _FakeCustomerReviewApi() : super(Dio());

  CustomerReview? review;
  ApiFailure? nextError;
  int getCalls = 0;
  int saveCalls = 0;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<CustomerReview?> getForBooking(String bookingId) async {
    getCalls += 1;
    _throwIfNeeded();
    return review;
  }

  @override
  Future<CustomerReview> upsertForBooking({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    saveCalls += 1;
    _throwIfNeeded();
    return testCustomerReview(rating: rating);
  }
}

class _FakeCleanerReviewApi extends CleanerReviewApi {
  _FakeCleanerReviewApi() : super(Dio());

  ReviewPage<CleanerReview> page = ReviewPage(
    items: [testCleanerReview()],
    nextCursor: 'cursor-1',
  );
  int listCalls = 0;
  String? lastStatus;
  String? lastAfter;

  @override
  Future<ReviewPage<CleanerReview>> list({
    String? status,
    int? limit,
    String? after,
  }) async {
    listCalls += 1;
    lastStatus = status;
    lastAfter = after;
    return page;
  }
}

class _FakeAdminReviewApi extends AdminReviewApi {
  _FakeAdminReviewApi() : super(Dio());

  ReviewPage<AdminReviewSummary> page = ReviewPage(
    items: [testAdminReviewSummary()],
    nextCursor: 'cursor-1',
  );
  AdminReviewDetail detail = testAdminReviewDetail();
  int listCalls = 0;
  int hideCalls = 0;
  String? lastStatus;
  int? lastRating;
  String? lastReason;

  @override
  Future<ReviewPage<AdminReviewSummary>> list({
    String? status,
    int? rating,
    String? cleanerUserId,
    int? limit,
    String? after,
  }) async {
    listCalls += 1;
    lastStatus = status;
    lastRating = rating;
    return page;
  }

  @override
  Future<AdminReviewDetail> get(String reviewId) async {
    return detail;
  }

  @override
  Future<AdminReviewDetail> hide({
    required String reviewId,
    required String reason,
  }) async {
    hideCalls += 1;
    lastReason = reason;
    return testAdminReviewDetail(
      moderationStatus: 'hidden',
      hiddenReason: reason,
    );
  }

  @override
  Future<AdminReviewDetail> unhide(String reviewId) async {
    return testAdminReviewDetail();
  }
}

void main() {
  test('customer load and save', () async {
    final api = _FakeCustomerReviewApi()..review = testCustomerReview();
    final container = ProviderContainer(
      overrides: [customerReviewApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await container
        .read(customerReviewControllerProvider.notifier)
        .load('507f1f77bcf86cd799439091');
    expect(
      container.read(customerReviewControllerProvider).review?.rating,
      equals(5),
    );
    final saved = await container
        .read(customerReviewControllerProvider.notifier)
        .save(bookingId: '507f1f77bcf86cd799439091', rating: 4);
    expect(saved, isTrue);
    expect(api.saveCalls, equals(1));
  });

  test('review_not_allowed on load is silent', () async {
    final api = _FakeCustomerReviewApi()
      ..nextError = ApiFailure(
        code: 'review_not_allowed',
        message: messageForApiCode('review_not_allowed'),
      );
    final container = ProviderContainer(
      overrides: [customerReviewApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await container
        .read(customerReviewControllerProvider.notifier)
        .load('507f1f77bcf86cd799439091');
    expect(container.read(customerReviewControllerProvider).review, isNull);
    expect(
      container.read(customerReviewControllerProvider).errorMessage,
      isNull,
    );
  });

  test('cleaner load and loadMore', () async {
    final api = _FakeCleanerReviewApi();
    final container = ProviderContainer(
      overrides: [cleanerReviewApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await container.read(cleanerReviewsControllerProvider.notifier).load();
    expect(
      container.read(cleanerReviewsControllerProvider).items,
      hasLength(1),
    );
    api.page = const ReviewPage(items: []);
    await container.read(cleanerReviewsControllerProvider.notifier).loadMore();
    expect(api.lastAfter, equals('cursor-1'));
  });

  test('admin hide updates detail', () async {
    final api = _FakeAdminReviewApi();
    final container = ProviderContainer(
      overrides: [adminReviewApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await container.read(adminReviewControllerProvider.notifier).load();
    await container
        .read(adminReviewControllerProvider.notifier)
        .loadDetail('507f1f77bcf86cd7994390e1');
    final hidden = await container
        .read(adminReviewControllerProvider.notifier)
        .hide(
          reviewId: '507f1f77bcf86cd7994390e1',
          reason: 'Off-topic language here.',
        );
    expect(hidden, isTrue);
    expect(api.lastReason, equals('Off-topic language here.'));
    expect(
      container.read(adminReviewControllerProvider).detail?.isHidden,
      isTrue,
    );
  });
}

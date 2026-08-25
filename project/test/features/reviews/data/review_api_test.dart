import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_api.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_models.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

void main() {
  test('customer review JSON omits customer identifiers', () {
    final json = customerReviewJson();
    expect(json.containsKey('customer_user_id'), isFalse);
    expect(json['verified_booking'], isTrue);
    expect(
      CustomerReview.fromJson(json).moderationStatus,
      equals(ReviewModerationStatus.published),
    );
  });

  test('getForBooking parses a nullable review', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      return jsonBody(successEnvelope(<String, dynamic>{'review': null}), 200);
    });
    expect(await CustomerReviewApi(dio).getForBooking('booking'), isNull);
  });

  test('upsert sends rating and comment', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      expect(options.data['rating'], equals(5));
      expect(options.data['comment'], equals('Great job.'));
      return jsonBody(
        successEnvelope(<String, dynamic>{'review': customerReviewJson()}),
        201,
      );
    });
    final review = await CustomerReviewApi(dio).upsertForBooking(
      bookingId: '507f1f77bcf86cd799439091',
      rating: 5,
      comment: 'Great job.',
    );
    expect(review.rating, equals(5));
  });

  test('cleaner list uses status and cursor', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      expect(options.queryParameters['status'], equals('published'));
      expect(options.queryParameters['after'], equals('cursor-1'));
      return jsonBody(
        successEnvelope(<String, dynamic>{
          'items': [cleanerReviewJson()],
          'next_cursor': null,
        }),
        200,
      );
    });
    final page = await CleanerReviewApi(dio)
        .list(status: 'published', after: 'cursor-1');
    expect(page.items.single.reviewerDisplayName, equals('Verified customer'));
  });

  test('admin hide sends a reason', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      expect(options.data['reason'], equals('Off-topic language here.'));
      return jsonBody(
        successEnvelope(
          adminReviewJson(
            moderationStatus: 'hidden',
            hiddenReason: 'Off-topic language here.',
          ),
        ),
        200,
      );
    });
    final detail = await AdminReviewApi(dio).hide(
      reviewId: '507f1f77bcf86cd7994390e1',
      reason: 'Off-topic language here.',
    );
    expect(detail.isHidden, isTrue);
  });

  test('review_not_allowed maps to a safe ApiFailure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      return jsonBody(
        errorEnvelope(code: 'review_not_allowed', message: 'ignored'),
        409,
      );
    });
    await expectLater(
      CustomerReviewApi(dio)
          .upsertForBooking(bookingId: '507f1f77bcf86cd799439091', rating: 5),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.message,
          'message',
          contains('completed'),
        ),
      ),
    );
  });
}

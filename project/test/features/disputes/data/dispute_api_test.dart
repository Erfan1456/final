import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_api.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_models.dart';

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
  test('unknown dispute enums are safe', () {
    expect(DisputeStatus.fromWire('reopened'), DisputeStatus.unknown);
    expect(DisputeCategory.fromWire('legal'), DisputeCategory.unknown);
  });

  test('getForBooking parses null and existing disputes', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    var calls = 0;
    dio.httpClientAdapter = _Adapter((options) async {
      calls += 1;
      if (calls == 1) {
        return jsonBody(
          successEnvelope(<String, dynamic>{'dispute': null}),
          200,
        );
      }
      return jsonBody(
        successEnvelope(<String, dynamic>{'dispute': bookingDisputeJson()}),
        200,
      );
    });
    final api = BookingDisputeApi(dio);
    expect(await api.getForBooking('booking'), isNull);
    expect((await api.getForBooking('booking'))!.status, DisputeStatus.open);
  });

  test('create close and admin lifecycle parse safely', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      if (options.path.contains('/review') ||
          options.path.contains('/resolve') ||
          options.path.contains('/close') ||
          options.method == 'GET' &&
              options.path.contains('/admin/disputes/')) {
        return jsonBody(
          successEnvelope(<String, dynamic>{
            'dispute': adminDisputeJson(status: 'under_review'),
            'booking': <String, dynamic>{
              'id': '507f1f77bcf86cd799439091',
              'status': 'confirmed',
              'service_name': 'Home Cleaning',
              'start_at': '2026-09-01T03:00:00.000Z',
              'end_at': '2026-09-01T05:00:00.000Z',
              'quoted_total_minor': 8000,
              'currency_code': 'USD',
            },
          }),
          200,
        );
      }
      if (options.path.endsWith('/disputes')) {
        return jsonBody(
          successEnvelope(<String, dynamic>{
            'items': [adminDisputeJson()],
            'next_cursor': null,
          }),
          200,
        );
      }
      if (options.path.contains('/close')) {
        return jsonBody(
          successEnvelope(<String, dynamic>{
            'dispute': bookingDisputeJson(status: 'closed'),
          }),
          200,
        );
      }
      return jsonBody(
        successEnvelope(<String, dynamic>{'dispute': bookingDisputeJson()}),
        201,
      );
    });
    final created = await BookingDisputeApi(dio).create(
      bookingId: '507f1f77bcf86cd799439091',
      category: 'service_quality',
      subject: 'Late arrival issue',
      description: 'The cleaner arrived more than two hours late to the job.',
    );
    expect(created.status, DisputeStatus.open);
    final admin = AdminDisputeApi(dio);
    final page = await admin.list(status: 'open');
    expect(page.items, hasLength(1));
    expect((await admin.get('id')).dispute.status, DisputeStatus.underReview);
  });

  test('maps dispute_already_exists safely', () {
    expect(
      messageForApiCode('dispute_already_exists'),
      contains('already exists'),
    );
  });
}

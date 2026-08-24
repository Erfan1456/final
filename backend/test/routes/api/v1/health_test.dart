import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/api/v1/health.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  group('GET /api/v1/health', () {
    test('responds with a 200 JSON health payload', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();
      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        response.headers[HttpHeaders.contentTypeHeader],
        contains('application/json'),
      );
      expect(body['success'], isTrue);
      expect(data['status'], equals('ok'));
      expect(data['service'], equals('home_cleaning_marketplace_api'));
      expect(data['environment'], equals('development'));
    });
  });
}

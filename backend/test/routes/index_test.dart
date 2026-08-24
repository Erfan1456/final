import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  group('GET /', () {
    test('responds with a JSON service descriptor', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();
      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        response.headers[HttpHeaders.contentTypeHeader],
        contains('application/json'),
      );
      expect(body['success'], isTrue);
      expect(
        (body['data'] as Map<String, dynamic>)['service'],
        equals('home_cleaning_marketplace_api'),
      );
      expect(
        (body['data'] as Map<String, dynamic>)['api'],
        equals('/api/v1'),
      );
    });
  });
}

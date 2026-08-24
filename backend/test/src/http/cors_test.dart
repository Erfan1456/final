import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/http/cors_headers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/_middleware.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  group('corsHeaders', () {
    test('is empty when no origin is allowed', () {
      expect(corsHeaders(null), isEmpty);
    });

    test('includes CORS headers for an allowed origin', () {
      final headers = corsHeaders('http://localhost:3000');

      expect(
        headers[HttpHeaders.accessControlAllowOriginHeader],
        equals('http://localhost:3000'),
      );
      expect(
        headers[HttpHeaders.accessControlAllowMethodsHeader],
        contains('OPTIONS'),
      );
      expect(
        headers[HttpHeaders.accessControlAllowHeadersHeader],
        contains('Content-Type'),
      );
    });
  });

  group('middleware OPTIONS preflight', () {
    test('returns 204 for a development localhost origin', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();
      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.options);
      when(() => request.headers).thenReturn(
        const <String, String>{'origin': 'http://localhost:3000'},
      );

      Future<Response> unusedHandler(RequestContext context) {
        return Future<Response>.value(Response());
      }

      final response = await middleware(unusedHandler)(context);

      expect(response.statusCode, equals(HttpStatus.noContent));
      expect(
        response.headers[HttpHeaders.accessControlAllowOriginHeader],
        equals('http://localhost:3000'),
      );
    });
  });
}

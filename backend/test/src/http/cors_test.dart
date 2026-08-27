import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
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
      expect(
        headers[HttpHeaders.accessControlAllowHeadersHeader],
        contains('Idempotency-Key'),
      );
      expect(
        headers[HttpHeaders.accessControlAllowHeadersHeader],
        contains('Authorization'),
      );
    });
  });

  group('middleware OPTIONS preflight', () {
    tearDown(resetMiddlewareCaches);

    test('returns 204 for a development localhost origin', () async {
      resetMiddlewareCaches(
        config: const ServerConfig(
          environment: 'development',
          allowedOrigins: <String>[],
        ),
      );

      final response = await _options('http://localhost:3000');

      expect(response.statusCode, equals(HttpStatus.noContent));
      expect(
        response.headers[HttpHeaders.accessControlAllowOriginHeader],
        equals('http://localhost:3000'),
      );
      expect(response.headers['X-Content-Type-Options'], equals('nosniff'));
      expect(response.headers['X-Request-Id'], isNotEmpty);
    });

    test('echoes a configured allowed origin', () async {
      resetMiddlewareCaches(
        config: const ServerConfig(
          environment: 'production',
          allowedOrigins: <String>['https://app.example.test'],
        ),
      );

      final response = await _options('https://app.example.test');

      expect(response.statusCode, equals(HttpStatus.noContent));
      expect(
        response.headers[HttpHeaders.accessControlAllowOriginHeader],
        equals('https://app.example.test'),
      );
    });

    test('omits Allow-Origin for a disallowed origin', () async {
      resetMiddlewareCaches(
        config: const ServerConfig(
          environment: 'production',
          allowedOrigins: <String>['https://app.example.test'],
        ),
      );

      final response = await _options('http://localhost:3000');

      expect(response.statusCode, equals(HttpStatus.noContent));
      expect(
        response.headers[HttpHeaders.accessControlAllowOriginHeader],
        isNull,
      );
    });

    test('does not reflect an arbitrary unknown origin', () async {
      resetMiddlewareCaches(
        config: const ServerConfig(
          environment: 'production',
          allowedOrigins: <String>['https://app.example.test'],
        ),
      );

      final response = await _options('https://evil.example.test');
      expect(
        response.headers[HttpHeaders.accessControlAllowOriginHeader],
        isNull,
      );
    });
  });
}

Future<Response> _options(String origin) async {
  final context = _MockRequestContext();
  final request = _MockRequest();
  when(() => context.request).thenReturn(request);
  when(() => request.method).thenReturn(HttpMethod.options);
  when(() => request.headers).thenReturn(
    <String, String>{'origin': origin},
  );

  Future<Response> unusedHandler(RequestContext context) {
    return Future<Response>.value(Response());
  }

  return middleware(unusedHandler)(context);
}

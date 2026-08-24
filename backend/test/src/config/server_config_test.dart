import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:test/test.dart';

void main() {
  group('ServerConfig.fromEnvironment', () {
    test('defaults to development when APP_ENV is absent', () {
      final config = ServerConfig.fromEnvironment(const <String, String>{});

      expect(config.environment, equals('development'));
      expect(config.isDevelopment, isTrue);
      expect(config.allowedOrigins, isEmpty);
    });

    test('uses explicit APP_ENV', () {
      final config = ServerConfig.fromEnvironment(const <String, String>{
        'APP_ENV': 'production',
      });

      expect(config.environment, equals('production'));
      expect(config.isDevelopment, isFalse);
    });

    test('parses comma-separated ALLOWED_ORIGINS', () {
      final config = ServerConfig.fromEnvironment(const <String, String>{
        'ALLOWED_ORIGINS':
            'http://localhost:3000, https://admin.example.invalid ',
      });

      expect(
        config.allowedOrigins,
        equals(<String>[
          'http://localhost:3000',
          'https://admin.example.invalid',
        ]),
      );
    });
  });

  group('ServerConfig.allowedOriginHeader', () {
    test('allows an explicit origin', () {
      const config = ServerConfig(
        environment: 'production',
        allowedOrigins: <String>['https://admin.example.invalid'],
      );

      expect(
        config.allowedOriginHeader('https://admin.example.invalid'),
        equals('https://admin.example.invalid'),
      );
    });

    test('rejects an unknown origin in production', () {
      const config = ServerConfig(
        environment: 'production',
        allowedOrigins: <String>['https://admin.example.invalid'],
      );

      expect(
        config.allowedOriginHeader('https://other.example.invalid'),
        isNull,
      );
    });

    test('does not use a wildcard when production allow-list is empty', () {
      const config = ServerConfig(
        environment: 'production',
        allowedOrigins: <String>[],
      );

      expect(
        config.allowedOriginHeader('http://localhost:8080'),
        isNull,
      );
    });

    test('allows localhost origins in development by default', () {
      const config = ServerConfig(
        environment: 'development',
        allowedOrigins: <String>[],
      );

      expect(
        config.allowedOriginHeader('http://localhost:12345'),
        equals('http://localhost:12345'),
      );
      expect(
        config.allowedOriginHeader('http://127.0.0.1:8080'),
        equals('http://127.0.0.1:8080'),
      );
    });

    test('rejects a non-local origin in development by default', () {
      const config = ServerConfig(
        environment: 'development',
        allowedOrigins: <String>[],
      );

      expect(
        config.allowedOriginHeader('https://evil.example.invalid'),
        isNull,
      );
    });
  });
}

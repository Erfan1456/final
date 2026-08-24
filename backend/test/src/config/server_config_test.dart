import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:test/test.dart';

void main() {
  group('ServerConfig.fromEnvironment', () {
    test('defaults to development when APP_ENV is absent', () {
      final config = ServerConfig.fromEnvironment(const <String, String>{});

      expect(config.environment, equals('development'));
      expect(config.isDevelopment, isTrue);
      expect(config.allowedOrigins, isEmpty);
      expect(config.hasMongoUri, isFalse);
      expect(config.mongoUri, isEmpty);
    });

    test('hasMongoUri is false when MONGODB_URI is absent', () {
      final config = ServerConfig.fromEnvironment(const <String, String>{
        'APP_ENV': 'development',
      });

      expect(config.hasMongoUri, isFalse);
    });

    test('hasMongoUri is true when a fake MONGODB_URI is present', () {
      const fakeUri = 'mongodb://example.invalid:27017/test';
      final config = ServerConfig.fromEnvironment(const <String, String>{
        'MONGODB_URI': fakeUri,
      });

      expect(config.hasMongoUri, isTrue);
      expect(config.mongoUri, equals(fakeUri));
      expect(config.toString(), isNot(contains(fakeUri)));
      expect(config.toString(), contains('hasMongoUri: true'));
    });

    test('accepts an explicit fake MongoDB URI through the constructor', () {
      const fakeUri = 'mongodb://example.invalid:27017/test';
      const config = ServerConfig(
        environment: 'development',
        allowedOrigins: <String>[],
        mongoUri: fakeUri,
      );

      expect(config.hasMongoUri, isTrue);
      expect(config.mongoUri, equals(fakeUri));
      expect('$config', isNot(contains(fakeUri)));
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

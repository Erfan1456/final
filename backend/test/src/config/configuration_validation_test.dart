import 'package:home_cleaning_marketplace_api/src/config/configuration_validation.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:test/test.dart';

void main() {
  group('validateServerConfig', () {
    test('accepts development defaults', () {
      expect(
        () => validateServerConfig(
          const ServerConfig(
            environment: 'development',
            allowedOrigins: <String>[],
          ),
        ),
        returnsNormally,
      );
    });

    test('rejects unknown APP_ENV', () {
      expect(
        () => validateServerConfig(
          const ServerConfig(
            environment: 'staging',
            allowedOrigins: <String>[],
          ),
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('rejects wildcard ALLOWED_ORIGINS', () {
      expect(
        () => validateServerConfig(
          const ServerConfig(
            environment: 'development',
            allowedOrigins: <String>['*'],
          ),
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('production requires mongo, secret, origins, and commission', () {
      expect(
        () => validateServerConfig(
          const ServerConfig(
            environment: 'production',
            allowedOrigins: <String>[],
          ),
        ),
        throwsA(isA<ConfigurationException>()),
      );

      expect(
        () => validateServerConfig(
          const ServerConfig(
            environment: 'production',
            allowedOrigins: <String>['https://app.example.test'],
            mongoUri: 'mongodb://example.invalid:27017/app',
            accessTokenSecret: 'short',
            hasExplicitPlatformCommissionBps: true,
          ),
        ),
        throwsA(isA<ConfigurationException>()),
      );

      expect(
        () => validateServerConfig(
          const ServerConfig(
            environment: 'production',
            allowedOrigins: <String>['https://app.example.test'],
            mongoUri: 'mongodb://example.invalid:27017/app',
            accessTokenSecret: 'test-access-token-secret-32bytes!!',
            hasExplicitPlatformCommissionBps: true,
          ),
        ),
        returnsNormally,
      );
    });

    test('production rejects missing explicit commission', () {
      expect(
        () => validateServerConfig(
          const ServerConfig(
            environment: 'production',
            allowedOrigins: <String>['https://app.example.test'],
            mongoUri: 'mongodb://example.invalid:27017/app',
            accessTokenSecret: 'test-access-token-secret-32bytes!!',
          ),
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });
  });

  group('production provider capability flags', () {
    test('production never allows sandbox or development delivery', () {
      final config = ServerConfig.fromEnvironment(const <String, String>{
        'APP_ENV': 'production',
        'SANDBOX_PAYMENT_WEBHOOK_SECRET':
            'sandbox-payment-webhook-secret-32b!!',
        'SANDBOX_PAYOUT_WEBHOOK_SECRET': 'sandbox-payout-webhook-secret-32b!!!',
      });

      expect(config.isProduction, isTrue);
      expect(config.allowsSandboxPayments, isFalse);
      expect(config.allowsSandboxPayouts, isFalse);
      expect(config.allowsDevelopmentAccountActions, isFalse);
    });
  });
}

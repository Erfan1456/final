import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/config/app_config.dart';

void main() {
  group('AppConfig.validate', () {
    test('debug allows empty and http local URLs', () {
      expect(
        () => AppConfig.unchecked(apiBaseUrl: '').validate(releaseMode: false),
        returnsNormally,
      );
      expect(
        () =>
            AppConfig.unchecked(apiBaseUrl: 'http://10.0.2.2:8080')
                .validate(releaseMode: false),
        returnsNormally,
      );
      expect(
        () =>
            AppConfig.unchecked(apiBaseUrl: 'https://api.example.invalid')
                .validate(releaseMode: false),
        returnsNormally,
      );
    });

    test('release rejects empty and http', () {
      expect(
        () => AppConfig.unchecked(apiBaseUrl: '').validate(releaseMode: true),
        throwsA(isA<AppConfigException>()),
      );
      expect(
        () =>
            AppConfig.unchecked(apiBaseUrl: 'http://api.example.invalid')
                .validate(releaseMode: true),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('release accepts https and normalizes trailing slash', () {
      final config = AppConfig.unchecked(
        apiBaseUrl: 'https://api.example.invalid/',
      );
      expect(() => config.validate(releaseMode: true), returnsNormally);
      expect(
        config.normalizedApiBaseUrl,
        equals('https://api.example.invalid'),
      );
    });

    test('rejects invalid URI', () {
      expect(
        () =>
            AppConfig.unchecked(apiBaseUrl: 'not a uri')
                .validate(releaseMode: false),
        throwsA(isA<AppConfigException>()),
      );
    });
  });
}

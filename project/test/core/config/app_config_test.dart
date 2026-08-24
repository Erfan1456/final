import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/config/app_config.dart';

void main() {
  test('empty API base URL is treated as absent', () {
    const config = AppConfig(apiBaseUrl: '');

    expect(config.apiBaseUrl, isEmpty);
    expect(config.hasApiBaseUrl, isFalse);
  });

  test('whitespace-only API base URL is treated as absent', () {
    const config = AppConfig(apiBaseUrl: '   ');

    expect(config.hasApiBaseUrl, isFalse);
  });

  test('non-empty API base URL is present', () {
    const config = AppConfig(apiBaseUrl: 'https://example.invalid');

    expect(config.hasApiBaseUrl, isTrue);
    expect(config.apiBaseUrl, 'https://example.invalid');
  });
}

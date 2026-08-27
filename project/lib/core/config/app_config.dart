import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thrown when release/profile configuration is invalid.
class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}

/// Public, non-secret runtime configuration for the Flutter client.
///
/// [apiBaseUrl] is read from the compile-time Dart environment variable
/// `API_BASE_URL`. It is not a secret. MongoDB URIs, passwords, tokens, and
/// other private credentials must never be stored here.
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  factory AppConfig.fromEnvironment({bool? releaseMode}) {
    const raw = String.fromEnvironment('API_BASE_URL');
    final config = AppConfig(apiBaseUrl: raw);
    config.validate(releaseMode: releaseMode ?? kReleaseMode);
    return config;
  }

  /// Creates config without throwing (for tests that assert validation).
  factory AppConfig.unchecked({required String apiBaseUrl}) {
    return AppConfig(apiBaseUrl: apiBaseUrl);
  }

  final String apiBaseUrl;

  bool get hasApiBaseUrl => apiBaseUrl.trim().isNotEmpty;

  /// Normalized base URL without a trailing slash.
  String get normalizedApiBaseUrl {
    final trimmed = apiBaseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Validates [apiBaseUrl] for the active build mode.
  ///
  /// Debug/profile (non-release) may use `http://` for local backends.
  /// Release requires a non-empty `https://` absolute URI.
  void validate({required bool releaseMode}) {
    final raw = apiBaseUrl.trim();
    if (!releaseMode) {
      if (raw.isEmpty) {
        return;
      }
      final uri = Uri.tryParse(raw);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        throw const AppConfigException('API_BASE_URL must be a valid URI.');
      }
      return;
    }

    if (raw.isEmpty) {
      throw const AppConfigException(
        'API_BASE_URL is required for release builds.',
      );
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const AppConfigException('API_BASE_URL must be a valid URI.');
    }
    if (uri.scheme.toLowerCase() != 'https') {
      throw const AppConfigException(
        'API_BASE_URL must use https:// in release builds.',
      );
    }
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

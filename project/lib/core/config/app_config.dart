import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Public, non-secret runtime configuration for the Flutter client.
///
/// [apiBaseUrl] is read from the compile-time Dart environment variable
/// `API_BASE_URL`. It is not a secret. MongoDB URIs, passwords, tokens, and
/// other private credentials must never be stored here.
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  factory AppConfig.fromEnvironment() {
    return const AppConfig(apiBaseUrl: String.fromEnvironment('API_BASE_URL'));
  }

  final String apiBaseUrl;

  bool get hasApiBaseUrl => apiBaseUrl.trim().isNotEmpty;
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

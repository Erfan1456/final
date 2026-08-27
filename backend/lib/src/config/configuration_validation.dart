import 'dart:convert';

import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_claims.dart';

/// Thrown when server configuration is invalid for the active environment.
class ConfigurationException implements Exception {
  /// Creates an exception with a safe, non-secret message.
  const ConfigurationException(this.message);

  /// Human-readable validation failure (never contains secret values).
  final String message;

  @override
  String toString() => 'ConfigurationException: $message';
}

/// Centralized boot-time configuration validation.
///
/// Development/test remain convenient. Production requires explicit secrets
/// and origins. Unknown [ServerConfig.environment] values always fail.
void validateServerConfig(ServerConfig config) {
  if (!ServerConfig.supportedEnvironments.contains(config.environment)) {
    throw const ConfigurationException(
      'APP_ENV must be one of: development, test, production.',
    );
  }

  if (config.allowedOrigins.any((origin) => origin == '*')) {
    throw const ConfigurationException(
      'ALLOWED_ORIGINS must not include wildcard "*".',
    );
  }

  if (!config.isProduction) {
    return;
  }

  if (!config.hasMongoUri) {
    throw const ConfigurationException(
      'MONGODB_URI is required in production.',
    );
  }

  if (!config.hasAccessTokenSecret) {
    throw const ConfigurationException(
      'ACCESS_TOKEN_SECRET is required in production.',
    );
  }

  if (utf8.encode(config.accessTokenSecret).length <
      accessTokenSecretMinUtf8Bytes) {
    throw const ConfigurationException(
      'ACCESS_TOKEN_SECRET must be at least 32 UTF-8 bytes in production.',
    );
  }

  if (config.allowedOrigins.isEmpty) {
    throw const ConfigurationException(
      'ALLOWED_ORIGINS must be an explicit non-empty allow-list in production.',
    );
  }

  if (!config.hasExplicitPlatformCommissionBps ||
      !config.hasValidPlatformCommissionBps) {
    throw const ConfigurationException(
      'PLATFORM_COMMISSION_BPS must be an explicit integer '
      '0–10000 in production.',
    );
  }
}

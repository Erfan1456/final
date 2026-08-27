import 'dart:io';

import 'package:home_cleaning_marketplace_api/src/config/configuration_validation.dart';

/// Repository-owned HTTP listen-port resolution for production startup.
///
/// Dart Frog's generated server still parses `PORT` with `int.tryParse` and
/// silently falls back to 8080 for non-numeric values. This helper is the
/// source of truth for fail-fast validation used by the custom entrypoint
/// (`backend/main.dart`) before the socket binds.
class PortConfig {
  const PortConfig._();

  /// Default listen port when `PORT` is absent from the environment.
  static const int defaultPort = 8080;

  /// Inclusive minimum valid TCP port.
  static const int minPort = 1;

  /// Inclusive maximum valid TCP port.
  static const int maxPort = 65535;

  /// Safe message when an explicit `PORT` value is invalid.
  ///
  /// Does not echo the raw environment value.
  static const String invalidPortMessage =
      'PORT configuration is invalid: must be an integer from 1 to 65535.';

  /// Resolves the listen port from [environmentVariables], or
  /// [Platform.environment] when omitted.
  ///
  /// Policy:
  /// - key absent → [defaultPort]
  /// - key present and valid decimal integer in 1–65535 → that value
  /// - key present but empty / non-numeric / out of range → throws
  ///   [ConfigurationException]
  static int resolve([Map<String, String>? environmentVariables]) {
    final env = environmentVariables ?? Platform.environment;
    if (!env.containsKey('PORT')) {
      return defaultPort;
    }

    final trimmed = env['PORT']!.trim();
    if (trimmed.isEmpty) {
      throw const ConfigurationException(invalidPortMessage);
    }

    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < minPort || parsed > maxPort) {
      throw const ConfigurationException(invalidPortMessage);
    }

    return parsed;
  }
}

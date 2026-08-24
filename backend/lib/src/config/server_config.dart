import 'dart:io';

/// Non-secret server/runtime configuration.
///
/// Supported process environment variables:
/// - `APP_ENV` — defaults to `development` when absent
/// - `ALLOWED_ORIGINS` — comma-separated origin list
///
/// MongoDB URIs, JWT secrets, and other credentials are not part of this
/// configuration.
class ServerConfig {
  /// Creates an explicit configuration, useful for tests.
  const ServerConfig({
    required this.environment,
    required this.allowedOrigins,
  });

  /// Reads non-secret settings from [environmentVariables], or from
  /// [Platform.environment] when omitted.
  factory ServerConfig.fromEnvironment([
    Map<String, String>? environmentVariables,
  ]) {
    final env = environmentVariables ?? Platform.environment;
    final rawEnv = env['APP_ENV']?.trim();
    final environment = (rawEnv == null || rawEnv.isEmpty)
        ? defaultEnvironment
        : rawEnv;

    final rawOrigins = env['ALLOWED_ORIGINS']?.trim();
    final allowedOrigins = (rawOrigins == null || rawOrigins.isEmpty)
        ? const <String>[]
        : rawOrigins
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(growable: false);

    return ServerConfig(
      environment: environment,
      allowedOrigins: allowedOrigins,
    );
  }

  /// Default `APP_ENV` when the variable is absent.
  static const String defaultEnvironment = 'development';

  /// Current application environment name, for example `development`.
  final String environment;

  /// Explicit CORS allow-list parsed from `ALLOWED_ORIGINS`.
  final List<String> allowedOrigins;

  /// Whether [environment] is the development default.
  bool get isDevelopment => environment == defaultEnvironment;

  /// Origin to echo in CORS headers, or `null` when the request origin is not
  /// allowed.
  ///
  /// Development with an empty allow-list permits localhost / 127.0.0.1
  /// origins. Non-development environments never fall back to a wildcard.
  String? allowedOriginHeader(String? requestOrigin) {
    if (requestOrigin == null || requestOrigin.isEmpty) {
      return null;
    }

    if (allowedOrigins.contains(requestOrigin)) {
      return requestOrigin;
    }

    if (allowedOrigins.isEmpty &&
        isDevelopment &&
        isLocalDevelopmentOrigin(requestOrigin)) {
      return requestOrigin;
    }

    return null;
  }

  /// Whether [origin] is an http(s) localhost or 127.0.0.1 origin.
  static bool isLocalDevelopmentOrigin(String origin) {
    final uri = Uri.tryParse(origin);
    if (uri == null) {
      return false;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return false;
    }
    return uri.host == 'localhost' || uri.host == '127.0.0.1';
  }
}

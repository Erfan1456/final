import 'dart:convert';
import 'dart:io';

/// Server/runtime configuration.
///
/// Supported environment variables:
/// - `APP_ENV` — defaults to `development` when absent
/// - `ALLOWED_ORIGINS` — comma-separated origin list
/// - `MONGODB_URI` — MongoDB Atlas connection URI (secret; never logged)
/// - `ACCESS_TOKEN_SECRET` — HS256 signing secret (secret; never logged)
/// - `SANDBOX_PAYMENT_WEBHOOK_SECRET` — sandbox HMAC secret (never logged)
///
/// The MongoDB URI has no default. When it is absent, [hasMongoUri] is false
/// and liveness health can still succeed.
///
/// [accessTokenSecret] has no default. The process can start without it
/// because no authentication route is active yet. Token services must reject
/// missing or short secrets themselves.
///
/// [sandboxPaymentWebhookSecret] has no default. The process can start without
/// it; sandbox payment initialization reports unavailable instead.
class ServerConfig {
  /// Creates an explicit configuration, useful for tests.
  const ServerConfig({
    required this.environment,
    required this.allowedOrigins,
    this.mongoUri = '',
    this.accessTokenSecret = '',
    this.sandboxPaymentWebhookSecret = '',
  });

  /// Reads settings from [environmentVariables], or from
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

    final mongoUri = env['MONGODB_URI']?.trim() ?? '';
    final accessTokenSecret = env['ACCESS_TOKEN_SECRET']?.trim() ?? '';
    final sandboxPaymentWebhookSecret =
        env['SANDBOX_PAYMENT_WEBHOOK_SECRET']?.trim() ?? '';

    return ServerConfig(
      environment: environment,
      allowedOrigins: allowedOrigins,
      mongoUri: mongoUri,
      accessTokenSecret: accessTokenSecret,
      sandboxPaymentWebhookSecret: sandboxPaymentWebhookSecret,
    );
  }

  /// Default `APP_ENV` when the variable is absent.
  static const String defaultEnvironment = 'development';

  /// Current application environment name, for example `development`.
  final String environment;

  /// Explicit CORS allow-list parsed from `ALLOWED_ORIGINS`.
  final List<String> allowedOrigins;

  /// MongoDB connection URI from `MONGODB_URI`, or empty when unset.
  ///
  /// Do not print, log, or include this value in HTTP responses.
  final String mongoUri;

  /// HS256 access-token signing secret from `ACCESS_TOKEN_SECRET`.
  ///
  /// Do not print, log, or include this value in [toString], exceptions, or
  /// HTTP responses. There is no development default.
  final String accessTokenSecret;

  /// HMAC secret for the development/test sandbox webhook.
  ///
  /// Backend only. Minimum 32 UTF-8 bytes at runtime. Do not print, log, or
  /// include this value in [toString], exceptions, or HTTP responses.
  final String sandboxPaymentWebhookSecret;

  /// Whether a non-empty MongoDB URI was configured.
  bool get hasMongoUri => mongoUri.isNotEmpty;

  /// Whether a non-empty access-token secret was configured.
  bool get hasAccessTokenSecret => accessTokenSecret.isNotEmpty;

  /// Whether a non-empty sandbox webhook secret was configured.
  bool get hasSandboxPaymentWebhookSecret =>
      sandboxPaymentWebhookSecret.isNotEmpty;

  /// Whether the sandbox webhook secret meets the 32 UTF-8 byte minimum.
  bool get hasValidSandboxWebhookSecret {
    return utf8.encode(sandboxPaymentWebhookSecret).length >= 32;
  }

  /// Whether [environment] is the development default.
  bool get isDevelopment => environment == defaultEnvironment;

  /// Whether [environment] is the automated test environment.
  bool get isTest => environment == 'test';

  /// Whether [environment] is production.
  bool get isProduction => environment == 'production';

  /// Whether the development sandbox provider may be constructed.
  ///
  /// Production never falls back to sandbox, even if a secret is present.
  bool get allowsSandboxPayments => isDevelopment || isTest;

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

  @override
  String toString() =>
      'ServerConfig(environment: $environment, hasMongoUri: $hasMongoUri, '
      'hasAccessTokenSecret: $hasAccessTokenSecret, '
      'hasSandboxPaymentWebhookSecret: $hasSandboxPaymentWebhookSecret)';
}

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
/// - `SANDBOX_PAYOUT_WEBHOOK_SECRET` — sandbox payout HMAC secret
///   (never logged)
/// - `PLATFORM_COMMISSION_BPS` — platform commission in basis points
///   (not secret)
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
///
/// [sandboxPayoutWebhookSecret] has no default. The process can start without
/// it; sandbox payout initialization reports unavailable instead.
///
/// [platformCommissionBps] defaults to [defaultPlatformCommissionBps] (1500)
/// when unset. That default is intended for development/test. Production
/// should set `PLATFORM_COMMISSION_BPS` explicitly; the process still boots
/// with the documented default so configuration loading stays non-throwing.
class ServerConfig {
  /// Creates an explicit configuration, useful for tests.
  const ServerConfig({
    required this.environment,
    required this.allowedOrigins,
    this.mongoUri = '',
    this.accessTokenSecret = '',
    this.sandboxPaymentWebhookSecret = '',
    this.sandboxPayoutWebhookSecret = '',
    this.platformCommissionBps = defaultPlatformCommissionBps,
    this.hasExplicitPlatformCommissionBps = false,
    this.hasValidPlatformCommissionBps = true,
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
    final sandboxPayoutWebhookSecret =
        env['SANDBOX_PAYOUT_WEBHOOK_SECRET']?.trim() ?? '';
    final commission = _parsePlatformCommissionBps(
      env['PLATFORM_COMMISSION_BPS']?.trim(),
    );

    return ServerConfig(
      environment: environment,
      allowedOrigins: allowedOrigins,
      mongoUri: mongoUri,
      accessTokenSecret: accessTokenSecret,
      sandboxPaymentWebhookSecret: sandboxPaymentWebhookSecret,
      sandboxPayoutWebhookSecret: sandboxPayoutWebhookSecret,
      platformCommissionBps: commission.bps,
      hasExplicitPlatformCommissionBps: commission.explicit,
      hasValidPlatformCommissionBps: commission.valid,
    );
  }

  /// Default `APP_ENV` when the variable is absent.
  static const String defaultEnvironment = 'development';

  /// Supported [environment] values. Unknown values fail validation.
  static const Set<String> supportedEnvironments = <String>{
    'development',
    'test',
    'production',
  };

  /// Development/test default: 1500 bps = 15%.
  static const int defaultPlatformCommissionBps = 1500;

  /// Inclusive minimum commission in basis points.
  static const int minPlatformCommissionBps = 0;

  /// Inclusive maximum commission in basis points (100%).
  static const int maxPlatformCommissionBps = 10000;

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

  /// HMAC secret for the development/test sandbox payout webhook.
  ///
  /// Backend only. Minimum 32 UTF-8 bytes at runtime. Do not print, log, or
  /// include this value in [toString], exceptions, or HTTP responses.
  final String sandboxPayoutWebhookSecret;

  /// Platform commission in basis points snapshotted onto new earnings.
  ///
  /// Not a secret. Integer 0–10000. Existing earnings are never recalculated
  /// when this value changes.
  final int platformCommissionBps;

  /// Whether `PLATFORM_COMMISSION_BPS` was present in the environment.
  final bool hasExplicitPlatformCommissionBps;

  /// Whether the configured commission parsed as an integer in 0–10000.
  ///
  /// Unset configuration uses [defaultPlatformCommissionBps] and is valid.
  /// An explicit invalid value keeps the process booting with the default
  /// but [hasValidPlatformCommissionBps] is false so earning creation can
  /// refuse to snapshot a guessed rate.
  final bool hasValidPlatformCommissionBps;

  /// Whether a non-empty MongoDB URI was configured.
  bool get hasMongoUri => mongoUri.isNotEmpty;

  /// Whether a non-empty access-token secret was configured.
  bool get hasAccessTokenSecret => accessTokenSecret.isNotEmpty;

  /// Whether a non-empty sandbox webhook secret was configured.
  bool get hasSandboxPaymentWebhookSecret =>
      sandboxPaymentWebhookSecret.isNotEmpty;

  /// Whether a non-empty sandbox payout webhook secret was configured.
  bool get hasSandboxPayoutWebhookSecret =>
      sandboxPayoutWebhookSecret.isNotEmpty;

  /// Whether the sandbox webhook secret meets the 32 UTF-8 byte minimum.
  bool get hasValidSandboxWebhookSecret {
    return utf8.encode(sandboxPaymentWebhookSecret).length >= 32;
  }

  /// Whether the sandbox payout webhook secret meets the 32 UTF-8 byte minimum.
  bool get hasValidSandboxPayoutWebhookSecret {
    return utf8.encode(sandboxPayoutWebhookSecret).length >= 32;
  }

  /// Whether [environment] is the development default.
  bool get isDevelopment => environment == defaultEnvironment;

  /// Whether [environment] is the automated test environment.
  bool get isTest => environment == 'test';

  /// Whether [environment] is production.
  bool get isProduction => environment == 'production';

  /// Whether [environment] is one of [supportedEnvironments].
  bool get isKnownEnvironment => supportedEnvironments.contains(environment);

  /// Whether development/test account-action delivery may be constructed.
  ///
  /// Production never falls back to returning raw action tokens.
  bool get allowsDevelopmentAccountActions => isDevelopment || isTest;

  /// Whether the development sandbox provider may be constructed.
  ///
  /// Production never falls back to sandbox, even if a secret is present.
  bool get allowsSandboxPayments => isDevelopment || isTest;

  /// Whether the development sandbox payout provider may be constructed.
  ///
  /// Production never falls back to sandbox payouts, even if a secret is
  /// present.
  bool get allowsSandboxPayouts => isDevelopment || isTest;

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

  static ({int bps, bool explicit, bool valid}) _parsePlatformCommissionBps(
    String? raw,
  ) {
    if (raw == null || raw.isEmpty) {
      return (
        bps: defaultPlatformCommissionBps,
        explicit: false,
        valid: true,
      );
    }
    final parsed = int.tryParse(raw);
    if (parsed == null ||
        parsed < minPlatformCommissionBps ||
        parsed > maxPlatformCommissionBps) {
      return (
        bps: defaultPlatformCommissionBps,
        explicit: true,
        valid: false,
      );
    }
    return (bps: parsed, explicit: true, valid: true);
  }

  @override
  String toString() =>
      'ServerConfig(environment: $environment, hasMongoUri: $hasMongoUri, '
      'hasAccessTokenSecret: $hasAccessTokenSecret, '
      'hasSandboxPaymentWebhookSecret: $hasSandboxPaymentWebhookSecret, '
      'hasSandboxPayoutWebhookSecret: $hasSandboxPayoutWebhookSecret, '
      'platformCommissionBps: $platformCommissionBps, '
      'hasValidPlatformCommissionBps: $hasValidPlatformCommissionBps)';
}

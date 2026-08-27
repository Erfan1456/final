import 'dart:io';

/// CORS headers for an allowed origin.
///
/// Production must set `ALLOWED_ORIGINS` explicitly. This helper never emits
/// `Access-Control-Allow-Origin: *`.
Map<String, String> corsHeaders(String? allowedOrigin) {
  if (allowedOrigin == null || allowedOrigin.isEmpty) {
    return const <String, String>{};
  }

  return <String, String>{
    HttpHeaders.accessControlAllowOriginHeader: allowedOrigin,
    HttpHeaders.accessControlAllowMethodsHeader:
        'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    HttpHeaders.accessControlAllowHeadersHeader:
        'Accept, Authorization, Content-Type, Idempotency-Key, X-Request-Id',
    HttpHeaders.varyHeader: 'Origin',
  };
}

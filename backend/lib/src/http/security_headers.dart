/// Conservative API response security headers.
///
/// TLS/HSTS remains a reverse-proxy responsibility and is intentionally not
/// set by the application.
Map<String, String> securityResponseHeaders() {
  return const <String, String>{
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'no-referrer',
  };
}

import 'dart:math';

/// Request correlation helpers.
///
/// Accepts a conservative incoming `X-Request-Id` or generates an opaque id.
/// Never includes tokens, emails, passwords, or URIs.
class RequestId {
  /// Response / request header name.
  static const String headerName = 'X-Request-Id';

  /// Maximum accepted length for an incoming request id.
  static const int maxLength = 128;

  /// Returns [incoming] when safe, otherwise a newly generated opaque id.
  static String resolve(String? incoming) {
    final candidate = incoming?.trim();
    if (candidate != null &&
        candidate.isNotEmpty &&
        candidate.length <= maxLength &&
        _safePattern.hasMatch(candidate)) {
      return candidate;
    }
    return generate();
  }

  /// Generates an opaque lowercase hex request id.
  static String generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static final RegExp _safePattern = RegExp(r'^[A-Za-z0-9._\-]+$');
}

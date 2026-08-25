import 'dart:convert';
import 'dart:math';

/// Generates an Idempotency-Key with at least 128 bits of entropy.
String generateBookingIdempotencyKey([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

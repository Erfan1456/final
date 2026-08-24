/// Password hashing and verification boundary for future authentication.
///
/// Implementations must not log plaintext passwords or encoded hashes.
abstract interface class PasswordHasher {
  /// Returns an encoded password hash for [password] as supplied.
  String hash(String password);

  /// Whether [password] matches [encodedHash].
  ///
  /// Malformed or unsupported hashes return `false`.
  bool verify({
    required String password,
    required String encodedHash,
  });

  /// Whether [encodedHash] should be replaced after a successful verify.
  ///
  /// Malformed or weaker/different hashes return `true`.
  bool needsRehash(String encodedHash);
}

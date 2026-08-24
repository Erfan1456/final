/// Normalizes an email for lookup and uniqueness.
///
/// Policy is trim + lowercase only. Provider-specific rewriting is not applied.
String normalizeEmail(String email) => email.trim().toLowerCase();

/// Account-action token or delivery failures. Messages stay generic.
sealed class AccountActionException implements Exception {
  /// Creates an application exception.
  const AccountActionException({
    required this.code,
    required this.message,
  });

  /// Stable client error code.
  final String code;

  /// Safe human-readable message. Never includes token material.
  final String message;
}

/// Unknown, expired, claimed, revoked, or wrong-purpose token.
class InvalidAccountActionTokenException extends AccountActionException {
  /// Creates a generic invalid-token error.
  const InvalidAccountActionTokenException()
    : super(
        code: 'invalid_or_expired_account_action_token',
        message: 'This action link is invalid or has expired.',
      );
}

/// Production or unavailable account-action delivery.
class AccountActionDeliveryUnavailableException extends AccountActionException {
  /// Creates a delivery-unavailable error.
  const AccountActionDeliveryUnavailableException()
    : super(
        code: 'account_action_delivery_unavailable',
        message: 'Account-action delivery is currently unavailable.',
      );
}

/// Stored account-action document could not be read.
class AccountActionDocumentException extends AccountActionException {
  /// Creates a document-shape error.
  const AccountActionDocumentException(String message)
    : super(
        code: 'account_action_document_invalid',
        message: message,
      );
}

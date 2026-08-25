import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_purpose.dart';

/// Development/test-only account-action payload. Never persist or log [token].
class DevelopmentAccountAction {
  /// Creates a development action result.
  const DevelopmentAccountAction({
    required this.purpose,
    required this.token,
  });

  /// Token purpose.
  final AccountActionPurpose purpose;

  /// Raw one-time token. Returned only in development/test HTTP envelopes.
  final String token;

  /// Safe JSON for development/test responses.
  Map<String, String> toJson() {
    return <String, String>{
      'purpose': purpose.wireValue,
      'token': token,
    };
  }
}

/// Provider-neutral account-action delivery boundary.
///
/// Implementations must not persist or log the raw token.
abstract interface class AccountActionDeliveryProvider {
  /// Whether this provider can deliver actions in the current environment.
  bool get isAvailable;

  /// Delivers an email-verification action.
  Future<DevelopmentAccountAction?> deliverEmailVerification({
    required String recipientEmail,
    required String rawToken,
    required DateTime expiresAt,
  });

  /// Delivers a password-reset action.
  Future<DevelopmentAccountAction?> deliverPasswordReset({
    required String recipientEmail,
    required String rawToken,
    required DateTime expiresAt,
  });
}

import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_delivery_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_purpose.dart';

/// Development/test delivery that returns the raw token to the caller.
///
/// Construct only when `APP_ENV` is `development` or `test`.
class DevelopmentAccountActionDeliveryProvider
    implements AccountActionDeliveryProvider {
  /// Creates a development delivery provider.
  const DevelopmentAccountActionDeliveryProvider();

  @override
  bool get isAvailable => true;

  @override
  Future<DevelopmentAccountAction?> deliverEmailVerification({
    required String recipientEmail,
    required String rawToken,
    required DateTime expiresAt,
  }) async {
    return DevelopmentAccountAction(
      purpose: AccountActionPurpose.emailVerification,
      token: rawToken,
    );
  }

  @override
  Future<DevelopmentAccountAction?> deliverPasswordReset({
    required String recipientEmail,
    required String rawToken,
    required DateTime expiresAt,
  }) async {
    return DevelopmentAccountAction(
      purpose: AccountActionPurpose.passwordReset,
      token: rawToken,
    );
  }
}

/// Production delivery boundary. TASK 020 does not integrate a real provider.
class UnavailableAccountActionDeliveryProvider
    implements AccountActionDeliveryProvider {
  /// Creates an unavailable production delivery provider.
  const UnavailableAccountActionDeliveryProvider();

  @override
  bool get isAvailable => false;

  @override
  Future<DevelopmentAccountAction?> deliverEmailVerification({
    required String recipientEmail,
    required String rawToken,
    required DateTime expiresAt,
  }) async {
    throw const AccountActionDeliveryUnavailableException();
  }

  @override
  Future<DevelopmentAccountAction?> deliverPasswordReset({
    required String recipientEmail,
    required String rawToken,
    required DateTime expiresAt,
  }) async {
    throw const AccountActionDeliveryUnavailableException();
  }
}

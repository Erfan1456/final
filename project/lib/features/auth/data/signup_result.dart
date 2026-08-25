import 'package:home_cleaning_marketplace/features/auth/data/development_account_action.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_user.dart';

/// Signup success without issued tokens.
class SignupResult {
  /// Creates a signup result.
  const SignupResult({
    required this.user,
    required this.verificationRequired,
    this.developmentAction,
  });

  /// Parses signup `data` from POST /api/v1/auth/signup.
  factory SignupResult.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final verificationRequired = json['verification_required'];
    if (userJson is! Map || verificationRequired is! bool) {
      throw const FormatException('Signup JSON is missing required fields.');
    }
    DevelopmentAccountAction? developmentAction;
    final actionJson = json['development_action'];
    if (actionJson is Map) {
      developmentAction = DevelopmentAccountAction.fromJson(
        Map<String, dynamic>.from(actionJson),
      );
    }
    return SignupResult(
      user: AuthUser.fromJson(Map<String, dynamic>.from(userJson)),
      verificationRequired: verificationRequired,
      developmentAction: developmentAction,
    );
  }

  /// Newly created account.
  final AuthUser user;

  /// Whether the client should direct the user to verify email.
  final bool verificationRequired;

  /// Development/test delivery payload. Null in production.
  final DevelopmentAccountAction? developmentAction;
}

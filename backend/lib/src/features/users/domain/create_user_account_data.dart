import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';

/// Input for persisting a new [UserAccount].
///
/// Contains an already-produced password hash. Never contains a plaintext
/// password. Persistence fields such as `_id`, `email_normalized`, and
/// timestamps are derived by the repository.
class CreateUserAccountData {
  /// Creates account insert input.
  const CreateUserAccountData({
    required this.role,
    required this.email,
    required this.passwordHash,
    this.accountStatus = AccountStatus.active,
    this.emailVerified = false,
  });

  /// Requested role. Authorization of admin creation belongs to a later task.
  final UserRole role;

  /// User-facing email. The repository trims this and derives the normalized
  /// lookup value.
  final String email;

  /// Already-generated password hash. Never a plaintext password.
  final String passwordHash;

  /// Initial account status. Defaults to [AccountStatus.active].
  final AccountStatus accountStatus;

  /// Whether the email address has already been verified.
  final bool emailVerified;
}

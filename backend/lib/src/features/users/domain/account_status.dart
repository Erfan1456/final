/// Persisted account status. Cleaner approval is not represented here.
enum AccountStatus {
  /// Account may authenticate when later auth is implemented.
  active,

  /// Account is blocked by an administrator.
  suspended,

  /// Account has been deactivated.
  deactivated;

  /// Stable database/wire representation. Never persist [index].
  String get wireValue {
    switch (this) {
      case AccountStatus.active:
        return 'active';
      case AccountStatus.suspended:
        return 'suspended';
      case AccountStatus.deactivated:
        return 'deactivated';
    }
  }

  /// Parses a stored status string. Unknown values fail.
  static AccountStatus fromWire(String value) {
    switch (value) {
      case 'active':
        return AccountStatus.active;
      case 'suspended':
        return AccountStatus.suspended;
      case 'deactivated':
        return AccountStatus.deactivated;
      default:
        throw const FormatException('Unknown AccountStatus.');
    }
  }
}

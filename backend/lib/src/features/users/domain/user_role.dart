/// Persisted user role. Wire/database values are explicit lowercase strings.
enum UserRole {
  /// Marketplace customer.
  customer,

  /// Service provider / cleaner.
  cleaner,

  /// Administrator. Public signup must not create this role later.
  admin;

  /// Stable database/wire representation. Never persist [index].
  String get wireValue {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.cleaner:
        return 'cleaner';
      case UserRole.admin:
        return 'admin';
    }
  }

  /// Parses a stored role string. Unknown values fail.
  static UserRole fromWire(String value) {
    switch (value) {
      case 'customer':
        return UserRole.customer;
      case 'cleaner':
        return UserRole.cleaner;
      case 'admin':
        return UserRole.admin;
      default:
        throw const FormatException('Unknown UserRole.');
    }
  }
}

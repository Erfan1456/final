import 'package:mongo_dart/mongo_dart.dart';

/// Constants for the portfolio demo MongoDB seed.
///
/// Passwords are never stored here. They come only from environment variables
/// at apply time.
abstract final class DemoSeedConstants {
  /// Stable seed key used for idempotent re-apply.
  static const String seedKey = 'portfolio_demo_v1';

  /// Tooling-only manifest collection (not in CollectionNames).
  static const String manifestCollection = 'demo_seed_manifests';

  /// Expected Atlas database name.
  static const String expectedDatabaseName = 'home_cleaning_marketplace';

  /// Environment variable for the target admin password.
  static const String adminPasswordEnv = 'DEMO_SEED_ADMIN_PASSWORD';

  /// Environment variable for all other demo account passwords.
  static const String sharedPasswordEnv = 'DEMO_SEED_SHARED_PASSWORD';

  /// Target admin email (special upsert semantics).
  static const String targetAdminEmail = 'erfan.khan.cse@gmail.com';

  /// Normalized target admin email.
  static const String targetAdminEmailNormalized = 'erfan.khan.cse@gmail.com';

  /// Secondary demo admin email.
  static const String demoAdminEmail = 'admin.demo@example.com';

  /// Placeholder service ObjectId for dry-run (no Mongo).
  static final ObjectId dryRunServiceId = ObjectId.fromHexString(
    'c10000000000000000000001',
  );

  /// Builds a deterministic 24-hex ObjectId.
  ///
  /// [prefix] must be exactly two hex characters. [n] is a positive index.
  static ObjectId id(String prefix, int n) {
    if (prefix.length != 2) {
      throw ArgumentError.value(prefix, 'prefix', 'must be 2 hex chars');
    }
    if (n < 1 || n > 0xffffff) {
      throw ArgumentError.value(n, 'n', 'out of range');
    }
    final body = n.toRadixString(16).padLeft(22, '0');
    return ObjectId.fromHexString('$prefix$body');
  }
}

/// Hex prefixes for deterministic seed ids.
abstract final class DemoSeedIdPrefix {
  static const String users = 'd1';
  static const String customerProfiles = 'd2';
  static const String cleanerProfiles = 'd3';
  static const String addresses = 'd4';
  static const String cleanerServices = 'd5';
  static const String availability = 'd6';
  static const String bookings = 'd7';
  static const String payments = 'd8';
  static const String conversations = 'd9';
  static const String conversationMembers = 'da';
  static const String messages = 'db';
  static const String notifications = 'dc';
  static const String reviews = 'dd';
  static const String disputes = 'de';
  static const String auditLogs = 'df';
  static const String earnings = 'e1';
  static const String payouts = 'e2';
  static const String paymentWebhooks = 'e3';
  static const String payoutWebhooks = 'e4';
  static const String manifest = 'e5';
}

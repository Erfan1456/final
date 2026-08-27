/// MongoDB URI path helpers for demo-seed configuration safety.
///
/// Never log full URIs from callers — these helpers only inspect/replace the
/// database path segment.
library;

import 'demo_seed_exception.dart';

/// Extracts the database name from a MongoDB connection [uri] path.
///
/// Returns `null` when the URI has no path database segment (mongo_dart would
/// default to `test`). Does not print or return credentials.
String? mongoUriDatabaseName(String uri) {
  final schemeEnd = uri.indexOf('://');
  if (schemeEnd < 0) {
    throw const FormatException('Mongo URI is missing a scheme');
  }

  final afterScheme = schemeEnd + 3;
  final pathStart = uri.indexOf('/', afterScheme);
  if (pathStart < 0) {
    return null;
  }

  final queryStart = uri.indexOf('?', pathStart);
  final pathEnd = queryStart < 0 ? uri.length : queryStart;
  final path = uri.substring(pathStart + 1, pathEnd);
  if (path.isEmpty) {
    return null;
  }

  // First path segment is the database name.
  final slash = path.indexOf('/');
  final name = slash < 0 ? path : path.substring(0, slash);
  if (name.isEmpty) {
    return null;
  }
  return Uri.decodeComponent(name);
}

/// Whether [uri] explicitly targets [expectedDatabaseName].
///
/// URIs with no database path (driver default `test`) are not accepted.
bool mongoUriTargetsDatabase(String uri, String expectedDatabaseName) {
  final name = mongoUriDatabaseName(uri);
  return name == expectedDatabaseName;
}

/// Throws [DemoSeedException] when [uri] does not explicitly target [expected].
///
/// Message never includes the URI.
void requireMongoUriDatabase(String uri, String expected) {
  if (!mongoUriTargetsDatabase(uri, expected)) {
    throw DemoSeedException(
      'Configured MongoDB database must be $expected.',
    );
  }
}

/// Rewrites a MongoDB connection URI so it targets [databaseName].
///
/// Preserves scheme, credentials, host, and query. Replaces or inserts only
/// the database path. Used for private local `.env` alignment — not by the
/// seed mutate path.
String mongoUriWithDatabase(String uri, String databaseName) {
  if (databaseName.isEmpty || databaseName.contains('/')) {
    throw ArgumentError.value(databaseName, 'databaseName', 'invalid');
  }

  final schemeEnd = uri.indexOf('://');
  if (schemeEnd < 0) {
    throw const FormatException('Mongo URI is missing a scheme');
  }

  final afterScheme = schemeEnd + 3;
  final pathStart = uri.indexOf('/', afterScheme);
  final queryStart = uri.indexOf('?', afterScheme);

  if (pathStart < 0) {
    if (queryStart < 0) {
      return '$uri/$databaseName';
    }
    return '${uri.substring(0, queryStart)}/$databaseName'
        '${uri.substring(queryStart)}';
  }

  final pathEnd = queryStart < 0 ? uri.length : queryStart;
  final beforePath = uri.substring(0, pathStart);
  final afterPath = uri.substring(pathEnd);
  return '$beforePath/$databaseName$afterPath';
}

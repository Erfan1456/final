import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Factory used to create a [MongoConnection] from a URI.
///
/// Tests may inject a fake factory so unit tests never contact MongoDB Atlas.
typedef MongoConnectionFactory = Future<MongoConnection> Function(String uri);

/// Minimal lifecycle wrapper around a mongo_dart [Db].
abstract class MongoConnection {
  /// Whether the underlying driver reports an open connection.
  bool get isConnected;

  /// Opens the driver connection if it is not already open.
  Future<void> open();

  /// Closes the driver connection.
  Future<void> close();

  /// Issues MongoDB `ping`. Must not perform application CRUD.
  Future<void> ping();

  /// The native driver instance when this connection wraps mongo_dart.
  Db? get nativeDb => null;
}

/// mongo_dart-backed [MongoConnection].
class MongoDartConnection implements MongoConnection {
  /// Wraps an already-constructed [Db]. Does not log connection details.
  MongoDartConnection(this._db);

  final Db _db;

  @override
  bool get isConnected => _db.isConnected;

  @override
  Db? get nativeDb => _db;

  @override
  Future<void> open() => _db.open();

  @override
  Future<void> close() => _db.close();

  @override
  Future<void> ping() async {
    final result = await _db.pingCommand();
    final ok = result['ok'];
    if (ok == 0 || ok == 0.0) {
      throw const MongoDatabaseNotReady();
    }
  }
}

/// Internal marker used when ping reports a non-ok result.
class MongoDatabaseNotReady implements Exception {
  /// Creates a sanitized not-ready marker. It must not include URI details.
  const MongoDatabaseNotReady();

  @override
  String toString() => 'MongoDatabaseNotReady';
}

/// Reusable server-side MongoDB Atlas connection lifecycle.
///
/// Connection is lazy, shared, and guarded against concurrent first-connect.
/// The URI is never logged or included in string representations.
class MongoDatabase {
  /// Creates a manager from [config].
  ///
  /// [connectionFactory] is a test seam. Production uses [Db.create].
  MongoDatabase({
    required ServerConfig config,
    MongoConnectionFactory? connectionFactory,
  }) : _config = config,
       _connectionFactory = connectionFactory ?? _createMongoDartConnection;

  final ServerConfig _config;
  final MongoConnectionFactory _connectionFactory;

  MongoConnection? _connection;
  Future<void>? _connecting;

  /// Whether `MONGODB_URI` was supplied to [ServerConfig].
  bool get isConfigured => _config.hasMongoUri;

  /// Native driver instance when connected; otherwise `null`.
  ///
  /// Intended for future backend data services only. Never returned over HTTP.
  Db? get db {
    final connection = _connection;
    if (connection == null || !connection.isConnected) {
      return null;
    }
    return connection.nativeDb;
  }

  /// Opens the shared connection if configured and not already open.
  ///
  /// Concurrent callers share a single in-flight connect [Future].
  Future<void> connect() {
    if (!isConfigured) {
      return Future<void>.value();
    }
    if (_connection != null && _connection!.isConnected) {
      return Future<void>.value();
    }
    return _connecting ??= _establish();
  }

  Future<void> _establish() async {
    try {
      final connection = await _connectionFactory(_config.mongoUri);
      if (!connection.isConnected) {
        await connection.open();
      }
      _connection = connection;
    } catch (_) {
      _connecting = null;
      rethrow;
    }
  }

  /// Returns whether MongoDB is configured and responds to ping.
  ///
  /// Failures are converted to `false`. Driver errors are not propagated.
  Future<bool> ping() async {
    if (!isConfigured) {
      return false;
    }

    try {
      await connect();
      final connection = _connection;
      if (connection == null || !connection.isConnected) {
        return false;
      }
      await connection.ping();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Closes the shared connection. Safe to call more than once.
  Future<void> close() async {
    final connection = _connection;
    _connection = null;
    _connecting = null;
    if (connection == null) {
      return;
    }
    try {
      await connection.close();
    } catch (_) {
      // Ignore close failures so lifecycle cleanup stays idempotent.
    }
  }

  @override
  String toString() => 'MongoDatabase(isConfigured: $isConfigured)';

  static Future<MongoConnection> _createMongoDartConnection(String uri) async {
    final db = await Db.create(uri);
    return MongoDartConnection(db);
  }
}

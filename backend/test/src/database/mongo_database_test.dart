import 'dart:async';

import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

class _FakeConnection implements MongoConnection {
  _FakeConnection({
    this.failPing = false,
    this.failOpen = false,
    Completer<void>? openGate,
  }) : _openGate = openGate;

  final bool failPing;
  final bool failOpen;
  final Completer<void>? _openGate;

  bool _open = false;
  int openCalls = 0;
  int closeCalls = 0;
  int pingCalls = 0;

  @override
  bool get isConnected => _open;

  @override
  Db? get nativeDb => null;

  @override
  Future<void> open() async {
    openCalls++;
    final openGate = _openGate;
    if (openGate != null) {
      await openGate.future;
    }
    if (failOpen) {
      throw const MongoDatabaseNotReady();
    }
    _open = true;
  }

  @override
  Future<void> close() async {
    closeCalls++;
    _open = false;
  }

  @override
  Future<void> ping() async {
    pingCalls++;
    if (failPing) {
      throw const MongoDatabaseNotReady();
    }
  }
}

void main() {
  const fakeUri = 'mongodb://example.invalid:27017/test';

  ServerConfig configured() {
    return const ServerConfig(
      environment: 'development',
      allowedOrigins: <String>[],
      mongoUri: fakeUri,
    );
  }

  ServerConfig unconfigured() {
    return const ServerConfig(
      environment: 'development',
      allowedOrigins: <String>[],
    );
  }

  group('MongoDatabase', () {
    test('unconfigured database reports not configured', () {
      final mongo = MongoDatabase(config: unconfigured());

      expect(mongo.isConfigured, isFalse);
      expect(mongo.toString(), isNot(contains(fakeUri)));
    });

    test(
      'unconfigured ping returns false without opening a connection',
      () async {
        var factoryCalls = 0;
        final mongo = MongoDatabase(
          config: unconfigured(),
          connectionFactory: (uri) async {
            factoryCalls++;
            return _FakeConnection();
          },
        );

        expect(await mongo.ping(), isFalse);
        expect(factoryCalls, equals(0));
      },
    );

    test(
      'concurrent connect calls share a single connection attempt',
      () async {
        var factoryCalls = 0;
        final gate = Completer<void>();
        final connection = _FakeConnection(openGate: gate);
        final mongo = MongoDatabase(
          config: configured(),
          connectionFactory: (uri) async {
            factoryCalls++;
            expect(uri, equals(fakeUri));
            return connection;
          },
        );

        final first = mongo.connect();
        final second = mongo.connect();
        expect(factoryCalls, equals(1));

        gate.complete();
        await Future.wait<void>(<Future<void>>[first, second]);

        expect(factoryCalls, equals(1));
        expect(connection.openCalls, equals(1));
        expect(mongo.db, isNull);
      },
    );

    test('successful ping returns true', () async {
      final connection = _FakeConnection();
      final mongo = MongoDatabase(
        config: configured(),
        connectionFactory: (uri) async => connection,
      );

      expect(await mongo.ping(), isTrue);
      expect(connection.pingCalls, equals(1));
    });

    test('failed ping is converted to not-ready', () async {
      final connection = _FakeConnection(failPing: true);
      final mongo = MongoDatabase(
        config: configured(),
        connectionFactory: (uri) async => connection,
      );

      expect(await mongo.ping(), isFalse);
    });

    test('failed connect is converted to not-ready', () async {
      final mongo = MongoDatabase(
        config: configured(),
        connectionFactory: (uri) async => _FakeConnection(failOpen: true),
      );

      expect(await mongo.ping(), isFalse);
    });

    test('close is safe and idempotent', () async {
      final connection = _FakeConnection();
      final mongo = MongoDatabase(
        config: configured(),
        connectionFactory: (uri) async => connection,
      );

      await mongo.close();
      await mongo.connect();
      await mongo.close();
      await mongo.close();

      expect(connection.closeCalls, equals(1));
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/data/flutter_secure_auth_token_storage.dart';

void main() {
  late Map<String, String> store;
  late FlutterSecureAuthTokenStorage storage;

  setUp(() {
    store = <String, String>{};
    storage = FlutterSecureAuthTokenStorage(
      readRaw: (key) async => store[key],
      writeRaw: (key, value) async {
        store[key] = value;
      },
      deleteRaw: (key) async {
        store.remove(key);
      },
    );
  });

  test('write/read round trip uses one storage key', () async {
    const pair = AuthTokenPair(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );

    await storage.write(pair);
    final read = await storage.read();

    expect(store.keys, equals([FlutterSecureAuthTokenStorage.storageKey]));
    expect(read?.accessToken, equals('access-token'));
    expect(read?.refreshToken, equals('refresh-token'));
    expect(store.values.single, isNot(contains('password')));
    expect(jsonDecode(store.values.single), isNot(contains('password')));
  });

  test('clear removes the stored pair', () async {
    await storage.write(
      const AuthTokenPair(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );
    await storage.clear();

    expect(await storage.read(), isNull);
    expect(store, isEmpty);
  });

  test('missing value is treated as no session', () async {
    expect(await storage.read(), isNull);
  });

  test('corrupt JSON is cleared and treated as no session', () async {
    store[FlutterSecureAuthTokenStorage.storageKey] = '{not-json';

    expect(await storage.read(), isNull);
    expect(
      store.containsKey(FlutterSecureAuthTokenStorage.storageKey),
      isFalse,
    );
  });

  test('malformed JSON object is cleared', () async {
    store[FlutterSecureAuthTokenStorage.storageKey] = jsonEncode(
      <String, String>{'access_token': 'only-one'},
    );

    expect(await storage.read(), isNull);
    expect(store, isEmpty);
  });

  test('token pair toString does not include token values', () {
    const pair = AuthTokenPair(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    expect(pair.toString(), equals('AuthTokenPair(redacted)'));
    expect(pair.toString(), isNot(contains('access-token')));
  });
}

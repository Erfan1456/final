import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/api/v1/ready.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockMongoDatabase extends Mock implements MongoDatabase {}

void main() {
  late _MockRequestContext context;
  late _MockRequest request;
  late _MockMongoDatabase mongo;

  setUp(() {
    context = _MockRequestContext();
    request = _MockRequest();
    mongo = _MockMongoDatabase();
    when(() => context.request).thenReturn(request);
    when(() => context.read<MongoDatabase>()).thenReturn(mongo);
  });

  group('GET /api/v1/ready', () {
    test('returns 200 when the database is ready', () async {
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => mongo.isConfigured).thenReturn(true);
      when(() => mongo.ping()).thenAnswer((_) async => true);

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect(data['status'], equals('ready'));
      expect(jsonEncode(body), isNot(contains('mongodb://')));
      expect(jsonEncode(body), isNot(contains('mongodb+srv://')));
    });

    test('returns 503 when the database is unavailable', () async {
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => mongo.isConfigured).thenReturn(true);
      when(() => mongo.ping()).thenAnswer((_) async => false);

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.serviceUnavailable));
      expect(body['success'], isFalse);
      expect(error['code'], equals('database_unavailable'));
      expect(error['message'], equals('Service is not ready.'));
      expect(jsonEncode(body), isNot(contains('MongoDatabaseNotReady')));
      expect(jsonEncode(body), isNot(contains('mongodb://')));
    });

    test('returns 503 when the database is unconfigured', () async {
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => mongo.isConfigured).thenReturn(false);

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.serviceUnavailable));
      expect(body['success'], isFalse);
      expect(error['code'], equals('database_unavailable'));
      verifyNever(() => mongo.ping());
    });

    test('non-GET methods return 405', () async {
      when(() => request.method).thenReturn(HttpMethod.post);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      verifyNever(() => mongo.ping());
    });
  });
}

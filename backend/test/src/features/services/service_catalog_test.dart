import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/application/canonical_service_catalog.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_billing_model.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_validation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../routes/api/v1/services.dart' as services_route;
import '../../../helpers/marketplace_test_fixtures.dart';
import '../../../helpers/memory_collection_store.dart';

class _MockContext extends Mock implements RequestContext {}

class _RecordingEnsureIndex {
  final calls = <Map<String, dynamic>>[];

  Future<void> call({
    required String collectionName,
    required Map<String, dynamic> keys,
    required bool unique,
    required String name,
  }) async {
    calls.add(<String, dynamic>{
      'collectionName': collectionName,
      'keys': Map<String, dynamic>.from(keys),
      'unique': unique,
      'name': name,
    });
  }
}

void main() {
  group('ServiceBillingModel', () {
    test('hourly wire value is explicit', () {
      expect(ServiceBillingModel.hourly.wireValue, equals('hourly'));
      expect(
        ServiceBillingModel.fromWire('hourly'),
        ServiceBillingModel.hourly,
      );
      expect(
        () => ServiceBillingModel.fromWire('fixed'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ServiceValidation', () {
    test('accepts a valid slug and rejects invalid slugs', () {
      expect(
        ServiceValidation.requireSlug('home-cleaning'),
        equals('home-cleaning'),
      );
      expect(
        () => ServiceValidation.requireSlug('Home-Cleaning'),
        throwsA(anything),
      );
      expect(() => ServiceValidation.requireSlug('-home'), throwsA(anything));
      expect(() => ServiceValidation.requireSlug('home-'), throwsA(anything));
    });

    test('rejects HTML in the description', () {
      expect(
        () => ServiceValidation.requireDescription('<script>alert(1)</script>'),
        throwsA(anything),
      );
    });
  });

  group('MongoServiceRepository', () {
    late MemoryCollectionDocumentStore store;
    late MongoServiceRepository repository;

    setUp(() {
      store = MemoryCollectionDocumentStore();
      repository = MongoServiceRepository(documents: store);
    });

    test('listActive excludes inactive services', () async {
      store.documents.add(testHomeCleaningService().toDocument());
      store.documents.add(
        testHomeCleaningService(
          active: false,
          id: ObjectId.fromHexString('507f1f77bcf86cd7994390ab'),
        ).toDocument()..['slug'] = 'other-service',
      );
      final listed = await repository.listActive();
      expect(listed, hasLength(1));
      expect(listed.single.slug, equals('home-cleaning'));
    });
  });

  group('CanonicalServiceCatalogEnsure', () {
    test('is idempotent on a fake store', () async {
      final store = MemoryCollectionDocumentStore();
      final repository = MongoServiceRepository(documents: store);
      final catalog = CanonicalServiceCatalogEnsure(
        repository: repository,
        store: ServiceCatalogStore(documents: store),
        clock: marketplaceTestNow,
      );
      final first = await catalog.ensureHomeCleaning();
      final second = await catalog.ensureHomeCleaning();
      expect(store.documents, hasLength(1));
      expect(first.slug, equals('home-cleaning'));
      expect(second.id, equals(first.id));
      expect(second.name, equals('Home Cleaning'));
      expect(second.billingModel, ServiceBillingModel.hourly);
      expect(second.active, isTrue);
    });
  });

  group('ensureServiceIndexes', () {
    test('requests unique slug and active+slug indexes', () async {
      final recorder = _RecordingEnsureIndex();
      await ensureServiceIndexes(ensureIndex: recorder.call);
      expect(recorder.calls, hasLength(2));
      expect(recorder.calls.first['name'], equals(servicesSlugUniqueIndexName));
      expect(recorder.calls.first['unique'], isTrue);
      expect(recorder.calls.first['collectionName'], CollectionNames.services);
      expect(recorder.calls.last['name'], equals(servicesActiveSlugIndexName));
    });
  });

  group('GET /api/v1/services', () {
    late MemoryCollectionDocumentStore store;
    late MongoServiceRepository repository;

    setUp(() {
      store = MemoryCollectionDocumentStore();
      repository = MongoServiceRepository(documents: store);
    });

    RequestContext ctx(Request request) {
      final context = _MockContext();
      when(() => context.request).thenReturn(request);
      when(() => context.read<ServiceRepository>()).thenReturn(repository);
      return context;
    }

    test('public GET returns active catalog without JWT', () async {
      store.documents.add(testHomeCleaningService().toDocument());
      final response = await services_route.onRequest(
        ctx(Request('GET', Uri.parse('http://localhost/api/v1/services'))),
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      final items = (body['data'] as Map)['items'] as List;
      expect(items, hasLength(1));
      final item = items.single as Map;
      expect(item['slug'], equals('home-cleaning'));
      expect(item['billing_model'], equals('hourly'));
      expect(item.containsKey('created_at'), isFalse);
      expect(item.containsKey('active'), isFalse);
      expect(jsonEncode(body), isNot(contains('password')));
    });

    test('inactive services are excluded', () async {
      store.documents.add(testHomeCleaningService(active: false).toDocument());
      final response = await services_route.onRequest(
        ctx(Request('GET', Uri.parse('http://localhost/api/v1/services'))),
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect((body['data'] as Map)['items'] as List, isEmpty);
    });

    test('wrong method is 405', () async {
      final response = await services_route.onRequest(
        ctx(Request('POST', Uri.parse('http://localhost/api/v1/services'))),
      );
      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });
  });
}

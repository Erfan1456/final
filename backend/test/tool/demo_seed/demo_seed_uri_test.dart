import 'package:test/test.dart';

import '../../../tool/demo_seed/demo_seed_constants.dart';
import '../../../tool/demo_seed/demo_seed_exception.dart';
import '../../../tool/demo_seed/demo_seed_uri.dart';

void main() {
  const expected = DemoSeedConstants.expectedDatabaseName;

  group('mongoUriDatabaseName / mongoUriTargetsDatabase', () {
    test('URI targeting home_cleaning_marketplace is accepted', () {
      const uri =
          'mongodb://user:pass@localhost:27017/home_cleaning_marketplace';
      expect(mongoUriDatabaseName(uri), equals(expected));
      expect(mongoUriTargetsDatabase(uri, expected), isTrue);
      expect(() => requireMongoUriDatabase(uri, expected), returnsNormally);
    });

    test('URI targeting test is rejected', () {
      const uri = 'mongodb://user:pass@localhost:27017/test';
      expect(mongoUriDatabaseName(uri), equals('test'));
      expect(mongoUriTargetsDatabase(uri, expected), isFalse);
      expect(
        () => requireMongoUriDatabase(uri, expected),
        throwsA(
          isA<DemoSeedException>().having(
            (e) => e.message,
            'message',
            contains('home_cleaning_marketplace'),
          ),
        ),
      );
    });

    test('URI without explicit DB path is rejected', () {
      const uri = 'mongodb+srv://user:pass@cluster.example.net';
      expect(mongoUriDatabaseName(uri), isNull);
      expect(mongoUriTargetsDatabase(uri, expected), isFalse);
      expect(
        () => requireMongoUriDatabase(uri, expected),
        throwsA(isA<DemoSeedException>()),
      );
    });

    test('URI targeting another DB is rejected', () {
      const uri = 'mongodb://user:pass@localhost:27017/other_app';
      expect(mongoUriDatabaseName(uri), equals('other_app'));
      expect(mongoUriTargetsDatabase(uri, expected), isFalse);
      expect(
        () => requireMongoUriDatabase(uri, expected),
        throwsA(isA<DemoSeedException>()),
      );
    });

    test('SRV URI with query parameters and correct DB is accepted', () {
      const uri =
          'mongodb+srv://user:pass@cluster.example.net/'
          'home_cleaning_marketplace?retryWrites=true&w=majority';
      expect(mongoUriDatabaseName(uri), equals(expected));
      expect(mongoUriTargetsDatabase(uri, expected), isTrue);
      expect(() => requireMongoUriDatabase(uri, expected), returnsNormally);
    });

    test('URI with empty path before query is rejected', () {
      const uri =
          'mongodb+srv://user:pass@cluster.example.net/?retryWrites=true';
      expect(mongoUriDatabaseName(uri), isNull);
      expect(mongoUriTargetsDatabase(uri, expected), isFalse);
    });
  });

  group('mongoUriWithDatabase', () {
    test('inserts database when path is absent before query', () {
      expect(
        mongoUriWithDatabase(
          'mongodb+srv://u:p@cluster.example.net?retryWrites=true',
          expected,
        ),
        equals(
          'mongodb+srv://u:p@cluster.example.net/$expected'
          '?retryWrites=true',
        ),
      );
    });

    test('replaces existing database path segment', () {
      expect(
        mongoUriWithDatabase(
          'mongodb://u:p@localhost:27017/test?authSource=admin',
          expected,
        ),
        equals(
          'mongodb://u:p@localhost:27017/$expected?authSource=admin',
        ),
      );
    });
  });
}

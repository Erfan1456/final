import 'package:test/test.dart';

import '../../../tool/demo_seed/demo_seed_cli_errors.dart';
import '../../../tool/demo_seed/demo_seed_constants.dart';
import '../../../tool/demo_seed/demo_seed_exception.dart';
import '../../../tool/demo_seed/demo_seed_uri.dart';

void main() {
  group('requireMongoUriDatabase safe error', () {
    test('known database-target validation exposes expected safe message', () {
      expect(
        () => requireMongoUriDatabase(
          'mongodb://user:pass@localhost:27017/test',
          DemoSeedConstants.expectedDatabaseName,
        ),
        throwsA(
          isA<DemoSeedException>().having(
            (e) => e.message,
            'message',
            'Configured MongoDB database must be home_cleaning_marketplace.',
          ),
        ),
      );
    });
  });

  group('renderSeedCliFailure', () {
    test('known DemoSeedException message is preserved', () {
      const error = DemoSeedException(
        'Configured MongoDB database must be home_cleaning_marketplace.',
      );
      expect(
        renderSeedCliFailure(
          error,
          unexpectedMessage:
              'Seed apply failed due to an unexpected '
              'database/tool error.',
        ),
        equals(
          'Configured MongoDB database must be home_cleaning_marketplace.',
        ),
      );
    });

    test('unexpected exception with fake URI secret is not echoed', () {
      final leaky = Exception(
        'Connection failed for '
        'mongodb+srv://admin:s3cret@cluster.example.net/db',
      );
      final rendered = renderSeedCliFailure(
        leaky,
        unexpectedMessage:
            'Seed apply failed due to an unexpected database/tool error.',
      );
      expect(
        rendered,
        equals(
          'Seed apply failed due to an unexpected database/tool error.',
        ),
      );
      expect(rendered, isNot(contains('mongodb+srv://')));
      expect(rendered, isNot(contains('s3cret')));
      expect(rendered, isNot(contains('cluster.example.net')));
      expect(rendered, isNot(contains(leaky.toString())));
    });

    test('unexpected exception produces generic failure text only', () {
      expect(
        renderSeedCliFailure(
          StateError('driver boom'),
          unexpectedMessage:
              'Seed summary failed due to an unexpected database/tool error.',
        ),
        equals(
          'Seed summary failed due to an unexpected database/tool error.',
        ),
      );
    });

    test('reportSeedCliFailure never writes a stack trace', () {
      final lines = <String>[];
      try {
        throw Exception('boom');
      } catch (error, stackTrace) {
        reportSeedCliFailure(
          error,
          unexpectedMessage:
              'Seed apply failed due to an unexpected database/tool error.',
          write: lines.add,
        );
        expect(lines, hasLength(1));
        expect(lines.single, isNot(contains('stackTrace')));
        expect(lines.single, isNot(contains(stackTrace.toString())));
        expect(lines.single, isNot(contains('#0')));
      }
    });
  });
}

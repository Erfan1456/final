import 'package:home_cleaning_marketplace_api/src/http/request_id.dart';
import 'package:test/test.dart';

void main() {
  group('RequestId', () {
    test('accepts a safe incoming id', () {
      expect(RequestId.resolve('abc-123_ok'), equals('abc-123_ok'));
    });

    test('rejects unsafe incoming ids and generates opaque hex', () {
      final generated = RequestId.resolve('bad id with spaces');
      expect(generated, matches(RegExp(r'^[a-f0-9]{32}$')));

      final empty = RequestId.resolve('');
      expect(empty, matches(RegExp(r'^[a-f0-9]{32}$')));
    });
  });
}

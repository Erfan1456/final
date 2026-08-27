import 'package:home_cleaning_marketplace_api/src/config/configuration_validation.dart';
import 'package:home_cleaning_marketplace_api/src/config/port_config.dart';
import 'package:test/test.dart';

void main() {
  group('PortConfig.resolve', () {
    test('absent PORT defaults to 8080', () {
      expect(PortConfig.resolve(const <String, String>{}), equals(8080));
    });

    test('PORT=8080 succeeds', () {
      expect(
        PortConfig.resolve(const <String, String>{'PORT': '8080'}),
        equals(8080),
      );
    });

    test('PORT=1 succeeds', () {
      expect(
        PortConfig.resolve(const <String, String>{'PORT': '1'}),
        equals(1),
      );
    });

    test('PORT=65535 succeeds', () {
      expect(
        PortConfig.resolve(const <String, String>{'PORT': '65535'}),
        equals(65535),
      );
    });

    test('PORT=0 fails', () {
      expect(
        () => PortConfig.resolve(const <String, String>{'PORT': '0'}),
        throwsA(
          isA<ConfigurationException>().having(
            (e) => e.message,
            'message',
            contains('PORT configuration is invalid'),
          ),
        ),
      );
    });

    test('PORT=65536 fails', () {
      expect(
        () => PortConfig.resolve(const <String, String>{'PORT': '65536'}),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('PORT=-1 fails', () {
      expect(
        () => PortConfig.resolve(const <String, String>{'PORT': '-1'}),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('PORT=abc fails', () {
      expect(
        () => PortConfig.resolve(const <String, String>{'PORT': 'abc'}),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('explicit empty PORT fails', () {
      expect(
        () => PortConfig.resolve(const <String, String>{'PORT': ''}),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('explicit whitespace-only PORT fails', () {
      expect(
        () => PortConfig.resolve(const <String, String>{'PORT': '   '}),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('failure message does not echo the raw PORT value', () {
      try {
        PortConfig.resolve(const <String, String>{'PORT': 'not-a-port'});
        fail('expected ConfigurationException');
      } on ConfigurationException catch (error) {
        expect(error.message, isNot(contains('not-a-port')));
        expect(error.message, contains('PORT configuration is invalid'));
      }
    });
  });
}

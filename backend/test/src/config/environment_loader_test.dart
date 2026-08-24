import 'dart:io';

import 'package:home_cleaning_marketplace_api/src/config/environment_loader.dart';
import 'package:test/test.dart';

void main() {
  group('EnvironmentLoader', () {
    test('reads explicit process environment values', () {
      final values = const EnvironmentLoader().load(
        processEnvironment: const <String, String>{
          'APP_ENV': 'test',
          'ALLOWED_ORIGINS': 'http://localhost:3000',
        },
        loadEnvFile: false,
      );

      expect(values['APP_ENV'], equals('test'));
      expect(values['ALLOWED_ORIGINS'], equals('http://localhost:3000'));
      expect(values.containsKey('MONGODB_URI'), isFalse);
    });

    test('returns an empty overlay when the env file is absent', () {
      final values = const EnvironmentLoader().load(
        processEnvironment: const <String, String>{'APP_ENV': 'production'},
        envFilePath: 'this-file-does-not-exist.env',
      );

      expect(values['APP_ENV'], equals('production'));
    });

    test('loads fake values from a temporary env file', () {
      final directory = Directory.systemTemp.createTempSync('env_loader_');
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final file = File('${directory.path}${Platform.pathSeparator}test.env')
        ..writeAsStringSync(
          'APP_ENV=from_file\n'
          'MONGODB_URI=mongodb://example.invalid:27017/test\n',
        );

      final values = const EnvironmentLoader().load(
        processEnvironment: const <String, String>{},
        envFilePath: file.path,
      );

      expect(values['APP_ENV'], equals('from_file'));
      expect(
        values['MONGODB_URI'],
        equals('mongodb://example.invalid:27017/test'),
      );
    });

    test('process environment takes precedence over file values', () {
      final directory = Directory.systemTemp.createTempSync('env_loader_');
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final file = File('${directory.path}${Platform.pathSeparator}test.env')
        ..writeAsStringSync(
          'APP_ENV=from_file\n'
          'MONGODB_URI=mongodb://file.invalid:27017/test\n',
        );

      final values = const EnvironmentLoader().load(
        processEnvironment: const <String, String>{
          'APP_ENV': 'from_process',
        },
        envFilePath: file.path,
      );

      expect(values['APP_ENV'], equals('from_process'));
      expect(
        values['MONGODB_URI'],
        equals('mongodb://file.invalid:27017/test'),
      );
    });
  });
}

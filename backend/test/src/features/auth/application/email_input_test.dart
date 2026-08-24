import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/email_input.dart';
import 'package:test/test.dart';

void main() {
  group('EmailInput.parse', () {
    test('trims surrounding whitespace and accepts a simple address', () {
      expect(
        EmailInput.parse('  Person@example.com  '),
        equals('Person@example.com'),
      );
    });

    test('does not lowercase the display email', () {
      expect(
        EmailInput.parse('Person@Example.COM'),
        equals('Person@Example.COM'),
      );
    });

    test('rejects empty and whitespace-only values', () {
      expect(
        () => EmailInput.parse(''),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => EmailInput.parse('   '),
        throwsA(isA<InvalidAuthInputException>()),
      );
    });

    test('rejects values longer than 254 characters', () {
      final local = 'a' * 243;
      expect(
        () => EmailInput.parse('$local@example.com'),
        throwsA(isA<InvalidAuthInputException>()),
      );
    });

    test('rejects embedded whitespace and control characters', () {
      expect(
        () => EmailInput.parse('person @example.com'),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => EmailInput.parse('person\t@example.com'),
        throwsA(isA<InvalidAuthInputException>()),
      );
    });

    test('requires exactly one @ with non-empty local and domain', () {
      expect(
        () => EmailInput.parse('person.example.com'),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => EmailInput.parse('person@@example.com'),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => EmailInput.parse('@example.com'),
        throwsA(isA<InvalidAuthInputException>()),
      );
      expect(
        () => EmailInput.parse('person@'),
        throwsA(isA<InvalidAuthInputException>()),
      );
    });
  });
}

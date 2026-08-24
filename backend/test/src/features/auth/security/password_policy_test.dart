import 'package:home_cleaning_marketplace_api/src/features/auth/security/password_policy.dart';
import 'package:test/test.dart';

void main() {
  const policy = PasswordPolicy();

  String ofLength(int length, [String unit = 'a']) {
    return List<String>.filled(length, unit).join();
  }

  group('PasswordPolicy', () {
    test('rejects below 15 Unicode code points', () {
      final result = policy.validate(ofLength(14));

      expect(result.isValid, isFalse);
      expect(result.issue, equals(PasswordPolicyIssue.tooShort));
    });

    test('accepts exactly 15 Unicode code points', () {
      expect(policy.validate(ofLength(15)).isValid, isTrue);
    });

    test('accepts 128 Unicode code points', () {
      expect(policy.validate(ofLength(128)).isValid, isTrue);
    });

    test('rejects above 128 Unicode code points', () {
      final result = policy.validate(ofLength(129));

      expect(result.isValid, isFalse);
      expect(result.issue, equals(PasswordPolicyIssue.tooLong));
    });

    test('accepts spaces and counts them', () {
      expect(policy.validate(ofLength(15, ' ')).isValid, isTrue);
    });

    test('accepts Unicode code points', () {
      expect(policy.validate(ofLength(15, 'あ')).isValid, isTrue);
    });

    test('counts leading and trailing spaces instead of trimming', () {
      expect(policy.validate('              a').isValid, isTrue);
      expect(policy.validate(' a             ').isValid, isTrue);
      expect(policy.validate('              ').isValid, isFalse);
    });

    test('does not treat uppercase and lowercase as the same secret', () {
      const mixed = 'Abcdefghijklmno';
      const lower = 'abcdefghijklmno';

      expect(mixed.runes.length, equals(PasswordPolicy.minimumLength));
      expect(lower.runes.length, equals(PasswordPolicy.minimumLength));
      expect(policy.validate(mixed).isValid, isTrue);
      expect(policy.validate(lower).isValid, isTrue);
      expect(mixed, isNot(equals(lower)));
    });

    test('imposes no symbol, number, or uppercase composition rule', () {
      expect(policy.validate('aaaaaaaaaaaaaaa').isValid, isTrue);
      expect(policy.validate('AAAAAAAAAAAAAAA').isValid, isTrue);
      expect(policy.validate('111111111111111').isValid, isTrue);
    });
  });
}

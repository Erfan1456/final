import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/email_normalization.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:test/test.dart';

void main() {
  group('UserRole', () {
    test('maps each role to an explicit lowercase wire value', () {
      expect(UserRole.customer.wireValue, equals('customer'));
      expect(UserRole.cleaner.wireValue, equals('cleaner'));
      expect(UserRole.admin.wireValue, equals('admin'));
    });

    test('parses each stored wire value', () {
      expect(UserRole.fromWire('customer'), equals(UserRole.customer));
      expect(UserRole.fromWire('cleaner'), equals(UserRole.cleaner));
      expect(UserRole.fromWire('admin'), equals(UserRole.admin));
    });

    test('unknown values fail rather than defaulting to customer', () {
      expect(() => UserRole.fromWire('owner'), throwsFormatException);
      expect(() => UserRole.fromWire('CUSTOMER'), throwsFormatException);
      expect(() => UserRole.fromWire('0'), throwsFormatException);
    });
  });

  group('AccountStatus', () {
    test('maps each status to an explicit lowercase wire value', () {
      expect(AccountStatus.active.wireValue, equals('active'));
      expect(AccountStatus.suspended.wireValue, equals('suspended'));
      expect(AccountStatus.deactivated.wireValue, equals('deactivated'));
    });

    test('parses each stored wire value', () {
      expect(AccountStatus.fromWire('active'), equals(AccountStatus.active));
      expect(
        AccountStatus.fromWire('suspended'),
        equals(AccountStatus.suspended),
      );
      expect(
        AccountStatus.fromWire('deactivated'),
        equals(AccountStatus.deactivated),
      );
    });

    test('unknown values fail', () {
      expect(() => AccountStatus.fromWire('pending'), throwsFormatException);
      expect(() => AccountStatus.fromWire('ACTIVE'), throwsFormatException);
    });
  });

  group('normalizeEmail', () {
    test('trims whitespace and lowercases', () {
      expect(
        normalizeEmail('  Example.User@Example.COM  '),
        equals('example.user@example.com'),
      );
    });

    test('leaves an already-normalized value unchanged', () {
      expect(
        normalizeEmail('person@example.com'),
        equals('person@example.com'),
      );
    });

    test('does not strip plus addressing or gmail dots', () {
      expect(
        normalizeEmail('First.Last+tag@Example.COM'),
        equals('first.last+tag@example.com'),
      );
    });
  });
}

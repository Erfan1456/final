import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

void main() {
  final id = ObjectId.fromHexString('507f1f77bcf86cd799439011');
  final createdAt = DateTime.utc(2026, 8, 24, 12);
  final updatedAt = DateTime.utc(2026, 8, 24, 13);

  Map<String, dynamic> validDocument() {
    return <String, dynamic>{
      '_id': id,
      'role': 'customer',
      'email': 'Person@example.com',
      'email_normalized': 'person@example.com',
      'password_hash': 'fake-password-hash-not-real',
      'account_status': 'active',
      'email_verified': false,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  UserAccount validAccount() {
    return UserAccount(
      id: id,
      role: UserRole.customer,
      email: 'Person@example.com',
      emailNormalized: 'person@example.com',
      passwordHash: 'fake-password-hash-not-real',
      accountStatus: AccountStatus.active,
      emailVerified: false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  group('UserAccount.fromDocument', () {
    test('parses a valid document', () {
      final account = UserAccount.fromDocument(validDocument());

      expect(account.id, equals(id));
      expect(account.role, equals(UserRole.customer));
      expect(account.email, equals('Person@example.com'));
      expect(account.emailNormalized, equals('person@example.com'));
      expect(account.passwordHash, equals('fake-password-hash-not-real'));
      expect(account.accountStatus, equals(AccountStatus.active));
      expect(account.emailVerified, isFalse);
      expect(account.createdAt.isUtc, isTrue);
      expect(account.updatedAt.isUtc, isTrue);
      expect(account.createdAt, equals(createdAt));
      expect(account.updatedAt, equals(updatedAt));
    });

    test('converts timestamp values to UTC', () {
      final localCreated = DateTime(2026, 8, 24, 18);
      final document = validDocument()
        ..['created_at'] = localCreated
        ..['updated_at'] = localCreated;

      final account = UserAccount.fromDocument(document);

      expect(account.createdAt.isUtc, isTrue);
      expect(account.updatedAt.isUtc, isTrue);
      expect(account.createdAt, equals(localCreated.toUtc()));
    });

    test('fails when _id is missing or not ObjectId', () {
      final missing = validDocument()..remove('_id');
      final wrongType = validDocument()..['_id'] = '507f1f77bcf86cd799439011';

      expect(
        () => UserAccount.fromDocument(missing),
        throwsA(isA<UserAccountDocumentException>()),
      );
      expect(
        () => UserAccount.fromDocument(wrongType),
        throwsA(isA<UserAccountDocumentException>()),
      );
    });

    test('fails when a required string field is missing', () {
      final missingEmail = validDocument()..remove('email');
      final missingHash = validDocument()..remove('password_hash');

      expect(
        () => UserAccount.fromDocument(missingEmail),
        throwsA(isA<UserAccountDocumentException>()),
      );
      expect(
        () => UserAccount.fromDocument(missingHash),
        throwsA(isA<UserAccountDocumentException>()),
      );
    });

    test('fails when a critical BSON type is wrong', () {
      final wrongVerified = validDocument()..['email_verified'] = 1;
      final wrongCreated = validDocument()..['created_at'] = '2026-08-24';

      expect(
        () => UserAccount.fromDocument(wrongVerified),
        throwsA(isA<UserAccountDocumentException>()),
      );
      expect(
        () => UserAccount.fromDocument(wrongCreated),
        throwsA(isA<UserAccountDocumentException>()),
      );
    });

    test('fails when role or status is unknown', () {
      final unknownRole = validDocument()..['role'] = 'owner';
      final unknownStatus = validDocument()..['account_status'] = 'pending';

      expect(
        () => UserAccount.fromDocument(unknownRole),
        throwsFormatException,
      );
      expect(
        () => UserAccount.fromDocument(unknownStatus),
        throwsFormatException,
      );
    });
  });

  group('UserAccount.toDocument', () {
    test('uses explicit wire strings and UTC timestamps', () {
      final document = validAccount().toDocument();

      expect(document['_id'], equals(id));
      expect(document['role'], equals('customer'));
      expect(document['email'], equals('Person@example.com'));
      expect(document['email_normalized'], equals('person@example.com'));
      expect(document['password_hash'], equals('fake-password-hash-not-real'));
      expect(document['account_status'], equals('active'));
      expect(document['email_verified'], isFalse);
      expect((document['created_at'] as DateTime).isUtc, isTrue);
      expect((document['updated_at'] as DateTime).isUtc, isTrue);
    });
  });

  group('UserAccount.toPublicJson', () {
    test('exposes safe public fields only', () {
      final json = validAccount().toPublicJson();

      expect(json['id'], equals(id.oid));
      expect(json['role'], equals('customer'));
      expect(json['email'], equals('Person@example.com'));
      expect(json['accountStatus'], equals('active'));
      expect(json['emailVerified'], isFalse);
      expect(json['createdAt'], equals(createdAt.toIso8601String()));
      expect(json['updatedAt'], equals(updatedAt.toIso8601String()));
    });

    test('does not contain password fields or normalized email', () {
      final json = validAccount().toPublicJson();
      final encodedKeys = json.keys.toSet();

      expect(encodedKeys.contains('passwordHash'), isFalse);
      expect(encodedKeys.contains('password_hash'), isFalse);
      expect(encodedKeys.contains('password'), isFalse);
      expect(encodedKeys.contains('emailNormalized'), isFalse);
      expect(encodedKeys.contains('email_normalized'), isFalse);
      expect(json.values, isNot(contains('fake-password-hash-not-real')));
    });
  });

  group('UserAccount.toString', () {
    test('does not include the password hash', () {
      final description = validAccount().toString();

      expect(description, contains(id.oid));
      expect(description, isNot(contains('fake-password-hash-not-real')));
      expect(description, isNot(contains('password')));
    });
  });
}

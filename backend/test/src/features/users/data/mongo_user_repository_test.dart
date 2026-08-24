import 'package:home_cleaning_marketplace_api/src/features/users/data/mongo_user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/create_user_account_data.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/email_normalization.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

class _MemoryUserDocuments implements UserDocumentStore {
  _MemoryUserDocuments({this.insertResult});

  final List<Map<String, dynamic>> documents = <Map<String, dynamic>>[];
  UserInsertResult? insertResult;

  @override
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector) async {
    for (final document in documents) {
      if (_matches(document, selector)) {
        return Map<String, dynamic>.from(document);
      }
    }
    return null;
  }

  @override
  Future<UserInsertResult> insertOne(Map<String, dynamic> document) async {
    final forced = insertResult;
    if (forced != null) {
      return forced;
    }
    documents.add(Map<String, dynamic>.from(document));
    return const UserInsertResult.success();
  }

  bool _matches(Map<String, dynamic> document, Map<String, dynamic> selector) {
    for (final entry in selector.entries) {
      if (document[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}

void main() {
  final existingId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
  final createdAt = DateTime.utc(2026, 8, 24, 12);
  final updatedAt = DateTime.utc(2026, 8, 24, 13);

  Map<String, dynamic> storedCustomer() {
    return <String, dynamic>{
      '_id': existingId,
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

  group('MongoUserRepository.findById', () {
    test('returns the account when found', () async {
      final store = _MemoryUserDocuments()..documents.add(storedCustomer());
      final repository = MongoUserRepository(documents: store);

      final account = await repository.findById(existingId);

      expect(account, isNotNull);
      expect(account!.id, equals(existingId));
      expect(account.email, equals('Person@example.com'));
    });

    test('returns null when not found', () async {
      final repository = MongoUserRepository(documents: _MemoryUserDocuments());

      final account = await repository.findById(ObjectId());

      expect(account, isNull);
    });
  });

  group('MongoUserRepository.findByEmail and emailExists', () {
    test('normalizes the caller email before lookup', () async {
      final store = _MemoryUserDocuments()..documents.add(storedCustomer());
      final repository = MongoUserRepository(documents: store);

      final account = await repository.findByEmail(
        '  Person@example.com  ',
      );

      expect(account, isNotNull);
      expect(account!.emailNormalized, equals('person@example.com'));
      expect(await repository.emailExists('PERSON@EXAMPLE.COM'), isTrue);
    });

    test('returns not found when the normalized email is absent', () async {
      final repository = MongoUserRepository(documents: _MemoryUserDocuments());

      expect(await repository.findByEmail('missing@example.com'), isNull);
      expect(await repository.emailExists('missing@example.com'), isFalse);
    });
  });

  group('MongoUserRepository.create', () {
    test('persists derived identity fields and the provided hash', () async {
      final store = _MemoryUserDocuments();
      final repository = MongoUserRepository(documents: store);

      final created = await repository.create(
        const CreateUserAccountData(
          role: UserRole.cleaner,
          email: '  New.User@Example.COM  ',
          passwordHash: 'fake-password-hash-not-real',
          emailVerified: true,
        ),
      );

      expect(created.id, isA<ObjectId>());
      expect(created.role, equals(UserRole.cleaner));
      expect(created.email, equals('New.User@Example.COM'));
      expect(created.emailNormalized, equals('new.user@example.com'));
      expect(created.passwordHash, equals('fake-password-hash-not-real'));
      expect(created.emailVerified, isTrue);
      expect(created.createdAt.isUtc, isTrue);
      expect(created.updatedAt.isUtc, isTrue);
      expect(store.documents, hasLength(1));
      expect(store.documents.single['role'], equals('cleaner'));
      expect(store.documents.single['account_status'], equals('active'));
      expect(
        store.documents.single['email_normalized'],
        equals(normalizeEmail('  New.User@Example.COM  ')),
      );
      expect(
        created.toPublicJson().keys,
        isNot(contains('password_hash')),
      );
      expect(
        created.toPublicJson().values,
        isNot(contains('fake-password-hash-not-real')),
      );
    });

    test('maps duplicate-key inserts to DuplicateUserEmailException', () async {
      final store = _MemoryUserDocuments(
        insertResult: const UserInsertResult.duplicate(),
      );
      final repository = MongoUserRepository(documents: store);

      expect(
        () => repository.create(
          const CreateUserAccountData(
            role: UserRole.customer,
            email: 'person@example.com',
            passwordHash: 'fake-password-hash-not-real',
          ),
        ),
        throwsA(isA<DuplicateUserEmailException>()),
      );
    });

    test('maps other write failures to UserAccountWriteException', () async {
      final store = _MemoryUserDocuments(
        insertResult: const UserInsertResult.failed(),
      );
      final repository = MongoUserRepository(documents: store);

      expect(
        () => repository.create(
          const CreateUserAccountData(
            role: UserRole.customer,
            email: 'person@example.com',
            passwordHash: 'fake-password-hash-not-real',
          ),
        ),
        throwsA(isA<UserAccountWriteException>()),
      );
    });
  });

  group('UserAccount public exposure after repository create', () {
    test('returned model does not expose the password hash publicly', () async {
      final repository = MongoUserRepository(documents: _MemoryUserDocuments());
      final created = await repository.create(
        const CreateUserAccountData(
          role: UserRole.admin,
          email: 'admin@example.com',
          passwordHash: 'fake-password-hash-not-real',
        ),
      );

      final publicJson = created.toPublicJson();
      expect(created, isA<UserAccount>());
      expect(publicJson.containsKey('passwordHash'), isFalse);
      expect(publicJson.containsKey('password_hash'), isFalse);
      expect('$created', isNot(contains('fake-password-hash-not-real')));
    });
  });
}

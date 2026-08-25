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
  Future<List<Map<String, dynamic>>> findMany(
    Map<String, dynamic> selector, {
    Map<String, int>? sort,
    int? limit,
  }) async {
    return [
      for (final document in documents)
        if (_matches(document, selector)) Map<String, dynamic>.from(document),
    ];
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

  Map<String, dynamic>? lastUpdateSelector;
  Map<String, dynamic>? lastUpdate;
  UserUpdateResult? updateResult;
  int updateCalls = 0;

  @override
  Future<UserUpdateResult> updateOne({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> update,
  }) async {
    updateCalls += 1;
    lastUpdateSelector = selector;
    lastUpdate = update;
    final forced = updateResult;
    if (forced != null) {
      return forced;
    }
    for (final document in documents) {
      if (!_matches(document, selector)) {
        continue;
      }
      final set = update[r'$set'];
      if (set is Map) {
        set.forEach((key, value) {
          document[key.toString()] = value;
        });
      }
      return const UserUpdateResult.success();
    }
    return const UserUpdateResult.notFound();
  }

  bool _matches(Map<String, dynamic> document, Map<String, dynamic> selector) {
    for (final entry in selector.entries) {
      final expected = entry.value;
      if (expected is Map && expected.containsKey(r'$lt')) {
        final actual = document[entry.key];
        final bound = expected[r'$lt'];
        if (actual is ObjectId && bound is ObjectId) {
          if (actual.oid.compareTo(bound.oid) >= 0) {
            return false;
          }
          continue;
        }
        return false;
      }
      if (expected is Map && expected.containsKey(r'$in')) {
        final options = expected[r'$in'];
        if (options is! List || !options.contains(document[entry.key])) {
          return false;
        }
        continue;
      }
      if (document[entry.key] != expected) {
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

  group('MongoUserRepository.updatePasswordHash', () {
    test('updates only password_hash and updated_at by _id', () async {
      final store = _MemoryUserDocuments()..documents.add(storedCustomer());
      final repository = MongoUserRepository(documents: store);
      final updatedAt = DateTime.utc(2026, 8, 25, 15);

      await repository.updatePasswordHash(
        userId: existingId,
        passwordHash: 'replacement-password-hash-not-real',
        updatedAt: updatedAt,
      );

      expect(store.updateCalls, equals(1));
      expect(
        store.lastUpdateSelector,
        equals(<String, dynamic>{'_id': existingId}),
      );
      expect(
        store.lastUpdate,
        equals(<String, dynamic>{
          r'$set': <String, dynamic>{
            'password_hash': 'replacement-password-hash-not-real',
            'updated_at': updatedAt,
          },
        }),
      );
      expect(
        store.documents.single['password_hash'],
        equals('replacement-password-hash-not-real'),
      );
      expect(store.documents.single['updated_at'], equals(updatedAt));
      expect(store.documents.single['role'], equals('customer'));
      expect(store.documents.single['email'], equals('Person@example.com'));
      expect(store.documents.single['account_status'], equals('active'));
      expect(store.documents.single['email_verified'], isFalse);
    });

    test('throws when no document matches', () async {
      final repository = MongoUserRepository(documents: _MemoryUserDocuments());

      expect(
        () => repository.updatePasswordHash(
          userId: existingId,
          passwordHash: 'replacement-password-hash-not-real',
          updatedAt: DateTime.utc(2026, 8, 25),
        ),
        throwsA(isA<UserAccountWriteException>()),
      );
    });

    test('throws when the write fails', () async {
      final store = _MemoryUserDocuments()
        ..documents.add(storedCustomer())
        ..updateResult = const UserUpdateResult.failed();
      final repository = MongoUserRepository(documents: store);

      expect(
        () => repository.updatePasswordHash(
          userId: existingId,
          passwordHash: 'replacement-password-hash-not-real',
          updatedAt: DateTime.utc(2026, 8, 25),
        ),
        throwsA(isA<UserAccountWriteException>()),
      );
    });
  });

  group('MongoUserRepository.findByIds', () {
    test('returns matching accounts and omits missing ids', () async {
      final otherId = ObjectId.fromHexString('507f1f77bcf86cd799439099');
      final store = _MemoryUserDocuments()..documents.add(storedCustomer());
      final repository = MongoUserRepository(documents: store);

      final found = await repository.findByIds(<ObjectId>[existingId, otherId]);

      expect(found, hasLength(1));
      expect(found.single.id, equals(existingId));
    });

    test('returns an empty list for no ids', () async {
      final repository = MongoUserRepository(documents: _MemoryUserDocuments());
      expect(await repository.findByIds(const <ObjectId>[]), isEmpty);
    });
  });
}

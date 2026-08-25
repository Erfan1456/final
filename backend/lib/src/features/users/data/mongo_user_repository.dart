import 'package:home_cleaning_marketplace_api/src/features/users/data/user_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/create_user_account_data.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/email_normalization.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// MongoDB implementation of [UserRepository].
///
/// Receives a [Db] or a [UserDocumentStore]. It does not read environment
/// variables or construct a MongoDatabase instance.
class MongoUserRepository implements UserRepository {
  /// Creates a repository over [documents].
  MongoUserRepository({required UserDocumentStore documents})
    : _documents = documents;

  /// Creates a repository using the users collection on [db].
  factory MongoUserRepository.fromDb(Db db) {
    return MongoUserRepository(documents: MongoUserDocumentStore.fromDb(db));
  }

  final UserDocumentStore _documents;

  @override
  Future<UserAccount?> findById(ObjectId id) {
    return _find(<String, dynamic>{'_id': id});
  }

  @override
  Future<UserAccount?> findByEmail(String email) {
    return _find(<String, dynamic>{
      'email_normalized': normalizeEmail(email),
    });
  }

  @override
  Future<bool> emailExists(String email) async {
    return await findByEmail(email) != null;
  }

  @override
  Future<List<UserAccount>> findByIds(Iterable<ObjectId> ids) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) {
      return const <UserAccount>[];
    }
    final documents = await _documents.findMany(<String, dynamic>{
      '_id': <String, dynamic>{r'$in': unique},
    });
    return documents.map(UserAccount.fromDocument).toList();
  }

  @override
  Future<UserAccount> create(CreateUserAccountData data) async {
    final now = DateTime.now().toUtc();
    final account = UserAccount(
      id: ObjectId(),
      role: data.role,
      email: data.email.trim(),
      emailNormalized: normalizeEmail(data.email),
      passwordHash: data.passwordHash,
      accountStatus: data.accountStatus,
      emailVerified: data.emailVerified,
      createdAt: now,
      updatedAt: now,
    );

    final result = await _documents.insertOne(account.toDocument());
    if (result.isDuplicateKey) {
      throw const DuplicateUserEmailException();
    }
    if (!result.isSuccess) {
      throw const UserAccountWriteException();
    }
    return account;
  }

  @override
  Future<void> updatePasswordHash({
    required ObjectId userId,
    required String passwordHash,
    required DateTime updatedAt,
  }) async {
    final result = await _documents.updateOne(
      selector: <String, dynamic>{'_id': userId},
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'password_hash': passwordHash,
          'updated_at': updatedAt.toUtc(),
        },
      },
    );
    if (!result.isSuccess) {
      throw const UserAccountWriteException();
    }
  }

  @override
  Future<UserAccount> markEmailVerified({
    required ObjectId userId,
    required DateTime updatedAt,
  }) async {
    final result = await _documents.updateOne(
      selector: <String, dynamic>{'_id': userId},
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'email_verified': true,
          'updated_at': updatedAt.toUtc(),
        },
      },
    );
    if (!result.isSuccess) {
      throw const UserAccountWriteException();
    }
    final account = await findById(userId);
    if (account == null) {
      throw const UserAccountWriteException();
    }
    return account;
  }

  @override
  Future<UserAccountPage> adminPage({
    required int limit,
    UserRole? role,
    AccountStatus? status,
    String? emailNormalized,
    ObjectId? after,
  }) async {
    final selector = <String, dynamic>{};
    if (role != null) {
      selector['role'] = role.wireValue;
    }
    if (status != null) {
      selector['account_status'] = status.wireValue;
    }
    if (emailNormalized != null) {
      selector['email_normalized'] = emailNormalized;
    }
    if (after != null) {
      selector['_id'] = <String, dynamic>{r'$lt': after};
    }
    final documents = await _documents.findMany(
      selector,
      sort: const <String, int>{'_id': -1},
      limit: limit + 1,
    );
    final hasMore = documents.length > limit;
    final page = hasMore ? documents.sublist(0, limit) : documents;
    final items = page.map(UserAccount.fromDocument).toList();
    return UserAccountPage(
      items: items,
      nextCursor: hasMore ? items.last.id.oid : null,
    );
  }

  @override
  Future<UserAccount?> setActiveToSuspended({
    required ObjectId userId,
    required DateTime now,
  }) {
    return _setStatus(
      userId: userId,
      now: now,
      fromStatuses: <String>[AccountStatus.active.wireValue],
      toStatus: AccountStatus.suspended,
    );
  }

  @override
  Future<UserAccount?> setSuspendedToActive({
    required ObjectId userId,
    required DateTime now,
  }) {
    return _setStatus(
      userId: userId,
      now: now,
      fromStatuses: <String>[AccountStatus.suspended.wireValue],
      toStatus: AccountStatus.active,
    );
  }

  @override
  Future<UserAccount?> setActiveOrSuspendedToDeactivated({
    required ObjectId userId,
    required DateTime now,
  }) {
    return _setStatus(
      userId: userId,
      now: now,
      fromStatuses: <String>[
        AccountStatus.active.wireValue,
        AccountStatus.suspended.wireValue,
      ],
      toStatus: AccountStatus.deactivated,
    );
  }

  Future<UserAccount?> _setStatus({
    required ObjectId userId,
    required DateTime now,
    required List<String> fromStatuses,
    required AccountStatus toStatus,
  }) async {
    final result = await _documents.updateOne(
      selector: <String, dynamic>{
        '_id': userId,
        'role': <String, dynamic>{
          r'$in': <String>[
            UserRole.customer.wireValue,
            UserRole.cleaner.wireValue,
          ],
        },
        'account_status': fromStatuses.length == 1
            ? fromStatuses.first
            : <String, dynamic>{r'$in': fromStatuses},
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'account_status': toStatus.wireValue,
          'updated_at': now.toUtc(),
        },
      },
    );
    if (!result.isSuccess && result.matched) {
      throw const UserAccountWriteException();
    }
    if (!result.matched) {
      return null;
    }
    return findById(userId);
  }

  Future<UserAccount?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return UserAccount.fromDocument(document);
  }
}

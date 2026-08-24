import 'package:home_cleaning_marketplace_api/src/features/users/data/user_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/create_user_account_data.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/email_normalization.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
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

  Future<UserAccount?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return UserAccount.fromDocument(document);
  }
}

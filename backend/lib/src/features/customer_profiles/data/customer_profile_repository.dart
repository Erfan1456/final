import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for customer marketplace profiles.
abstract class CustomerProfileRepository {
  /// Returns the profile owned by [userId], or `null`.
  Future<CustomerProfile?> findByUserId(ObjectId userId);

  /// Returns profiles whose `user_id` is in [ids]. Missing ids are omitted.
  Future<List<CustomerProfile>> findByUserIds(Iterable<ObjectId> ids);

  /// Creates or updates the owned profile's editable fields.
  ///
  /// Does not accept `user_id`, `default_address_id`, or timestamps from
  /// callers as document-owned identity. [userId] is the authenticated owner.
  Future<CustomerProfile> upsertProfile({
    required ObjectId userId,
    required String fullName,
    required String? phoneE164,
  });

  /// Sets [addressId] as the profile's default address pointer.
  ///
  /// Returns `null` when no profile exists for [userId].
  Future<CustomerProfile?> setDefaultAddress({
    required ObjectId userId,
    required ObjectId addressId,
  });

  /// Clears `default_address_id` only when it currently equals [addressId].
  Future<void> clearDefaultAddressIfMatches({
    required ObjectId userId,
    required ObjectId addressId,
  });
}

/// MongoDB implementation of [CustomerProfileRepository].
class MongoCustomerProfileRepository implements CustomerProfileRepository {
  /// Creates a repository over [documents].
  MongoCustomerProfileRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  /// Creates a repository using the customer_profiles collection on [db].
  factory MongoCustomerProfileRepository.fromDb(Db db) {
    return MongoCustomerProfileRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.customerProfiles),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<CustomerProfile?> findByUserId(ObjectId userId) {
    return _find(<String, dynamic>{'user_id': userId});
  }

  @override
  Future<List<CustomerProfile>> findByUserIds(Iterable<ObjectId> ids) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) {
      return const <CustomerProfile>[];
    }
    final documents = await _documents.findMany(
      selector: <String, dynamic>{
        'user_id': <String, dynamic>{r'$in': unique},
      },
    );
    return documents.map(CustomerProfile.fromDocument).toList();
  }

  @override
  Future<CustomerProfile> upsertProfile({
    required ObjectId userId,
    required String fullName,
    required String? phoneE164,
  }) async {
    final now = DateTime.now().toUtc();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{'user_id': userId},
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'full_name': fullName,
          'phone_e164': phoneE164,
          'updated_at': now,
        },
        r'$setOnInsert': <String, dynamic>{
          '_id': ObjectId(),
          'user_id': userId,
          'created_at': now,
          'default_address_id': null,
        },
      },
      upsert: true,
    );
    if (!result.isSuccess) {
      final retry = await _documents.updateOne(
        selector: <String, dynamic>{'user_id': userId},
        update: <String, dynamic>{
          r'$set': <String, dynamic>{
            'full_name': fullName,
            'phone_e164': phoneE164,
            'updated_at': now,
          },
        },
      );
      if (!retry.isSuccess && !retry.matched) {
        throw const CustomerProfileWriteException();
      }
    }
    final profile = await findByUserId(userId);
    if (profile == null) {
      throw const CustomerProfileWriteException();
    }
    return profile;
  }

  @override
  Future<CustomerProfile?> setDefaultAddress({
    required ObjectId userId,
    required ObjectId addressId,
  }) async {
    final now = DateTime.now().toUtc();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{'user_id': userId},
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'default_address_id': addressId,
          'updated_at': now,
        },
      },
    );
    if (!result.isSuccess && result.matched) {
      throw const CustomerProfileWriteException();
    }
    if (!result.matched) {
      return null;
    }
    return findByUserId(userId);
  }

  @override
  Future<void> clearDefaultAddressIfMatches({
    required ObjectId userId,
    required ObjectId addressId,
  }) async {
    final now = DateTime.now().toUtc();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{
        'user_id': userId,
        'default_address_id': addressId,
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'default_address_id': null,
          'updated_at': now,
        },
      },
    );
    if (!result.isSuccess && result.matched) {
      throw const CustomerProfileWriteException();
    }
  }

  Future<CustomerProfile?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return CustomerProfile.fromDocument(document);
  }
}

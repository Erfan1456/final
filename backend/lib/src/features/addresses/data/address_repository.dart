import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Editable address fields owned by the application service after validation.
class AddressWriteData {
  /// Creates validated address fields.
  const AddressWriteData({
    required this.label,
    required this.line1,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.countryCode,
    this.line2,
  });

  /// Short label.
  final String label;

  /// Primary street line.
  final String line1;

  /// Optional second street line.
  final String? line2;

  /// City / locality.
  final String city;

  /// Region / state / division.
  final String region;

  /// Postal code.
  final String postalCode;

  /// Uppercase ISO 3166-1 alpha-2 country code.
  final String countryCode;
}

/// Persistence contract for customer service addresses.
abstract class AddressRepository {
  /// Counts addresses owned by [userId].
  Future<int> countForUser(ObjectId userId);

  /// Lists addresses owned by [userId], newest first.
  Future<List<Address>> listForUser(ObjectId userId);

  /// Finds [id] only when it is also owned by [userId].
  Future<Address?> findOwnedById({
    required ObjectId id,
    required ObjectId userId,
  });

  /// Inserts an owned address. [userId] is the authenticated owner.
  Future<Address> create({
    required ObjectId userId,
    required AddressWriteData data,
  });

  /// Replaces editable fields of an owned address.
  Future<Address?> updateOwned({
    required ObjectId id,
    required ObjectId userId,
    required AddressWriteData data,
  });

  /// Deletes an owned address. Returns `false` when not found.
  Future<bool> deleteOwned({
    required ObjectId id,
    required ObjectId userId,
  });
}

/// MongoDB implementation of [AddressRepository].
class MongoAddressRepository implements AddressRepository {
  /// Creates a repository over [documents].
  MongoAddressRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  /// Creates a repository using the addresses collection on [db].
  factory MongoAddressRepository.fromDb(Db db) {
    return MongoAddressRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.addresses),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<int> countForUser(ObjectId userId) {
    return _documents.count(<String, dynamic>{'user_id': userId});
  }

  @override
  Future<List<Address>> listForUser(ObjectId userId) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{'user_id': userId},
      sort: const <String, int>{'created_at': -1},
    );
    return documents.map(Address.fromDocument).toList();
  }

  @override
  Future<Address?> findOwnedById({
    required ObjectId id,
    required ObjectId userId,
  }) {
    return _find(<String, dynamic>{'_id': id, 'user_id': userId});
  }

  @override
  Future<Address> create({
    required ObjectId userId,
    required AddressWriteData data,
  }) async {
    final now = DateTime.now().toUtc();
    final address = Address(
      id: ObjectId(),
      userId: userId,
      label: data.label,
      line1: data.line1,
      line2: data.line2,
      city: data.city,
      region: data.region,
      postalCode: data.postalCode,
      countryCode: data.countryCode,
      createdAt: now,
      updatedAt: now,
    );
    final result = await _documents.insertOne(address.toDocument());
    if (!result.isSuccess) {
      throw const AddressWriteException();
    }
    return address;
  }

  @override
  Future<Address?> updateOwned({
    required ObjectId id,
    required ObjectId userId,
    required AddressWriteData data,
  }) async {
    final now = DateTime.now().toUtc();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{'_id': id, 'user_id': userId},
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'label': data.label,
          'line1': data.line1,
          'line2': data.line2,
          'city': data.city,
          'region': data.region,
          'postal_code': data.postalCode,
          'country_code': data.countryCode,
          'updated_at': now,
        },
      },
    );
    if (!result.isSuccess && result.matched) {
      throw const AddressWriteException();
    }
    if (!result.matched) {
      return null;
    }
    return findOwnedById(id: id, userId: userId);
  }

  @override
  Future<bool> deleteOwned({
    required ObjectId id,
    required ObjectId userId,
  }) async {
    final result = await _documents.deleteOne(<String, dynamic>{
      '_id': id,
      'user_id': userId,
    });
    if (!result.isSuccess && result.deleted) {
      throw const AddressWriteException();
    }
    return result.deleted;
  }

  Future<Address?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return Address.fromDocument(document);
  }
}

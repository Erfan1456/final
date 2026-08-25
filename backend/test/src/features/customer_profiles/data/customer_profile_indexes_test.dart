import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_indexes.dart';
import 'package:test/test.dart';

class _RecordingEnsureIndex {
  String? collectionName;
  Map<String, dynamic>? keys;
  bool? unique;
  String? name;
  int calls = 0;

  Future<void> call({
    required String collectionName,
    required Map<String, dynamic> keys,
    required bool unique,
    required String name,
  }) async {
    calls += 1;
    this.collectionName = collectionName;
    this.keys = Map<String, dynamic>.from(keys);
    this.unique = unique;
    this.name = name;
  }
}

void main() {
  group('ensureCustomerProfileIndexes', () {
    test('requests the unique user_id index', () async {
      final recorder = _RecordingEnsureIndex();
      await ensureCustomerProfileIndexes(ensureIndex: recorder.call);

      expect(recorder.calls, equals(1));
      expect(recorder.collectionName, equals(CollectionNames.customerProfiles));
      expect(
        recorder.keys,
        equals(const <String, dynamic>{customerProfilesUserIdField: 1}),
      );
      expect(recorder.unique, isTrue);
      expect(recorder.name, equals(customerProfilesUserIdUniqueIndexName));
      expect(recorder.name, equals('customer_profiles_user_id_unique'));
    });
  });
}
